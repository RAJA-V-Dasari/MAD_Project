import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/task_model.dart';
import '../../models/user_model.dart';

class TaskCompletedScreen extends StatefulWidget {
  final String taskId;

  const TaskCompletedScreen({super.key, required this.taskId});

  @override
  State<TaskCompletedScreen> createState() => _TaskCompletedScreenState();
}

class _TaskCompletedScreenState extends State<TaskCompletedScreen> {
  TaskModel? task;
  String projectName = '';
  String phaseName = '';
  UserModel? assignedUser;
  UserModel? reviewerUser;
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

      final assignedUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(taskData.assignedToUid)
              .get();

      final reviewerDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(taskData.reviewedByUid)
              .get();

      if (!mounted) return;

      setState(() {
        task = taskData;
        assignedUser = UserModel.fromFirestore(assignedUserDoc);
        reviewerUser = UserModel.fromFirestore(reviewerDoc);
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

  @override
  Widget build(BuildContext context) {
    if (isLoading ||
        task == null ||
        assignedUser == null ||
        reviewerUser == null) {
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
                  "Submitted At",
                  task!.submittedAt != null
                      ? DateFormat(
                        'yyyy-MM-dd HH:mm:ss',
                      ).format(task!.submittedAt!.toDate())
                      : 'N/A',
                ),
                metaRow("Rating", task!.rating?.toString() ?? 'N/A'),
                metaRow("Format", task!.expectedFileFormat),
                metaRow("Reviewed By", reviewerUser!.email),
                metaRow(
                  "Reviewed At",
                  task!.reviewedAt != null
                      ? DateFormat(
                        'yyyy-MM-dd HH:mm:ss',
                      ).format(task!.reviewedAt!.toDate())
                      : 'N/A',
                ),
                metaRow("Status", "Completed", valueColor: Colors.green),

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
                  "Review Comments",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(task!.reviewFeedback ?? "No review comments provided."),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
