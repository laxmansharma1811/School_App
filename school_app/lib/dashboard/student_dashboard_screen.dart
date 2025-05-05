import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_app/services/assignment_service.dart';
import 'package:school_app/services/submission_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> with SingleTickerProviderStateMixin {
  final AssignmentService _assignmentService = AssignmentService();
  final SubmissionService _submissionService = SubmissionService();
  final user = FirebaseAuth.instance.currentUser;
  
  late TabController _tabController;
  bool _isUploading = false;
  String? _uploadingAssignmentId;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _uploadAssignment(String assignmentId) async {
    setState(() {
      _isUploading = true;
      _uploadingAssignmentId = assignmentId;
    });
    
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        await _submissionService.submitAssignment(
          assignmentId: assignmentId,
          studentId: user!.uid,
          file: file,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting assignment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadingAssignmentId = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  int _getDaysRemaining(DateTime deadline) {
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }

  Color _getDeadlineColor(DateTime deadline) {
    final daysRemaining = _getDaysRemaining(deadline);
    
    if (daysRemaining < 0) {
      return Colors.red;
    } else if (daysRemaining <= 1) {
      return Colors.orange;
    } else if (daysRemaining <= 3) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: Theme.of(context).primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'My Assignments',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          top: -20,
                          child: Icon(
                            Icons.assignment,
                            size: 100,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'PENDING'),
                    Tab(text: 'COMPLETED'),
                  ],
                ),
              ),
            ];
          },
          body: _buildAssignmentsList(),
        ),
      ),
    );
  }

  Widget _buildAssignmentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _assignmentService.getAssignments(),
      builder: (context, assignmentSnapshot) {
        if (assignmentSnapshot.hasError) {
          return _buildErrorState('Error loading assignments');
        }
        
        if (!assignmentSnapshot.hasData) {
          return _buildLoadingState();
        }

        final assignments = assignmentSnapshot.data!.docs;

        return StreamBuilder<QuerySnapshot>(
          stream: _submissionService.getStudentSubmissions(user!.uid),
          builder: (context, submissionSnapshot) {
            if (submissionSnapshot.hasError) {
              return _buildErrorState('Error loading submissions');
            }
            
            if (!submissionSnapshot.hasData) {
              return _buildLoadingState();
            }

            final submissions = submissionSnapshot.data!.docs;
            final pendingAssignments = assignments.where((assignment) {
              return !submissions.any((submission) =>
                  submission['assignmentId'] == assignment.id);
            }).toList();
            
            final completedAssignments = assignments.where((assignment) {
              return submissions.any((submission) =>
                  submission['assignmentId'] == assignment.id);
            }).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildPendingAssignments(pendingAssignments),
                _buildCompletedAssignments(completedAssignments, submissions),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Loading assignments...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAssignments(List<QueryDocumentSnapshot> pendingAssignments) {
    if (pendingAssignments.isEmpty) {
      return _buildEmptyState(
        'No pending assignments',
        'You\'re all caught up!',
        Icons.check_circle_outline,
        Colors.green,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingAssignments.length,
        itemBuilder: (context, index) {
          final assignment = pendingAssignments[index];
          final data = assignment.data() as Map<String, dynamic>;
          final deadline = (data['deadline'] as Timestamp).toDate();
          final daysRemaining = _getDaysRemaining(deadline);
          final deadlineColor = _getDeadlineColor(deadline);
          
          return _buildAssignmentCard(
            title: data['title'] ?? 'No Title',
            description: data['description'] ?? 'No description provided',
            deadline: deadline,
            daysRemaining: daysRemaining,
            deadlineColor: deadlineColor,
            isPending: true,
            onUpload: () => _uploadAssignment(assignment.id),
            isUploading: _isUploading && _uploadingAssignmentId == assignment.id,
          );
        },
      ),
    );
  }

  Widget _buildCompletedAssignments(
    List<QueryDocumentSnapshot> completedAssignments,
    List<QueryDocumentSnapshot> submissions,
  ) {
    if (completedAssignments.isEmpty) {
      return _buildEmptyState(
        'No completed assignments',
        'You haven\'t submitted any assignments yet',
        Icons.assignment_outlined,
        Colors.grey,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: completedAssignments.length,
        itemBuilder: (context, index) {
          final assignment = completedAssignments[index];
          final data = assignment.data() as Map<String, dynamic>;
          final submission = submissions.firstWhere(
            (s) => s['assignmentId'] == assignment.id,
          );
          final submissionData = submission.data() as Map<String, dynamic>;
          final submittedAt = (submissionData['submittedAt'] as Timestamp).toDate();
          final grade = submissionData['grade'];
          
          return _buildAssignmentCard(
            title: data['title'] ?? 'No Title',
            description: data['description'] ?? 'No description provided',
            submittedAt: submittedAt,
            grade: grade,
            isPending: false,
          );
        },
      ),
    );
  }

  Widget _buildAssignmentCard({
    required String title,
    required String description,
    DateTime? deadline,
    DateTime? submittedAt,
    int? daysRemaining,
    Color? deadlineColor,
    dynamic grade,
    bool isPending = true,
    VoidCallback? onUpload,
    bool isUploading = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isPending 
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPending ? Icons.assignment_outlined : Icons.assignment_turned_in,
                  color: isPending 
                      ? Theme.of(context).primaryColor
                      : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isPending 
                          ? Theme.of(context).primaryColor
                          : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                if (isPending && deadline != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: deadlineColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Deadline: ${_formatDate(deadline)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: deadlineColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        daysRemaining! < 0 
                            ? Icons.warning 
                            : Icons.timer,
                        size: 16,
                        color: deadlineColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        daysRemaining < 0
                            ? 'Overdue by ${daysRemaining.abs()} days'
                            : daysRemaining == 0
                                ? 'Due today'
                                : '$daysRemaining days remaining',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: deadlineColor,
                        ),
                      ),
                    ],
                  ),
                ],
                if (!isPending && submittedAt != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Submitted: ${_formatDate(submittedAt)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        grade != null ? Icons.grade : Icons.hourglass_empty,
                        size: 16,
                        color: grade != null ? Colors.amber : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        grade != null 
                            ? 'Grade: $grade' 
                            : 'Not graded yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: grade != null ? Colors.amber : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isPending && onUpload != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isUploading ? null : onUpload,
                      icon: isUploading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(isUploading ? 'Uploading...' : 'Submit Assignment'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: color.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
