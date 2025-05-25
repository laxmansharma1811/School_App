import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/screens/grade_submission_screen.dart';
import 'package:school_app/services/submission_service.dart';
import 'package:intl/intl.dart'; // Add this package for date formatting

class SubmissionScreen extends StatelessWidget {
  final String assignmentId;

  const SubmissionScreen({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context) {
    final SubmissionService _submissionService = SubmissionService();
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final bool isDesktop = screenSize.width > 1024;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        title: const Text(
          'Submissions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implement filtering functionality
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.withOpacity(0.05), Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _submissionService.getSubmissions(assignmentId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading submissions',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              );
            }

            final submissions = snapshot.data!.docs;

            if (submissions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No submissions found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Assignment ID: $assignmentId',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            // Responsive layout based on screen size
            if (isDesktop) {
              // Grid view for desktop
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: submissions.length,
                  itemBuilder:
                      (context, index) =>
                          _buildSubmissionCard(context, submissions[index]),
                ),
              );
            } else if (isTablet) {
              // Grid view for tablet
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: submissions.length,
                  itemBuilder:
                      (context, index) =>
                          _buildSubmissionCard(context, submissions[index]),
                ),
              );
            } else {
              // List view for mobile
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: ListView.builder(
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    return _buildSubmissionListItem(
                      context,
                      submissions[index],
                    );
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // Card design for tablet and desktop
  Widget _buildSubmissionCard(
    BuildContext context,
    DocumentSnapshot submission,
  ) {
    final data = submission.data() as Map<String, dynamic>;
    final DateTime submittedDate = (data['submittedAt'] as Timestamp).toDate();
    final String formattedDate = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(submittedDate);
    final bool isGraded = data['grade'] != null;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.withOpacity(0.2),
                  child: Icon(Icons.assignment_turned_in, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student ID: ${data['studentId']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.insert_drive_file,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['fileName'] ?? 'Unnamed file',
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.grade,
                  size: 16,
                  color: isGraded ? Colors.amber : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  isGraded ? 'Grade: ${data['grade']}' : 'Not Graded',
                  style: TextStyle(
                    fontWeight: isGraded ? FontWeight.bold : FontWeight.normal,
                    color: isGraded ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.grade, size: 16),
                label: Text(isGraded ? 'Update Grade' : 'Grade'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => GradeSubmissionScreen(
                            submissionId: submission.id,
                            submissionData: data,
                          ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // List item design for mobile
  Widget _buildSubmissionListItem(
    BuildContext context,
    DocumentSnapshot submission,
  ) {
    final data = submission.data() as Map<String, dynamic>;
    final DateTime submittedDate = (data['submittedAt'] as Timestamp).toDate();
    final String formattedDate = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(submittedDate);
    final bool isGraded = data['grade'] != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.teal.withOpacity(0.2),
                  child: const Icon(
                    Icons.assignment_turned_in,
                    color: Colors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student ID: ${data['studentId']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['fileName'] ?? 'Unnamed file',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.grade,
                            size: 16,
                            color: isGraded ? Colors.amber : Colors.grey[400],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isGraded ? 'Grade: ${data['grade']}' : 'Not Graded',
                            style: TextStyle(
                              fontWeight:
                                  isGraded
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isGraded ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => GradeSubmissionScreen(
                              submissionId: submission.id,
                              submissionData: data,
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    isGraded ? 'Update' : 'Grade',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
