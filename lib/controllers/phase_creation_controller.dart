import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_tide_1/models/phase_model.dart';
import 'package:uuid/uuid.dart';

class PhaseController {
  static Future<void> createPhase({
    required BuildContext context,
    required String projectId,
    required String name,
    required String description,
    required DateTime startDate,
    required DateTime deadline,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String phaseId = const Uuid().v4();

    try {
      final projectRef = firestore.collection('projects').doc(projectId);
      final phaseCollection = projectRef.collection('phases');

      // Fetch all existing phases
      final snapshot = await phaseCollection.get();
      final List<PhaseModel> existingPhases =
          snapshot.docs.map((doc) => PhaseModel.fromFirestore(doc)).toList();

      // Add new phase and calculate index based on deadline
      List<PhaseModel> allPhases = List.from(existingPhases);
      final newPhase = PhaseModel(
        phaseId: phaseId,
        projectId: projectId,
        name: name,
        description: description,
        startDate: Timestamp.fromDate(startDate),
        deadline: Timestamp.fromDate(deadline),
        noOfTasks: 0,
        status:
            startDate.isAfter(DateTime.now()) ? "Yet to start" : "In Progress",
        index: 0, // temp
      );

      allPhases.add(newPhase);
      allPhases.sort((a, b) => a.deadline.compareTo(b.deadline));

      // Update indexes
      for (int i = 0; i < allPhases.length; i++) {
        allPhases[i] = PhaseModel(
          phaseId: allPhases[i].phaseId,
          projectId: allPhases[i].projectId,
          name: allPhases[i].name,
          description: allPhases[i].description,
          startDate: allPhases[i].startDate,
          deadline: allPhases[i].deadline,
          noOfTasks: allPhases[i].noOfTasks,
          status: allPhases[i].status,
          index: i + 1,
        );
      }

      // Save updated/new phases
      for (var phase in allPhases) {
        await phaseCollection.doc(phase.phaseId).set(phase.toMap());
      }

      // Determine new project deadline and currentPhaseIndex
      final maxDeadline = allPhases.last.deadline;
      final currentPhaseIndex =
          allPhases
              .firstWhere(
                (p) => p.status == "In Progress",
                orElse: () => allPhases.first,
              )
              .index;

      await projectRef.update({
        'noOfPhases': allPhases.length,
        'deadline': maxDeadline,
        'currentPhaseIndex': currentPhaseIndex,
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phase created successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
