import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_tide_1/controllers/phase_creation_controller.dart';

class CreatePhasePage extends StatefulWidget {
  final String projectId;

  const CreatePhasePage({super.key, required this.projectId});

  @override
  State<CreatePhasePage> createState() => _CreatePhasePageState();
}

class _CreatePhasePageState extends State<CreatePhasePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _deadline;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_deadline ?? _startDate),
      firstDate: isStartDate ? DateTime.now() : _startDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(_startDate);
          if (_deadline != null && _deadline!.isBefore(_startDate)) {
            _deadline = null;
            _deadlineController.clear();
          }
        } else {
          _deadline = DateTime(picked.year, picked.month, picked.day, 23, 59);
          _deadlineController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(_deadline!);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _startDateController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Phase")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Create Phase",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "Name",
                            ),
                            validator:
                                (value) => value!.isEmpty ? "Enter name" : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descController,
                            decoration: const InputDecoration(
                              labelText: "Description",
                            ),
                            maxLines: 3,
                            validator:
                                (value) =>
                                    value!.isEmpty ? "Enter description" : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _startDateController,
                            readOnly: true,
                            onTap: () => _selectDate(context, true),
                            decoration: const InputDecoration(
                              labelText: "Start Date",
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _deadlineController,
                            readOnly: true,
                            onTap: () => _selectDate(context, false),
                            decoration: const InputDecoration(
                              labelText: "Deadline",
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Select deadline"
                                        : null,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate() &&
                                  _deadline != null) {
                                if (_startDate.isAfter(_deadline!)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Start date cannot be after the deadline.",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                await PhaseController.createPhase(
                                  context: context,
                                  projectId: widget.projectId,
                                  name: _nameController.text.trim(),
                                  description: _descController.text.trim(),
                                  startDate: _startDate,
                                  deadline: _deadline!,
                                );
                              }
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.deepPurple, // Button background
                              foregroundColor: Colors.white, // Text color
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  100,
                                ), // Rounded corners
                              ),
                              elevation: 5, // Shadow
                            ),
                            child: const Text("Create"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
