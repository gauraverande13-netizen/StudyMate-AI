import 'dart:async';
import 'package:flutter/material.dart';
import 'package:studymate_ai/View/LoginScreen.dart';
import 'package:studymate_ai/constant/Main_Navbar.dart';
import 'package:studymate_ai/repo/user_session.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;
      final loggedIn = await UserSession.isLoggedIn();
      final userId = await UserSession.getUserId();
      final userName = await UserSession.getUserName();
      final userEmail = await UserSession.getUserEmail();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => loggedIn && userId != null
              ? MainNavWrapper(
                  userId: userId,
                  userName: userName,
                  userEmail: userEmail,
                )
              : const Loginscreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4F46E5).withOpacity(0.12),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 44,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "StudyMate AI",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF131B2E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Smart Revision & AI Tutor",
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            Spacer(),

            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Preparing your study space...",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
