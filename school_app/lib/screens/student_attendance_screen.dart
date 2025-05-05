import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_app/services/attendance_service.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AttendanceService _attendanceService = AttendanceService();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _attendanceService.getStudentAttendance(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading attendance'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final attendanceRecords = snapshot.data!.docs;
          if (attendanceRecords.isEmpty) {
            return const Center(child: Text('No attendance records found'));
          }

          return ListView.builder(
            itemCount: attendanceRecords.length,
            itemBuilder: (context, index) {
              final record = attendanceRecords[index];
              final data = record.data() as Map<String, dynamic>;

              return ListTile(
                title: Text('Class: ${data['className']}'),
                subtitle: Text(
                  'Date: ${data['date']} | Status: ${data['isPresent'] ? 'Present' : 'Absent'}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}