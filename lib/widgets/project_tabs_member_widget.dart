import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../models/phase_model.dart';
import '../models/task_model.dart';
import '../screens/member_screens/phase_screen_member.dart';
import 'phase_card.dart';
import 'task_cards/your_task_card_widget.dart';
import 'task_cards/submission_card.dart';

import '../controllers/phase_status_controller.dart';

class ProjectTabsMemberWidget extends StatefulWidget {
  final TabController tabController;
  final ProjectModel project;
  final List<PhaseModel> phases;
  final String currentUserId;

  const ProjectTabsMemberWidget({
    super.key,
    required this.tabController,
    required this.project,
    required this.phases,
    required this.currentUserId,
  });

  @override
  State<ProjectTabsMemberWidget> createState() =>
      _ProjectTabsMemberWidgetState();
}

class _ProjectTabsMemberWidgetState extends State<ProjectTabsMemberWidget> {
  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: widget.tabController,
      children: [
        // ---------- PHASES TAB ----------
        Scaffold(
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('projects')
                          .doc(widget.project.projectId)
                          .collection('phases')
                          .orderBy('index')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No phases found.'));
                    }

                    final phases =
                        snapshot.data!.docs.map((doc) {
                          final phase = PhaseModel.fromFirestore(doc);

                          // Trigger async update for phase status
                          PhaseStatusController.updatePhaseStatus(
                            widget.project.projectId,
                            phase.phaseId,
                          );

                          return phase;
                        }).toList();

                    return ListView.builder(
                      itemCount: phases.length,
                      itemBuilder: (context, index) {
                        final phase = phases[index];
                        return PhaseCardWidget(
                          phase: phase,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => PhaseScreenMember(
                                      projectId: phase.projectId,
                                      phaseId: phase.phaseId,
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ---------- TASKS TAB ----------
        StreamBuilder<Map<String, List<Map<String, dynamic>>>>(
          stream: groupedTasksStreamUsingCollectionGroup(
            projectId: widget.project.projectId,
            currentUserId: widget.currentUserId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No tasks assigned to you."));
            }

            final groupedTasks = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children:
                  groupedTasks.entries.map((entry) {
                    final phaseName = entry.key;
                    final tasks = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phaseName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...tasks.map((task) {
                          return YourTaskCardWidget(
                            taskId: task['taskId'],
                            taskName: task['name'],
                            deadline: (task['deadline'] as Timestamp).toDate(),
                            status: task['status'],
                            attemptNo: task['attemptNo'] ?? 1,
                            expectedFileFormat:
                                task['expectedFileFormat'] ?? 'N/A',
                          );
                        }).toList(),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
            );
          },
        ),

        // ---------- SUBMISSIONS TAB ----------
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collectionGroup('tasks')
                  .where('projectId', isEqualTo: widget.project.projectId)
                  .where('status', isEqualTo: 'Completed')
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("No completed submissions found."),
              );
            }

            final tasks =
                snapshot.data!.docs
                    .map((doc) => TaskModel.fromFirestore(doc))
                    .toList();

            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return SubmissionCard(task: tasks[index]);
              },
            );
          },
        ),

        // ---------- MEMBERS TAB ----------
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Project Members',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchOrderedMembers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final members = snapshot.data!;
                    return ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        String label = member['email'];
                        if (member['isLead'] == true) {
                          label += ' (Lead)';
                        } else if (member['id'] == widget.currentUserId) {
                          label += ' (You)';
                        }
                        return ListTile(title: Text(label));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchOrderedMembers() async {
    List<Map<String, dynamic>> allMembers = [];

    // Team Lead first
    final leadDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.project.teamLeadId)
            .get();
    allMembers.add({
      'id': leadDoc.id,
      'email': leadDoc['email'] ?? 'Unknown',
      'isLead': true,
    });

    // Add current user if not lead
    if (widget.currentUserId != widget.project.teamLeadId) {
      final currentUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUserId)
              .get();
      allMembers.add({
        'id': currentUserDoc.id,
        'email': currentUserDoc['email'] ?? 'Unknown',
        'isLead': false,
      });
    }

    // Add other members (excluding lead and current user)
    for (String uid in widget.project.members) {
      if (uid != widget.project.teamLeadId && uid != widget.currentUserId) {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        allMembers.add({
          'id': uid,
          'email': userDoc['email'] ?? 'Unknown',
          'isLead': false,
        });
      }
    }

    return allMembers;
  }

  Stream<Map<String, List<Map<String, dynamic>>>>
  groupedTasksStreamUsingCollectionGroup({
    required String projectId,
    required String currentUserId,
  }) {
    final tasksStream =
        FirebaseFirestore.instance
            .collectionGroup('tasks')
            .where('assignedToUid', isEqualTo: currentUserId)
            .snapshots();

    return tasksStream.asyncMap((snapshot) async {
      final groupedTasks = <String, List<Map<String, dynamic>>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final taskId = doc.id;

        // Get phaseId and projectId from the path
        final taskRef = doc.reference;
        final phaseRef = taskRef.parent.parent;
        final projectRef = phaseRef?.parent.parent;

        final docProjectId = projectRef?.id;
        final docPhaseId = phaseRef?.id;

        if (docProjectId != projectId || docPhaseId == null) continue;

        // Get phase name (ideally cached or fetched once)
        final phaseSnap =
            await FirebaseFirestore.instance
                .collection('projects')
                .doc(projectId)
                .collection('phases')
                .doc(docPhaseId)
                .get();

        final phaseName =
            phaseSnap.exists ? phaseSnap['name'] : 'Unknown Phase';

        final task = {
          ...data,
          'taskId': taskId,
          'phaseId': docPhaseId,
          'phaseName': phaseName,
        };

        groupedTasks.putIfAbsent(phaseName, () => []).add(task);
      }

      // Sort each phase's tasks by deadline
      for (final tasks in groupedTasks.values) {
        tasks.sort(
          (a, b) => (a['deadline'] as Timestamp).compareTo(
            b['deadline'] as Timestamp,
          ),
        );
      }

      return groupedTasks;
    });
  }
}
