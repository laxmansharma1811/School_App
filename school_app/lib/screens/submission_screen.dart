import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/screens/grade_submission_screen.dart';
import 'package:school_app/services/submission_service.dart';


class SubmissionScreen extends StatelessWidget {
  final String assignmentId;

  const SubmissionScreen({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context) {
    final SubmissionService _submissionService = SubmissionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submissions'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _submissionService.getSubmissions(assignmentId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading submissions'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final submissions = snapshot.data!.docs;

          if (submissions.isEmpty) {
            return const Center(child: Text('No submissions found'));
          }

          return ListView.builder(
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final submission = submissions[index];
              final data = submission.data() as Map<String, dynamic>;

              return ListTile(
                title: Text('Submission by Student ID: ${data['studentId']}'),
                subtitle: Text(
                  'File: ${data['fileName']} \nSubmitted: ${(data['submittedAt'] as Timestamp).toDate()} \nGrade: ${data['grade']?.toString() ?? 'Not Graded'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.grade),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GradeSubmissionScreen(
                          submissionId: submission.id,
                          submissionData: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}