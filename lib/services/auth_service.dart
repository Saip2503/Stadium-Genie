import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Exception thrown for any failures occurring during the authentication process.
class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}

/// Service class handling authentication logic, supporting Google Sign-in and
/// Anonymous login options with configurable request timeouts.
class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Stream of user auth state updates.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Retrieve the current logged-in user profile, if available.
  User? get currentUser => _auth.currentUser;

  /// Performs Google Sign-In with popup (on Web) or redirect credential exchange (on Mobile).
  /// Sets a 30 seconds operation timeout limits to prevent hanging.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        return await _auth
            .signInWithPopup(googleProvider)
            .timeout(const Duration(seconds: 30));
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn
            .signIn()
            .timeout(const Duration(seconds: 30));
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication.timeout(const Duration(seconds: 30));
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth
            .signInWithCredential(credential)
            .timeout(const Duration(seconds: 30));
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

  /// Logs the user in anonymously as a guest.
  /// Sets a 30 seconds operation timeout.
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth
          .signInAnonymously()
          .timeout(const Duration(seconds: 30));
    } on FirebaseAuthException catch (e) {
      debugPrint("Anonymous sign in failed: ${e.code} ${e.message}");
      throw AuthServiceException(
        e.message ??
            'Anonymous sign-in failed. Please verify Firebase Authentication is configured.',
      );
    } catch (e) {
      debugPrint("Anonymous sign in failed: $e");
      rethrow;
    }
  }

  /// Logs the current session user out, clearing cached tokens.
  Future<void> signOut() async {
    try {
      await _auth.signOut().timeout(const Duration(seconds: 30));
      if (!kIsWeb) {
        await _googleSignIn.signOut().timeout(const Duration(seconds: 30));
      }
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }
}
