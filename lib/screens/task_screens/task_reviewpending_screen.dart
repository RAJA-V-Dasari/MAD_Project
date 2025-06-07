import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/task_model.dart';
import '../../models/user_model.dart';

class TaskReviewPendingScreen extends StatefulWidget {
  final String taskId;

  const TaskReviewPendingScreen({super.key, required this.taskId});

  @override
  State<TaskReviewPendingScreen> createState() =>
      _TaskReviewPendingScreenState();
}

class _TaskReviewPendingScreenState extends State<TaskReviewPendingScreen> {
  TaskModel? task;
  String projectName = '';
  String phaseName = '';
  UserModel? assignedUser;

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
                  "Your Submission File",
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
