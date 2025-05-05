import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SubmissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> submitAssignment({
    required String assignmentId,
    required String studentId,
    required PlatformFile file,
  }) async {
    try {
      String fileName = file.name;
      Reference storageRef = _storage.ref().child('submissions/$assignmentId/$studentId/$fileName');
      UploadTask uploadTask;

      if (kIsWeb) {
        // Web: Upload file bytes
        uploadTask = storageRef.putData(file.bytes!);
      } else {
        // Android: Upload file from path
        uploadTask = storageRef.putFile(File(file.path!));
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('submissions').add({
        'assignmentId': assignmentId,
        'studentId': studentId,
        'fileUrl': downloadUrl,
        'fileName': fileName,
        'submittedAt': FieldValue.serverTimestamp(),
        'grade': null,
      });
      Fluttertoast.showToast(msg: 'Submission uploaded successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to submit assignment: $e');
    }
  }

  Future<void> gradeSubmission({
    required String submissionId,
    required double grade,
  }) async {
    try {
      await _firestore.collection('submissions').doc(submissionId).update({
        'grade': grade,
        'gradedAt': FieldValue.serverTimestamp(),
      });
      Fluttertoast.showToast(msg: 'Submission graded successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to grade submission: $e');
    }
  }

  Stream<QuerySnapshot> getSubmissions(String assignmentId) {
    return _firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots();
  }

  Stream<QuerySnapshot> getStudentSubmissions(String studentId) {
    return _firestore
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .snapshots();
  }
}