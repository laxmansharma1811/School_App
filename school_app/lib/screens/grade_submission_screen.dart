import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_app/services/submission_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GradeSubmissionScreen extends StatefulWidget {
  final String submissionId;
  final Map<String, dynamic> submissionData;

  const GradeSubmissionScreen({
    super.key,
    required this.submissionId,
    required this.submissionData,
  });

  @override
  _GradeSubmissionScreenState createState() => _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState extends State<GradeSubmissionScreen> {
  final SubmissionService _submissionService = SubmissionService();
  final _gradeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.submissionData['grade'] != null) {
      _gradeController.text = widget.submissionData['grade'].toString();
    }
  }

  void _gradeSubmission() async {
    final grade = double.tryParse(_gradeController.text.trim());
    if (grade == null || grade < 0 || grade > 100) {
      Fluttertoast.showToast(msg: 'Enter a valid grade (0-100)');
      return;
    }

    setState(() => _isLoading = true);
    await _submissionService.gradeSubmission(
      submissionId: widget.submissionId,
      grade: grade,
    );
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Submission'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('File: ${widget.submissionData['fileName']}'),
            Text('Submitted: ${(widget.submissionData['submittedAt'] as Timestamp).toDate()}'),
            const SizedBox(height: 20),
            TextField(
              controller: _gradeController,
              decoration: const InputDecoration(
                labelText: 'Grade (0-100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _gradeSubmission,
                    child: const Text('Submit Grade'),
                  ),
          ],
        ),
      ),
    );
  }
}