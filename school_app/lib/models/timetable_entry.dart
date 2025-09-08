import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableEntry {
  final String id;
  final String subject;
  final String teacherName;
  final String className;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String roomNumber;

  TimetableEntry({
    required this.id,
    required this.subject,
    required this.teacherName,
    required this.className,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.roomNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'teacherName': teacherName,
      'className': className,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'roomNumber': roomNumber,
    };
  }

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    return TimetableEntry(
      id: map['id'] ?? '',
      subject: map['subject'] ?? '',
      teacherName: map['teacherName'] ?? '',
      className: map['className'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
    );
  }

  factory TimetableEntry.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> map = doc.data() as Map<String, dynamic>;
    return TimetableEntry.fromMap({...map, 'id': doc.id});
  }
}
