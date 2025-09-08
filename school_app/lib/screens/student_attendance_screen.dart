import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({Key? key}) : super(key: key);

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  bool _isLoading = true;
  String? _studentClass;
  Map<String, dynamic> _attendanceSummary = {
    'total': 0,
    'present': 0,
    'absent': 0,
    'percentage': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadStudentClass();
  }

  Future<void> _loadStudentClass() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        setState(() {
          _studentClass = userDoc.get('class');
          _isLoading = false;
        });
        _loadAttendanceSummary();
      }
    } catch (e) {
      print('Error loading student class: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAttendanceSummary() async {
    if (_studentClass == null) return;

    try {
      final QuerySnapshot attendanceQuery = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: _auth.currentUser!.uid)
          .get();

      int total = attendanceQuery.docs.length;
      int present = attendanceQuery.docs
          .where((doc) => doc['isPresent'] == true)
          .length;

      setState(() {
        _attendanceSummary = {
          'total': total,
          'present': present,
          'absent': total - present,
          'percentage': total > 0 ? (present / total * 100) : 0.0,
        };
      });
    } catch (e) {
      print('Error loading attendance summary: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentClass == null
              ? _buildNoClassAssigned()
              : Column(
                  children: [
                    _buildAttendanceSummaryCard(),
                    _buildMonthSelector(),
                    Expanded(child: _buildAttendanceList()),
                  ],
                ),
    );
  }

  Widget _buildNoClassAssigned() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_rounded,
            size: 64,
            color: Colors.orange[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Class Assigned',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please contact your administrator',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Attendance Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Total Classes',
                _attendanceSummary['total'].toString(),
                Icons.calendar_today,
              ),
              _buildSummaryItem(
                'Present',
                _attendanceSummary['present'].toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildSummaryItem(
                'Absent',
                _attendanceSummary['absent'].toString(),
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.percent,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Attendance: ${_attendanceSummary['percentage'].toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(
          icon,
          color: color ?? Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedMonth,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: _getAvailableMonths()
            .map((month) => DropdownMenuItem(
                  value: month,
                  child: Text(month),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedMonth = value;
            });
          }
        },
      ),
    );
  }

  List<String> _getAvailableMonths() {
    // Get the last 12 months including current month
    List<String> months = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      months.add(DateFormat('MMMM yyyy').format(month));
    }
    return months;
  }

  Widget _buildAttendanceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: _auth.currentUser!.uid)
          .where('date', isGreaterThanOrEqualTo: _getMonthStartDate())
          .where('date', isLessThan: _getMonthEndDate())
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final attendanceRecords = snapshot.data!.docs;

        if (attendanceRecords.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No attendance records for $_selectedMonth',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: attendanceRecords.length,
          itemBuilder: (context, index) {
            final record = attendanceRecords[index].data() as Map<String, dynamic>;
            return _buildAttendanceCard(record);
          },
        );
      },
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final bool isPresent = record['isPresent'] ?? false;
    final String date = record['date'] ?? 'Unknown Date';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPresent ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isPresent
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          child: Icon(
            isPresent ? Icons.check : Icons.close,
            color: isPresent ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          date,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          isPresent ? 'Present' : 'Absent',
          style: TextStyle(
            color: isPresent ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          record['time'] ?? '',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _getMonthStartDate() {
    final DateTime date = DateFormat('MMMM yyyy').parse(_selectedMonth);
    return DateFormat('MM/dd/yyyy').format(DateTime(date.year, date.month, 1));
  }

  String _getMonthEndDate() {
    final DateTime date = DateFormat('MMMM yyyy').parse(_selectedMonth);
    return DateFormat('MM/dd/yyyy')
        .format(DateTime(date.year, date.month + 1, 1));
  }
}
