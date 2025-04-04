import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as fcm;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'apple_auth_helper.dart';

class AuthService {
  final String baseUrl = Config.apiUrl;
  final storage = new FlutterSecureStorage();

  Future<void> register(String username, String password) async {
    print("Attempting registration");
    final response = await http
        .post(
          Uri.parse('$baseUrl/register'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'username': username,
            'password': password,
          }),
        )
        .timeout(
          const Duration(seconds: 3),
        );

    if (response.statusCode != 200) {
      final responseJson = jsonDecode(response.body);
      final message = responseJson["detail"];
      print(responseJson["detail"]);
      throw Exception(message);
    }
  }

Future<void> login(String username, String password) async {
  print("Attempting login");
  final response = await http.post(
    Uri.parse('$baseUrl/token'),  // Ensure the correct endpoint is used
    headers: <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',  // Use form-encoded content type
    },
    body: {
      'username': username,  // Form-urlencoded data
      'password': password,
    },
  ).timeout(const Duration(seconds: 3),);

  print(response.body);  // Debug print to show the full response

  if (response.statusCode == 200) {
    final responseJson = jsonDecode(response.body);
    await storage.write(key: 'token', value: responseJson['access_token']);
    await storage.write(key: 'username', value: username);
  } else {
    final responseJson = jsonDecode(response.body);
    final message = responseJson["detail"];
    print(message);
    throw Exception(message);
  }
}

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  Future<String?> getUsername() async {
    return await storage.read(key: 'username');
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'username');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await fcm.DefaultCacheManager().emptyCache();
  }
  
  //Google sign in
  Future<bool> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    print("Signed in as ${userCredential.user?.displayName}");
    await storage.write(key: 'username', value: userCredential.user?.displayName);

    //Get Firebase ID Token
    User? user = FirebaseAuth.instance.currentUser;
    String? idToken = await user?.getIdToken(); // This is the Firebase-issued ID token

    //Get session token from our backend and save it
    final response = await http.post(
      Uri.parse('$baseUrl/googlelogin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body);
      await storage.write(key: 'token', value: responseJson['access_token']);
      return true;
    }
    return false;
  }
  
  // Apple sign in - Simplified version
  Future<bool> signInWithApple() async {
    print("🍎 Starting simplified Apple Sign In process");
    
    try {
      // Use helper class that tries multiple approaches
      final UserCredential? userCredential = await AppleAuthHelper.signInWithApple();
      
      if (userCredential == null || userCredential.user == null) {
        print("❌ Failed to get user from Apple Sign In");
        return false;
      }
      
      print("✅ Apple Sign In successful!");
      print("🍎 User ID: ${userCredential.user?.uid}");
      print("🍎 Email: ${userCredential.user?.email}");
      
      // Get and store display name
      String? displayName = userCredential.user?.displayName;
      if (displayName == null || displayName.isEmpty) {
        // Fall back to email prefix if available
        displayName = userCredential.user?.email?.split('@')[0] ?? 'Apple User';
        print("🍎 Using email-derived display name: $displayName");
      }
      
      // Store username
      await storage.write(key: 'username', value: displayName);
      print("✅ Stored username: $displayName");
      
      // Send token to backend
      try {
        print("🍎 Getting Firebase ID token for backend");
        final idToken = await userCredential.user?.getIdToken();
        
        if (idToken == null) {
          print("❌ Firebase ID token is null");
          throw Exception("Failed to get Firebase ID token");
        }
        
        print("✅ Got Firebase token (${idToken.length} chars)");
        print("🍎 Sending token to backend");
        
        final response = await http.post(
          Uri.parse('$baseUrl/applelogin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_token': idToken}),
        ).timeout(const Duration(seconds: 10));
        
        print("🍎 Backend response status: ${response.statusCode}");
        
        if (response.statusCode == 200) {
          final responseJson = jsonDecode(response.body);
          await storage.write(key: 'token', value: responseJson['access_token']);
          print("✅ Successfully saved backend token");
        } else {
          print("❌ Backend login failed: ${response.statusCode}");
          // Continue with login even if backend token exchange fails
        }
      } catch (backendError) {
        print("❌ Backend error: $backendError");
        // Continue with login even if backend fails
      }
      
      return true;
    } catch (e) {
      print("❌ Apple Sign In failed: $e");
      
      // Show detailed error if it's an Apple error code
      if (e.toString().contains("1000")) {
        print("❌ Error 1000 - Provider configuration issue");
        print("❌ Make sure Sign in with Apple is enabled in Apple Developer Portal");
        print("❌ Verify Firebase has Apple provider enabled");
      }
      
      rethrow;
    }
  }
}
