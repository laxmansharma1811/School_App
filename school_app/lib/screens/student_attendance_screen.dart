import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_app/services/attendance_service.dart';
import 'package:intl/intl.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final user = FirebaseAuth.instance.currentUser;
  String _filterBy = 'All';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterOptions(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAttendanceSummary(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _attendanceService.getStudentAttendance(user!.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState();
                }
                if (!snapshot.hasData) {
                  return _buildLoadingState();
                }

                final attendanceRecords = snapshot.data!.docs;
                if (attendanceRecords.isEmpty) {
                  return _buildEmptyState();
                }

                // Filter records if needed
                final filteredRecords = _filterRecords(attendanceRecords);

                // Group records by month
                final groupedRecords = _groupRecordsByMonth(filteredRecords);

                return _buildAttendanceList(groupedRecords, isTablet);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _attendanceService.getStudentAttendance(user!.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text('Calculating attendance...'));
          }

          final records = snapshot.data!.docs;
          final totalClasses = records.length;
          final presentClasses =
              records.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isPresent'] == true;
              }).length;

          final attendancePercentage =
              totalClasses > 0
                  ? (presentClasses / totalClasses * 100).toStringAsFixed(1)
                  : '0.0';

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                context,
                'Total Classes',
                totalClasses.toString(),
                Icons.calendar_month,
              ),
              _buildSummaryItem(
                context,
                'Present',
                presentClasses.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildSummaryItem(
                context,
                'Absent',
                (totalClasses - presentClasses).toString(),
                Icons.cancel,
                Colors.red,
              ),
              _buildSummaryItem(
                context,
                'Attendance',
                '$attendancePercentage%',
                Icons.percent,
                _getAttendanceColor(double.parse(attendancePercentage)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            'Error loading attendance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading attendance records...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, color: Colors.grey[400], size: 80),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Your attendance records will appear here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterRecords(
    List<QueryDocumentSnapshot> records,
  ) {
    if (_filterBy == 'All') return records;

    return records.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (_filterBy == 'Present') return data['isPresent'] == true;
      if (_filterBy == 'Absent') return data['isPresent'] == false;
      return true;
    }).toList();
  }

  Map<String, List<QueryDocumentSnapshot>> _groupRecordsByMonth(
    List<QueryDocumentSnapshot> records,
  ) {
    final grouped = <String, List<QueryDocumentSnapshot>>{};

    for (final record in records) {
      final data = record.data() as Map<String, dynamic>;
      final dateStr = data['date'] as String;

      // Try to parse the date
      DateTime? date;
      try {
        // Assuming date format is MM/DD/YYYY or similar
        final parts = dateStr.split('/');
        if (parts.length >= 3) {
          date = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }
      } catch (e) {
        // If parsing fails, use the original string
      }

      final monthYear =
          date != null ? DateFormat('MMMM yyyy').format(date) : 'Unknown Date';

      if (!grouped.containsKey(monthYear)) {
        grouped[monthYear] = [];
      }

      grouped[monthYear]!.add(record);
    }

    return grouped;
  }

  Widget _buildAttendanceList(
    Map<String, List<QueryDocumentSnapshot>> groupedRecords,
    bool isTablet,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedRecords.length,
      itemBuilder: (context, index) {
        final monthYear = groupedRecords.keys.elementAt(index);
        final records = groupedRecords[monthYear]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                monthYear,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            isTablet ? _buildTabletGrid(records) : _buildPhoneList(records),
            const Divider(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildPhoneList(List<QueryDocumentSnapshot> records) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final data = record.data() as Map<String, dynamic>;
        final isPresent = data['isPresent'] as bool;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isPresent ? Colors.green.shade200 : Colors.red.shade200,
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor:
                  isPresent
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
              child: Icon(
                isPresent ? Icons.check : Icons.close,
                color: isPresent ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              'Class: ${data['className']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Date: ${data['date']}'),
                Text(
                  'Status: ${isPresent ? 'Present' : 'Absent'}',
                  style: TextStyle(
                    color: isPresent ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
            onTap: () {
              // Show detailed view if needed
              _showAttendanceDetails(context, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildTabletGrid(List<QueryDocumentSnapshot> records) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final data = record.data() as Map<String, dynamic>;
        final isPresent = data['isPresent'] as bool;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isPresent ? Colors.green.shade200 : Colors.red.shade200,
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _showAttendanceDetails(context, data);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            isPresent
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                        child: Icon(
                          isPresent ? Icons.check : Icons.close,
                          size: 16,
                          color: isPresent ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['className'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${data['date']}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPresent ? 'Present' : 'Absent',
                    style: TextStyle(
                      color: isPresent ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAttendanceDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(height: 24),
              _buildDetailRow('Class', data['className']),
              _buildDetailRow('Date', data['date']),
              _buildDetailRow(
                'Status',
                data['isPresent'] ? 'Present' : 'Absent',
              ),
              if (data['notes'] != null)
                _buildDetailRow('Notes', data['notes']),
              if (data['markedBy'] != null)
                _buildDetailRow('Marked By', data['markedBy']),
              if (data['timestamp'] != null)
                _buildDetailRow(
                  'Time',
                  data['timestamp'] is Timestamp
                      ? DateFormat(
                        'hh:mm a',
                      ).format((data['timestamp'] as Timestamp).toDate())
                      : 'Unknown',
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color:
                    label == 'Status'
                        ? (value == 'Present' ? Colors.green : Colors.red)
                        : Colors.black,
                fontWeight:
                    label == 'Status' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Attendance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('All'),
              _buildFilterOption('Present'),
              _buildFilterOption('Absent'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterOption(String filter) {
    return RadioListTile<String>(
      title: Text(filter),
      value: filter,
      groupValue: _filterBy,
      onChanged: (value) {
        setState(() {
          _filterBy = value!;
        });
        Navigator.pop(context);
      },
    );
  }
}
