import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/screens/add_timetable_screen.dart';
import 'package:school_app/services/timetable_service.dart';

class TimetableListScreen extends StatelessWidget {
  const TimetableListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TimetableService _timetableService = TimetableService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Management'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _timetableService.getTimetables(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading timetables'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final timetables = snapshot.data!.docs;

          if (timetables.isEmpty) {
            return const Center(child: Text('No timetables found'));
          }

          return ListView.builder(
            itemCount: timetables.length,
            itemBuilder: (context, index) {
              final timetable = timetables[index];
              final data = timetable.data() as Map<String, dynamic>;

              return ListTile(
                title: Text('${data['className']} - ${data['subject']}'),
                subtitle: Text('Day: ${data['day']} | Time: ${data['time']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTimetableScreen(
                              timetableId: timetable.id,
                              timetableData: data,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Timetable'),
                            content: const Text(
                                'Are you sure you want to delete this timetable?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _timetableService.deleteTimetable(timetable.id);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
}