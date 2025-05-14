import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_app/services/submission_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.submissionData['grade'] != null) {
      _gradeController.text = widget.submissionData['grade'].toString();
    }
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  void _gradeSubmission() async {
    if (!_formKey.currentState!.validate()) return;

    final grade = double.tryParse(_gradeController.text.trim());
    if (grade == null || grade < 0 || grade > 100) {
      Fluttertoast.showToast(msg: 'Enter a valid grade (0-100)');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _submissionService.gradeSubmission(
        submissionId: widget.submissionId,
        grade: grade,
      );
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Grade submitted successfully',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to submit grade: ${e.toString()}',
          backgroundColor: Colors.red,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Submission'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubmissionInfoCard(isSmallScreen),
                          SizedBox(height: isSmallScreen ? 24.0 : 32.0),
                          _buildGradeSection(isSmallScreen),
                          SizedBox(height: isSmallScreen ? 32.0 : 48.0),
                          _buildSubmitButton(isSmallScreen),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubmissionInfoCard(bool isSmallScreen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submission Details',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Divider(height: 24),
            _infoRow(
              'Student',
              widget.submissionData['studentName'] ?? 'Unknown Student',
              isSmallScreen,
            ),
            _infoRow(
              'Assignment',
              widget.submissionData['assignmentTitle'] ?? 'Untitled Assignment',
              isSmallScreen,
            ),
            _infoRow(
              'File',
              widget.submissionData['fileName'] ?? 'No file',
              isSmallScreen,
            ),
            _infoRow(
              'Submitted',
              _formatDate(widget.submissionData['submittedAt'] as Timestamp),
              isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child:
          isSmallScreen
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 16)),
                ],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(value, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
    );
  }

  Widget _buildGradeSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Grade',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _gradeController,
          decoration: InputDecoration(
            labelText: 'Grade (0-100)',
            hintText: 'Enter a number between 0 and 100',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.grade),
            suffixText: '%',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a grade';
            }
            final grade = double.tryParse(value);
            if (grade == null) {
              return 'Please enter a valid number';
            }
            if (grade < 0 || grade > 100) {
              return 'Grade must be between 0 and 100';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 50 : 56,
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                onPressed: _gradeSubmission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Submit Grade',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
    );
  }
}
