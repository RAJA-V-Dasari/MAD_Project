import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../controllers/project_task_status_updater.dart';
import 'dart:async';

import '../../models/project_model.dart';
import '../../models/phase_model.dart';
import '../../widgets/project_tabs_member_widget.dart';

class ProjectScreenMember extends StatefulWidget {
  final String projectId;
  final String currentUserId;

  const ProjectScreenMember({
    super.key,
    required this.projectId,
    required this.currentUserId,
  });

  @override
  State<ProjectScreenMember> createState() => _ProjectScreenMemberState();
}

class _ProjectScreenMemberState extends State<ProjectScreenMember>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProjectModel? project;
  List<PhaseModel> phases = [];
  bool isLoading = true;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      setState(() {}); // optional UI refresh
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
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching project or phases: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _exitProject() async {
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .update({
          'members': FieldValue.arrayRemove([widget.currentUserId]),
        });

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _confirmExitProject() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Exit Project"),
            content: const Text("Are you sure you want to leave this project?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text("Exit"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _exitProject(); // Call it cleanly
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(project?.name ?? "Project"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'exit') {
                _confirmExitProject();
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'exit', child: Text('Exit Project')),
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
                    Tab(text: 'Your Tasks'),
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
              : ProjectTabsMemberWidget(
                tabController: _tabController,
                project: project!,
                phases: phases,
                currentUserId: widget.currentUserId,
              ),
    );
  }
}
