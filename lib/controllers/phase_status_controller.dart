import 'package:cloud_firestore/cloud_firestore.dart';

class PhaseStatusController {
  static Future<void> updatePhaseStatus(
    String projectId,
    String phaseId,
  ) async {
    final phaseRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('phases')
        .doc(phaseId);

    final phaseSnap = await phaseRef.get();
    if (!phaseSnap.exists) return;

    final phaseData = phaseSnap.data()!;
    final DateTime phaseStart = (phaseData['startDate'] as Timestamp).toDate();
    final DateTime phaseDeadline =
        (phaseData['deadline'] as Timestamp).toDate();
    final DateTime now = DateTime.now();

    final taskSnapshot = await phaseRef.collection('tasks').get();

    if (taskSnapshot.docs.isEmpty) {
      // No tasks yet — determine based on current time and phase start
      if (now.isBefore(phaseStart)) {
        await phaseRef.update({'status': 'Yet To Start'});
      } else {
        await phaseRef.update({'status': 'In Progress'});
      }
      return;
    }

    final tasks = taskSnapshot.docs.map((doc) => doc.data()).toList();
    final allCompleted = tasks.every(
      (task) => (task['status'] as String).toLowerCase() == 'completed',
    );

    if (allCompleted) {
      await phaseRef.update({'status': 'Completed'});
    } else if (now.isBefore(phaseStart)) {
      await phaseRef.update({'status': 'Yet To Start'});
    } else if (now.isAfter(phaseDeadline)) {
      await phaseRef.update({'status': 'Past Due'});
    } else {
      await phaseRef.update({'status': 'In Progress'});
    }
  }
}
