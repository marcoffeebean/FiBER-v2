import 'dart:typed_data';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class AccountException implements Exception {
  AccountException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AccountProfile {
  const AccountProfile({
    required this.username,
    required this.email,
    this.photoUrl,
  });

  final String username;
  final String email;
  final String? photoUrl;
}

class AccountService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw AccountException('You are not signed in.');
    return user;
  }

  // Converts Firebase errors into messages the UI can show.
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AccountException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AccountException(_authMessage(e));
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: ${e.code} ${e.message}');
      throw AccountException(
        e.code == 'permission-denied'
            ? 'You do not have permission to make this change.'
            : 'Could not save. Check your connection and try again.',
      );
    }
  }

  static String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'The current password is incorrect.';
      case 'email-already-in-use':
        return 'That email is already used by another account.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'requires-recent-login':
        return 'For security, please enter your current password again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Something went wrong (${e.code}). Please try again.';
    }
  }

  /// Reloads the Firebase Auth user and reads the profile from Firestore.
  /// If a verified email change has happened, Firestore is brought in line.
  static Future<AccountProfile> loadProfile() => _guard(() async {
    final user = _requireUser();
    await user.reload();
    final authEmail = _auth.currentUser?.email ?? user.email ?? '';

    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    final storedEmail = (data['email'] ?? '').toString();

    if (authEmail.isNotEmpty && authEmail != storedEmail) {
      await _db.collection('users').doc(user.uid).set({
        'email': authEmail,
      }, SetOptions(merge: true));
    }

    return AccountProfile(
      username: (data['username'] ?? '').toString(),
      email: authEmail.isNotEmpty ? authEmail : storedEmail,
      photoUrl: data['photoBase64'] as String?,
    );
  });

  static Future<void> saveUsername(String username) => _guard(() async {
    final user = _requireUser();
    await _db.collection('users').doc(user.uid).set({
      'username': username,
    }, SetOptions(merge: true));
  });

  /// Required before changing email or password.
  static Future<void> reauthenticate(String currentPassword) =>
      _guard(() async {
        final user = _requireUser();
        final email = user.email;
        if (email == null) {
          throw AccountException('This account has no email address.');
        }
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: currentPassword),
        );
      });

  /// Sends a verification link to the new address. The sign-in email changes
  /// only after the user clicks it. Firestore is updated later by loadProfile.
  static Future<void> requestEmailChange(String newEmail) => _guard(() async {
    final user = _requireUser();
    await user.verifyBeforeUpdateEmail(newEmail);
  });

  static Future<void> changePassword(String newPassword) => _guard(() async {
    final user = _requireUser();
    await user.updatePassword(newPassword);
  });

  /// Stores the picture at avatars/<own uid>. Storage rules allow writes only
  /// to the signed-in user's own path, so one user cannot replace another's.
  /// Stores a small thumbnail (base64) on the user's own Firestore document.
  static Future<String> uploadAvatar(Uint8List bytes) => _guard(() async {
    final user = _requireUser();
    final encoded = base64Encode(bytes);
    await _db.collection('users').doc(user.uid).set({
      'photoBase64': encoded,
    }, SetOptions(merge: true));
    return encoded;
  });
}
