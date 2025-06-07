import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/task_model.dart';
import '../../models/user_model.dart';

class TaskReadonlyScreen extends StatefulWidget {
  final String taskId;

  const TaskReadonlyScreen({super.key, required this.taskId});

  @override
  State<TaskReadonlyScreen> createState() => _TaskReadonlyScreenState();
}

class _TaskReadonlyScreenState extends State<TaskReadonlyScreen> {
  TaskModel? task;
  String projectName = '';
  String phaseName = '';
  UserModel? assignedUser;
  final TextEditingController descriptionController = TextEditingController();

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
        phaseName = phaseDoc['name'] ?? 'Unknown Phase';
        projectName = projectDoc['name'] ?? 'Unknown Project';
        descriptionController.text = taskData.description;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching task data: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load task: $e')));
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'under review':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget metaRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: valueColor),
            ),
          ),
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
                metaRow("Assigned To", assignedUser!.email),
                metaRow(
                  "Deadline",
                  DateFormat('yyyy-MM-dd').format(task!.deadline.toDate()),
                ),
                metaRow(
                  "Status",
                  task!.status,
                  valueColor: getStatusColor(task!.status),
                ),
                metaRow("Format", task!.expectedFileFormat),
                if (task!.attemptNo > 1)
                  metaRow("Attempt", task!.attemptNo.toString()),

                const Divider(thickness: 1, height: 32),
                const Text(
                  "Description",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  descriptionController.text,
                  style: const TextStyle(fontSize: 16),
                ),
                const Divider(thickness: 1, height: 32),
                const Text(
                  "Submission",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "No Submission",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
