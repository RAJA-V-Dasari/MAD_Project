import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskCardWidget extends StatelessWidget {
  final String taskName;
  final String projectName;
  final DateTime deadline;
  final String status;
  final VoidCallback? onTap;

  const TaskCardWidget({
    super.key,
    required this.taskName,
    required this.projectName,
    required this.deadline,
    required this.status,
    this.onTap,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return const Color(0xFFFFA726); // Orange
      case "under review":
        return const Color(0xFF42A5F5); // Blue
      case "completed":
        return const Color(0xFF66BB6A); // Green
      case "overdue":
        return const Color(0xFFEF5350); // Red
      default:
        return Colors.grey;
    }
  }

  Color _statusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return const Color(0xFFFFF3E0); // Light Orange
      case "under review":
        return const Color(0xFFE3F2FD); // Light Blue
      case "completed":
        return const Color(0xFFE8F5E9); // Light Green
      case "overdue":
        return const Color(0xFFFFEBEE); // Light Red
      default:
        return const Color(0xFFF5F5F5); // Neutral Light Grey
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
            Text("Project: $projectName"),
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
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
