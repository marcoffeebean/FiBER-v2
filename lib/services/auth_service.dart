import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static AppUser? _currentUser;
  static AppUser? get currentUser => _currentUser;

  // ── Sign Up — always student by default ───────────────────────
  static Future<AppUser?> signUp(
    String email,
    String password,
    String username, {
    String name = '',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await _db.collection('users').doc(uid).set({
        'email': email,
        'username': username,
        'name': name,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _currentUser = AppUser(
        id: uid,
        email: email,
        role: UserRole.student,
        username: username,
        name: name,
        password: password,
      );

      return _currentUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('SignUp error: $e');
      return null;
    }
  }

  // ── Login — role fetched from Firestore ───────────────────────
  static Future<AppUser?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();

      if (data == null) {
        debugPrint('No Firestore document found for uid: $uid');
        return null;
      }

      final roleStr = (data['role'] ?? 'student')
          .toString()
          .trim()
          .toLowerCase();
      debugPrint('Role from Firestore: "$roleStr"');

      UserRole role;
      switch (roleStr) {
        case 'admin':
          role = UserRole.admin;
          break;
        case 'teacher':
          role = UserRole.teacher;
          break;
        default:
          role = UserRole.student;
      }

      debugPrint('Parsed role: ${role.name}');

      _currentUser = AppUser(
        id: uid,
        email: email,
        role: role,
        username: data['username'] ?? '',
        name: data['name'] ?? '',
        password: '',
      );

      return _currentUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────
  static Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }

  // ── Create Teacher Account (admin only) ───────────────────────
  static Future<bool> createTeacherAccount({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      // Use secondary Firebase app so admin stays logged in
      final secondaryApp = await Firebase.initializeApp(
        name: 'secondary',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Create teacher account using secondary app
      final credential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Save teacher data to Firestore
      await _db.collection('users').doc(uid).set({
        'email': email,
        'username': username,
        'name': name,
        'role': 'teacher',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Teacher account created: $email');

      // Sign out from secondary app and delete it
      await secondaryAuth.signOut();
      await secondaryApp.delete();

      return true;
    } catch (e) {
      debugPrint('Create teacher error: $e');
      return false;
    }
  }

  // ── Get all users (admin) ──────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllUsersAsync() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'email': data['email'] ?? '',
          'username': data['username'] ?? '',
          'name': data['name'] ?? '',
          'role': data['role'] ?? '',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Edit user (admin) ──────────────────────────────────────────
  static Future<bool> editUser({
    required String id,
    String? newEmail,
    String? newPassword,
    String? newName,
    String? newUsername,
    String? newRole,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (newName != null) updates['name'] = newName;
      if (newUsername != null) updates['username'] = newUsername;
      if (newEmail != null) updates['email'] = newEmail;
      if (newRole != null) updates['role'] = newRole;

      await _db.collection('users').doc(id).update(updates);

      if (newPassword != null && newPassword.isNotEmpty) {
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == id) {
          await currentUser.updatePassword(newPassword);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Delete user (admin) ────────────────────────────────────────
  static Future<void> deleteUser(String id) async {
    try {
      await _db.collection('users').doc(id).delete();
    } catch (e) {}
  }

  // ── Update password ────────────────────────────────────────────
  static Future<bool> updatePassword(String newPassword) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.updatePassword(newPassword);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ── Update username ────────────────────────────────────────────
  static Future<bool> updateUsername(String newUsername) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && _currentUser != null) {
        await _db
            .collection('users')
            .doc(currentUser.uid)
            .update({'username': newUsername});
        _currentUser = AppUser(
          id: _currentUser!.id,
          email: _currentUser!.email,
          role: _currentUser!.role,
          username: newUsername,
          name: _currentUser!.name,
          password: _currentUser!.password,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ── Update email ───────────────────────────────────────────────
  static Future<bool> updateEmail(String newEmail) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && _currentUser != null) {
        await currentUser.verifyBeforeUpdateEmail(newEmail);
        await _db.collection('users').doc(currentUser.uid).update({
          'email': newEmail,
        });
        _currentUser = AppUser(
          id: _currentUser!.id,
          email: newEmail,
          role: _currentUser!.role,
          username: _currentUser!.username,
          name: _currentUser!.name,
          password: _currentUser!.password,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}