import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String taskId;
  final String phaseId;
  final String projectId;
  final String name;
  final String description;
  final String status; // Pending, Under Review, Complete
  final String assignedToUid;
  final Timestamp deadline;
  final String expectedFileFormat;
  final int attemptNo;
  final Timestamp? submittedAt;
  final Timestamp? reviewedAt;
  final String? submittedFileUrl; // Supabase file URL
  final String? submittedComments;
  final String? reviewFeedback; // Feedback from Team Lead
  final String? reviewedByUid; // Reviewer UID
  final double? rating; // Rating out of 10, nullable

  TaskModel({
    required this.taskId,
    required this.phaseId,
    required this.projectId,
    required this.name,
    required this.description,
    required this.status,
    required this.assignedToUid,
    required this.deadline,
    required this.expectedFileFormat,
    required this.attemptNo,
    this.submittedAt,
    this.reviewedAt,
    this.submittedFileUrl,
    this.submittedComments,
    this.reviewFeedback,
    this.reviewedByUid,
    this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'phaseId': phaseId,
      'projectId': projectId,
      'name': name,
      'description': description,
      'status': status,
      'assignedToUid': assignedToUid,
      'deadline': deadline,
      'expectedFileFormat': expectedFileFormat,
      'attemptNo': attemptNo,
      'submittedAt': submittedAt,
      'reviewedAt': reviewedAt,
      'submittedFileUrl': submittedFileUrl,
      'submittedComments': submittedComments,
      'reviewFeedback': reviewFeedback,
      'reviewedByUid': reviewedByUid,
      'rating': rating,
    };
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return TaskModel(
      taskId: data['taskId'],
      phaseId: data['phaseId'],
      projectId: data['projectId'],
      name: data['name'],
      description: data['description'],
      status: data['status'],
      assignedToUid: data['assignedToUid'],
      deadline: data['deadline'],
      expectedFileFormat: data['expectedFileFormat'],
      attemptNo: data['attemptNo'],
      submittedAt: data['submittedAt'],
      reviewedAt: data['reviewedAt'],
      submittedFileUrl: data['submittedFileUrl'],
      submittedComments: data['submittedComments'],
      reviewFeedback: data['reviewFeedback'],
      reviewedByUid: data['reviewedByUid'],
      rating:
          data['rating'] != null ? (data['rating'] as num).toDouble() : null,
    );
  }
}
