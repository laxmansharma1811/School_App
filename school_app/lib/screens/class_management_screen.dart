import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/services/class_service.dart';
import 'package:school_app/authentication/auth_service.dart' as auth_service;

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  _ClassManagementScreenState createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final ClassService _classService = ClassService();
  final auth_service.AuthService _authService = auth_service.AuthService();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() async {
    String? role = await _authService.getUserRole();
    setState(() {
      _userRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Class Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6C63FF), Color(0xFFF8F9FA)],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Manage classes and student assignments',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _userRole == 'admin' 
                  ? _classService.getAllClasses()
                  : _classService.getMyClasses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.class_,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No classes found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first class to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    Map<String, dynamic> classData = doc.data() as Map<String, dynamic>;
                    
                    return _buildClassCard(doc.id, classData);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClassDialog(),
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Class',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildClassCard(String classId, Map<String, dynamic> classData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.class_,
                      color: Color(0xFF6C63FF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${classData['className']} - ${classData['section']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          classData['subject'] ?? 'No subject',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, classId, classData),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view_students',
                        child: Row(
                          children: [
                            Icon(Icons.people, size: 20),
                            SizedBox(width: 8),
                            Text('View Students'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'assign_student',
                        child: Row(
                          children: [
                            Icon(Icons.person_add, size: 20),
                            SizedBox(width: 8),
                            Text('Assign Student'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit Class'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Class', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                classData['description'] ?? 'No description',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    'Teacher',
                    classData['teacherName'] ?? 'Unknown',
                    Icons.person,
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    'Students',
                    '${classData['currentStudents'] ?? 0}/${classData['maxStudents'] ?? 30}',
                    Icons.people,
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, String classId, Map<String, dynamic> classData) {
    switch (action) {
      case 'view_students':
        _showStudentsDialog(classId, classData);
        break;
      case 'assign_student':
        _showAssignStudentDialog(classId);
        break;
      case 'edit':
        _showEditClassDialog(classId, classData);
        break;
      case 'delete':
        _showDeleteConfirmDialog(classId, classData);
        break;
    }
  }

  void _showCreateClassDialog() {
    final TextEditingController classNameController = TextEditingController();
    final TextEditingController sectionController = TextEditingController();
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController maxStudentsController = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: classNameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  hintText: 'e.g., Grade 10',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sectionController,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  hintText: 'e.g., A, B, C',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g., Mathematics',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Class description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxStudentsController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Students',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (classNameController.text.trim().isEmpty ||
                  sectionController.text.trim().isEmpty ||
                  subjectController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Get current user data
              String? currentUserId = _authService.getCurrentUserId();
              if (currentUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User not authenticated'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              DocumentSnapshot userDoc = await FirebaseFirestore.instance
                  .collection('profiles')
                  .doc(currentUserId)
                  .get();

              String teacherName = 'Unknown Teacher';
              if (userDoc.exists) {
                Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
                teacherName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
                if (teacherName.isEmpty) {
                  teacherName = userData['email'] ?? 'Unknown Teacher';
                }
              }

              bool success = await _classService.createClass(
                className: classNameController.text.trim(),
                section: sectionController.text.trim(),
                subject: subjectController.text.trim(),
                description: descriptionController.text.trim(),
                teacherId: currentUserId,
                teacherName: teacherName,
                maxStudents: int.tryParse(maxStudentsController.text) ?? 30,
              );

              if (success) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showStudentsDialog(String classId, Map<String, dynamic> classData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Students in ${classData['className']} - ${classData['section']}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _classService.getStudentsInClass(classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              List<Map<String, dynamic>> students = snapshot.data ?? [];

              if (students.isEmpty) {
                return const Center(
                  child: Text('No students assigned to this class'),
                );
              }

              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> student = students[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6C63FF),
                      child: Text(
                        (student['firstName']?[0] ?? 'S').toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text('${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'),
                    subtitle: Text(student['email'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () async {
                        bool confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Student'),
                            content: Text('Remove ${student['firstName']} ${student['lastName']} from this class?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        ) ?? false;

                        if (confirm) {
                          await _classService.removeStudentFromClass(
                            classId: classId,
                            studentId: student['id'],
                          );
                          Navigator.pop(context);
                          _showStudentsDialog(classId, classData);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAssignStudentDialog(String classId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Student to Class'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _classService.getAvailableStudents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              List<Map<String, dynamic>> students = snapshot.data ?? [];

              if (students.isEmpty) {
                return const Center(
                  child: Text('No available students to assign'),
                );
              }

              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> student = students[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6C63FF),
                      child: Text(
                        (student['firstName']?[0] ?? 'S').toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text('${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'),
                    subtitle: Text(student['email'] ?? ''),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        bool success = await _classService.assignStudentToClass(
                          classId: classId,
                          studentId: student['id'],
                          studentName: '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}',
                        );

                        if (success) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Assign'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(String classId, Map<String, dynamic> classData) {
    final TextEditingController classNameController = TextEditingController(text: classData['className']);
    final TextEditingController sectionController = TextEditingController(text: classData['section']);
    final TextEditingController subjectController = TextEditingController(text: classData['subject']);
    final TextEditingController descriptionController = TextEditingController(text: classData['description']);
    final TextEditingController maxStudentsController = TextEditingController(text: classData['maxStudents'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: classNameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sectionController,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxStudentsController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Students',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              bool success = await _classService.updateClass(
                classId: classId,
                className: classNameController.text.trim(),
                section: sectionController.text.trim(),
                subject: subjectController.text.trim(),
                description: descriptionController.text.trim(),
                maxStudents: int.tryParse(maxStudentsController.text) ?? 30,
              );

              if (success) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(String classId, Map<String, dynamic> classData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text(
          'Are you sure you want to delete "${classData['className']} - ${classData['section']}"?\n\n'
          'This will remove all students from the class and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              bool success = await _classService.deleteClass(classId);
              if (success) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
