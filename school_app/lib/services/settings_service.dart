import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Change user password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        Fluttertoast.showToast(
          msg: 'User not authenticated',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }

      // Re-authenticate user with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      Fluttertoast.showToast(
        msg: 'Password changed successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Password change failed';
      
      switch (e.code) {
        case 'wrong-password':
          message = 'Current password is incorrect';
          break;
        case 'weak-password':
          message = 'New password is too weak';
          break;
        case 'requires-recent-login':
          message = 'Please log out and log in again before changing password';
          break;
        default:
          message = e.message ?? 'Password change failed';
      }

      Fluttertoast.showToast(
        msg: message,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An unexpected error occurred: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? address,
    String? dateOfBirth,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('profiles').doc(user.uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'address': address,
        'dateOfBirth': dateOfBirth,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(
        msg: 'Profile updated successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      return true;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to update profile: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'notifications': prefs.getBool('notifications') ?? true,
      'darkMode': prefs.getBool('darkMode') ?? false,
      'language': prefs.getString('language') ?? 'English',
      'autoBackup': prefs.getBool('autoBackup') ?? true,
      'biometricAuth': prefs.getBool('biometricAuth') ?? false,
    };
  }

  // Save user preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('notifications', preferences['notifications'] ?? true);
    await prefs.setBool('darkMode', preferences['darkMode'] ?? false);
    await prefs.setString('language', preferences['language'] ?? 'English');
    await prefs.setBool('autoBackup', preferences['autoBackup'] ?? true);
    await prefs.setBool('biometricAuth', preferences['biometricAuth'] ?? false);

    Fluttertoast.showToast(
      msg: 'Preferences saved successfully',
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = await _firestore.collection('profiles').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Delete account
  Future<bool> deleteAccount(String currentPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      await _firestore.collection('profiles').doc(user.uid).delete();
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user account
      await user.delete();

      Fluttertoast.showToast(
        msg: 'Account deleted successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      return true;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to delete account: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Export user data
  Future<Map<String, dynamic>?> exportUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot profile = await _firestore.collection('profiles').doc(user.uid).get();
      DocumentSnapshot userData = await _firestore.collection('users').doc(user.uid).get();

      Map<String, dynamic> exportData = {
        'user_info': {
          'email': user.email,
          'created_at': user.metadata.creationTime?.toIso8601String(),
          'last_sign_in': user.metadata.lastSignInTime?.toIso8601String(),
        },
        'profile': profile.exists ? profile.data() : null,
        'user_data': userData.exists ? userData.data() : null,
        'exported_at': DateTime.now().toIso8601String(),
      };

      return exportData;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to export data: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return null;
    }
  }
}
