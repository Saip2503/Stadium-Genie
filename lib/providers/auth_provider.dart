import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the current Firebase user.
final userProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider for the current user's profile info (synchronous).
final currentUserProvider = Provider<User?>((ref) {
  // This is a simple wrapper around FirebaseAuth.instance.currentUser
  // In a real app, you might want to listen to userProvider
  return FirebaseAuth.instance.currentUser;
});
