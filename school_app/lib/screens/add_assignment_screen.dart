import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_app/services/assignment_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class AddAssignmentScreen extends StatefulWidget {
  final String? assignmentId;
  final Map<String, dynamic>? assignmentData;

  const AddAssignmentScreen({super.key, this.assignmentId, this.assignmentData});

  @override
  _AddAssignmentScreenState createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> with SingleTickerProviderStateMixin {
  final AssignmentService _assignmentService = AssignmentService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _deadline;
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
    
    // Populate form if editing an existing assignment
    if (widget.assignmentData != null) {
      _titleController.text = widget.assignmentData!['title'] ?? '';
      _descriptionController.text = widget.assignmentData!['description'] ?? '';
      _deadline = (widget.assignmentData!['deadline'] as Timestamp?)?.toDate();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _saveAssignment() async {
    setState(() => _formSubmitted = true);
    
    if (_formKey.currentState!.validate() && _deadline != null) {
      setState(() => _isLoading = true);
      
      try {
        if (widget.assignmentId == null) {
          await _assignmentService.addAssignment(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            deadline: _deadline!,
          );
          
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Assignment created successfully',
              backgroundColor: Colors.green,
            );
          }
        } else {
          await _assignmentService.updateAssignment(
            assignmentId: widget.assignmentId!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            deadline: _deadline!,
          );
          
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Assignment updated successfully',
              backgroundColor: Colors.green,
            );
          }
        }
        
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: 'Error: ${e.toString()}',
            backgroundColor: Colors.red,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else if (_deadline == null) {
      Fluttertoast.showToast(
        msg: 'Please select a deadline',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _selectDeadline() async {
    final picked = await showDateTimePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final isNewAssignment = widget.assignmentId == null;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          isNewAssignment ? 'Create Assignment' : 'Edit Assignment',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveAssignment,
            tooltip: 'Save Assignment',
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
                _buildHeaderSection(isNewAssignment),
                _buildFormSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isNewAssignment) {
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
            child: Icon(
              isNewAssignment ? Icons.add_task : Icons.edit_note,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNewAssignment ? 'New Assignment' : 'Update Assignment',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isNewAssignment 
                      ? 'Create a new assignment for students'
                      : 'Update the existing assignment details',
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
            // Title Field
            _buildSectionTitle('Assignment Title', true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter assignment title',
                prefixIcon: const Icon(Icons.title),
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
                  return 'Please enter a title';
                }
                return null;
              },
              autovalidateMode: _formSubmitted 
                  ? AutovalidateMode.always 
                  : AutovalidateMode.disabled,
            ),
            const SizedBox(height: 24),
            
            // Description Field
            _buildSectionTitle('Description', true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Enter assignment description',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                alignLabelWithHint: true,
                errorStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              autovalidateMode: _formSubmitted 
                  ? AutovalidateMode.always 
                  : AutovalidateMode.disabled,
            ),
            const SizedBox(height: 24),
            
            // Deadline Field
            _buildSectionTitle('Deadline', true),
            const SizedBox(height: 8),
            _buildDeadlineSelector(),
            const SizedBox(height: 40),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAssignment,
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
                    : Text(
                        widget.assignmentId == null 
                            ? 'Create Assignment' 
                            : 'Update Assignment',
                        style: const TextStyle(
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

  Widget _buildDeadlineSelector() {
    return GestureDetector(
      onTap: _selectDeadline,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: _formSubmitted && _deadline == null
              ? Border.all(color: Colors.red, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: _deadline != null 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _deadline != null
                    ? _formatDateTime(_deadline!)
                    : 'Select deadline date and time',
                style: TextStyle(
                  color: _deadline != null ? Colors.black87 : Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

Future<DateTime?> showDateTimePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  final ThemeData theme = Theme.of(context);
  
  final date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (context, child) {
      return Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: theme.primaryColor,
          ),
        ),
        child: child!,
      );
    },
  );
  
  if (date == null) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
    builder: (context, child) {
      return Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: theme.primaryColor,
          ),
        ),
        child: child!,
      );
    },
  );
  
  if (time == null) return null;

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}
