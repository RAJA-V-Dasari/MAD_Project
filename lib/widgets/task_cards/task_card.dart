import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../screens/task_screens/task_edit_screen.dart';
import '../../screens/task_screens/task_review_screen.dart';
import '../../screens/task_screens/task_completed_screen.dart';
import '../../screens/task_screens/task_readonly_screen.dart';
import '../../screens/task_screens/task_reviewpending_screen.dart';
import '../../screens/task_screens/task_overview_screen.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF66BB6A); // Green
      case 'pending':
        return const Color(0xFFFFA726); // Orange
      case 'under review':
        return const Color(0xFF42A5F5); // Blue
      case 'overdue':
        return const Color(0xFFEF5350); // Red
      default:
        return Colors.grey;
    }
  }

  Color _getSubtleStatusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFFE8F5E9); // light green
      case 'pending':
        return const Color(0xFFFFF3E0); // light orange
      case 'under review':
        return const Color(0xFFE3F2FD); // light blue
      case 'overdue':
        return const Color(0xFFFFEBEE); // light red
      default:
        return const Color(0xFFF5F5F5); // neutral light grey
    }
  }

  Future<String> _getUserEmail(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc).email;
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUserEmail(task.assignedToUid),
      builder: (context, snapshot) {
        String assignedEmail = 'Loading...';
        if (snapshot.connectionState == ConnectionState.done) {
          assignedEmail = snapshot.data ?? 'Unknown';
        }

        return Card(
          color: _getSubtleStatusBackground(task.status),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              task.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "Deadline: ${DateFormat('yyyy-MM-dd').format(task.deadline.toDate())}",
                ),
                Text("Assigned Member: $assignedEmail"),
                Row(
                  children: [
                    const Text("Status: "),
                    Text(
                      task.status,
                      style: TextStyle(
                        color: _getStatusColor(task.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              if (currentUid == null) return;

              final projectDoc =
                  await FirebaseFirestore.instance
                      .collection('projects')
                      .doc(task.projectId)
                      .get();
              final projectData = projectDoc.data();
              if (projectData == null) return;

              final teamLeadId = projectData['teamLeadId'];
              final memberEmails = List<String>.from(
                projectData['members'] ?? [],
              );

              final isAssignedMember = currentUid == task.assignedToUid;
              final isTeamLead = currentUid == teamLeadId;
              final isOtherMember =
                  !isAssignedMember &&
                  !isTeamLead &&
                  memberEmails.contains(currentUid);

              final status = task.status.toLowerCase().trim();

              if (isAssignedMember) {
                if (status == 'pending' || status == 'overdue') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskEditPage(taskId: task.taskId),
                    ),
                  );
                } else if (status == 'completed') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskCompletedScreen(taskId: task.taskId),
                    ),
                  );
                } else if (status == 'under review') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => TaskReviewPendingScreen(taskId: task.taskId),
                    ),
                  );
                }
              } else if (isTeamLead) {
                if (status == 'under review') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskReviewScreen(taskId: task.taskId),
                    ),
                  );
                } else if (status == 'completed') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskCompletedScreen(taskId: task.taskId),
                    ),
                  );
                } else if (status == 'pending' || status == 'overdue') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskOverviewScreen(taskId: task.taskId),
                    ),
                  );
                }
              } else if (isOtherMember) {
                if (status == 'completed') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskCompletedScreen(taskId: task.taskId),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskReadonlyScreen(taskId: task.taskId),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("You don't have access to this task."),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
