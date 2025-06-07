import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/phase_model.dart';

class ProjectUpdateController {
  static Future<void> updateProjectFields(String projectId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final projectRef = firestore.collection('projects').doc(projectId);
    final phaseCollection = projectRef.collection('phases');

    try {
      // Fetch all phases
      final snapshot = await phaseCollection.get();
      List<PhaseModel> phases =
          snapshot.docs.map((doc) => PhaseModel.fromFirestore(doc)).toList();

      if (phases.isEmpty) {
        await projectRef.update({
          'noOfPhases': 0,
          'deadline': null,
          'currentPhaseIndex': 0,
        });
        return;
      }

      // Sort by deadline
      phases.sort((a, b) => a.deadline.compareTo(b.deadline));

      // Update index of each phase (1-based)
      for (int i = 0; i < phases.length; i++) {
        await phaseCollection.doc(phases[i].phaseId).update({'index': i + 1});
        phases[i] = PhaseModel(
          phaseId: phases[i].phaseId,
          projectId: phases[i].projectId,
          name: phases[i].name,
          description: phases[i].description,
          startDate: phases[i].startDate,
          deadline: phases[i].deadline,
          noOfTasks: phases[i].noOfTasks,
          status: phases[i].status,
          index: i + 1,
        );
      }

      // Compute updated project-level values
      final int noOfPhases = phases.length;
      final Timestamp newDeadline = phases.last.deadline;

      final currentPhase = phases.firstWhere(
        (p) => p.status == 'In Progress',
        orElse: () => phases.first,
      );
      final int currentPhaseIndex = currentPhase.index;

      // Update project doc
      await projectRef.update({
        'noOfPhases': noOfPhases,
        'deadline': newDeadline,
        'currentPhaseIndex': currentPhaseIndex,
      });
    } catch (e) {
      print('Error in ProjectUpdateController: $e');
      rethrow;
    }
  }
}
