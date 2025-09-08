import 'package:flutter/material.dart';
import '../models/timetable_entry.dart';
import '../services/timetable_service.dart';

class StudentTimetableScreen extends StatefulWidget {
  final String className;

  const StudentTimetableScreen({Key? key, required this.className})
      : super(key: key);

  @override
  _StudentTimetableScreenState createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen> {
  final TimetableService _timetableService = TimetableService();
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  String _selectedDay = 'Monday';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Timetable'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedDay,
              decoration: const InputDecoration(
                labelText: 'Select Day',
                border: OutlineInputBorder(),
              ),
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
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TimetableEntry>>(
              stream: _timetableService.getTimetableForClass(widget.className),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final entries = snapshot.data!
                    .where((entry) => entry.dayOfWeek == _selectedDay)
                    .toList()
                  ..sort((a, b) => _compareTime(a.startTime, b.startTime));

                if (entries.isEmpty) {
                  return Center(
                    child: Text('No classes scheduled for $_selectedDay'),
                  );
                }

                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.subject,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${entry.startTime} - ${entry.endTime}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Teacher: ${entry.teacherName}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Room: ${entry.roomNumber}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
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
