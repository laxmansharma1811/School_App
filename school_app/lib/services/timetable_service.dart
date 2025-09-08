import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable_entry.dart';

class TimetableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new timetable entry
  Future<void> addTimetableEntry(TimetableEntry entry) async {
    try {
      await _firestore.collection('timetable').add(entry.toMap());
    } catch (e) {
      throw Exception('Failed to add timetable entry: $e');
    }
  }

  // Update an existing timetable entry
  Future<void> updateTimetableEntry(TimetableEntry entry) async {
    try {
      await _firestore
          .collection('timetable')
          .doc(entry.id)
          .update(entry.toMap());
    } catch (e) {
      throw Exception('Failed to update timetable entry: $e');
    }
  }

  // Delete a timetable entry
  Future<void> deleteTimetableEntry(String entryId) async {
    try {
      await _firestore.collection('timetable').doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete timetable entry: $e');
    }
  }

  // Get timetable entries for a specific class
  Stream<List<TimetableEntry>> getTimetableForClass(String className) {
    return _firestore
        .collection('timetable')
        .where('className', isEqualTo: className)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TimetableEntry.fromDocument(doc))
            .toList());
  }

  // Get all timetable entries
  Stream<List<TimetableEntry>> getAllTimetableEntries() {
    return _firestore
        .collection('timetable')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TimetableEntry.fromDocument(doc))
            .toList());
  }
}
