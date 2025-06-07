//Model Not in Use

import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String submissionId;
  final bool accepted;
  final String ratedBy;
  final int rating;
  final String reviewComments;

  ReviewModel({
    required this.reviewId,
    required this.submissionId,
    required this.accepted,
    required this.ratedBy,
    required this.rating,
    required this.reviewComments,
  });

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'submissionId': submissionId,
      'accepted': accepted,
      'ratedBy': ratedBy,
      'rating': rating,
      'reviewComments': reviewComments,
    };
  }

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return ReviewModel(
      reviewId: data['reviewId'],
      submissionId: data['submissionId'],
      accepted: data['accepted'],
      ratedBy: data['ratedBy'],
      rating: data['rating'],
      reviewComments: data['reviewComments'],
    );
  }
}
