import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:studymate_ai/View/LoginScreen.dart';
import 'package:studymate_ai/repo/user_session.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? userEmail;
  final VoidCallback? onLogout;

  const ProfileScreen({
    super.key,
    this.userId,
    this.userName,
    this.userEmail,
    this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  int? _userId;
  String _name = 'Student';
  String _email = 'student@studymate.ai';
  int _docsCount = 0;
  int _cardsCount = 0;
  int _tasksCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      _name = widget.userName!;
    }
    if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
      _email = widget.userEmail!;
    }
    _initUserDataAndStats();
  }

  Future<void> _initUserDataAndStats() async {
    if (_userId == null) {
      _userId = await UserSession.getUserId();
    }
    if (widget.userName == null || widget.userName!.isEmpty) {
      final savedName = await UserSession.getUserName();
      if (savedName != null && savedName.isNotEmpty) {
        _name = savedName;
      }
    }
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      final savedEmail = await UserSession.getUserEmail();
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _email = savedEmail;
      }
    }
    if (mounted) setState(() {});
    _loadProfileStats();
  }

  // Dynamic counts backend se fetch karna for active user
  Future<void> _loadProfileStats() async {
    setState(() => _isLoading = true);

    try {
      final effectiveId = _userId ?? await UserSession.getUserId();
      final query = effectiveId != null ? '?user_id=$effectiveId' : '';

      // 1. Docs count
      final docsRes = await http.get(Uri.parse('$baseUrl/docs/$query'));
      int docs = 0;
      if (docsRes.statusCode == 200) {
        final List list = jsonDecode(docsRes.body);
        docs = list.length;
      }

      // 2. Flashcards count
      final cardsRes = await http.get(Uri.parse('$baseUrl/flashcards/$query'));
      int cards = 0;
      if (cardsRes.statusCode == 200) {
        final List list = jsonDecode(cardsRes.body);
        cards = list.length;
      }

      // 3. Planner summary (today tasks)
      final plannerRes = await http.get(
        Uri.parse('$baseUrl/planner/summary/today$query'),
      );
      int tasks = 0;
      if (plannerRes.statusCode == 200) {
        final data = jsonDecode(plannerRes.body);
        tasks = data['total_tasks'] ?? 0;
      }

      if (!mounted) return;
      setState(() {
        _docsCount = docs;
        _cardsCount = cards;
        _tasksCount = tasks;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching stats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to log out from StudyMate AI?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await UserSession.clearSession();
              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Loginscreen()),
                (route) => false,
              );
              if (widget.onLogout != null) {
                widget.onLogout!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialLetter = _name.isNotEmpty ? _name[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // User Info Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar with Initial
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initialLetter,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _email,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Active Student',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Study Stats Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Documents', '$_docsCount', Icons.description_outlined),
                          Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                          _buildStatItem('Flashcards', '$_cardsCount', Icons.layers_outlined),
                          Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                          _buildStatItem('Daily Tasks', '$_tasksCount', Icons.calendar_today_outlined),
                        ],
                      ),
              ),
              const SizedBox(height: 22),

              // Logout Container
              InkWell(
                onTap: _handleLogout,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
