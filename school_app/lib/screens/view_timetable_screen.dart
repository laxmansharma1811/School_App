import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/services/timetable_service.dart';

class ViewTimetableScreen extends StatelessWidget {
  const ViewTimetableScreen({super.key});

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
        backgroundColor: Colors.blue,
        title: const Text(
          'View Timetable',
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
            icon: const Icon(Icons.calendar_today),
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
            colors: [Colors.blue.withOpacity(0.05), Colors.white],
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
                      'Error loading timetable',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
                      'No timetable available',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
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
              // Weekly calendar view for desktop
              return _buildWeeklyCalendarView(
                context,
                timetablesByDay,
                sortedDays,
              );
            } else if (isTablet) {
              // Day-based grid view for tablet
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListView.builder(
                  itemCount: sortedDays.length,
                  itemBuilder: (context, dayIndex) {
                    final day = sortedDays[dayIndex];
                    final dayTimetables = timetablesByDay[day]!;

                    // Sort timetables by time
                    dayTimetables.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      return aData['time'].toString().compareTo(
                        bData['time'].toString(),
                      );
                    });

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

                    // Sort timetables by time
                    dayTimetables.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      return aData['time'].toString().compareTo(
                        bData['time'].toString(),
                      );
                    });

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
    );
  }

  // Weekly calendar view for desktop
  Widget _buildWeeklyCalendarView(
    BuildContext context,
    Map<String, List<DocumentSnapshot>> timetablesByDay,
    List<String> sortedDays,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar header
          Row(
            children: [
              const SizedBox(width: 80), // Time column space
              ...sortedDays
                  .map(
                    (day) => Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          day,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
          const SizedBox(height: 16),

          // Calendar body
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _buildTimeSlots(context, timetablesByDay, sortedDays),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build time slots for weekly calendar
  List<Widget> _buildTimeSlots(
    BuildContext context,
    Map<String, List<DocumentSnapshot>> timetablesByDay,
    List<String> sortedDays,
  ) {
    // Get all unique time slots
    Set<String> allTimeSlots = {};
    timetablesByDay.forEach((day, timetables) {
      for (var timetable in timetables) {
        final data = timetable.data() as Map<String, dynamic>;
        allTimeSlots.add(data['time'].toString());
      }
    });

    // Sort time slots
    List<String> sortedTimeSlots = allTimeSlots.toList()..sort();

    return sortedTimeSlots.map((timeSlot) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                timeSlot,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Day columns
          ...sortedDays.map((day) {
            // Find timetable for this day and time slot
            final dayTimetables = timetablesByDay[day] ?? [];
            final timetablesForTimeSlot =
                dayTimetables.where((timetable) {
                  final data = timetable.data() as Map<String, dynamic>;
                  return data['time'].toString() == timeSlot;
                }).toList();

            return Expanded(
              child: Container(
                margin: const EdgeInsets.all(4),
                height: timetablesForTimeSlot.isEmpty ? 40 : null,
                child:
                    timetablesForTimeSlot.isEmpty
                        ? Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        )
                        : Column(
                          children:
                              timetablesForTimeSlot.map((timetable) {
                                final data =
                                    timetable.data() as Map<String, dynamic>;
                                final String className =
                                    data['className'] ?? 'Unknown Class';
                                final String subject =
                                    data['subject'] ?? 'Unknown Subject';

                                // Generate a consistent color based on the subject name
                                final int colorValue =
                                    subject.hashCode & 0xFFFFFF;
                                final Color subjectColor = Color(
                                  colorValue,
                                ).withOpacity(0.8);
                                final Color lightColor = Color(
                                  colorValue,
                                ).withOpacity(0.2);

                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: lightColor,
                                    border: Border.all(color: subjectColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subject,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        className,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
              ),
            );
          }).toList(),
        ],
      );
    }).toList();
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
              color: Colors.blue,
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
            child: Divider(color: Colors.blue.withOpacity(0.3), thickness: 1),
          ),
        ],
      ),
    );
  }

  // Card design for tablet
  Widget _buildTimetableCard(BuildContext context, DocumentSnapshot timetable) {
    final data = timetable.data() as Map<String, dynamic>;
    final String className = data['className'] ?? 'Unknown Class';
    final String subject = data['subject'] ?? 'Unknown Subject';
    final String time = data['time'] ?? 'No Time Set';

    // Generate a consistent color based on the subject name
    final int colorValue = subject.hashCode & 0xFFFFFF;
    final Color subjectColor = Color(colorValue).withOpacity(0.8);
    final Color lightColor = Color(colorValue).withOpacity(0.2);

    return Card(
      elevation: 2,
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
        ),
      ),
    );
  }
}
