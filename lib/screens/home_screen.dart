
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/screens/daily_questions_screen.dart';
import 'package:journal_app/widgets/streak_card.dart';
import 'package:journal_app/widgets/doodle_card.dart';
import 'package:journal_app/utils/page_transitions.dart';
import 'package:journal_app/services/storage_service.dart';
import '../services/notification_service.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:journal_app/widgets/floating_dock.dart';
import 'package:journal_app/screens/history_screen.dart';
import 'package:journal_app/screens/profile_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:journal_app/models/daily_entry.dart';
import 'dart:math';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _userName = "Rythamo User";
  int _streak = 0;
  int _answeredCount = 0;
  DailyEntry? _todayEntry;
  final StorageService _storageService = StorageService();

  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isDockVisible = true;
  
  // Mascot animations based on answer count
  String _getMascotForAnswerCount(int count) {
    final random = Random();
    if (count == 0) {
      // Only greeting for no answers - welcoming, not sad
      return 'assets/mascot/greeting.json';
    } else if (count == 1) {
      return 'assets/mascot/idle.json';
    } else if (count == 2) {
      return 'assets/mascot/jumping.json';
    } else {
      // 3-4 answers: excited, jumping, or celebrating
      final options = ['assets/mascot/excited.json', 'assets/mascot/jumping.json', 'assets/mascot/celebrating.json'];
      return options[random.nextInt(options.length)];
    }
  }
  
  late String _currentMascot;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _currentMascot = 'assets/mascot/greeting.json'; // Default until data loads
    
    // Track app usage for smart notifications
    RythamoNotificationService().trackAppUsage();
    
    _loadUserName();
    _loadStreak();
    _loadTodayEntry();
    
    // Cycle mascot every 8 seconds
    Future.delayed(const Duration(seconds: 8), _cycleMascot);
    
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == 
          ScrollDirection.reverse) {
        if (_isDockVisible) setState(() => _isDockVisible = false);
      } else {
        if (!_isDockVisible) setState(() => _isDockVisible = true);
      }
    });
  }
  
  void _cycleMascot() {
    if (mounted) {
      setState(() {
        _currentMascot = _getMascotForAnswerCount(_answeredCount);
      });
      Future.delayed(const Duration(seconds: 8), _cycleMascot);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? "Rythamo User";
      });
    }
  }

  Future<void> _loadStreak() async {
    final streak = await _storageService.calculateStreak();
    if (mounted) {
      setState(() {
        _streak = streak;
      });
      // Update notifications with current streak for dynamic messages
      RythamoNotificationService().updateStreak(streak);
    }
  }

  Future<void> _loadTodayEntry() async {
    final entry = await _storageService.getDailyEntryForDate(DateTime.now());
    if (mounted) {
      setState(() {
        _todayEntry = entry;
        _answeredCount = entry?.answeredCount ?? 0;
        // Update mascot based on answer count
        _currentMascot = _getMascotForAnswerCount(_answeredCount);
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeNotifierProvider);
    
    // Determine text color based on theme
    final textColor = themeMode != RythamoThemeMode.latte 
        ? Colors.white 
        : RythamoColors.darkCharcoalText;

    final List<Widget> _screens = [
      _buildHomeContent(textColor),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse) {
                if (_isDockVisible) setState(() => _isDockVisible = false);
              } else if (notification.direction == ScrollDirection.forward) {
                if (!_isDockVisible) setState(() => _isDockVisible = true);
              }
              return true;
            },
            child: _screens[_currentIndex],
          ),
          
          // Floating Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: SafeArea(
                top: false,
                child: FloatingDock(
                  currentIndex: _currentIndex,
                  onTap: _onTabTapped,
                  isVisible: _isDockVisible,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(Color textColor) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeNotifierProvider);
    final bool hasCompletedToday = _answeredCount == 4;
    
    // Theme-aware card colors based on Catppuccin palette
    final cardColor = themeMode == RythamoThemeMode.latte
        ? const Color(0xFFE6E9EF) // Latte surface0
        : themeMode == RythamoThemeMode.frappe
            ? const Color(0xFF414559) // Frappe surface0
            : themeMode == RythamoThemeMode.macchiato
                ? const Color(0xFF363A4F) // Macchiato surface0
                : const Color(0xFF313244); // Mocha surface0
    
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HERO SECTION =====
            
            // Greeting - Full Width at Top
            Center(
              child: Column(
                children: [
                  Text(
                    "HELLO",
                    style: RythamoTypography.grSubhead(textColor).copyWith(
                      color: RythamoColors.salmonOrange,
                      letterSpacing: 6.0,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userName.toUpperCase(),
                    style: RythamoTypography.grDisplay(textColor).copyWith(
                      fontSize: RythamoTypography.displaySize * 0.7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Full-Screen Mascot Animation (randomly cycling)
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: SizedBox(
                  key: ValueKey(_currentMascot),
                  height: MediaQuery.of(context).size.height * 0.32,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Lottie.asset(
                    _currentMascot,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // ===== DAILY REFLECTION CARD - BIGGER =====
            _buildDailyQuestionsHero(textColor, cardColor, hasCompletedToday),
            
            const SizedBox(height: 16),

            // ===== STREAK & MOOD ROW =====
            Row(
              children: [
                Expanded(child: StreakCard(streakDays: _streak)),
                const SizedBox(width: 16),
                Expanded(child: DoodleCard(cardColor: cardColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyQuestionsHero(Color textColor, Color cardColor, bool hasCompletedToday) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode != RythamoThemeMode.latte;
    
    // Color theory: Desaturated complementary colors for dark mode
    // Salmon orange's complement is mint/teal green
    final completedColor = isDark 
        ? const Color(0xFF3B7A6B) // Desaturated mint teal for dark (complement of salmon)
        : const Color(0xFF52B788); // Soft sage green for light
    
    final incompleteColor = isDark
        ? const Color(0xFF9A6B4C) // Warm bronze/amber for dark (desaturated)
        : const Color(0xFFE8927C); // Soft coral for light
    
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          PageTransitions.slideUp(
            DailyQuestionsScreen(existingEntry: _todayEntry),
          ),
        );
        if (result == true) {
          _loadTodayEntry();
          _loadStreak();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: hasCompletedToday ? completedColor : incompleteColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: (hasCompletedToday ? completedColor : incompleteColor).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      hasCompletedToday ? Icons.check_circle : Icons.edit_note,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      hasCompletedToday ? "COMPLETED" : "DAILY REFLECTION",
                      style: RythamoTypography.grCaption(Colors.white).copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$_answeredCount / 4",
                    style: RythamoTypography.grBody(Colors.white).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // All 4 questions preview
            ...StorageService.dailyQuestions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final isAnswered = _todayEntry != null && 
                  index < _todayEntry!.responses.length && 
                  _todayEntry!.responses[index].hasAnswer;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isAnswered 
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: isAnswered
                            ? const Icon(Icons.check, size: 16, color: Color(0xFF40C057))
                            : Text(
                                "${index + 1}",
                                style: RythamoTypography.grBody(Colors.white).copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        question,
                        style: RythamoTypography.grBody(Colors.white).copyWith(
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: isAnswered ? FontWeight.w600 : FontWeight.w400,
                          color: Colors.white.withOpacity(isAnswered ? 1.0 : 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 24),
            
            // CTA Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasCompletedToday ? Icons.edit : Icons.play_arrow_rounded,
                      color: hasCompletedToday ? completedColor : RythamoColors.salmonOrange,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasCompletedToday ? "Edit Reflection" : "Start Reflection",
                      style: RythamoTypography.grBody(
                        hasCompletedToday ? completedColor : RythamoColors.salmonOrange,
                      ).copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


