import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/screens/add_timetable_screen.dart';
import 'package:school_app/services/timetable_service.dart';

class TimetableListScreen extends StatelessWidget {
  const TimetableListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TimetableService _timetableService = TimetableService();
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final bool isDesktop = screenSize.width > 1024;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        title: const Text(
          'Timetable Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implement filtering functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              // Implement calendar view
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.withOpacity(0.05), Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _timetableService.getTimetables(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading timetables',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              );
            }

            final timetables = snapshot.data!.docs;

            if (timetables.isEmpty) {
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
                    const Text(
                      'No timetables found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Timetable'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddTimetableScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }

            // Group timetables by day for better organization
            Map<String, List<DocumentSnapshot>> timetablesByDay = {};
            for (var timetable in timetables) {
              final data = timetable.data() as Map<String, dynamic>;
              final day = data['day'] as String;
              if (!timetablesByDay.containsKey(day)) {
                timetablesByDay[day] = [];
              }
              timetablesByDay[day]!.add(timetable);
            }

            // Sort days in a logical order
            final sortedDays = _sortDays(timetablesByDay.keys.toList());

            // Responsive layout based on screen size
            if (isDesktop) {
              // Calendar-like grid view for desktop
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: sortedDays.length,
                  itemBuilder: (context, dayIndex) {
                    final day = sortedDays[dayIndex];
                    final dayTimetables = timetablesByDay[day]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDayHeader(day),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: dayTimetables.length,
                          itemBuilder:
                              (context, index) => _buildTimetableCard(
                                context,
                                dayTimetables[index],
                                _timetableService,
                              ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              );
            } else if (isTablet) {
              // Two-column grid for tablet
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListView.builder(
                  itemCount: sortedDays.length,
                  itemBuilder: (context, dayIndex) {
                    final day = sortedDays[dayIndex];
                    final dayTimetables = timetablesByDay[day]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDayHeader(day),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: dayTimetables.length,
                          itemBuilder:
                              (context, index) => _buildTimetableCard(
                                context,
                                dayTimetables[index],
                                _timetableService,
                              ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              );
            } else {
              // List view grouped by day for mobile
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: ListView.builder(
                  itemCount: sortedDays.length,
                  itemBuilder: (context, dayIndex) {
                    final day = sortedDays[dayIndex];
                    final dayTimetables = timetablesByDay[day]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDayHeader(day),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dayTimetables.length,
                          itemBuilder: (context, index) {
                            return _buildTimetableListItem(
                              context,
                              dayTimetables[index],
                              _timetableService,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTimetableScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper method to sort days in logical order
  List<String> _sortDays(List<String> days) {
    final dayOrder = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };

    days.sort((a, b) {
      return (dayOrder[a] ?? 99).compareTo(dayOrder[b] ?? 99);
    });

    return days;
  }

  // Day header widget
  Widget _buildDayHeader(String day) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              day,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(color: Colors.purple.withOpacity(0.3), thickness: 1),
          ),
        ],
      ),
    );
  }

  // Card design for tablet and desktop
  Widget _buildTimetableCard(
    BuildContext context,
    DocumentSnapshot timetable,
    TimetableService timetableService,
  ) {
    final data = timetable.data() as Map<String, dynamic>;
    final String className = data['className'] ?? 'Unknown Class';
    final String subject = data['subject'] ?? 'Unknown Subject';
    final String time = data['time'] ?? 'No Time Set';

    // Generate a consistent color based on the subject name
    final int colorValue = subject.hashCode & 0xFFFFFF;
    final Color subjectColor = Color(colorValue).withOpacity(0.8);
    final Color lightColor = Color(colorValue).withOpacity(0.2);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: subjectColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: lightColor,
                    child: Text(
                      subject.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: subjectColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          className,
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.purple),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AddTimetableScreen(
                                timetableId: timetable.id,
                                timetableData: data,
                              ),
                        ),
                      );
                    },
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed:
                        () => _confirmDelete(
                          context,
                          timetable.id,
                          timetableService,
                        ),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // List item design for mobile
  Widget _buildTimetableListItem(
    BuildContext context,
    DocumentSnapshot timetable,
    TimetableService timetableService,
  ) {
    final data = timetable.data() as Map<String, dynamic>;
    final String className = data['className'] ?? 'Unknown Class';
    final String subject = data['subject'] ?? 'Unknown Subject';
    final String time = data['time'] ?? 'No Time Set';

    // Generate a consistent color based on the subject name
    final int colorValue = subject.hashCode & 0xFFFFFF;
    final Color subjectColor = Color(colorValue).withOpacity(0.8);
    final Color lightColor = Color(colorValue).withOpacity(0.2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: subjectColor, width: 6)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: lightColor,
            child: Text(
              subject.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: subjectColor,
              ),
            ),
          ),
          title: Text(
            '$subject - $className',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(time),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.purple),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AddTimetableScreen(
                            timetableId: timetable.id,
                            timetableData: data,
                          ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed:
                    () =>
                        _confirmDelete(context, timetable.id, timetableService),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Extracted delete confirmation dialog
  Future<void> _confirmDelete(
    BuildContext context,
    String timetableId,
    TimetableService timetableService,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Timetable'),
            content: const Text(
              'Are you sure you want to delete this timetable?',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await timetableService.deleteTimetable(timetableId);
      // Optional: Show a snackbar confirmation
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable deleted successfully')),
        );
      }
    }
  }
}
