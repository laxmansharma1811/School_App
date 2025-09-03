import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:school_app/services/notification_service.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  Future<void> addAssignment({
    required String title,
    required String description,
    required DateTime deadline,
    String? classId, // Add class ID parameter
    String? className, // Add class name parameter
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        Fluttertoast.showToast(msg: 'User not authenticated');
        return;
      }

      // Get teacher information
      DocumentSnapshot teacherDoc = await _firestore
          .collection('profiles')
          .doc(currentUser.uid)
          .get();

      String teacherName = 'Unknown Teacher';
      if (teacherDoc.exists) {
        Map<String, dynamic> teacherData = teacherDoc.data() as Map<String, dynamic>;
        teacherName = '${teacherData['firstName'] ?? ''} ${teacherData['lastName'] ?? ''}'.trim();
        if (teacherName.isEmpty) {
          teacherName = teacherData['email'] ?? 'Unknown Teacher';
        }
      }

      // Add assignment to Firestore
      DocumentReference assignmentRef = await _firestore.collection('assignments').add({
        'title': title,
        'description': description,
        'deadline': Timestamp.fromDate(deadline),
        'classId': classId,
        'className': className,
        'teacherId': currentUser.uid,
        'teacherName': teacherName,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Send notification to students in the specified class
      if (classId != null) {
        await _notificationService.sendAssignmentNotificationToClass(
          assignmentId: assignmentRef.id,
          assignmentTitle: title,
          description: description,
          deadline: deadline,
          classId: classId,
          className: className ?? 'Unknown Class',
        );
      }

      Fluttertoast.showToast(msg: 'Assignment added and notifications sent');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to add assignment: $e');
    }
  }

  Future<void> updateAssignment({
    required String assignmentId,
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    try {
      await _firestore.collection('assignments').doc(assignmentId).update({
        'title': title,
        'description': description,
        'deadline': Timestamp.fromDate(deadline),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Fluttertoast.showToast(msg: 'Assignment updated successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to update assignment: $e');
    }
  }

  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _firestore.collection('assignments').doc(assignmentId).delete();
      Fluttertoast.showToast(msg: 'Assignment deleted successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to delete assignment: $e');
    }
  }

  Stream<QuerySnapshot> getAssignments() {
    return _firestore
        .collection('assignments')
        .orderBy('deadline')
        .snapshots();
  }
}
