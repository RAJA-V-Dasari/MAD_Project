import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication_screens/login_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String firstName = '';
  String lastName = '';
  String email = '';
  String dob = '';
  double completionRate = 0.0;
  double onTimeRate = 0.0;
  int totalTasks = 0;
  int completedTasks = 0;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
    fetchTaskStats();
  }

  Future<void> fetchProfileData() async {
    final doc = await _firestore.collection('users').doc(widget.userId).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        firstName = data['firstName'] ?? '';
        lastName = data['lastName'] ?? '';
        email = data['email'] ?? '';
        dob = data['dob'] ?? '';
      });
    }
  }

  Future<void> fetchTaskStats() async {
    final tasksQuery =
        await _firestore
            .collectionGroup('tasks')
            .where('assignedToUid', isEqualTo: widget.userId)
            .get();
    int total = tasksQuery.docs.length;
    int completed = 0;
    int onTime = 0;

    for (var doc in tasksQuery.docs) {
      final data = doc.data();
      final status = data['status'].toString().toLowerCase();
      final submittedAt = data['submittedAt'];
      final deadline = data['deadline'];

      if (status == 'completed') {
        completed++;
        if (submittedAt != null && deadline != null) {
          if ((submittedAt as Timestamp).toDate().isBefore(
            (deadline as Timestamp).toDate(),
          )) {
            onTime++;
          }
        }
      }
    }

    setState(() {
      totalTasks = total;
      completedTasks = completed;
      completionRate = total > 0 ? (completed / total) : 0.0;
      onTimeRate = completed > 0 ? (onTime / completed) : 0.0;
    });
  }

  Widget buildCircularStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                backgroundColor: Colors.grey.shade300,
                color: color,
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget buildLinearStat() {
    return Column(
      children: [
        const Text(
          'Completed Tasks',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: totalTasks > 0 ? (completedTasks / totalTasks) : 0.0,
          backgroundColor: Colors.grey[300],
          color: Colors.green,
          minHeight: 12,
        ),
        const SizedBox(height: 8),
        Text(
          '$completedTasks / $totalTasks',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$firstName $lastName',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(email, style: const TextStyle(fontSize: 16)),
            Text('DOB: $dob', style: const TextStyle(fontSize: 16)),
            const Divider(thickness: 1),
            const SizedBox(height: 30),

            // STATS SECTION
            buildCircularStat(
              'Task Completion Rate',
              completionRate,
              Colors.blue,
            ),
            buildCircularStat('On-Time Submissions', onTimeRate, Colors.orange),
            buildLinearStat(),

            const SizedBox(height: 20),
            const Divider(thickness: 1),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Account Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            // ACTIONS
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(userId: widget.userId),
                  ),
                ).then((_) => fetchProfileData()); // Refresh profile on return
              },
            ),

            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
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
