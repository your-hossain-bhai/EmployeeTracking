// auth_service.dart
// Authentication Service
//
// This service handles user authentication via Firebase Auth.
// It provides methods for sign in, sign up, sign out, and
// manages the current user state.

import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_model.dart';

/// Authentication service for managing user authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await getUserProfile(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Register a new user with email and password
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String companyId,
    UserRole role = UserRole.employee,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(displayName);

        // Create user profile in Firestore
        final now = DateTime.now();
        final user = UserModel(
          id: credential.user!.uid,
          email: email,
          displayName: displayName,
          role: role,
          companyId: companyId,
          createdAt: now,
          updatedAt: now,
        );

        await _firestore
            .collection('users')
            .doc(user.id)
            .set(user.toFirestore());

        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get user profile from Firestore
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.id)
        .update(user.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  /// Upload profile photo to Firebase Storage and return the download URL
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      final storage = FirebaseStorage.instance;
      final ref = storage.ref().child('profile_photos/$userId.jpg');

      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      print('Uploading photo for user: $userId');
      print('File path: ${imageFile.path}');
      print('File size: ${await imageFile.length()} bytes');

      // Upload the file with metadata
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': userId},
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      print('Upload complete. Bytes transferred: ${snapshot.bytesTransferred}');

      // Get the download URL
      final downloadUrl = await ref.getDownloadURL();
      print('Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      rethrow;
    }
  }

  /// Update user profile photo
  Future<void> updateProfilePhoto(String userId, File imageFile) async {
    // Upload the photo and get URL
    final photoUrl = await uploadProfilePhoto(userId, imageFile);

    // Update user document with new photo URL
    await _firestore.collection('users').doc(userId).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Also update Firebase Auth profile
    await _auth.currentUser?.updatePhotoURL(photoUrl);
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No authenticated user');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No authenticated user');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete Firestore data
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete auth account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email');
      case 'wrong-password':
        return Exception('Wrong password');
      case 'email-already-in-use':
        return Exception('Email is already registered');
      case 'invalid-email':
        return Exception('Invalid email address');
      case 'weak-password':
        return Exception('Password is too weak');
      case 'user-disabled':
        return Exception('User account has been disabled');
      case 'too-many-requests':
        return Exception('Too many requests. Please try again later');
      default:
        return Exception(e.message ?? 'Authentication error');
    }
  }
}
