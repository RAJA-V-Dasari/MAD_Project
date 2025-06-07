import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_tide_1/controllers/project_update_controller.dart';
import 'package:task_tide_1/models/phase_model.dart';

class EditPhasePage extends StatefulWidget {
  final String projectId;
  final String phaseId;

  const EditPhasePage({
    super.key,
    required this.projectId,
    required this.phaseId,
  });

  @override
  State<EditPhasePage> createState() => _EditPhasePageState();
}

class _EditPhasePageState extends State<EditPhasePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _startDate;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _loadPhaseDetails();
  }

  Future<void> _loadPhaseDetails() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .collection('phases')
            .doc(widget.phaseId)
            .get();

    if (doc.exists) {
      final phase = PhaseModel.fromFirestore(doc);
      _nameController.text = phase.name;
      _descController.text = phase.description;
      _startDate = phase.startDate.toDate();
      _deadline = phase.deadline.toDate();
      setState(() {});
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _deadline == null)
      return;

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('phases')
        .doc(widget.phaseId)
        .update({
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'startDate': Timestamp.fromDate(_startDate!),
          'deadline': Timestamp.fromDate(_deadline!),
        });

    await ProjectUpdateController.updateProjectFields(widget.projectId);

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Phase updated successfully")));
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required Function(DateTime) onConfirm,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) onConfirm(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Phase")),
      body:
          _startDate == null || _deadline == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Phase Name",
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? "Enter name"
                                    : null,
                      ),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: "Description",
                        ),
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? "Enter description"
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text("Start Date"),
                        subtitle: Text(
                          _startDate!.toLocal().toString().split(' ')[0],
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap:
                            () => _pickDate(
                              initial: _startDate,
                              onConfirm:
                                  (date) => setState(() => _startDate = date),
                            ),
                      ),
                      ListTile(
                        title: const Text("Deadline"),
                        subtitle: Text(
                          _deadline!.toLocal().toString().split(' ')[0],
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap:
                            () => _pickDate(
                              initial: _deadline,
                              onConfirm:
                                  (date) => setState(() => _deadline = date),
                            ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveChanges,
                        child: const Text("Save Changes"),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
