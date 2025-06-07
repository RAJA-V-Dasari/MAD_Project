import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_tide_1/controllers/project_update_controller.dart';
import 'edit_screens/edit_phase_screen.dart';
import 'create_screens/create_task_screen.dart';
import '../../widgets/task_cards/task_card.dart';
import '../../models/task_model.dart';

class PhaseScreenLead extends StatefulWidget {
  final String projectId;
  final String phaseId;

  const PhaseScreenLead({
    super.key,
    required this.projectId,
    required this.phaseId,
  });

  @override
  State<PhaseScreenLead> createState() => _PhaseScreenLeadState();
}

class _PhaseScreenLeadState extends State<PhaseScreenLead> {
  String projectName = '';
  String phaseName = '';

  @override
  void initState() {
    super.initState();
    fetchPhaseAndProjectInfo();
  }

  Future<void> fetchPhaseAndProjectInfo() async {
    try {
      final projectDoc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(widget.projectId)
              .get();
      if (projectDoc.exists) projectName = projectDoc['name'];

      final phaseDoc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(widget.projectId)
              .collection('phases')
              .doc(widget.phaseId)
              .get();
      if (phaseDoc.exists) phaseName = phaseDoc['name'];

      setState(() {});
    } catch (e) {
      debugPrint('Error fetching phase/project info: $e');
    }
  }

  Future<void> deletePhase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Phase"),
            content: const Text(
              "Are you sure you want to delete this phase? All tasks in this phase will also be deleted.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Delete all tasks under the phase
      final taskCollection = firestore
          .collection('projects')
          .doc(widget.projectId)
          .collection('phases')
          .doc(widget.phaseId)
          .collection('tasks');

      final taskDocs = await taskCollection.get();
      for (final doc in taskDocs.docs) {
        await doc.reference.delete();
      }

      // 2. Delete the phase itself
      await firestore
          .collection('projects')
          .doc(widget.projectId)
          .collection('phases')
          .doc(widget.phaseId)
          .delete();

      // 3. Update project-level info
      await ProjectUpdateController.updateProjectFields(widget.projectId);

      if (context.mounted) {
        Navigator.pop(context); // Close this screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Phase and its tasks deleted successfully"),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error deleting phase: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditPhasePage(
                          projectId: widget.projectId,
                          phaseId: widget.phaseId,
                        ),
                  ),
                ).then((_) => fetchPhaseAndProjectInfo());
              } else if (value == 'delete') {
                deletePhase();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'edit', child: Text("Edit Phase")),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text("Delete Phase"),
                  ),
                ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.projectId)
                .collection('phases')
                .doc(widget.phaseId)
                .collection('tasks')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading tasks"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks =
              snapshot.data!.docs
                  .map((doc) => TaskModel.fromFirestore(doc))
                  .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child:
                    tasks.isEmpty
                        ? const Center(child: Text("No tasks found"))
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            return TaskCard(task: tasks[index]);
                          },
                        ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreateTaskScreen(
                    phaseId: widget.phaseId,
                    projectId: widget.projectId,
                  ),
            ),
          );
        },
        label: const Text("New Task"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
