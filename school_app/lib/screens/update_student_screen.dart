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
    _attendanceController =
        TextEditingController(text: widget.studentData['attendance'].toString());
    _academicScoreController = TextEditingController(
        text: widget.studentData['academicScore'].toString());
  }

  void _updateStudent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await _studentService.updateStudent(
        studentId: widget.studentId,
        name: _nameController.text.trim(),
        grade: _gradeController.text.trim(),
        attendance: int.parse(_attendanceController.text.trim()),
        academicScore: double.parse(_academicScoreController.text.trim()),
      );
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Student')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: _gradeController,
                decoration: const InputDecoration(labelText: 'Grade'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter a grade' : null,
              ),
              TextFormField(
                controller: _attendanceController,
                decoration: const InputDecoration(labelText: 'Attendance (%)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Enter attendance';
                  final num = int.tryParse(value);
                  if (num == null || num < 0 || num > 100) {
                    return 'Enter a valid percentage (0-100)';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _academicScoreController,
                decoration: const InputDecoration(labelText: 'Academic Score'),
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
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _updateStudent,
                      child: const Text('Update Student'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
