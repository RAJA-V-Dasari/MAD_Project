import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class CreateProjectPage extends StatefulWidget {
  final String userId;

  const CreateProjectPage({super.key, required this.userId});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _memberEmailController = TextEditingController();

  List<String> addedMemberIds = [];
  List<String> addedMemberEmails = [];

  String searchText = '';
  String? selectedUserId;

  Future<void> _createProject() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Description are required')),
      );
      return;
    }

    final String projectId = const Uuid().v4();

    await FirebaseFirestore.instance.collection('projects').doc(projectId).set({
      'projectId': projectId,
      'name': name,
      'description': description,
      'noOfPhases': 0,
      'teamLeadId': widget.userId,
      'members': addedMemberIds,
      'currentPhaseIndex': 0,
      'overallProgress': 0.0,
      'deadline': Timestamp.fromMillisecondsSinceEpoch(0),
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project created successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text(
                  'Create Project',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Project Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _memberEmailController,
                  onChanged: (value) {
                    setState(() {
                      searchText = value.trim().toLowerCase();
                      selectedUserId = null;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search member by email',
                  ),
                ),
                const SizedBox(height: 10),
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

                      if (docs.isEmpty) {
                        return const Text('No matching users');
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final user = docs[index];
                          final email = user['email'];

                          if (addedMemberEmails.contains(email) ||
                              user.id == widget.userId) {
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
                ElevatedButton(
                  onPressed: () async {
                    final email = _memberEmailController.text.trim();

                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an email')),
                      );
                      return;
                    }

                    if (addedMemberEmails.contains(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Member already added')),
                      );
                      return;
                    }

                    final userId = await _getUserIdByEmail(email);

                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No user found with this email'),
                        ),
                      );
                      return;
                    }

                    if (userId == widget.userId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot add yourself as a member'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      addedMemberEmails.add(email);
                      addedMemberIds.add(userId);
                      _memberEmailController.clear();
                      searchText = '';
                      selectedUserId = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Member'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Added Members',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...addedMemberEmails.map((email) {
                  int index = addedMemberEmails.indexOf(email);
                  return ListTile(
                    title: Text(email),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          addedMemberEmails.removeAt(index);
                          addedMemberIds.removeAt(index);
                        });
                      },
                    ),
                  );
                }),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _createProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Project'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
