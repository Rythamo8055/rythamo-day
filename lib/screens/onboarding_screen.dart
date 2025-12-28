import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/screens/home_screen.dart';
import 'package:journal_app/utils/page_transitions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:journal_app/services/avatar_service.dart';
import 'package:journal_app/widgets/avatar_picker.dart';
import 'package:journal_app/widgets/avatar_display.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _whyController = TextEditingController();
  int _currentPage = 0;
  AvatarConfig? _selectedAvatarConfig;
  
  // 7 pages: Welcome, Daily Reflections, Name, Theme, Avatar, My Why, Ready
  static const int _totalPages = 7;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    final why = prefs.getString('my_why');
    final avatarConfig = await AvatarService.loadAvatar();
    
    if (mounted) {
      setState(() {
        if (name != null) _nameController.text = name;
        if (why != null) _whyController.text = why;
        _selectedAvatarConfig = avatarConfig;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _whyController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('my_why', _whyController.text.trim());
    
    final currentTheme = ref.read(themeNotifierProvider);
    await prefs.setInt('theme_mode', currentTheme.index);
    
    if (_selectedAvatarConfig != null) {
      await AvatarService.saveAvatar(_selectedAvatarConfig!);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageTransitions.fade(const HomeScreen()),
      );
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 2: // Name page - must have name
        return _nameController.text.trim().isNotEmpty;
      case 4: // Avatar page - must have avatar
        return _selectedAvatarConfig != null;
      default:
        return true;
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1 && _canProceed()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode != RythamoThemeMode.latte;
    final textColor = isDark ? Colors.white : RythamoColors.darkCharcoalText;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true, // Keyboard handling
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button and progress
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
              child: Row(
                children: [
                  // Back button (hidden on first page)
                  AnimatedOpacity(
                    opacity: _currentPage > 0 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: _currentPage > 0 ? _previousPage : null,
                      icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_currentPage + 1) / _totalPages,
                            backgroundColor: textColor.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(RythamoColors.salmonOrange),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${_currentPage + 1} of $_totalPages",
                          style: RythamoTypography.grCaption(textColor).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
            
            // Pages - wrapped in Expanded + SingleChildScrollView for keyboard
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(textColor),
                  _buildFeaturePage(textColor),
                  _buildNamePage(textColor, theme.cardColor),
                  _buildThemePage(textColor, theme.cardColor),
                  _buildAvatarPage(textColor, theme.cardColor),
                  _buildWhyPage(textColor, theme.cardColor),
                  _buildReadyPage(textColor),
                ],
              ),
            ),
            
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // Skip button for My Why page (index 5)
                  if (_currentPage == 5)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextButton(
                        onPressed: _nextPage,
                        child: Text(
                          "Skip for now",
                          style: RythamoTypography.grBody(textColor).copyWith(
                            color: textColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  // Main button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        onPressed: _currentPage == _totalPages - 1 
                            ? _completeOnboarding 
                            : (_canProceed() ? _nextPage : null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canProceed() 
                              ? RythamoColors.salmonOrange 
                              : textColor.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _getButtonText(),
                          style: RythamoTypography.grBody(
                            _canProceed() ? Colors.white : textColor.withOpacity(0.5),
                          ).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getButtonText() {
    if (_currentPage == 0) return "Let's Begin";
    if (_currentPage == 2 && !_canProceed()) return "Enter your name";
    if (_currentPage == 4 && !_canProceed()) return "Pick an avatar";
    if (_currentPage == _totalPages - 1) return "Start Journaling 🚀";
    return "Continue";
  }

  // ===== WELCOME PAGE =====
  Widget _buildWelcomePage(Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          SizedBox(
            height: 200,
            width: 200,
            child: Lottie.asset('assets/mascot/celebrating.json'),
          ),
          const SizedBox(height: 32),
          Text(
            "Hey there! 👋",
            style: RythamoTypography.grHeadline(textColor).copyWith(
              fontSize: RythamoTypography.headlineSize * 0.75,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Welcome to Rythamo Day",
            style: RythamoTypography.grSubhead(RythamoColors.salmonOrange),
          ),
          const SizedBox(height: 24),
          Text(
            "Your personal companion for daily reflection and capturing life's beautiful moments.",
            textAlign: TextAlign.center,
            style: RythamoTypography.grBody(textColor).copyWith(
              fontSize: 16,
              color: textColor.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===== FEATURE PAGE (Daily Reflections only) =====
  Widget _buildFeaturePage(Color textColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            width: 150,
            child: Lottie.asset('assets/mascot/thinking.json'),
          ),
          const SizedBox(height: 32),
          Text(
            "Daily Reflections",
            style: RythamoTypography.grHeadline(textColor).copyWith(
              fontSize: RythamoTypography.headlineSize * 0.65,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "4 Meaningful Questions",
            style: RythamoTypography.grSubhead(RythamoColors.salmonOrange),
          ),
          const SizedBox(height: 24),
          Text(
            "Every day, answer 4 thoughtful questions that help you pause, reflect, and grow.",
            textAlign: TextAlign.center,
            style: RythamoTypography.grBody(textColor).copyWith(
              color: textColor.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildHighlight("🌅 Start your day mindfully", textColor),
          _buildHighlight("📝 Build a journaling habit", textColor),
          _buildHighlight("💭 Discover patterns in thoughts", textColor),
        ],
      ),
    );
  }
  
  Widget _buildHighlight(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: RythamoTypography.grBody(textColor).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===== NAME PAGE =====
  Widget _buildNamePage(Color textColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: 120,
            child: Lottie.asset('assets/mascot/teaching.json'),
          ),
          const SizedBox(height: 24),
          Text(
            "What's your name?",
            style: RythamoTypography.grHeadline(textColor).copyWith(
              fontSize: RythamoTypography.headlineSize * 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "So we can personalize your experience",
            style: RythamoTypography.grBody(textColor).copyWith(
              color: textColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            style: RythamoTypography.grBody(textColor).copyWith(fontSize: 20),
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}), // Update button state
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: RythamoTypography.grBody(textColor).copyWith(
                color: textColor.withOpacity(0.3),
                fontSize: 20,
              ),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 150), // Space for keyboard
        ],
      ),
    );
  }

  // ===== THEME PAGE - Elegant Grid =====
  Widget _buildThemePage(Color textColor, Color cardColor) {
    final themeMode = ref.watch(themeNotifierProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            width: 100,
            child: Lottie.asset('assets/mascot/excited.json'),
          ),
          const SizedBox(height: 24),
          Text(
            "Choose your vibe",
            style: RythamoTypography.grHeadline(textColor).copyWith(
              fontSize: RythamoTypography.headlineSize * 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pick a theme that feels right",
            style: RythamoTypography.grBody(textColor).copyWith(
              color: textColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          // Elegant 2x2 grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildThemeCard(RythamoThemeMode.latte, "Latte", "☀️", "Light & Airy", themeMode, cardColor, textColor),
              _buildThemeCard(RythamoThemeMode.frappe, "Frappé", "🫐", "Cool & Calm", themeMode, cardColor, textColor),
              _buildThemeCard(RythamoThemeMode.macchiato, "Macchiato", "☕", "Warm Blend", themeMode, cardColor, textColor),
              _buildThemeCard(RythamoThemeMode.mocha, "Mocha", "🍫", "Deep & Rich", themeMode, cardColor, textColor),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildThemeCard(RythamoThemeMode mode, String name, String emoji, String desc, 
      RythamoThemeMode current, Color cardColor, Color textColor) {
    final isSelected = mode == current;
    return GestureDetector(
      onTap: () => ref.read(themeNotifierProvider.notifier).setMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isSelected ? RythamoColors.salmonOrange : cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? RythamoColors.salmonOrange : textColor.withOpacity(0.1),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              name,
              style: RythamoTypography.grBody(isSelected ? Colors.white : textColor).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              desc,
              style: RythamoTypography.grCaption(isSelected ? Colors.white.withOpacity(0.8) : textColor.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  // ===== AVATAR PAGE - Full Screen Picker =====
  Widget _buildAvatarPage(Color textColor, Color cardColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
          child: Column(
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: Lottie.asset(
                  _selectedAvatarConfig != null 
                      ? 'assets/mascot/excited.json' 
                      : 'assets/mascot/idle.json',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Create your avatar",
                style: RythamoTypography.grHeadline(textColor).copyWith(
                  fontSize: RythamoTypography.headlineSize * 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tap any avatar below to select",
                style: RythamoTypography.grBody(textColor).copyWith(
                  color: textColor.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Full screen avatar grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final preset = AvatarConfig.preset(index);
                final isSelected = _selectedAvatarConfig != null &&
                    _selectedAvatarConfig!.accessories == preset.accessories &&
                    _selectedAvatarConfig!.hair == preset.hair;
                
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAvatarConfig = preset);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? RythamoColors.salmonOrange : textColor.withOpacity(0.1),
                        width: isSelected ? 4 : 1,
                      ),
                    ),
                    child: ClipOval(
                      child: AvatarDisplay(config: preset, size: 100),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ===== WHY PAGE =====
  Widget _buildWhyPage(Color textColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            width: 100,
            child: Lottie.asset('assets/mascot/reading.json'),
          ),
          const SizedBox(height: 24),
          Text(
            "What's your 'why'?",
            style: RythamoTypography.grHeadline(textColor).copyWith(
              fontSize: RythamoTypography.headlineSize * 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Why do you want to journal? (Optional)",
            style: RythamoTypography.grBody(textColor).copyWith(
              color: textColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _whyController,
            maxLines: 4,
            style: RythamoTypography.grBody(textColor),
            decoration: InputDecoration(
              hintText: 'I want to remember the small moments...',
              hintStyle: RythamoTypography.grBody(textColor).copyWith(
                color: textColor.withOpacity(0.3),
              ),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 150), // Space for keyboard
        ],
      ),
    );
  }

  // ===== READY PAGE =====
  Widget _buildReadyPage(Color textColor) {
    final name = _nameController.text.trim();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          SizedBox(
            height: 180,
            width: 180,
            child: Lottie.asset('assets/mascot/celebrating.json'),
          ),
          const SizedBox(height: 32),
          Text(
            "You're all set, $name! 🎉",
            style: RythamoTypography.grHeadline(textColor).copyWith(
              fontSize: RythamoTypography.headlineSize * 0.55,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Your journaling journey begins now",
            style: RythamoTypography.grSubhead(RythamoColors.salmonOrange),
          ),
          const SizedBox(height: 24),
          Text(
            "There's no right or wrong way to journal. Just be honest with yourself and enjoy the process.",
            textAlign: TextAlign.center,
            style: RythamoTypography.grBody(textColor).copyWith(
              color: textColor.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
