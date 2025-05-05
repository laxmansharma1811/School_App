import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/services/timetable_service.dart';


class ViewTimetableScreen extends StatelessWidget {
  const ViewTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TimetableService _timetableService = TimetableService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Timetable'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _timetableService.getTimetables(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading timetable'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final timetables = snapshot.data!.docs;

          if (timetables.isEmpty) {
            return const Center(child: Text('No timetable available'));
          }

          return ListView.builder(
            itemCount: timetables.length,
            itemBuilder: (context, index) {
              final timetable = timetables[index];
              final data = timetable.data() as Map<String, dynamic>;

              return ListTile(
                title: Text('${data['className']} - ${data['subject']}'),
                subtitle: Text('Day: ${data['day']} | Time: ${data['time']}'),
              );
            },
          );
        },
      ),
    );
  }
}
