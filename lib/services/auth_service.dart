import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _updateLastLogin(credential.user!.uid);
        return await getUserProfile(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        final user = UserModel(
          id: credential.user!.uid,
          email: email,
          displayName: displayName,
          role: role,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          privacySettings: PrivacySettings(),
        );
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(user.toFirestore());
        return user;
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> getUserProfile(String oderId) async {
    try {
      final doc = await _firestore.collection('users').doc(oderId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.id)
        .update(user.toFirestore());
  }

  Future<void> updatePrivacySettings(
    String oderId,
    PrivacySettings settings,
  ) async {
    await _firestore.collection('users').doc(oderId).update({
      'privacySettings': settings.toMap(),
    });
  }

  Future<void> _updateLastLogin(String oderId) async {
    await _firestore.collection('users').doc(oderId).update({
      'lastLoginAt': Timestamp.now(),
    });
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }
}
