import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mark attendance for a class
  Future<void> markAttendance({
    required String className,
    required String date,
    required String studentId,
    required bool isPresent,
  }) async {
    try {
      await _firestore.collection('attendance').add({
        'className': className,
        'date': date, // Format: YYYY-MM-DD
        'studentId': studentId,
        'isPresent': isPresent,
        'markedAt': FieldValue.serverTimestamp(),
      });
      Fluttertoast.showToast(msg: 'Attendance marked successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to mark attendance: $e');
    }
  }

  // Get attendance records for a specific class and date
  Stream<QuerySnapshot> getAttendanceByClassAndDate(String className, String date) {
    return _firestore
        .collection('attendance')
        .where('className', isEqualTo: className)
        .where('date', isEqualTo: date)
        .snapshots();
  }

  // Get attendance records for a specific student
  Stream<QuerySnapshot> getStudentAttendance(String studentId) {
    return _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots();
  }
}
