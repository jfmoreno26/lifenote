import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Wraps Firebase Auth and the signed-in user's profile document (`users/{uid}`).
class AuthService extends ChangeNotifier {
  AuthService() {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  User? get user => _auth.currentUser;
  AppUser? profile;
  bool initializing = true;

  bool get isAdmin => profile?.isAdmin ?? false;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _db.collection('users').doc(uid);

  Future<void> _onAuthChanged(User? u) async {
    await _profileSub?.cancel();
    _profileSub = null;
    profile = null;
    if (u == null) {
      initializing = false;
      notifyListeners();
      return;
    }
    final ref = _userDoc(u.uid);
    try {
      final snap = await ref.get();
      if (!snap.exists) {
        // Merge so we never clobber the name written concurrently by register().
        await ref.set({
          if ((u.displayName ?? '').isNotEmpty) 'name': u.displayName,
          'email': u.email ?? '',
          'role': Role.user.name,
          'waterGoal': 8,
          'glassMl': 250,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Profile bootstrap failed: $e');
    }
    _profileSub = ref.snapshots().listen((s) {
      if (s.exists) profile = AppUser.fromDoc(s);
      initializing = false;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('Profile stream error: $e');
      initializing = false;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) =>
      _guard(() => _auth.signInWithEmailAndPassword(email: email.trim(), password: password));

  Future<void> register(String name, String email, String password) => _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
        await cred.user?.updateDisplayName(name.trim());
        // The auth listener may already have created the doc without a name.
        await _userDoc(cred.user!.uid).set({
          'name': name.trim(),
          'email': email.trim(),
          'role': Role.user.name,
        }, SetOptions(merge: true));
      });

  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  Future<void> signOut() => _auth.signOut();

  Future<void> updateName(String name) => _guard(() async {
        await user!.updateDisplayName(name.trim());
        await _userDoc(user!.uid).update({'name': name.trim()});
      });

  Future<void> updateWaterGoal(int glasses, int glassMl) =>
      _userDoc(user!.uid).update({'waterGoal': glasses, 'glassMl': glassMl});

  Future<void> _reauth(String password) async {
    final cred = EmailAuthProvider.credential(email: user!.email!, password: password);
    await user!.reauthenticateWithCredential(cred);
  }

  Future<void> changePassword(String current, String next) => _guard(() async {
        await _reauth(current);
        await user!.updatePassword(next);
      });

  /// Sends a verification link to [newEmail]; the change applies once it's clicked.
  Future<void> changeEmail(String password, String newEmail) => _guard(() async {
        await _reauth(password);
        await user!.verifyBeforeUpdateEmail(newEmail.trim());
      });

  /// Deletes all of the user's data, their profile and finally the auth account.
  Future<void> deleteAccount(String password) => _guard(() async {
        await _reauth(password);
        final uid = user!.uid;
        for (final name in ['notes', 'activities', 'projects', 'water']) {
          final docs = await _userDoc(uid).collection(name).get();
          var batch = _db.batch();
          var n = 0;
          for (final d in docs.docs) {
            batch.delete(d.reference);
            if (++n % 400 == 0) {
              await batch.commit();
              batch = _db.batch();
            }
          }
          await batch.commit();
        }
        await _userDoc(uid).delete();
        await user!.delete();
      });

  /// Admin only: list every user profile (enforced by Firestore rules).
  Stream<List<AppUser>> allUsers() => _db
      .collection('users')
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromDoc).toList()..sort((a, b) => a.name.compareTo(b.name)));

  Future<void> setRole(String uid, Role role) => _userDoc(uid).update({'role': role.name});

  Future<Map<String, int>> userCounts(String uid) async {
    final out = <String, int>{};
    for (final name in ['notes', 'activities', 'projects']) {
      final agg = await _userDoc(uid).collection(name).count().get();
      out[name] = agg.count ?? 0;
    }
    return out;
  }

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    } on FirebaseException catch (e) {
      throw AuthFailure(e.message ?? 'Something went wrong.');
    }
  }

  static String _message(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => 'That email address looks invalid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' => 'Incorrect email or password.',
        'email-already-in-use' => 'An account already exists for that email.',
        'weak-password' => 'Use a stronger password (at least 6 characters).',
        'requires-recent-login' => 'Please sign in again and retry.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'network-request-failed' => 'No internet connection.',
        _ => e.message ?? 'Authentication failed.',
      };

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
