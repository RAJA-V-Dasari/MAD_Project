import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/task_cards/task_card.dart';
import '../../models/task_model.dart';

class PhaseScreenMember extends StatefulWidget {
  final String projectId;
  final String phaseId;

  const PhaseScreenMember({
    super.key,
    required this.projectId,
    required this.phaseId,
  });

  @override
  State<PhaseScreenMember> createState() => _PhaseScreenMemberState();
}

class _PhaseScreenMemberState extends State<PhaseScreenMember> {
  String projectName = '';
  String phaseName = '';

  @override
  void initState() {
    super.initState();
    fetchPhaseAndProjectInfo();
  }

  Future<void> fetchPhaseAndProjectInfo() async {
    try {
      // Fetch project name
      final projectDoc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(widget.projectId)
              .get();

      if (projectDoc.exists) {
        projectName = projectDoc['name'];
      }

      // Fetch phase name
      final phaseDoc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(widget.projectId)
              .collection('phases')
              .doc(widget.phaseId)
              .get();

      if (phaseDoc.exists) {
        phaseName = phaseDoc['name'];
      }

      setState(() {}); // Trigger UI update
    } catch (e) {
      debugPrint('Error fetching phase/project info: $e');
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
    );
  }
}
