import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/task_model.dart';

class CreateTaskScreen extends StatefulWidget {
  final String phaseId;
  final String projectId; // add this

  const CreateTaskScreen({
    Key? key,
    required this.phaseId,
    required this.projectId,
  }) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expectedFileFormatController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _assigneeEmailController = TextEditingController();
  String searchText = '';
  String? selectedAssigneeId;
  String? _leaderUid;

  String? _assignedToUid;
  bool _isCreating = false;

  String _phaseName = '';
  String _projectName = '';
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    await _loadProjectAndPhaseData();
    setState(() => _isLoading = false);
  }

  List<String> _memberUids = [];
  DateTime? _phaseDeadline;
  DateTime? _phaseStartDate;
  String? _phaseStatus;

  Future<void> _loadProjectAndPhaseData() async {
    try {
      final projectRef = FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId);
      final phaseRef = projectRef.collection('phases').doc(widget.phaseId);

      final results = await Future.wait([projectRef.get(), phaseRef.get()]);
      final projectDoc = results[0];
      final phaseDoc = results[1];

      if (projectDoc.exists) {
        final data = projectDoc.data()!;
        _projectName = data['name'];
        _leaderUid = data['teamLeadId'];
        _memberUids = List<String>.from(data['members'] ?? []);
      }

      if (phaseDoc.exists) {
        _phaseName = phaseDoc['name'];
        _phaseStatus =
            (phaseDoc['status'] as String)
                .toLowerCase(); // lowercase for comparison
        Timestamp deadlineTs = phaseDoc['deadline'];
        _phaseDeadline = deadlineTs.toDate();
        Timestamp startTs = phaseDoc['startDate'];
        _phaseStartDate = startTs.toDate();
      }
    } catch (e) {
      print('Error loading project/phase data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load project/phase info')),
      );
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate() || _isCreating) return;

    if (_assignedToUid == null ||
        !_memberUids.contains(_assignedToUid) ||
        _assignedToUid == _leaderUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please assign to a valid project member (not the leader)",
          ),
        ),
      );
      setState(() => _isCreating = false);
      return;
    }

    setState(() => _isCreating = true);
    try {
      // If no UID assigned yet, try to resolve from email
      if (_assignedToUid == null) {
        final email = _assigneeEmailController.text.trim().toLowerCase();

        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

        if (querySnapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user found with that email')),
          );
          setState(() => _isCreating = false);
          return;
        }

        final doc = querySnapshot.docs.first;

        if (doc.id == _leaderUid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cannot assign task to project leader"),
            ),
          );
          setState(() => _isCreating = false);
          return;
        }

        _assignedToUid = doc.id;
      }

      final selectedDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(_deadlineController.text);
      final deadline = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        23,
        59,
      );

      final projectId = widget.projectId;

      final taskRef =
          FirebaseFirestore.instance
              .collection('projects')
              .doc(projectId)
              .collection('phases')
              .doc(widget.phaseId)
              .collection('tasks')
              .doc();

      final task = TaskModel(
        taskId: taskRef.id,
        phaseId: widget.phaseId,
        projectId: widget.projectId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        status: 'Pending',
        assignedToUid: _assignedToUid!,
        deadline: Timestamp.fromDate(deadline),
        expectedFileFormat: _expectedFileFormatController.text.trim(),
        attemptNo: 1,
        submittedAt: Timestamp.fromMillisecondsSinceEpoch(0),
        reviewedAt: Timestamp.fromMillisecondsSinceEpoch(0),
        submittedFileUrl: null,
        submittedComments: null,
        reviewFeedback: null,
        reviewedByUid: null,
        rating: -1,
      );

      await taskRef.set(task.toMap());

      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('phases')
          .doc(widget.phaseId)
          .update({'noOfTasks': FieldValue.increment(1)});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isLoading
                ? const Text('Loading...')
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$_phaseName - $_projectName",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
      ),

      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const Text(
                        'Create Task',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Enter task name'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Task Description',
                        ),
                        maxLines: 3,
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Enter Task Description'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _assigneeEmailController,
                        onChanged: (value) {
                          setState(() {
                            searchText = value.trim().toLowerCase();
                            selectedAssigneeId = null;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Assign To (Email)',
                        ),
                        validator:
                            (val) =>
                                selectedAssigneeId == null
                                    ? 'Please select a valid user'
                                    : null,
                      ),
                      const SizedBox(height: 8),
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

                            // Filter out users not in members list or who are the leader
                            final filteredUsers =
                                docs.where((user) {
                                  final uid = user.id;
                                  return _memberUids.contains(uid) &&
                                      uid != _leaderUid;
                                }).toList();

                            if (filteredUsers.isEmpty) {
                              return const Text('No matching users found');
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final email = user['email'];
                                final uid = user.id;

                                return ListTile(
                                  title: Text(email),
                                  onTap: () {
                                    setState(() {
                                      _assigneeEmailController.text = email;
                                      selectedAssigneeId = uid;
                                      _assignedToUid = uid;
                                      searchText = '';
                                    });
                                  },
                                );
                              },
                            );
                          },
                        ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _expectedFileFormatController,
                        decoration: const InputDecoration(
                          labelText: 'Expected File Format',
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Enter file format'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _deadlineController,
                        decoration: const InputDecoration(
                          labelText: 'Deadline',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          DateTime now = DateTime.now();
                          DateTime startDate =
                              (_phaseStatus == 'yet to start' &&
                                      _phaseStartDate != null)
                                  ? _phaseStartDate!
                                  : now;

                          DateTime lastDate = _phaseDeadline ?? DateTime(2100);

                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                startDate.isAfter(now) ? startDate : now,
                            firstDate: startDate.isAfter(now) ? startDate : now,
                            lastDate: lastDate,
                          );

                          if (picked != null) {
                            _deadlineController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(picked);
                          }
                        },
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Select deadline'
                                    : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isCreating ? null : _createTask,
                        child:
                            _isCreating
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text('Create'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
