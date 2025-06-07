import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectTaskStatusUpdater {
  static Future<void> updateOverdueTasksForProject(String projectId) async {
    final now = DateTime.now();

    final phasesSnapshot =
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('phases')
            .get();

    for (final phaseDoc in phasesSnapshot.docs) {
      final tasksSnapshot =
          await phaseDoc.reference
              .collection('tasks')
              .where('status', isEqualTo: 'Pending')
              .get();

      for (final taskDoc in tasksSnapshot.docs) {
        final deadline = (taskDoc['deadline'] as Timestamp).toDate();

        if (deadline.isBefore(now)) {
          await taskDoc.reference.update({'status': 'Overdue'});
        }
      }
    }
  }
}
