import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/screens/home_screen.dart';
import 'package:journal_app/screens/onboarding_screen.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:journal_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize NotificationService
  final notificationService = RythamoNotificationService();
  await notificationService.initialize();
  // Schedule default reminder at 8:00 PM if not already scheduled
  // In a real app, we'd check if it's already scheduled or let the user configure it.
  // For now, we'll just ensure the service is ready.
  // We will schedule it in the app initialization if needed.

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));
  
  runApp(const ProviderScope(child: JournalApp()));
}

class JournalApp extends ConsumerStatefulWidget {
  const JournalApp({super.key});

  @override
  ConsumerState<JournalApp> createState() => _JournalAppState();
}

class _JournalAppState extends ConsumerState<JournalApp> {
  bool _isLoading = true;
  bool _onboardingComplete = false;
  bool showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    
    // Version check to force onboarding on updates (but preserve data)
    const currentVersion = "1.0.1"; // Increment this for updates
    final savedVersion = prefs.getString('app_version');
    
    bool showOnboarding = !onboardingComplete;
    
    if (savedVersion != currentVersion) {
      // New version, show onboarding again to introduce features
      showOnboarding = true;
      // Update saved version
      await prefs.setString('app_version', currentVersion);
    }
    
    // Load saved theme preference
    final savedThemeIndex = prefs.getInt('theme_mode');
    if (savedThemeIndex != null && savedThemeIndex < RythamoThemeMode.values.length) {
      final savedTheme = RythamoThemeMode.values[savedThemeIndex];
      ref.read(themeNotifierProvider.notifier).setMode(savedTheme);
    }
    
    if (mounted) {
      setState(() {
        _onboardingComplete = !showOnboarding;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final theme = RythamoTheme.getTheme(themeMode);

    return MaterialApp(
      title: 'Rythamo Day',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: _isLoading
          ? Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: Center(
                child: CircularProgressIndicator(
                  color: theme.primaryColor,
                ),
              ),
            )
          : _onboardingComplete
              ? const HomeScreen()
              : const OnboardingScreen(),
    );
  }
}
