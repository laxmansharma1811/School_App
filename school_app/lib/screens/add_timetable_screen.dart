import 'package:flutter/material.dart';
import 'package:school_app/services/timetable_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class AddTimetableScreen extends StatefulWidget {
  final String? timetableId;
  final Map<String, dynamic>? timetableData;

  const AddTimetableScreen({super.key, this.timetableId, this.timetableData});

  @override
  _AddTimetableScreenState createState() => _AddTimetableScreenState();
}

class _AddTimetableScreenState extends State<AddTimetableScreen> with SingleTickerProviderStateMixin {
  final TimetableService _timetableService = TimetableService();
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _timeController = TextEditingController();
  final _subjectController = TextEditingController();
  
  String _selectedDay = 'Monday';
  bool _isLoading = false;
  bool _formSubmitted = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _days = [
    {'value': 'Monday', 'short': 'MON', 'color': Colors.blue},
    {'value': 'Tuesday', 'short': 'TUE', 'color': Colors.green},
    {'value': 'Wednesday', 'short': 'WED', 'color': Colors.purple},
    {'value': 'Thursday', 'short': 'THU', 'color': Colors.orange},
    {'value': 'Friday', 'short': 'FRI', 'color': Colors.pink},
    {'value': 'Saturday', 'short': 'SAT', 'color': Colors.teal},
    {'value': 'Sunday', 'short': 'SUN', 'color': Colors.red},
  ];

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
    
    // Populate form if editing an existing timetable
    if (widget.timetableData != null) {
      _classNameController.text = widget.timetableData!['className'] ?? '';
      _timeController.text = widget.timetableData!['time'] ?? '';
      _subjectController.text = widget.timetableData!['subject'] ?? '';
      _selectedDay = widget.timetableData!['day'] ?? 'Monday';
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _timeController.dispose();
    _subjectController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _saveTimetable() async {
    setState(() => _formSubmitted = true);
    
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        if (widget.timetableId == null) {
          await _timetableService.addTimetable(
            className: _classNameController.text.trim(),
            day: _selectedDay,
            time: _timeController.text.trim(),
            subject: _subjectController.text.trim(),
          );
          
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Timetable entry added successfully',
              backgroundColor: Colors.green,
            );
          }
        } else {
          await _timetableService.updateTimetable(
            timetableId: widget.timetableId!,
            className: _classNameController.text.trim(),
            day: _selectedDay,
            time: _timeController.text.trim(),
            subject: _subjectController.text.trim(),
          );
          
          if (mounted) {
            Fluttertoast.showToast(
              msg: 'Timetable entry updated successfully',
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
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedTime != null) {
      // Format the time
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      final formattedTime = DateFormat('h:mm a').format(dateTime);
      
      setState(() {
        _timeController.text = formattedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNewTimetable = widget.timetableId == null;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          isNewTimetable ? 'Add Timetable' : 'Edit Timetable',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveTimetable,
            tooltip: 'Save Timetable',
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
                _buildHeaderSection(isNewTimetable),
                _buildFormSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isNewTimetable) {
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
              isNewTimetable ? Icons.calendar_month : Icons.edit_calendar,
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
                  isNewTimetable ? 'New Timetable Entry' : 'Update Timetable',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isNewTimetable 
                      ? 'Add a new class to the schedule'
                      : 'Update the existing class schedule',
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
            // Class Name Field
            _buildSectionTitle('Class Name', true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _classNameController,
              decoration: InputDecoration(
                hintText: 'Enter class name or grade',
                prefixIcon: const Icon(Icons.class_outlined),
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
                  return 'Please enter class name';
                }
                return null;
              },
              autovalidateMode: _formSubmitted 
                  ? AutovalidateMode.always 
                  : AutovalidateMode.disabled,
            ),
            const SizedBox(height: 24),
            
            // Day Selection
            _buildSectionTitle('Day of Week', true),
            const SizedBox(height: 12),
            _buildDaySelector(),
            const SizedBox(height: 24),
            
            // Time Field
            _buildSectionTitle('Class Time', true),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectTime,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    hintText: 'Select class time',
                    prefixIcon: const Icon(Icons.access_time),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
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
                      return 'Please select class time';
                    }
                    return null;
                  },
                  autovalidateMode: _formSubmitted 
                      ? AutovalidateMode.always 
                      : AutovalidateMode.disabled,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Subject Field
            _buildSectionTitle('Subject', true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'Enter subject name',
                prefixIcon: const Icon(Icons.book_outlined),
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
                  return 'Please enter subject name';
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
                onPressed: _isLoading ? null : _saveTimetable,
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
                        widget.timetableId == null 
                            ? 'Add to Timetable' 
                            : 'Update Timetable',
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

  Widget _buildDaySelector() {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = _selectedDay == day['value'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = day['value'];
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? day['color'].withOpacity(0.2) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: day['color'], width: 2)
                    : null,
                boxShadow: isSelected
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day['short'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? day['color'] : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? day['color'] : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
