import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new student
  Future<void> addStudent({
    required String name,
    required String grade,
    required int attendance,
    required double academicScore,
  }) async {
    try {
      await _firestore.collection('students').add({
        'name': name,
        'grade': grade,
        'attendance': attendance,
        'academicScore': academicScore,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Fluttertoast.showToast(msg: 'Student added successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to add student: $e');
    }
  }

  // Update an existing student
  Future<void> updateStudent({
    required String studentId,
    required String name,
    required String grade,
    required int attendance,
    required double academicScore,
  }) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'name': name,
        'grade': grade,
        'attendance': attendance,
        'academicScore': academicScore,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Fluttertoast.showToast(msg: 'Student updated successfully');
    } catch ( _e) {
      Fluttertoast.showToast(msg: 'Failed to update student: $e');
    }
  }

  // Delete a student
  Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).delete();
      Fluttertoast.showToast(msg: 'Student deleted successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to delete student: $e');
    }
  }

  // Get stream of students for real-time updates
  Stream<QuerySnapshot> getStudents() {
    return _firestore.collection('students').orderBy('name').snapshots();
  }
}