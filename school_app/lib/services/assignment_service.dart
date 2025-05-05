import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addAssignment({
    required String title,
    required String description,
    required DateTime deadline,
  }) async {
    try {
      await _firestore.collection('assignments').add({
        'title': title,
        'description': description,
        'deadline': Timestamp.fromDate(deadline),
        'createdAt': FieldValue.serverTimestamp(),
      });
      Fluttertoast.showToast(msg: 'Assignment added successfully');
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
