import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../screens/task_screens/task_review_screen.dart';

class ReviewCard extends StatelessWidget {
  final TaskModel task;

  const ReviewCard({super.key, required this.task});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'under review':
        return const Color(0xFF42A5F5); // Blue
      default:
        return Colors.grey;
    }
  }

  Future<String> _getUserEmail(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromFirestore(doc).email : 'Unknown';
    } catch (e) {
      return 'Error';
    }
  }

  Future<String> _getPhaseName(String projectId, String phaseId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(projectId)
              .collection('phases')
              .doc(phaseId)
              .get();
      return doc.exists ? doc['name'] ?? 'Unnamed Phase' : 'Unknown Phase';
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: Future.wait([
        _getUserEmail(task.assignedToUid),
        _getPhaseName(task.projectId, task.phaseId),
      ]),
      builder: (context, snapshot) {
        final submittedBy =
            (snapshot.hasData && snapshot.data!.isNotEmpty)
                ? snapshot.data![0]
                : 'Loading...';
        final phaseName =
            (snapshot.hasData && snapshot.data!.length > 1)
                ? snapshot.data![1]
                : 'Loading...';

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ), // Horizontal padding
          child: Card(
            color: Colors.blue.shade50,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              title: Text(
                task.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("Phase: $phaseName"),
                  Text(
                    "Submitted On: ${task.submittedAt != null ? DateFormat('yyyy-MM-dd').format(task.submittedAt!.toDate()) : 'Not submitted'}",
                  ),
                  Text("Submitted By: $submittedBy"),
                  Row(
                    children: [
                      const Text("Status: "),
                      Text(
                        task.status,
                        style: TextStyle(
                          color: _getStatusColor(task.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskReviewScreen(taskId: task.taskId),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
