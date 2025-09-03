import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send notification to specific users or roles
  Future<void> sendNotification({
    required String title,
    required String message,
    required String type, // 'assignment', 'announcement', 'deadline', 'general'
    List<String>? userIds, // Specific user IDs
    String? targetRole, // 'student', 'teacher', 'all'
    String? relatedId, // Assignment ID, etc.
    Map<String, dynamic>? additionalData,
    DateTime? scheduledTime,
  }) async {
    try {
      // Get current user for sender info
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get sender info
      DocumentSnapshot senderDoc = await _firestore
          .collection('profiles')
          .doc(currentUser.uid)
          .get();
      
      String senderName = 'Unknown';
      if (senderDoc.exists) {
        Map<String, dynamic> senderData = senderDoc.data() as Map<String, dynamic>;
        senderName = '${senderData['firstName'] ?? ''} ${senderData['lastName'] ?? ''}'.trim();
        if (senderName.isEmpty) senderName = senderData['email'] ?? 'Unknown';
      }

      List<String> targetUserIds = [];

      // Determine target users
      if (userIds != null && userIds.isNotEmpty) {
        targetUserIds = userIds;
      } else if (targetRole != null) {
        // Get users by role
        QuerySnapshot usersQuery;
        if (targetRole == 'all') {
          usersQuery = await _firestore.collection('users').get();
        } else {
          usersQuery = await _firestore
              .collection('users')
              .where('role', isEqualTo: targetRole)
              .get();
        }
        
        targetUserIds = usersQuery.docs.map((doc) => doc.id).toList();
      }

      // Create notification data
      Map<String, dynamic> notificationData = {
        'title': title,
        'message': message,
        'type': type,
        'senderId': currentUser.uid,
        'senderName': senderName,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'relatedId': relatedId,
        'additionalData': additionalData ?? {},
        'scheduledTime': scheduledTime,
      };

      // Send to each target user
      for (String userId in targetUserIds) {
        if (userId != currentUser.uid) { // Don't send to self
          await _firestore
              .collection('notifications')
              .doc(userId)
              .collection('userNotifications')
              .add({
            ...notificationData,
            'recipientId': userId,
          });
        }
      }

      Fluttertoast.showToast(
        msg: 'Notification sent to ${targetUserIds.length} users',
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to send notification: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Send assignment notification to class
  Future<void> sendAssignmentNotificationToClass({
    required String assignmentId,
    required String assignmentTitle,
    required String description,
    required DateTime deadline,
    required String classId,
    required String className,
  }) async {
    try {
      // Get students in the target class
      DocumentSnapshot classDoc = await _firestore
          .collection('classes')
          .doc(classId)
          .get();

      if (!classDoc.exists) {
        Fluttertoast.showToast(
          msg: 'Class not found',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
      List<dynamic> studentIds = classData['studentIds'] ?? [];

      if (studentIds.isEmpty) {
        Fluttertoast.showToast(
          msg: 'No students in this class',
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return;
      }

      await sendNotification(
        title: 'New Assignment: $assignmentTitle',
        message: 'Class: $className\nYou have a new assignment due on ${_formatDate(deadline)}.\n$description',
        type: 'assignment',
        userIds: studentIds.cast<String>(),
        relatedId: assignmentId,
        additionalData: {
          'deadline': deadline.toIso8601String(),
          'classId': classId,
          'className': className,
          'assignmentTitle': assignmentTitle,
        },
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to send class notification: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Send assignment notification
  Future<void> sendAssignmentNotification({
    required String assignmentId,
    required String assignmentTitle,
    required String description,
    required DateTime deadline,
    required String targetGrade,
  }) async {
    // Get students in the target grade
    QuerySnapshot studentsQuery = await _firestore
        .collection('profiles')
        .where('role', isEqualTo: 'student')
        .where('grade', isEqualTo: targetGrade)
        .get();

    List<String> studentIds = studentsQuery.docs.map((doc) => doc.id).toList();

    await sendNotification(
      title: 'New Assignment: $assignmentTitle',
      message: 'You have a new assignment due on ${_formatDate(deadline)}. $description',
      type: 'assignment',
      userIds: studentIds,
      relatedId: assignmentId,
      additionalData: {
        'deadline': deadline.toIso8601String(),
        'grade': targetGrade,
        'assignmentTitle': assignmentTitle,
      },
    );
  }

  // Send deadline reminder
  Future<void> sendDeadlineReminder({
    required String assignmentId,
    required String assignmentTitle,
    required DateTime deadline,
    required String targetGrade,
    required int daysLeft,
  }) async {
    QuerySnapshot studentsQuery = await _firestore
        .collection('profiles')
        .where('role', isEqualTo: 'student')
        .where('grade', isEqualTo: targetGrade)
        .get();

    List<String> studentIds = studentsQuery.docs.map((doc) => doc.id).toList();

    String reminderMessage = daysLeft == 0 
        ? 'Assignment "$assignmentTitle" is due today!'
        : 'Reminder: Assignment "$assignmentTitle" is due in $daysLeft day${daysLeft > 1 ? 's' : ''}';

    await sendNotification(
      title: 'Assignment Deadline Reminder',
      message: reminderMessage,
      type: 'deadline',
      userIds: studentIds,
      relatedId: assignmentId,
      additionalData: {
        'deadline': deadline.toIso8601String(),
        'daysLeft': daysLeft,
        'assignmentTitle': assignmentTitle,
      },
    );
  }

  // Get user notifications
  Stream<QuerySnapshot> getUserNotifications() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('notifications')
        .doc(currentUser.uid)
        .collection('userNotifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('userNotifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      QuerySnapshot unreadNotifications = await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('userNotifications')
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (QueryDocumentSnapshot doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('userNotifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .doc(currentUser.uid)
        .collection('userNotifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Check for upcoming deadlines and send reminders
  Future<void> checkAndSendDeadlineReminders() async {
    try {
      DateTime now = DateTime.now();
      DateTime threeDaysLater = now.add(const Duration(days: 3));

      // Get assignments with deadlines in the next 3 days
      QuerySnapshot assignmentsQuery = await _firestore
          .collection('assignments')
          .where('deadline', isGreaterThanOrEqualTo: now)
          .where('deadline', isLessThanOrEqualTo: threeDaysLater)
          .get();

      for (QueryDocumentSnapshot doc in assignmentsQuery.docs) {
        Map<String, dynamic> assignment = doc.data() as Map<String, dynamic>;
        DateTime deadline = (assignment['deadline'] as Timestamp).toDate();
        int daysLeft = deadline.difference(now).inDays;

        // Send reminder for deadlines 3 days, 1 day, and same day
        if (daysLeft == 3 || daysLeft == 1 || daysLeft == 0) {
          await sendDeadlineReminder(
            assignmentId: doc.id,
            assignmentTitle: assignment['title'] ?? 'Assignment',
            deadline: deadline,
            targetGrade: assignment['grade'] ?? '',
            daysLeft: daysLeft,
          );
        }
      }
    } catch (e) {
      print('Error checking deadline reminders: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
