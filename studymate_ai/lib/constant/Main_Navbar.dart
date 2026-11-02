import 'package:flutter/material.dart';
import 'package:studymate_ai/View/ChatAITutor_Screen.dart';
import 'package:studymate_ai/View/FlashCardScreen.dart';
import 'package:studymate_ai/View/HomeScreen.dart';
import 'package:studymate_ai/View/ProfileScreen.dart';
import 'package:studymate_ai/View/SummaryScreen.dart';
import 'package:studymate_ai/constant/App_colors.dart';
import 'package:studymate_ai/repo/user_session.dart';

class MainNavWrapper extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? userEmail;

  const MainNavWrapper({
    super.key,
    this.userId,
    this.userName,
    this.userEmail,
  });

  @override
  State<MainNavWrapper> createState() => _MainNavWrapperState();
}

class _MainNavWrapperState extends State<MainNavWrapper> {
  int _currentIndex = 0;
  int? _userId;
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _userName = widget.userName;
    _userEmail = widget.userEmail;
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final id = await UserSession.getUserId();
    final name = await UserSession.getUserName();
    final email = await UserSession.getUserEmail();
    if (mounted) {
      setState(() {
        _userId ??= id;
        _userName ??= name;
        _userEmail ??= email;
      });
    }
  }

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        userId: _userId,
        userName: _userName,
        onNavigateToTab: changeTab,
      ),
      ChataitutorScreen(
        userId: _userId,
        userName: _userName,
      ),
      SummaryScreen(
        userId: _userId,
      ),
      FlashCardScreen(
        userId: _userId,
      ),
      ProfileScreen(
        userId: _userId,
        userName: _userName,
        userEmail: _userEmail,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: IndexedStack(index: _currentIndex, children: screens),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, 'Home', 0),
            _buildNavItem(Icons.chat_bubble_outline_rounded, 'Chat', 1),
            _buildNavItem(Icons.description_outlined, 'Summary', 2),
            _buildNavItem(Icons.layers_outlined, 'Cards', 3),
            _buildNavItem(Icons.person_outline_rounded, 'Profile', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => changeTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected
                ? AppColors.primaryColor
                : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primaryColor
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
