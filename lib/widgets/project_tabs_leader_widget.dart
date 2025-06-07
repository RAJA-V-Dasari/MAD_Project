import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/phase_model.dart';
import '../models/project_model.dart';
import 'phase_card.dart';
import 'task_cards/review_card.dart';
import 'task_cards/submission_card.dart';
import 'package:task_tide_1/screens/leader_screens/create_screens/create_phase_screen.dart';
import 'package:task_tide_1/screens/leader_screens/phase_screen_leader.dart';
import '../controllers/phase_status_controller.dart';

class ProjectTabsWidget extends StatefulWidget {
  final TabController tabController;
  final List<PhaseModel> phases;
  final ProjectModel project;

  const ProjectTabsWidget({
    super.key,
    required this.tabController,
    required this.phases,
    required this.project,
  });

  @override
  State<ProjectTabsWidget> createState() => _ProjectTabsWidgetState();
}

class _ProjectTabsWidgetState extends State<ProjectTabsWidget> {
  final TextEditingController _memberEmailController = TextEditingController();
  String searchText = '';
  String? selectedUserId;

  @override
  void dispose() {
    _memberEmailController.dispose();
    super.dispose();
  }

  Future<String?> _getUserIdByEmail(String email) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  bool isAddingMember = false;

  Future<void> _addMember(String email) async {
    if (isAddingMember || email.isEmpty) return;

    setState(() {
      isAddingMember = true;
    });

    final userId = await _getUserIdByEmail(email);
    _memberEmailController.clear(); // Clear regardless of outcome

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user found with this email')),
      );
      setState(() {
        isAddingMember = false;
      });
      return;
    }

    if (userId == widget.project.teamLeadId ||
        widget.project.members.contains(userId)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User is already a member')));
      setState(() {
        isAddingMember = false;
      });
      return;
    }

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.project.projectId)
        .update({
          'members': FieldValue.arrayUnion([userId]),
        });

    setState(() {
      widget.project.members.add(userId);
      searchText = '';
      selectedUserId = null;
      isAddingMember = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: widget.tabController,
      children: [
        // Phases tab
        Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                    (_) => PhaseScreenLead(
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          CreatePhasePage(projectId: widget.project.projectId),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('New Phase'),
            backgroundColor: Colors.purple.shade100,
            foregroundColor: Colors.black,
          ),
        ),

        // Reviews tab
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collectionGroup('tasks')
                  .where('status', isEqualTo: 'Under Review')
                  .where('projectId', isEqualTo: widget.project.projectId)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No tasks under review.'));
            }

            final tasks =
                snapshot.data!.docs
                    .map((doc) => TaskModel.fromFirestore(doc))
                    .toList();

            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return ReviewCard(task: tasks[index]);
              },
            );
          },
        ),

        // Analytics tab
        const Center(child: Text('Analytics Section')),

        // Submissions tab
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collectionGroup('tasks')
                  .where('projectId', isEqualTo: widget.project.projectId)
                  .where(
                    'status',
                    isEqualTo: 'Completed',
                  ) // Firestore is case-sensitive
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No submissions found.'));
            }

            final tasks =
                snapshot.data!.docs
                    .map((doc) => TaskModel.fromFirestore(doc))
                    .where((task) => task.status.toLowerCase() == 'completed')
                    .toList();

            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return SubmissionCard(task: tasks[index]);
              },
            );
          },
        ),

        // Members tab
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Members',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _memberEmailController,
                      onChanged: (value) {
                        setState(() {
                          searchText = value.trim().toLowerCase();
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        isAddingMember
                            ? null
                            : () =>
                                _addMember(_memberEmailController.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child:
                        isAddingMember
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Add'),
                  ),
                ],
              ),
              if (searchText.isNotEmpty)
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .orderBy('email')
                          .startAt([searchText])
                          .endAt(['$searchText\uf8ff'])
                          .limit(5)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) return const Text('No matching users');
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final user = docs[index];
                        final email = user['email'];
                        if (widget.project.members.contains(user.id) ||
                            user.id == widget.project.teamLeadId) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          title: Text(email),
                          onTap: () {
                            setState(() {
                              _memberEmailController.text = email;
                              selectedUserId = user.id;
                              searchText = '';
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 16),
              const Text(
                'Current Members',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: Future.wait([
                    // Include team lead first
                    () async {
                      final doc =
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.project.teamLeadId)
                              .get();
                      return {
                        'id': doc.id,
                        'email': doc['email'] ?? 'Unknown',
                        'isTeamLead': true,
                      };
                    }(),
                    // Then the rest of the members
                    ...widget.project.members.map((uid) async {
                      final userDoc =
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .get();
                      return {
                        'id': uid,
                        'email': userDoc['email'] ?? 'Unknown',
                        'isTeamLead': false,
                      };
                    }),
                  ]),

                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final members = snapshot.data!;
                    return ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final bool isTeamLead = member['isTeamLead'] ?? false;
                        return ListTile(
                          title: Text(
                            isTeamLead
                                ? '${member['email']} (You)'
                                : member['email'],
                          ),
                          trailing:
                              isTeamLead
                                  ? null
                                  : TextButton(
                                    onPressed: () async {
                                      final confirm =
                                          await _confirmRemoveMember(
                                            member['email'],
                                          );
                                      if (confirm) {
                                        await FirebaseFirestore.instance
                                            .collection('projects')
                                            .doc(widget.project.projectId)
                                            .update({
                                              'members': FieldValue.arrayRemove(
                                                [member['id']],
                                              ),
                                            });
                                        setState(() {
                                          widget.project.members.remove(
                                            member['id'],
                                          );
                                        });
                                      }
                                    },

                                    child: const Text(
                                      'Remove',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                        );
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

  Future<bool> _confirmRemoveMember(String email) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Removal'),
                content: Text(
                  'Are you sure you want to remove $email from the project?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Remove'),
                  ),
                ],
              ),
        ) ??
        false; // If dialog is dismissed without choice, return false
  }
}
