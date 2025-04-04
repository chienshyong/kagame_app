import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

class AppleAuthHelper {
  /// Sign in with Apple using Firebase Auth's direct provider approach
  static Future<UserCredential?> signInWithApple() async {
    try {
      // Check if Apple Sign In is available on this device
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        debugPrint("Apple Sign In is not available on this device");
        return null;
      }
      
      // Use Firebase's direct approach with Apple provider
      debugPrint("Trying direct Firebase Apple provider approach");
      final appleProvider = OAuthProvider('apple.com');
      appleProvider.addScope('email');
      
      final credential = await FirebaseAuth.instance.signInWithProvider(appleProvider);
      debugPrint("Direct provider approach succeeded");
      return credential;
    } catch (e) {
      debugPrint("Apple Sign In failed: $e");
      rethrow;
    }
  }
}