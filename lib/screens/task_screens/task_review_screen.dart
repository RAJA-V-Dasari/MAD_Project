import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/task_model.dart';
import '../../models/user_model.dart';

class TaskReviewScreen extends StatefulWidget {
  final String taskId;

  const TaskReviewScreen({super.key, required this.taskId});

  @override
  State<TaskReviewScreen> createState() => _TaskReviewScreenState();
}

class _TaskReviewScreenState extends State<TaskReviewScreen> {
  TaskModel? task;
  String projectName = '';
  String phaseName = '';
  UserModel? assignedUser;

  final TextEditingController reviewCommentController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTaskAndMeta();
  }

  Future<void> fetchTaskAndMeta() async {
    try {
      final querySnap =
          await FirebaseFirestore.instance
              .collectionGroup('tasks')
              .where('taskId', isEqualTo: widget.taskId)
              .limit(1)
              .get();

      if (querySnap.docs.isEmpty) throw Exception('Task not found');

      final taskDoc = querySnap.docs.first;
      final taskData = TaskModel.fromFirestore(taskDoc);

      final phaseDoc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(taskData.projectId)
              .collection('phases')
              .doc(taskData.phaseId)
              .get();

      final projectDoc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(taskData.projectId)
              .get();

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(taskData.assignedToUid)
              .get();

      if (!mounted) return;

      setState(() {
        task = taskData;
        assignedUser = UserModel.fromFirestore(userDoc);
        phaseName = phaseDoc['name'] ?? '';
        projectName = projectDoc['name'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget metaRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: TextStyle(color: valueColor))),
        ],
      ),
    );
  }

  Future<void> updateTask({required bool accepted}) async {
    if (task == null) return;

    final ratingText = ratingController.text.trim();
    final reviewText = reviewCommentController.text.trim();

    if (accepted) {
      // On acceptance, both rating and review must be present
      final rating = double.tryParse(ratingText);
      if (rating == null || rating < 0 || rating > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a valid rating between 0 and 10."),
          ),
        );
        return;
      }
      if (reviewText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter review comments.")),
        );
        return;
      }
    } else {
      // On rejection, review comment must be present
      if (reviewText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please provide a reason for rejection."),
          ),
        );
        return;
      }
    }

    final docRef = FirebaseFirestore.instance
        .collection('projects')
        .doc(task!.projectId)
        .collection('phases')
        .doc(task!.phaseId)
        .collection('tasks')
        .doc(task!.taskId);

    final updateData = {
      'status': accepted ? 'Completed' : 'Pending',
      'reviewedAt': Timestamp.now(),
      'reviewedByUid': FirebaseAuth.instance.currentUser!.uid,
      'reviewFeedback': reviewText,
    };

    if (accepted) {
      updateData['rating'] = double.parse(ratingText);
    } else {
      updateData['rating'] = -1;
      updateData['attemptNo'] = task!.attemptNo + 1;
    }

    await docRef.update(updateData);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Task ${accepted ? 'accepted' : 'rejected'}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || task == null || assignedUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phaseName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              projectName,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                metaRow("Submitted By", assignedUser!.email),
                metaRow(
                  "Submitted On",
                  task!.submittedAt != null
                      ? DateFormat(
                        'yyyy-MM-dd',
                      ).format(task!.submittedAt!.toDate())
                      : 'N/A',
                ),
                metaRow("Status", "Under Review", valueColor: Colors.blue),
                const Divider(thickness: 1, height: 32),

                const Text(
                  "Description",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(task!.description, style: const TextStyle(fontSize: 16)),

                const SizedBox(height: 20),
                const Text(
                  "Submitted File",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final url = task!.submittedFileUrl;
                    if (url != null && await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Could not open the file."),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text("Download Submission"),
                ),

                const SizedBox(height: 20),
                const Text(
                  "Submission Comments",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(task!.submittedComments ?? "No comments provided."),

                const SizedBox(height: 20),
                const Text(
                  "Rate Submission",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: ratingController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "Rating",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("/ 10", style: TextStyle(fontSize: 16)),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  "Review Comments",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reviewCommentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Add feedback or remarks",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => updateTask(accepted: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          "Reject",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => updateTask(accepted: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        child: const Text(
                          "Accept",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
