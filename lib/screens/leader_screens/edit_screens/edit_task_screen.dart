import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../models/task_model.dart';
import '../../../models/user_model.dart';

class EditTaskScreen extends StatefulWidget {
  final String taskId;
  const EditTaskScreen({super.key, required this.taskId});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _formatController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();

  DateTime? _selectedDeadline;
  String? _selectedMemberUid;
  TaskModel? _existingTask;
  bool isLoading = true;
  List<String> _projectMemberUids = [];
  String? _teamLeadId;
  Timer? _debounce;
  String searchText = '';
  Timestamp? _phaseStart;
  Timestamp? _phaseDeadline;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      final taskQuery =
          await FirebaseFirestore.instance
              .collectionGroup('tasks')
              .where('taskId', isEqualTo: widget.taskId)
              .limit(1)
              .get();

      if (taskQuery.docs.isEmpty) throw Exception("Task not found");

      final doc = taskQuery.docs.first;
      final task = TaskModel.fromFirestore(doc);

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(task.assignedToUid)
              .get();
      final assignedUser = UserModel.fromFirestore(userDoc);
      final projectDoc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(task.projectId)
              .get();
      final phaseDoc =
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(task.projectId)
              .collection('phases')
              .doc(task.phaseId)
              .get();

      final phaseData = phaseDoc.data();

      setState(() {
        _existingTask = task;
        _projectMemberUids = List<String>.from(projectDoc['members']);
        _teamLeadId = projectDoc['teamLeadId'];
        _taskNameController.text = task.name;
        _descriptionController.text = task.description;
        _formatController.text = task.expectedFileFormat;
        _selectedDeadline = task.deadline.toDate();
        _selectedMemberUid = assignedUser.uid;
        _memberSearchController.text = assignedUser.email;
        _phaseStart = phaseData?['startDate'];
        _phaseDeadline = phaseData?['deadline'];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading task: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load task: $e')));
      }
    }
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDeadline == null ||
        _selectedMemberUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields.")),
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(_existingTask!.projectId)
          .collection('phases')
          .doc(_existingTask!.phaseId)
          .collection('tasks')
          .doc(_existingTask!.taskId);

      await docRef.update({
        'name': _taskNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'expectedFileFormat': _formatController.text.trim(),
        'deadline': Timestamp.fromDate(_selectedDeadline!),
        'assignedToUid': _selectedMemberUid,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Update failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update task: $e")));
      }
    }
  }

  void _pickDeadline() async {
    if (_phaseStart == null || _phaseDeadline == null) return;

    final now = DateTime.now();
    final minDate =
        now.isAfter(_phaseStart!.toDate()) ? now : _phaseStart!.toDate();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? minDate,
      firstDate: minDate,
      lastDate: _phaseDeadline!.toDate(),
    );

    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || _existingTask == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _taskNameController,
                decoration: const InputDecoration(labelText: 'Task Name'),
                validator: (value) => value!.isEmpty ? 'Enter task name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator:
                    (value) => value!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _formatController,
                decoration: const InputDecoration(
                  labelText: 'Expected File Format',
                ),
                validator:
                    (value) => value!.isEmpty ? 'Enter file format' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _memberSearchController,
                decoration: const InputDecoration(labelText: 'Assigned Member'),
                onChanged: (value) {
                  setState(() {
                    searchText = value.trim().toLowerCase();
                    _selectedMemberUid = null;
                  });
                },
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
                    final filtered =
                        docs.where((doc) {
                          final uid = doc.id;
                          return _projectMemberUids.contains(uid) &&
                              uid != _teamLeadId;
                        }).toList();

                    if (filtered.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No such members found',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        final email = user['email'];
                        final uid = user.id;

                        return ListTile(
                          title: Text(email),
                          onTap: () {
                            setState(() {
                              _memberSearchController.text = email;
                              _selectedMemberUid = uid;
                              searchText = '';
                            });
                          },
                        );
                      },
                    );
                  },
                ),

              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  _selectedDeadline != null
                      ? 'Deadline: ${DateFormat('yyyy-MM-dd').format(_selectedDeadline!)}'
                      : 'Pick Deadline',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDeadline,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateTask,
                child: const Text('Update Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
