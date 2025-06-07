import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'task_screen.dart';
import 'profile_screens/profile_screen.dart';
import '../widgets/custom_bottom_nav.dart';
import 'authentication_screens/login_screen.dart'; // Navigate to login screen when signed out

class MainScreen extends StatefulWidget {
  final String userId; // Passed from login

  const MainScreen({super.key, required this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();

    _authStream.listen((user) {
      if (user == null) {
        // User signed out -> Navigate to Login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  Future<bool> _onWillPop() async {
    final NavigatorState currentNavigator =
        _navigatorKeys[_currentIndex].currentState!;
    if (currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildTabNavigator(0, HomeScreen(userId: widget.userId)),
            _buildTabNavigator(1, TaskScreen(userId: widget.userId)),
            _buildTabNavigator(2, ProfileScreen(userId: widget.userId)),
          ],
        ),
        bottomNavigationBar:
            FirebaseAuth.instance.currentUser != null
                ? CustomBottomNavBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() => _currentIndex = index);
                  },
                )
                : null,
      ),
    );
  }

  Widget _buildTabNavigator(int index, Widget screen) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(builder: (_) => screen);
      },
    );
  }
}
