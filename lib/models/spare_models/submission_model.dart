// Model Not in Use

import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String submissionId;
  final String taskId;
  final Timestamp submittedAt;
  final String submittedBy;
  final String fileUrl;
  final String comments;

  SubmissionModel({
    required this.submissionId,
    required this.taskId,
    required this.submittedAt,
    required this.submittedBy,
    required this.fileUrl,
    required this.comments,
  });

  Map<String, dynamic> toMap() {
    return {
      'submissionId': submissionId,
      'taskId': taskId,
      'submittedAt': submittedAt,
      'submittedBy': submittedBy,
      'fileUrl': fileUrl,
      'comments': comments,
    };
  }

  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return SubmissionModel(
      submissionId: data['submissionId'],
      taskId: data['taskId'],
      submittedAt: data['submittedAt'],
      submittedBy: data['submittedBy'],
      fileUrl: data['fileUrl'],
      comments: data['comments'],
    );
  }
}
