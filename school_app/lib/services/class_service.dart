import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new class (only teachers and admins can do this)
  Future<bool> createClass({
    required String className,
    required String section,
    required String subject,
    required String description,
    required String teacherId,
    required String teacherName,
    required int maxStudents,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Check if user is teacher or admin
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      String role = userDoc.exists ? userDoc['role'] : '';
      if (role != 'teacher' && role != 'admin') {
        Fluttertoast.showToast(
          msg: 'Only teachers and admins can create classes',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }

      // Create the class
      await _firestore.collection('classes').add({
        'className': className,
        'section': section,
        'subject': subject,
        'description': description,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'maxStudents': maxStudents,
        'currentStudents': 0,
        'studentIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser.uid,
        'isActive': true,
      });

      Fluttertoast.showToast(
        msg: 'Class created successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      return true;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to create class: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Get all classes
  Stream<QuerySnapshot> getAllClasses() {
    return _firestore
        .collection('classes')
        .where('isActive', isEqualTo: true)
        .orderBy('className')
        .orderBy('section')
        .snapshots();
  }

  // Get classes by teacher
  Stream<QuerySnapshot> getClassesByTeacher(String teacherId) {
    return _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .orderBy('className')
        .snapshots();
  }

  // Get classes for current teacher
  Stream<QuerySnapshot> getMyClasses() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }
    return getClassesByTeacher(currentUser.uid);
  }

  // Assign student to class (only teacher of that class can do this)
  Future<bool> assignStudentToClass({
    required String classId,
    required String studentId,
    required String studentName,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get class document
      DocumentSnapshot classDoc = await _firestore
          .collection('classes')
          .doc(classId)
          .get();

      if (!classDoc.exists) {
        Fluttertoast.showToast(
          msg: 'Class not found',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      
      // Check if current user is the teacher of this class or admin
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      String role = userDoc.exists ? userDoc['role'] : '';
      bool isTeacherOfClass = classData['teacherId'] == currentUser.uid;
      bool isAdmin = role == 'admin';

      if (!isTeacherOfClass && !isAdmin) {
        Fluttertoast.showToast(
          msg: 'Only the class teacher or admin can assign students',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }

      // Check if class is full
      List<dynamic> studentIds = classData['studentIds'] ?? [];
      int maxStudents = classData['maxStudents'] ?? 30;
      
      if (studentIds.length >= maxStudents) {
        Fluttertoast.showToast(
          msg: 'Class is full (${maxStudents} students maximum)',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }

      // Check if student is already in this class
      if (studentIds.contains(studentId)) {
        Fluttertoast.showToast(
          msg: 'Student is already in this class',
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return false;
      }

      // Add student to class
      await _firestore.collection('classes').doc(classId).update({
        'studentIds': FieldValue.arrayUnion([studentId]),
        'currentStudents': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update student's profile with class information
      await _firestore.collection('profiles').doc(studentId).update({
        'classId': classId,
        'className': classData['className'],
        'section': classData['section'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(
        msg: 'Student assigned to class successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      return true;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to assign student: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Remove student from class
  Future<bool> removeStudentFromClass({
    required String classId,
    required String studentId,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get class document
      DocumentSnapshot classDoc = await _firestore
          .collection('classes')
          .doc(classId)
          .get();

      if (!classDoc.exists) return false;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      
      // Check permissions
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      String role = userDoc.exists ? userDoc['role'] : '';
      bool isTeacherOfClass = classData['teacherId'] == currentUser.uid;
      bool isAdmin = role == 'admin';

      if (!isTeacherOfClass && !isAdmin) {
        Fluttertoast.showToast(
          msg: 'Only the class teacher or admin can remove students',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }

      // Remove student from class
      await _firestore.collection('classes').doc(classId).update({
        'studentIds': FieldValue.arrayRemove([studentId]),
        'currentStudents': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove class information from student's profile
      await _firestore.collection('profiles').doc(studentId).update({
        'classId': FieldValue.delete(),
        'className': FieldValue.delete(),
        'section': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(
        msg: 'Student removed from class successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      return true;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to remove student: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Get students in a class
  Future<List<Map<String, dynamic>>> getStudentsInClass(String classId) async {
    try {
      DocumentSnapshot classDoc = await _firestore
          .collection('classes')
          .doc(classId)
          .get();

      if (!classDoc.exists) return [];

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> studentIds = classData['studentIds'] ?? [];

      if (studentIds.isEmpty) return [];

      // Get student profiles
      List<Map<String, dynamic>> students = [];
      for (String studentId in studentIds) {
        DocumentSnapshot studentDoc = await _firestore
            .collection('profiles')
            .doc(studentId)
            .get();
        
        if (studentDoc.exists) {
          Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;
          studentData['id'] = studentId;
          students.add(studentData);
        }
      }

      return students;
    } catch (e) {
      return [];
    }
  }

  // Update class details (only teacher of that class can do this)
  Future<bool> updateClass({
    required String classId,
    required String className,
    required String section,
    required String subject,
    required String description,
    required int maxStudents,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get class document
      DocumentSnapshot classDoc = await _firestore
          .collection('classes')
          .doc(classId)
          .get();

      if (!classDoc.exists) return false;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      
      // Check permissions
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      String role = userDoc.exists ? userDoc['role'] : '';
      bool isTeacherOfClass = classData['teacherId'] == currentUser.uid;
      bool isAdmin = role == 'admin';

      if (!isTeacherOfClass && !isAdmin) {
        Fluttertoast.showToast(
          msg: 'Only the class teacher or admin can update class details',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }

      // Check if reducing max students would exceed current students
      int currentStudents = classData['currentStudents'] ?? 0;
      if (maxStudents < currentStudents) {
        Fluttertoast.showToast(
          msg: 'Cannot reduce max students below current count ($currentStudents)',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }

      // Update class
      await _firestore.collection('classes').doc(classId).update({
        'className': className,
        'section': section,
        'subject': subject,
        'description': description,
        'maxStudents': maxStudents,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update class name in student profiles if changed
      if (classData['className'] != className || classData['section'] != section) {
        List<dynamic> studentIds = classData['studentIds'] ?? [];
        WriteBatch batch = _firestore.batch();
        
        for (String studentId in studentIds) {
          DocumentReference studentRef = _firestore.collection('profiles').doc(studentId);
          batch.update(studentRef, {
            'className': className,
            'section': section,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
      }

      Fluttertoast.showToast(
        msg: 'Class updated successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      return true;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to update class: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Delete class (only teacher of that class or admin can do this)
  Future<bool> deleteClass(String classId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get class document
      DocumentSnapshot classDoc = await _firestore
          .collection('classes')
          .doc(classId)
          .get();

      if (!classDoc.exists) return false;

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      
      // Check permissions
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      String role = userDoc.exists ? userDoc['role'] : '';
      bool isTeacherOfClass = classData['teacherId'] == currentUser.uid;
      bool isAdmin = role == 'admin';

      if (!isTeacherOfClass && !isAdmin) {
        Fluttertoast.showToast(
          msg: 'Only the class teacher or admin can delete the class',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }

      // Remove class from all student profiles
      List<dynamic> studentIds = classData['studentIds'] ?? [];
      WriteBatch batch = _firestore.batch();
      
      for (String studentId in studentIds) {
        DocumentReference studentRef = _firestore.collection('profiles').doc(studentId);
        batch.update(studentRef, {
          'classId': FieldValue.delete(),
          'className': FieldValue.delete(),
          'section': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Mark class as inactive instead of deleting
      batch.update(_firestore.collection('classes').doc(classId), {
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();

      Fluttertoast.showToast(
        msg: 'Class deleted successfully',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      return true;
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to delete class: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  // Get available students (not assigned to any class)
  Future<List<Map<String, dynamic>>> getAvailableStudents() async {
    try {
      QuerySnapshot studentsQuery = await _firestore
          .collection('profiles')
          .where('role', isEqualTo: 'student')
          .get();

      List<Map<String, dynamic>> availableStudents = [];
      
      for (QueryDocumentSnapshot doc in studentsQuery.docs) {
        Map<String, dynamic> studentData = doc.data() as Map<String, dynamic>;
        
        // Check if student is not assigned to any class
        if (!studentData.containsKey('classId') || studentData['classId'] == null) {
          studentData['id'] = doc.id;
          availableStudents.add(studentData);
        }
      }

      return availableStudents;
    } catch (e) {
      return [];
    }
  }
}
