import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TimetableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new timetable
  Future<void> addTimetable({
    required String className,
    required String day,
    required String time,
    required String subject,
  }) async {
    try {
      await _firestore.collection('timetables').add({
        'className': className,
        'day': day,
        'time': time,
        'subject': subject,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Fluttertoast.showToast(msg: 'Timetable added successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to add timetable: $e');
    }
  }

  // Update an existing timetable
  Future<void> updateTimetable({
    required String timetableId,
    required String className,
    required String day,
    required String time,
    required String subject,
  }) async {
    try {
      await _firestore.collection('timetables').doc(timetableId).update({
        'className': className,
        'day': day,
        'time': time,
        'subject': subject,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Fluttertoast.showToast(msg: 'Timetable updated successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to update timetable: $e');
    }
  }

  // Delete a timetable
  Future<void> deleteTimetable(String timetableId) async {
    try {
      await _firestore.collection('timetables').doc(timetableId).delete();
      Fluttertoast.showToast(msg: 'Timetable deleted successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to delete timetable: $e');
    }
  }

  // Get stream of timetables for real-time updates
  Stream<QuerySnapshot> getTimetables() {
    return _firestore
        .collection('timetables')
        .orderBy('day')
        .orderBy('time')
        .snapshots();
  }
}