import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../screens/task_screens/task_completed_screen.dart';
import '../../screens/task_screens/task_edit_screen.dart';
import '../../screens/task_screens/task_reviewpending_screen.dart';

class YourTaskCardWidget extends StatelessWidget {
  final String taskId;
  final String taskName;
  final DateTime deadline;
  final String status;
  final int attemptNo;
  final String expectedFileFormat;

  const YourTaskCardWidget({
    super.key,
    required this.taskId,
    required this.taskName,
    required this.deadline,
    required this.status,
    required this.attemptNo,
    required this.expectedFileFormat,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return const Color(0xFFFFA726);
      case "under review":
        return const Color(0xFF42A5F5);
      case "completed":
        return const Color(0xFF66BB6A);
      case "overdue":
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }

  Color _statusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return const Color(0xFFFFF3E0);
      case "under review":
        return const Color(0xFFE3F2FD);
      case "completed":
        return const Color(0xFFE8F5E9);
      case "overdue":
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  void _handleNavigation(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    if (normalizedStatus == 'completed') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskCompletedScreen(taskId: taskId)),
      );
    } else if (normalizedStatus == 'pending' || normalizedStatus == 'overdue') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskEditPage(taskId: taskId)),
      );
    } else if (normalizedStatus == 'under review') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskReviewPendingScreen(taskId: taskId),
        ),
      );
    } else {
      // Optionally show a snackbar for unimplemented status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Feature for this status is coming soon."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _statusBackgroundColor(status),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          taskName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Deadline: ${DateFormat('yyyy-MM-dd').format(deadline)}"),
            Text("Attempt: $attemptNo"),
            Text("Expected Format: $expectedFileFormat"),
            Row(
              children: [
                const Text("Status: "),
                Text(
                  status,
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (attemptNo > 1 && status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCDD2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "Asked to Redo",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _handleNavigation(context),
      ),
    );
  }
}
