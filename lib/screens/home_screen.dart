import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_buttons.dart';
import '../widgets/project_card.dart';
import '../widgets/section_title.dart';
import 'authentication_screens/login_screen.dart';
import 'leader_screens/create_screens/create_project_screen.dart';
import 'leader_screens/project_screen_leader.dart';
import 'member_screens/project_screen_member.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  List<Map<String, dynamic>> processProjects(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': data['projectId'],
        'title': data['name'],
        'deadline':
            data['deadline'] != Timestamp.fromMillisecondsSinceEpoch(0)
                ? (data['deadline'] as Timestamp).toDate().toString()
                : 'No-Deadline',
        'progress': (data['overallProgress'] as num).toInt(),
        'leaderId': data['teamLeadId'],
        'memberIds': List<String>.from(data['members'] ?? []),
        'createdAt': data['createdAt'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text("TaskTide"),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  MediaQuery.of(context).size.width - 60,
                  100,
                  0,
                  0,
                ),
                items: [
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: const [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
                elevation: 8.0,
              ).then((value) {
                if (value == 'logout') {
                  _logout();
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('projects')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text("Something went wrong"));
            }

            final projects = processProjects(snapshot.data!);

            final leadingProjects =
                projects.where((p) => p['leaderId'] == widget.userId).toList();
            final joinedProjects =
                projects
                    .where((p) => p['memberIds'].contains(widget.userId))
                    .toList();

            bool searchFilter(Map<String, dynamic> p) =>
                p['title'].toLowerCase().contains(_searchQuery);

            final filteredLeading =
                (selectedFilterIndex == 0
                        ? leadingProjects.take(2)
                        : leadingProjects)
                    .where(searchFilter)
                    .toList();

            final filteredJoined =
                (selectedFilterIndex == 0
                        ? joinedProjects.take(2)
                        : joinedProjects)
                    .where(searchFilter)
                    .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchBarWidget(
                  hintText: "Search for projects",
                  controller: _searchController,
                  onSearch: () {
                    setState(() {
                      _searchQuery = _searchController.text.toLowerCase();
                    });
                  },
                  onClear: () {
                    setState(() {
                      _searchQuery = "";
                    });
                  },
                ),

                const SizedBox(height: 16),
                FilterButtonsWidget(
                  labels: const ["All", "Leading", "Joined"],
                  selectedIndex: selectedFilterIndex,
                  onSelected: (index) {
                    setState(() {
                      selectedFilterIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (selectedFilterIndex == 0 ||
                            selectedFilterIndex == 1)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SectionTitleWidget(
                                    title: "Leading Projects",
                                    onTap: () {
                                      setState(() {
                                        selectedFilterIndex = 1;
                                      });
                                    },
                                  ),
                                  if (selectedFilterIndex ==
                                      0) // Only show in "All"
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedFilterIndex = 1;
                                        });
                                      },
                                      child: const Text(
                                        "Show all",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 8),
                              filteredLeading.isEmpty
                                  ? const Center(
                                    child: Text("No Projects Found"),
                                  )
                                  : Column(
                                    children:
                                        filteredLeading.map((project) {
                                          return ProjectCardWidget(
                                            title: project['title'],
                                            deadline:
                                                project['deadline'].split(
                                                  ' ',
                                                )[0],
                                            progress: project['progress'],
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => ProjectScreen(
                                                        projectId:
                                                            project['id'],
                                                      ),
                                                ),
                                              );
                                            },
                                          );
                                        }).toList(),
                                  ),
                            ],
                          ),
                        if (selectedFilterIndex == 0 ||
                            selectedFilterIndex == 2)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SectionTitleWidget(
                                    title: "Joined Projects",
                                    onTap: () {
                                      setState(() {
                                        selectedFilterIndex = 2;
                                      });
                                    },
                                  ),
                                  if (selectedFilterIndex ==
                                      0) // ✅ Show only in "All"
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedFilterIndex = 2;
                                        });
                                      },
                                      child: const Text(
                                        "Show all",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              filteredJoined.isEmpty
                                  ? const Center(
                                    child: Text("No Projects Found"),
                                  )
                                  : Column(
                                    children:
                                        filteredJoined.map((project) {
                                          return ProjectCardWidget(
                                            title: project['title'],
                                            deadline:
                                                project['deadline'].split(
                                                  ' ',
                                                )[0],
                                            progress: project['progress'],
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          ProjectScreenMember(
                                                            projectId:
                                                                project['id'],
                                                            currentUserId:
                                                                widget.userId,
                                                          ),
                                                ),
                                              );
                                            },
                                          );
                                        }).toList(),
                                  ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateProjectPage(userId: widget.userId),
            ),
          );
        },
        label: const Text("Create Project"),
        icon: const Icon(Icons.edit),
        backgroundColor: Colors.purple[100],
        foregroundColor: Colors.purple[900],
      ),
    );
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } catch (e) {
        print("Error logging out: $e");
      }
    }
  }
}
