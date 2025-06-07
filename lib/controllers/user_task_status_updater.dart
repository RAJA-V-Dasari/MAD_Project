import 'package:cloud_firestore/cloud_firestore.dart';

class UserTaskStatusUpdater {
  static Future<void> updateOverdueTasksForUser(String userId) async {
    final now = DateTime.now();

    final taskQuery =
        await FirebaseFirestore.instance
            .collectionGroup('tasks')
            .where('assignedToUid', isEqualTo: userId)
            .where('status', isEqualTo: 'Pending')
            .get();

    for (final doc in taskQuery.docs) {
      final deadline = (doc['deadline'] as Timestamp).toDate();

      if (deadline.isBefore(now)) {
        await doc.reference.update({'status': 'Overdue'});
      }
    }
  }
}
