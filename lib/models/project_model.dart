import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String projectId;
  final String name;
  final String description;
  final int noOfPhases;
  final String teamLeadId;
  final List<String> members;
  final int currentPhaseIndex;
  final double overallProgress;
  final Timestamp deadline;
  final Timestamp createdAt;

  ProjectModel({
    required this.projectId,
    required this.name,
    required this.description,
    required this.noOfPhases,
    required this.teamLeadId,
    required this.members,
    required this.currentPhaseIndex,
    required this.overallProgress,
    required this.deadline,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'name': name,
      'description': description,
      'noOfPhases': noOfPhases,
      'teamLeadId': teamLeadId,
      'members': members,
      'currentPhaseIndex': currentPhaseIndex,
      'overallProgress': overallProgress,
      'deadline': deadline,
      'createdAt': createdAt,
    };
  }

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return ProjectModel(
      projectId: data['projectId'],
      name: data['name'],
      description: data['description'],
      noOfPhases: data['noOfPhases'],
      teamLeadId: data['teamLeadId'],
      members: List<String>.from(data['members']),
      currentPhaseIndex: data['currentPhaseIndex'],
      overallProgress: (data['overallProgress'] as num).toDouble(),
      deadline: data['deadline'],
      createdAt: data['createdAt'],
    );
  }
}
