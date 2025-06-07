import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/search_bar.dart';
import '../widgets/filter_buttons.dart';
import '../widgets/task_cards/task_card_2.dart';
import '../controllers/user_task_status_updater.dart';

import 'task_screens/task_edit_screen.dart';
import 'task_screens/task_completed_screen.dart';
import 'task_screens/task_reviewpending_screen.dart';

class TaskScreen extends StatefulWidget {
  final String userId;

  const TaskScreen({super.key, required this.userId});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TextEditingController _searchController = TextEditingController();
  int selectedFilterIndex = 0;
  String _searchQuery = "";

  Timer? _midnightTimer;

  List<String> filterLabels = [
    "All",
    "Completed",
    "Pending",
    "Under Review",
    "Overdue",
  ];
  @override
  void initState() {
    super.initState();
    _updateOverdueTasksNowAndAtMidnight();
  }

  void _updateOverdueTasksNowAndAtMidnight() async {
    // Update immediately
    await UserTaskStatusUpdater.updateOverdueTasksForUser(widget.userId);

    // Calculate time until next midnight
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    _midnightTimer = Timer(durationUntilMidnight, () async {
      await UserTaskStatusUpdater.updateOverdueTasksForUser(widget.userId);
      setState(() {}); // Trigger UI refresh after status updates
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tasks")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SearchBarWidget(
              hintText: "Search for tasks",
              controller: _searchController,
              onSearch: () {
                setState(() {
                  _searchQuery = _searchController.text.toLowerCase();
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = "";
                });
              },
            ),
            const SizedBox(height: 16),
            FilterButtonsWidget(
              labels: filterLabels,
              selectedIndex: selectedFilterIndex,
              onSelected: (index) {
                setState(() {
                  selectedFilterIndex = index;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildTaskList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collectionGroup('tasks')
              .where('assignedToUid', isEqualTo: widget.userId)
              .orderBy('deadline')
              .snapshots(),
      builder: (context, taskSnapshot) {
        if (taskSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (taskSnapshot.hasError) {
          return const Center(child: Text("Error fetching tasks"));
        }

        final taskDocs = taskSnapshot.data!.docs;
        final now = Timestamp.now();

        final filteredTasks =
            taskDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              final status = (data['status'] ?? '').toString();
              final deadline =
                  data['deadline'] as Timestamp? ?? Timestamp.now();

              if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) {
                return false;
              }

              switch (selectedFilterIndex) {
                case 1: // Completed
                  return status.toLowerCase() == 'completed';
                case 2: // Pending
                  return status.toLowerCase() == 'pending' &&
                      deadline.compareTo(now) >= 0;
                case 3: // Under Review
                  return status.toLowerCase() == 'under review';
                case 4: // Overdue
                  return (status.toLowerCase() == 'pending' &&
                          deadline.compareTo(now) < 0) ||
                      status.toLowerCase() == 'overdue';
                default:
                  return true;
              }
            }).toList();

        if (filteredTasks.isEmpty) {
          return const Center(child: Text("No tasks found"));
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final doc = filteredTasks[index];
            final data = doc.data() as Map<String, dynamic>;

            final segments = doc.reference.path.split('/');
            if (segments.length < 4) {
              return const ListTile(title: Text("Invalid task path"));
            }

            final phaseRef = doc.reference.parent.parent;

            if (phaseRef == null) {
              return const ListTile(title: Text("Phase reference not found"));
            }

            return FutureBuilder<DocumentSnapshot>(
              future: phaseRef.get(),
              builder: (context, phaseSnapshot) {
                if (!phaseSnapshot.hasData || !phaseSnapshot.data!.exists) {
                  return const SizedBox(); // Phase not found
                }

                final phaseData =
                    phaseSnapshot.data!.data() as Map<String, dynamic>?;
                final projectId = phaseData?['projectId'];
                if (projectId == null) {
                  return const ListTile(title: Text("Project ID not found"));
                }

                final projectRef = FirebaseFirestore.instance
                    .collection('projects')
                    .doc(projectId);

                return FutureBuilder<DocumentSnapshot>(
                  future: projectRef.get(),
                  builder: (context, projectSnapshot) {
                    if (!projectSnapshot.hasData ||
                        !projectSnapshot.data!.exists) {
                      return const SizedBox(); // Project not found
                    }

                    final projectData =
                        projectSnapshot.data!.data() as Map<String, dynamic>?;
                    final projectName =
                        projectData?['name'] ?? 'Unnamed Project';

                    return TaskCardWidget(
                      taskName: data['name']?.toString() ?? 'Unnamed Task',
                      projectName: projectName,
                      deadline:
                          (data['deadline'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                      status: data['status']?.toString() ?? 'Unknown',
                      onTap: () {
                        final taskStatus =
                            (data['status'] ?? '').toString().toLowerCase();
                        if (taskStatus == 'pending' ||
                            taskStatus == 'overdue') {
                          final taskId = doc.id;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskEditPage(taskId: taskId),
                            ),
                          );
                        } else if (taskStatus == 'under review') {
                          final taskId = doc.id;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      TaskReviewPendingScreen(taskId: taskId),
                            ),
                          );
                        } else if (taskStatus == 'completed') {
                          final taskId = doc.id;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => TaskCompletedScreen(taskId: taskId),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Task with unknown status."),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
