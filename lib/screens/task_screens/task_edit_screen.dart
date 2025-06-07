import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/task_model.dart';
import '../../models/user_model.dart';

class TaskEditPage extends StatefulWidget {
  final String taskId;

  const TaskEditPage({super.key, required this.taskId});

  @override
  State<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends State<TaskEditPage> {
  TaskModel? task;
  String projectName = '';
  String phaseName = '';
  UserModel? assignedUser;
  PlatformFile? selectedFile;
  final TextEditingController commentController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isLoading = true;
  bool isSubmitting = false;

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

      if (querySnap.docs.isEmpty) {
        throw Exception('Task not found');
      }

      final taskDoc = querySnap.docs.first;
      final taskData = TaskModel.fromFirestore(taskDoc);

      final phaseDoc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(taskData.projectId)
              .collection('phases')
              .doc(taskData.phaseId)
              .get();

      if (!phaseDoc.exists) {
        throw Exception('Phase not found for ID: ${taskData.phaseId}');
      }

      final projectDoc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(taskData.projectId)
              .get();

      if (!projectDoc.exists) {
        throw Exception('Project not found for ID: ${taskData.projectId}');
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(taskData.assignedToUid)
              .get();

      if (!userDoc.exists) {
        throw Exception(
          'Assigned user not found for UID: ${taskData.assignedToUid}',
        );
      }

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

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && mounted) {
      setState(() {
        selectedFile = result.files.single;
      });
    }
  }

  Future<String> uploadFileToSupabase() async {
    final supabase = Supabase.instance.client;
    final file = selectedFile!;
    final path =
        'submissions/${task!.taskId}_${DateTime.now().millisecondsSinceEpoch}_${file.name}';

    final response = await supabase.storage
        .from('task-submissions')
        .uploadBinary(
          path,
          file.bytes!,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    if (response.isEmpty) {
      throw Exception("Failed to upload");
    }

    return supabase.storage.from('task-submissions').getPublicUrl(path);
  }

  Future<void> handleSubmit() async {
    if (selectedFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a file.")));
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final supabase = Supabase.instance.client;

    try {
      // Step 1: Delete old file if attemptNo > 1 and previous file exists
      // Delete old file ONLY IF a new file is selected
      if (selectedFile != null &&
          task!.attemptNo > 1 &&
          task!.submittedFileUrl != null &&
          task!.submittedFileUrl!.isNotEmpty) {
        final oldUrl = task!.submittedFileUrl!;
        final uri = Uri.parse(oldUrl);
        final segments = uri.pathSegments;
        final bucketIndex = segments.indexOf('task-submissions');
        final filePath = segments.sublist(bucketIndex + 1).join('/');

        await supabase.storage.from('task-submissions').remove([filePath]);
      }

      // Step 2: Upload new file
      final file = selectedFile!;
      final newPath =
          'submissions/${task!.taskId}_${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      final response = await supabase.storage
          .from('task-submissions')
          .uploadBinary(
            newPath,
            file.bytes!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      if (response.isEmpty) {
        throw Exception("Failed to upload file.");
      }

      final newFileUrl = supabase.storage
          .from('task-submissions')
          .getPublicUrl(newPath);

      // Step 3: Update Firestore
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(task!.projectId)
          .collection('phases')
          .doc(task!.phaseId)
          .collection('tasks')
          .doc(task!.taskId)
          .update({
            'submittedFileUrl': newFileUrl,
            'submittedAt': Timestamp.now(),
            'submittedComments': commentController.text.trim(),
            'status': 'Under Review',
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task submitted successfully.")),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Submission failed: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (isLoading || task == null || assignedUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Widget metaRow(String label, String value, {Color? valueColor}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$label: ",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
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
                  valueColor:
                      task!.status == "Pending"
                          ? Colors.orange
                          : task!.status == "Overdue"
                          ? Colors.red
                          : Colors.grey,
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
                if (task!.attemptNo > 1) ...[
                  const Text(
                    "Previous Submission",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      final url = task!.submittedFileUrl;
                      if (url != null) launchUrl(Uri.parse(url));
                    },
                    child: Text(
                      task!.submittedFileUrl ?? "No previous file found",
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Previous Submission Comments",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task!.submittedComments ?? "No previous comments",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Review Feedback",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task!.reviewFeedback ?? "No feedback yet",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1, height: 32),
                ],

                const SizedBox(height: 20),
                const Text(
                  "File Upload",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text("Choose File"),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedFile?.name ?? "No file chosen",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Comments",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Comments",
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        isSubmitting
                            ? null
                            : () {
                              showDialog(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text("Confirm Submission"),
                                      content: const Text(
                                        "Submission can be done only once. Proceed?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            handleSubmit();
                                          },
                                          child: const Text("Submit"),
                                        ),
                                      ],
                                    ),
                              );
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child:
                        isSubmitting
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              "Submit",
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
