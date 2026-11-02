import 'package:flutter/material.dart';
import 'package:studymate_ai/repo/planner_service.dart';
import 'package:studymate_ai/repo/user_session.dart';
import '../repo/dashboard_service.dart';
import 'DailyPlannerScreen.dart';

class HomeScreen extends StatefulWidget {
  final int? userId;
  final String? userName;
  final Function(int)? onNavigateToTab;

  const HomeScreen({
    super.key,
    this.userId,
    this.userName,
    this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _userId;
  String _userName = "Welcome";
  bool _isLoading = false;
  Map<String, dynamic>? _dashboardData;
  String? _errorMessage;

  int _totalTasks = 0;
  int _completedTasks = 0;
  int _remainingTasks = 0;
  int _percentDone = 0;
  bool _isLoadingGoals = true;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      _userName = widget.userName!;
    }
    _initUserData();
  }

  Future<void> _initUserData() async {
    if (_userId == null) {
      _userId = await UserSession.getUserId();
    }
    if (widget.userName == null || widget.userName!.isEmpty) {
      final savedName = await UserSession.getUserName();
      if (savedName != null && savedName.isNotEmpty) {
        _userName = savedName;
      }
    }
    if (mounted) setState(() {});

    _loadDailyGoals();
    _fetchDashboard();
  }

  String _getInitialLetter() {
    final name = _userName.trim();
    if (name.isEmpty) return 'W';
    return name[0].toUpperCase();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    try {
      final effectiveId = _userId ?? await UserSession.getUserId();
      final result = await DashboardService.getDashboardSummary(
        userId: effectiveId,
      ).timeout(const Duration(seconds: 4));

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _dashboardData = result['data'];
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      debugPrint("Dashboard Fetch Exception: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDailyGoals() async {
    setState(() => _isLoadingGoals = true);
    final effectiveId = _userId ?? (await UserSession.getUserId()) ?? 1;
    final summary = await PlannerService.fetchTodaySummary(userId: effectiveId);

    if (!mounted) return;
    setState(() {
      _totalTasks = summary['total_tasks'] ?? 0;
      _completedTasks = summary['completed_tasks'] ?? 0;
      _remainingTasks = summary['remaining_tasks'] ?? 0;
      _percentDone = summary['percent_done'] ?? 0;
      _isLoadingGoals = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchDashboard,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final recentWorks = (_dashboardData?['recent_works'] as List?) ?? [];
    final goalsCompleted = _dashboardData?['goals_completed'] ?? 0;
    final totalGoals = _dashboardData?['total_goals'] ?? 5;
    final completionPct = _dashboardData?['completion_percentage'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([_fetchDashboard(), _loadDailyGoals()]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hi, $_userName',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text('👋', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Let's review today's schedule",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(width: 10),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4F46E5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _getInitialLetter(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildDailyGoalsCard(),
                const SizedBox(height: 22),

                // 3. Action Cards Grid
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onNavigateToTab?.call(1),
                        child: _buildHighlightedCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Ask AI Tutor',
                          subtitle: 'Chat & solve doubts',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onNavigateToTab?.call(2),
                        child: _buildWhiteCard(
                          icon: Icons.description_outlined,
                          title: 'Upload & Summary',
                          subtitle: 'PDF, DOCX insights',
                          onTap: () {
                            widget.onNavigateToTab?.call(
                              2,
                            ); // बॉटम बारच्या Summary टॅबवर नेईल
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onNavigateToTab?.call(3),
                        child: _buildWhiteCard(
                          icon: Icons.style_outlined,
                          title: 'Flashcards',
                          subtitle: 'Active recall deck',
                          onTap: () {
                            widget.onNavigateToTab?.call(
                              3,
                            ); // बॉटम बारच्या Cards टॅबवर नेईल
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildWhiteCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'Daily Planner',
                        subtitle: 'Organize study schedule',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DailyPlannerScreen(
                                userId: _userId ?? 1,
                                onBack: () => Navigator.pop(context),
                              ),
                            ),
                          );
                          _loadDailyGoals();
                          _fetchDashboard();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // 4. Dynamic Recent Work Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RECENT WORK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dynamic list build
                if (recentWorks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'No recent work found',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  ...recentWorks.map((item) {
                    final bool isGreen = item['badge_type'] == 'green';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildRecentItem(
                        badgeText: item['badge_text'] ?? '',
                        badgeBg: isGreen
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFEEF2FF),
                        badgeColor: isGreen
                            ? const Color(0xFF059669)
                            : const Color(0xFF4F46E5),
                        title: item['title'] ?? '',
                        subtitle: item['subtitle'] ?? '',
                        statusTag: item['status_tag'] ?? '',
                        tagBg: isGreen
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFEEF2FF),
                        tagColor: isGreen
                            ? const Color(0xFF059669)
                            : const Color(0xFF4F46E5),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      height: 155,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap, // 👈 onTap पॅरामीटर जोडा
  }) {
    return InkWell(
      onTap: onTap, // 👈 क्लिक इव्हेंट इथे लागू होईल
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 155,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(icon, color: const Color(0xFF475569), size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem({
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required String statusTag,
    required Color tagBg,
    required Color tagColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusTag,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: tagColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalsCard() {
    return InkWell(
      onTap: () async {
        // Planner screen par jao aur wapas aane par goals reload karo
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyPlannerScreen(
              userId: _userId ?? 1,
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
        _loadDailyGoals();
        _fetchDashboard();
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF), // Light bluish-purple background
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE0EAFF)),
        ),
        child: Row(
          children: [
            // Circular Progress Indicator with Fraction
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD5E3FF), width: 2),
              ),
              alignment: Alignment.center,
              child: _isLoadingGoals
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '$_completedTasks/$_totalTasks',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
            ),
            const SizedBox(width: 16),

            // Goals Text & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Daily Goals',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _totalTasks == 0
                        ? 'No study tasks for today'
                        : '$_remainingTasks study blocks remaining for today',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Percent Done Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                '$_percentDone% Done',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
