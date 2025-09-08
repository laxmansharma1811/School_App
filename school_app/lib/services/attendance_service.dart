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
    String? markedBy,
    String? notes,
  }) async {
    try {
      // Ensure date is in MM/DD/YYYY format
      DateTime parsedDate = DateTime.parse(date);
      String formattedDate = "${parsedDate.month}/${parsedDate.day}/${parsedDate.year}";
      
      await _firestore.collection('attendance').add({
        'className': className,
        'date': formattedDate,
        'studentId': studentId,
        'isPresent': isPresent,
        'markedBy': markedBy,
        'notes': notes,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Fluttertoast.showToast(msg: 'Attendance marked successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to mark attendance: $e');
      throw e; // Rethrow to handle in UI
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
