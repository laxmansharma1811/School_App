import 'package:flutter/material.dart';
import 'package:school_app/services/student_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  _AddStudentScreenState createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> with SingleTickerProviderStateMixin {
  final StudentService _studentService = StudentService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _attendanceController = TextEditingController();
  final _academicScoreController = TextEditingController();
  
  bool _isLoading = false;
  bool _formSubmitted = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _attendanceController.dispose();
    _academicScoreController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addStudent() async {
    setState(() => _formSubmitted = true);
    
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await _studentService.addStudent(
          name: _nameController.text.trim(),
          grade: _gradeController.text.trim(),
          attendance: int.parse(_attendanceController.text.trim()),
          academicScore: double.parse(_academicScoreController.text.trim()),
        );
        
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Student added successfully',
            backgroundColor: Colors.green,
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Error: ${e.toString()}',
            backgroundColor: Colors.red,
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Add Student',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _addStudent,
            tooltip: 'Save Student',
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                _buildFormSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_add,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Student',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a new student to the system',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Name Field
            _buildSectionTitle('Student Name', true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter student full name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                errorStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter student name';
                }
                return null;
              },
              autovalidateMode: _formSubmitted 
                  ? AutovalidateMode.always 
                  : AutovalidateMode.disabled,
            ),
            const SizedBox(height: 24),
            
            // Grade Field
            _buildSectionTitle('Grade/Class', true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _gradeController,
              decoration: InputDecoration(
                hintText: 'Enter grade or class',
                prefixIcon: const Icon(Icons.school_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                errorStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter grade or class';
                }
                return null;
              },
              autovalidateMode: _formSubmitted 
                  ? AutovalidateMode.always 
                  : AutovalidateMode.disabled,
            ),
            const SizedBox(height: 24),
            
            // Attendance Field
            _buildSectionTitle('Attendance (%)', true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _attendanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter attendance percentage (0-100)',
                prefixIcon: const Icon(Icons.fact_check_outlined),
                suffixText: '%',
                suffixStyle: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                errorStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter attendance percentage';
                }
                final num = int.tryParse(value);
                if (num == null || num < 0 || num > 100) {
                  return 'Enter a valid percentage (0-100)';
                }
                return null;
              },
              autovalidateMode: _formSubmitted 
                  ? AutovalidateMode.always 
                  : AutovalidateMode.disabled,
            ),
            const SizedBox(height: 24),
            
            // Academic Score Field
            _buildSectionTitle('Academic Score', true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _academicScoreController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter academic score (0-100)',
                prefixIcon: const Icon(Icons.grade_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                errorStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter academic score';
                }
                final num = double.tryParse(value);
                if (num == null || num < 0 || num > 100) {
                  return 'Enter a valid score (0-100)';
                }
                return null;
              },
              autovalidateMode: _formSubmitted 
                  ? AutovalidateMode.always 
                  : AutovalidateMode.disabled,
            ),
            const SizedBox(height: 40),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Add Student',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isRequired) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
