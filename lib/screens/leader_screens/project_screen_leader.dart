import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/project_model.dart';
import '../../models/phase_model.dart';
import '../../widgets/project_tabs_leader_widget.dart';
import '../../controllers/project_task_status_updater.dart';

import 'edit_screens/edit_project_screen.dart';

class ProjectScreen extends StatefulWidget {
  final String projectId;
  final int bottomNavIndex;

  const ProjectScreen({
    super.key,
    required this.projectId,
    this.bottomNavIndex = 0,
  });

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProjectModel? project;
  List<PhaseModel> phases = [];
  bool isLoading = true;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _updateOverdueTasksNowAndAtMidnight();
    fetchProjectAndPhases();
  }

  void _updateOverdueTasksNowAndAtMidnight() async {
    await ProjectTaskStatusUpdater.updateOverdueTasksForProject(
      widget.projectId,
    );

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    _midnightTimer = Timer(durationUntilMidnight, () async {
      await ProjectTaskStatusUpdater.updateOverdueTasksForProject(
        widget.projectId,
      );
      setState(() {}); // Refresh screen if needed
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchProjectAndPhases() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(widget.projectId)
              .get();

      if (doc.exists) {
        final loadedProject = ProjectModel.fromFirestore(doc);

        final phasesSnapshot =
            await FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.projectId)
                .collection('phases')
                .orderBy('index')
                .get();

        final loadedPhases =
            phasesSnapshot.docs
                .map((phaseDoc) => PhaseModel.fromFirestore(phaseDoc))
                .toList();

        setState(() {
          project = loadedProject;
          phases = loadedPhases;
          isLoading = false;
        });
      } else {
        print("Project not found.");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching project or phases: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
              'Are you sure you want to delete this project and all its data?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext); // Close the dialog

                  final messenger = ScaffoldMessenger.of(
                    dialogContext,
                  ); // Safe context

                  try {
                    final projectRef = FirebaseFirestore.instance
                        .collection('projects')
                        .doc(widget.projectId);
                    final phasesSnapshot =
                        await projectRef.collection('phases').get();

                    for (var phaseDoc in phasesSnapshot.docs) {
                      final tasksSnapshot =
                          await phaseDoc.reference.collection('tasks').get();

                      for (var taskDoc in tasksSnapshot.docs) {
                        await taskDoc.reference.delete();
                      }

                      await phaseDoc.reference.delete();
                    }

                    await projectRef.delete();

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("Project deleted successfully."),
                      ),
                    );

                    if (!mounted) return;

                    Navigator.of(context).pop();
                  } catch (e) {
                    debugPrint("Error deleting project: $e");

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("Failed to delete project."),
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project?.name ?? "Project",
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProjectScreen(project: project!),
                  ),
                );
                fetchProjectAndPhases();
              } else if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Project'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Project'),
                  ),
                ],
          ),
        ],

        bottom:
            project != null
                ? TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Phases'),
                    Tab(text: 'Reviews'),
                    Tab(text: 'Analytics'),
                    Tab(text: 'Submissions'),
                    Tab(text: 'Members'),
                  ],
                )
                : null,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : project == null
              ? const Center(child: Text("Project not found"))
              : ProjectTabsWidget(
                tabController: _tabController,
                phases: phases,
                project: project!,
              ),
    );
  }
}
