import 'package:flutter/material.dart';
import 'screens/authentication_screens/login_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase

  await Supabase.initialize(
    url: 'https://huokkrrpumugbtfuvlqy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1b2trcnJwdW11Z2J0ZnV2bHF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4ODI3OTIsImV4cCI6MjA2NDQ1ODc5Mn0.Khs8KhkEMTLL5l8uu0_iktIhwdw4YOgPrEGvHcNBL-E',
  );
  runApp(const TaskTideApp());
}

class TaskTideApp extends StatelessWidget {
  const TaskTideApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskTide',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}
