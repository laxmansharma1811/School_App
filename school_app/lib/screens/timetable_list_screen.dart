import 'package:flutter/material.dart';
import 'package:school_app/models/timetable_entry.dart';
import 'package:school_app/services/timetable_service.dart';

class TimetableListScreen extends StatefulWidget {
  const TimetableListScreen({Key? key}) : super(key: key);

  @override
  _TimetableListScreenState createState() => _TimetableListScreenState();
}

class _TimetableListScreenState extends State<TimetableListScreen> with SingleTickerProviderStateMixin {
  final TimetableService _timetableService = TimetableService();
  late TabController _tabController;
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _daysOfWeek.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _daysOfWeek.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _daysOfWeek.map((day) => _buildDayTab(day)).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddTimetableDialog(context);
        },
        label: const Text('Add Entry'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDayTab(String day) {
    return StreamBuilder<List<TimetableEntry>>(
      stream: _timetableService.getAllTimetableEntries(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data!
            .where((entry) => entry.dayOfWeek == day)
            .toList()
          ..sort((a, b) => _compareTime(a.startTime, b.startTime));

        if (entries.isEmpty) {
          return Center(
            child: Text('No classes scheduled for $day'),
          );
        }

        return ListView.builder(
          itemCount: entries.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  entry.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Class: ${entry.className}'),
                    Text('Teacher: ${entry.teacherName}'),
                    Text('Time: ${entry.startTime} - ${entry.endTime}'),
                    Text('Room: ${entry.roomNumber}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _showDeleteConfirmationDialog(entry);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(TimetableEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timetable Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _timetableService.deleteTimetableEntry(entry.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddTimetableDialog(BuildContext context) {
    String selectedDay = _daysOfWeek[0];
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController();
    final teacherNameController = TextEditingController();
    final classNameController = TextEditingController();
    final roomNumberController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Timetable Entry'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: _daysOfWeek.map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedDay = value!;
                  },
                ),
                TextFormField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                TextFormField(
                  controller: teacherNameController,
                  decoration: const InputDecoration(labelText: 'Teacher Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                TextFormField(
                  controller: classNameController,
                  decoration: const InputDecoration(labelText: 'Class'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                TextFormField(
                  controller: roomNumberController,
                  decoration: const InputDecoration(labelText: 'Room Number'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required field' : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (time != null) {
                            startTime = time;
                          }
                        },
                        child: Text('Start Time: ${startTime.format(context)}'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (time != null) {
                            endTime = time;
                          }
                        },
                        child: Text('End Time: ${endTime.format(context)}'),
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
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final entry = TimetableEntry(
                  id: DateTime.now().toString(),
                  subject: subjectController.text,
                  teacherName: teacherNameController.text,
                  className: classNameController.text,
                  dayOfWeek: selectedDay,
                  startTime: startTime.format(context),
                  endTime: endTime.format(context),
                  roomNumber: roomNumberController.text,
                );

                _timetableService.addTimetableEntry(entry).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Timetable entry added successfully'),
                    ),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding entry: $error'),
                    ),
                  );
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  int _compareTime(String time1, String time2) {
    final t1 = _parseTime(time1);
    final t2 = _parseTime(time2);
    return t1.hour * 60 + t1.minute - (t2.hour * 60 + t2.minute);
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    int hour = int.parse(parts[0]);
    int minute = 0;
    
    if (parts.length > 1) {
      String minutePart = parts[1].replaceAll(RegExp(r'[^\d]'), '');
      minute = int.parse(minutePart);
    }
    
    if (timeStr.toLowerCase().contains('pm') && hour != 12) {
      hour += 12;
    } else if (timeStr.toLowerCase().contains('am') && hour == 12) {
      hour = 0;
    }
    
    return TimeOfDay(hour: hour, minute: minute);
  }
}
