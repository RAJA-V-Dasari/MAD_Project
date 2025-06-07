import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../screens/task_screens/task_completed_screen.dart';

class SubmissionCard extends StatelessWidget {
  final TaskModel task;

  const SubmissionCard({super.key, required this.task});

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
        final submittedBy = snapshot.hasData ? snapshot.data![0] : 'Loading...';
        final phaseName = snapshot.hasData ? snapshot.data![1] : 'Loading...';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            color: Colors.green.shade50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskCompletedScreen(taskId: task.taskId),
                  ),
                );
              },
              contentPadding: const EdgeInsets.all(20),
              title: Text(
                task.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text("Phase: $phaseName"),
                  Text(
                    "Submitted On: ${task.submittedAt != null ? DateFormat('yyyy-MM-dd').format(task.submittedAt!.toDate()) : 'N/A'}",
                  ),
                  Text("Submitted By: $submittedBy"),
                  const SizedBox(height: 6),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Status: ",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: "Completed",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }
}
