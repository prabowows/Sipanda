import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sipanda_app/firebase_options.dart';
import 'package:sipanda_app/core/theme.dart';
import 'package:sipanda_app/features/citizen/dashboard_screen.dart';
import 'package:sipanda_app/features/admin/admin_dashboard_screen.dart';
import 'package:sipanda_app/features/citizen/alert_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initializeApp info: $e");
  }
  runApp(const SipandaApp());
}

class SipandaApp extends StatelessWidget {
  const SipandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIPANDA',
      debugShowCheckedModeBanner: false,
      theme: SipandaTheme.darkTheme,
      home: const CitizenDashboardScreen(),
      routes: {
        '/admin': (context) => const AdminDashboardScreen(),
        '/history': (context) => const AlertHistoryScreen(),
      },
    );
  }
}
