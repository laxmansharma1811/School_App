import 'package:flutter/material.dart';
import '../models/timetable_entry.dart';
import '../services/timetable_service.dart';

class TimetableManagementScreen extends StatefulWidget {
  const TimetableManagementScreen({Key? key}) : super(key: key);

  @override
  _TimetableManagementScreenState createState() =>
      _TimetableManagementScreenState();
}

class _TimetableManagementScreenState extends State<TimetableManagementScreen> {
  final TimetableService _timetableService = TimetableService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();
  
  String _selectedDay = 'Monday';
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Timetable Entry'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                TextFormField(
                  controller: _teacherNameController,
                  decoration: const InputDecoration(labelText: 'Teacher Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                TextFormField(
                  controller: _classNameController,
                  decoration: const InputDecoration(labelText: 'Class Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                TextFormField(
                  controller: _roomNumberController,
                  decoration: const InputDecoration(labelText: 'Room Number'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedDay,
                  items: _daysOfWeek
                      .map((day) => DropdownMenuItem(
                            value: day,
                            child: Text(day),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDay = value!;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Day of Week'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (time != null) {
                            setState(() {
                              _startTime = time;
                            });
                          }
                        },
                        child: Text('Start Time: ${_startTime.format(context)}'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: _endTime,
                          );
                          if (time != null) {
                            setState(() {
                              _endTime = time;
                            });
                          }
                        },
                        child: Text('End Time: ${_endTime.format(context)}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _addTimetableEntry,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addTimetableEntry() {
    if (_formKey.currentState?.validate() ?? false) {
      final entry = TimetableEntry(
        id: DateTime.now().toString(),
        subject: _subjectController.text,
        teacherName: _teacherNameController.text,
        className: _classNameController.text,
        dayOfWeek: _selectedDay,
        startTime: _startTime.format(context),
        endTime: _endTime.format(context),
        roomNumber: _roomNumberController.text,
      );

      _timetableService.addTimetableEntry(entry).then((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable entry added successfully')),
        );
        _clearForm();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding entry: $error')),
        );
      });
    }
  }

  void _clearForm() {
    _subjectController.clear();
    _teacherNameController.clear();
    _classNameController.clear();
    _roomNumberController.clear();
    setState(() {
      _selectedDay = 'Monday';
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 9, minute: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Management'),
      ),
      body: StreamBuilder<List<TimetableEntry>>(
        stream: _timetableService.getAllTimetableEntries(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data!;
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text('${entry.subject} - ${entry.className}'),
                  subtitle: Text(
                      '${entry.dayOfWeek}, ${entry.startTime} - ${entry.endTime}\nTeacher: ${entry.teacherName}, Room: ${entry.roomNumber}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _timetableService.deleteTimetableEntry(entry.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherNameController.dispose();
    _classNameController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }
}
