import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('profiles').doc(user.uid).get();
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to get profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String dateOfBirth,
    required String gender,
    String? employeeId, // For teachers
    String? department, // For teachers
    String? qualification, // For teachers
    String? experience, // For teachers
    String? studentId, // For students
    String? grade, // For students
    String? rollNumber, // For students
    String? parentName, // For students
    String? parentPhone, // For students
    String? emergencyContact, // For students
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Get user role
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        String role = userDoc.exists ? userDoc['role'] : 'student';

        Map<String, dynamic> profileData = {
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'address': address,
          'dateOfBirth': dateOfBirth,
          'gender': gender,
          'role': role,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add role-specific fields
        if (role == 'teacher') {
          profileData.addAll({
            'employeeId': employeeId ?? '',
            'department': department ?? '',
            'qualification': qualification ?? '',
            'experience': experience ?? '',
          });
        } else if (role == 'student') {
          profileData.addAll({
            'studentId': studentId ?? '',
            'grade': grade ?? '',
            'rollNumber': rollNumber ?? '',
            'parentName': parentName ?? '',
            'parentPhone': parentPhone ?? '',
            'emergencyContact': emergencyContact ?? '',
          });
        }

        await _firestore.collection('profiles').doc(user.uid).set(
          profileData,
          SetOptions(merge: true),
        );

        Fluttertoast.showToast(msg: 'Profile updated successfully');
        return true;
      }
      return false;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to update profile: $e');
      return false;
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.exists ? doc['role'] : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Delete profile (optional)
  Future<bool> deleteProfile() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('profiles').doc(user.uid).delete();
        Fluttertoast.showToast(msg: 'Profile deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to delete profile: $e');
      return false;
    }
  }
}
