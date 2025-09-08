import 'package:flutter/material.dart';
import 'package:school_app/models/timetable_entry.dart';
import 'package:school_app/services/timetable_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewTimetableScreen extends StatefulWidget {
  const ViewTimetableScreen({Key? key}) : super(key: key);

  @override
  _ViewTimetableScreenState createState() => _ViewTimetableScreenState();
}

class _ViewTimetableScreenState extends State<ViewTimetableScreen>
    with SingleTickerProviderStateMixin {
  final TimetableService _timetableService = TimetableService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late TabController _tabController;
  String? _userRole;
  String? _className;
  bool _isLoading = true;

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
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userRole = userDoc.data()?['role'];
        _className = userDoc.data()?['class'];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_userRole == 'student'
            ? 'Class Timetable'
            : 'View Timetable'),
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
    );
  }

  Widget _buildDayTab(String day) {
    return StreamBuilder<List<TimetableEntry>>(
      stream: _userRole == 'student' && _className != null
          ? _timetableService.getTimetableForClass(_className!)
          : _timetableService.getAllTimetableEntries(),
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
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.subject,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${entry.startTime} - ${entry.endTime}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.teacherName,
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.class_,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.className,
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.room,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Room ${entry.roomNumber}',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
