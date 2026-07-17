import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        return await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Google sign in failed: ${e.code} ${e.message}");
      if (e.code == 'configuration-not-found') {
        throw const AuthServiceException(
          'Google sign-in is not enabled for this Firebase project yet. In Firebase Console, open Authentication, enable the Google provider, and make sure the Web app uses the stadium-genie Firebase config.',
        );
      }
      throw AuthServiceException(
        e.message ??
            'Google sign-in failed. Please check the Firebase Authentication setup.',
      );
    } catch (e) {
      debugPrint("Google sign in failed: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }
}
