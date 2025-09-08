import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/assignment_submission_form.dart';

class StudentAssignmentScreen extends StatefulWidget {
  const StudentAssignmentScreen({super.key});

  @override
  _StudentAssignmentScreenState createState() => _StudentAssignmentScreenState();
}

class _StudentAssignmentScreenState extends State<StudentAssignmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _studentClassId;
  String? _studentClassName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentClassInfo();
  }

  void _loadStudentClassInfo() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // First check the users collection for class information
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String classId = userData['class'] ?? '';

        if (classId.isNotEmpty) {
          // Fetch class details from classes collection
          DocumentSnapshot classDoc = await _firestore
              .collection('classes')
              .doc(classId)
              .get();

          if (classDoc.exists) {
            Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
            setState(() {
              _studentClassId = classId;
              _studentClassName = classData['className'] ?? 'Unknown Class';
              _isLoading = false;
            });
            return;
          }
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading class info: $e');
      setState(() {
        _isLoading = false;
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
      appBar: AppBar(
        title: const Text(
          'My Assignments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6C63FF).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _studentClassId == null
                ? _buildNoClassAssigned()
                : _buildAssignmentsList(),
      ),
    );
  }

  Widget _buildNoClassAssigned() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Class Assigned',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You haven\'t been assigned to any class yet. Please contact your teacher or administrator to be assigned to a class.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsList() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.class_, color: Color(0xFF6C63FF), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Class: $_studentClassName',
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('assignments')
                .where('classId', isEqualTo: _studentClassId)
                .where('isActive', isEqualTo: true)
                .orderBy('deadline')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading assignments',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                );
              }

              List<QueryDocumentSnapshot> assignments = snapshot.data?.docs ?? [];

              if (assignments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Assignments Yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You don\'t have any assignments for your class yet. New assignments will appear here when your teacher creates them.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  final data = assignment.data() as Map<String, dynamic>;
                  final deadline = (data['deadline'] as Timestamp).toDate();
                  final daysRemaining = _getDaysRemaining(deadline);
                  final deadlineColor = _getDeadlineColor(deadline);

                  return _buildAssignmentCard(
                    assignment: assignment,
                    data: data,
                    deadline: deadline,
                    daysRemaining: daysRemaining,
                    deadlineColor: deadlineColor,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentCard({
    required QueryDocumentSnapshot assignment,
    required Map<String, dynamic> data,
    required DateTime deadline,
    required int daysRemaining,
    required Color deadlineColor,
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
        border: Border.all(
          color: deadlineColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: deadlineColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: deadlineColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['title'] ?? 'No Title',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: deadlineColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: deadlineColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysRemaining < 0
                        ? 'OVERDUE'
                        : daysRemaining == 0
                            ? 'DUE TODAY'
                            : '${daysRemaining}d left',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
                  data['description'] ?? 'No description provided',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Teacher: ${data['teacherName'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: deadlineColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Deadline: ${_formatDate(deadline)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: deadlineColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showAssignmentDetails(assignment.id, data);
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDetails(String assignmentId, Map<String, dynamic> data) async {
    try {
      // Check if the assignment has been submitted
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final submissionDoc = await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .collection('submissions')
          .doc(userId)
          .get();

      final bool hasSubmitted = submissionDoc.exists;
      final DateTime deadline = (data['deadline'] as Timestamp).toDate();
      final bool isOverdue = DateTime.now().isAfter(deadline);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            data['title'] ?? 'Assignment Details',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasSubmitted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                                'Submitted',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                'on ${_formatDate((submissionDoc.data()?['submittedAt'] as Timestamp).toDate())}',
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
                if (isOverdue && !hasSubmitted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This assignment is overdue',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['description'] ?? 'No description provided',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'Teacher:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['teacherName'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'Deadline:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(deadline),
                  style: TextStyle(
                    fontSize: 16,
                    color: _getDeadlineColor(deadline),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (!hasSubmitted)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignmentSubmissionForm(
                        assignmentId: assignmentId,
                        assignmentData: data,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit Assignment'),
              ),
            if (hasSubmitted)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AssignmentSubmissionForm(
                        assignmentId: assignmentId,
                        assignmentData: data,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View/Edit Submission'),
              ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing assignment details: $e');
    }
  }
}
