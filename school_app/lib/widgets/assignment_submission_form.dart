import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AssignmentSubmissionForm extends StatefulWidget {
  final String assignmentId;
  final Map<String, dynamic> assignmentData;

  const AssignmentSubmissionForm({
    Key? key,
    required this.assignmentId,
    required this.assignmentData,
  }) : super(key: key);

  @override
  State<AssignmentSubmissionForm> createState() => _AssignmentSubmissionFormState();
}

class _AssignmentSubmissionFormState extends State<AssignmentSubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final _submissionController = TextEditingController();
  bool _isSubmitting = false;
  String? _existingSubmission;
  DateTime? _submissionDate;

  @override
  void initState() {
    super.initState();
    _loadExistingSubmission();
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSubmission() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(userId)
          .get();

      if (doc.exists) {
        setState(() {
          _existingSubmission = doc.data()?['content'];
          _submissionDate = (doc.data()?['submittedAt'] as Timestamp).toDate();
          _submissionController.text = _existingSubmission ?? '';
        });
      }
    } catch (e) {
      print('Error loading submission: $e');
    }
  }

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get user details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      final userName = '${userDoc.get('firstName')} ${userDoc.get('lastName')}';

      // Create submission document
      await FirebaseFirestore.instance
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(userId)
          .set({
            'content': _submissionController.text.trim(),
            'studentId': userId,
            'studentName': userName,
            'submittedAt': FieldValue.serverTimestamp(),
            'status': 'submitted',
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting assignment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadline = (widget.assignmentData['deadline'] as Timestamp).toDate();
    final isOverdue = DateTime.now().isAfter(deadline);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Assignment'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.assignmentData['title'] ?? 'Assignment',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.assignmentData['description'] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Deadline: ${DateFormat('MMM dd, yyyy • hh:mm a').format(deadline)}',
                            style: TextStyle(
                              color: isOverdue ? Colors.red : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_existingSubmission != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Previously Submitted',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            if (_submissionDate != null)
                              Text(
                                'on ${DateFormat('MMM dd, yyyy • hh:mm a').format(_submissionDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Your Submission',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _submissionController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: 'Enter your submission here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your submission';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAssignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit Assignment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
