import 'package:flutter/material.dart';
import 'package:school_app/services/student_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UpdateStudentScreen extends StatefulWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const UpdateStudentScreen({
    super.key,
    required this.studentId,
    required this.studentData,
  });

  @override
  _UpdateStudentScreenState createState() => _UpdateStudentScreenState();
}

class _UpdateStudentScreenState extends State<UpdateStudentScreen> {
  final StudentService _studentService = StudentService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _gradeController;
  late TextEditingController _attendanceController;
  late TextEditingController _academicScoreController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.studentData['name']);
    _gradeController = TextEditingController(text: widget.studentData['grade']);
    _attendanceController = TextEditingController(
      text: widget.studentData['attendance'].toString(),
    );
    _academicScoreController = TextEditingController(
      text: widget.studentData['academicScore'].toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _attendanceController.dispose();
    _academicScoreController.dispose();
    super.dispose();
  }

  void _updateStudent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _studentService.updateStudent(
          studentId: widget.studentId,
          name: _nameController.text.trim(),
          grade: _gradeController.text.trim(),
          attendance: int.parse(_attendanceController.text.trim()),
          academicScore: double.parse(_academicScoreController.text.trim()),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating student: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTabletOrDesktop = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        title: const Text(
          'Update Student',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.withOpacity(0.05), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width:
                    isTabletOrDesktop
                        ? screenSize.width * 0.7
                        : screenSize.width,
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header section with student avatar
                          Center(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.indigo.withOpacity(
                                    0.2,
                                  ),
                                  child: Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : 'S',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Update Student Information',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ID: ${widget.studentId}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),

                          // Form fields
                          _buildFormField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person,
                            validator:
                                (value) =>
                                    value!.isEmpty ? 'Enter a name' : null,
                          ),
                          const SizedBox(height: 16),

                          _buildFormField(
                            controller: _gradeController,
                            label: 'Grade/Class',
                            icon: Icons.school,
                            validator:
                                (value) =>
                                    value!.isEmpty ? 'Enter a grade' : null,
                          ),
                          const SizedBox(height: 16),

                          // Responsive layout for numerical fields on larger screens
                          if (isTabletOrDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: _attendanceController,
                                    label: 'Attendance (%)',
                                    icon: Icons.calendar_today,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value!.isEmpty)
                                        return 'Enter attendance';
                                      final num = int.tryParse(value);
                                      if (num == null || num < 0 || num > 100) {
                                        return 'Enter a valid percentage (0-100)';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    controller: _academicScoreController,
                                    label: 'Academic Score',
                                    icon: Icons.score,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value!.isEmpty)
                                        return 'Enter a score';
                                      final num = double.tryParse(value);
                                      if (num == null || num < 0 || num > 100) {
                                        return 'Enter a valid score (0-100)';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _buildFormField(
                                  controller: _attendanceController,
                                  label: 'Attendance (%)',
                                  icon: Icons.calendar_today,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value!.isEmpty)
                                      return 'Enter attendance';
                                    final num = int.tryParse(value);
                                    if (num == null || num < 0 || num > 100) {
                                      return 'Enter a valid percentage (0-100)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  controller: _academicScoreController,
                                  label: 'Academic Score',
                                  icon: Icons.score,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value!.isEmpty) return 'Enter a score';
                                    final num = double.tryParse(value);
                                    if (num == null || num < 0 || num > 100) {
                                      return 'Enter a valid score (0-100)';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),

                          const SizedBox(height: 32),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: const BorderSide(
                                      color: Colors.indigo,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.indigo),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _updateStudent,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : const Text(
                                            'Update Student',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build consistent form fields
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter $label',
        prefixIcon: Icon(icon, color: Colors.indigo),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
