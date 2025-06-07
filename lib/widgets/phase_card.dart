import 'package:flutter/material.dart';
import '../models/phase_model.dart';

class PhaseCardWidget extends StatelessWidget {
  final PhaseModel phase;
  final VoidCallback? onTap;

  const PhaseCardWidget({super.key, required this.phase, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (phase.status) {
      case 'Completed':
        statusColor = Colors.green;
        break;
      case 'In Progress':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    String deadlineText = phase.deadline.toDate().toString().split(' ')[0];

    return Card(
      color: Colors.purple[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          phase.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (phase.status.toLowerCase() == 'yet to start') ...[
              Text(
                'Start Date: ${phase.startDate.toDate().toString().split(' ')[0]}',
              ),
            ],
            Text('Deadline: $deadlineText'),
            Text('Number of Tasks: ${phase.noOfTasks}'),
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(phase.status, style: TextStyle(color: statusColor)),
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
