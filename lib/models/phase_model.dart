import 'package:cloud_firestore/cloud_firestore.dart';

class PhaseModel {
  final String phaseId;
  final String projectId;
  final String name;
  final String description;
  final Timestamp startDate;
  final Timestamp deadline;
  final int noOfTasks;
  final String status;
  final int index;

  PhaseModel({
    required this.phaseId,
    required this.projectId,
    required this.name,
    required this.description,
    required this.startDate,
    required this.deadline,
    required this.noOfTasks,
    required this.status,
    required this.index,
  });

  Map<String, dynamic> toMap() {
    return {
      'phaseId': phaseId,
      'projectId': projectId,
      'name': name,
      'description': description,
      'startDate': startDate,
      'deadline': deadline,
      'noOfTasks': noOfTasks,
      'status': status,
      'index': index,
    };
  }

  factory PhaseModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return PhaseModel(
      phaseId: data['phaseId'],
      projectId: data['projectId'],
      name: data['name'],
      description: data['description'],
      startDate: data['startDate'],
      deadline: data['deadline'],
      noOfTasks: data['noOfTasks'],
      status: data['status'],
      index: data['index'],
    );
  }
}
