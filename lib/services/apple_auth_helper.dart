import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

class AppleAuthHelper {
  // Creates a cryptographically secure random nonce
  static String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // SHA256 hash
  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Basic implementation without any extra parameters
  static Future<UserCredential?> signInWithApple() async {
    try {
      // Check if available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        debugPrint("Apple Sign In is not available on this device");
        return null;
      }
      
      // 1. Simple approach - direct provider without nonce
      try {
        debugPrint("Trying direct Firebase Apple provider approach");
        final appleProvider = OAuthProvider('apple.com');
        appleProvider.addScope('email');
        
        final credential = await FirebaseAuth.instance.signInWithProvider(appleProvider);
        debugPrint("Direct provider approach succeeded");
        return credential;
      } catch (e) {
        debugPrint("Direct provider approach failed: $e");
        // Fall through to next approach
      }
      
      // 2. Traditional approach with nonce
      try {
        debugPrint("Trying traditional Apple Sign In approach with nonce");
        // Generate nonce and SHA256 hash
        final rawNonce = generateNonce();
        final nonce = sha256ofString(rawNonce);
        
        // Request Apple credentials
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
          ],
          nonce: nonce,
        );
        
        // Ensure we got an identity token
        if (appleCredential.identityToken == null) {
          debugPrint("Apple identity token is null");
          throw Exception("Failed to get Apple identity token");
        }
        
        // Create Firebase credential
        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken!,
          rawNonce: rawNonce,
        );
        
        // Sign in with Firebase
        final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
        debugPrint("Traditional approach succeeded");
        return userCredential;
      } catch (e) {
        debugPrint("Traditional approach failed: $e");
        // Fall through to next approach
      }
      
      // 3. Minimal approach without nonce
      try {
        debugPrint("Trying minimal Apple Sign In approach without nonce");
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email],
        );
        
        if (appleCredential.identityToken == null) {
          debugPrint("Apple identity token is null in minimal approach");
          throw Exception("Failed to get Apple identity token");
        }
        
        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken!,
          accessToken: appleCredential.authorizationCode,
        );
        
        final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
        debugPrint("Minimal approach succeeded");
        return userCredential;
      } catch (e) {
        debugPrint("Minimal approach failed: $e");
        // All approaches failed
        throw e;
      }
    } catch (e) {
      debugPrint("All Apple Sign In approaches failed: $e");
      rethrow;
    }
  }
}