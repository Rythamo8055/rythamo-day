import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class RythamoNotificationService {
  static final RythamoNotificationService _instance = RythamoNotificationService._internal();

  factory RythamoNotificationService() {
    return _instance;
  }

  RythamoNotificationService._internal();

  final Random _random = Random();

  // Motivational messages based on streak
  static const Map<String, List<String>> _messages = {
    'noStreak': [
      "Ready to start your reflection journey? ✨",
      "Today is a perfect day to begin! 🌟",
      "Your first step starts now! 🚀",
      "Let's capture today's moments! 📝",
    ],
    'building': [ // 1-6 days
      "Keep the momentum going! 🔥",
      "You're building something great! 💪",
      "Day {streak}! You're on a roll! ⭐",
      "Your consistency is inspiring! 🌈",
      "Another day, another reflection! 📖",
    ],
    'weekStar': [ // 7-29 days
      "A whole week of reflections! 🌟",
      "You're a reflection champion! 🏆",
      "{streak} days strong! Keep shining! ✨",
      "Your dedication is remarkable! 🎯",
      "Making progress every single day! 📈",
    ],
    'onFire': [ // 30+ days
      "🔥 {streak} DAYS! You're UNSTOPPABLE!",
      "You've mastered daily reflection! 👑",
      "Incredible dedication for {streak} days! 💯",
      "You're an inspiration! Keep going! 🌟",
      "Living your best reflective life! ✨",
    ],
  };

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // default icon
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'daily_reminders',
          channelName: 'Daily Reminders',
          channelDescription: 'Notification channel for daily journaling reminders',
          defaultColor: RythamoColors.salmonOrange,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'basic_channel_group',
          channelGroupName: 'Basic group',
        )
      ],
      debug: true,
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  /// Track when user opens the app to learn their patterns
  Future<void> trackAppUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // Store the hour when the user typically uses the app
    List<String> usageHours = prefs.getStringList('usage_hours') ?? [];
    usageHours.add(now.hour.toString());
    
    // Keep only the last 14 data points
    if (usageHours.length > 14) {
      usageHours = usageHours.sublist(usageHours.length - 14);
    }
    
    await prefs.setStringList('usage_hours', usageHours);
    
    // Recalculate optimal notification time
    await _updateOptimalNotificationTime();
  }

  /// Calculate the optimal notification time based on user's usage patterns
  Future<TimeOfDay> _calculateOptimalTime() async {
    final prefs = await SharedPreferences.getInstance();
    final usageHours = prefs.getStringList('usage_hours') ?? [];
    
    if (usageHours.length < 3) {
      // Not enough data, use default 8:00 PM
      return const TimeOfDay(hour: 20, minute: 0);
    }
    
    // Find the most common hour
    final hourCounts = <int, int>{};
    for (final hourStr in usageHours) {
      final hour = int.tryParse(hourStr) ?? 20;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    // Find the hour with the most usage
    int bestHour = 20;
    int bestCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > bestCount) {
        bestCount = count;
        bestHour = hour;
      }
    });
    
    // Schedule notification 30 minutes before their typical usage time
    int notificationHour = bestHour - 1;
    if (notificationHour < 0) notificationHour = 23;
    
    return TimeOfDay(hour: notificationHour, minute: 30);
  }

  Future<void> _updateOptimalNotificationTime() async {
    final optimalTime = await _calculateOptimalTime();
    final streak = await _getCurrentStreak();
    
    await scheduleDynamicReminder(
      time: optimalTime,
      streak: streak,
    );
  }

  Future<int> _getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('current_streak') ?? 0;
  }

  /// Save current streak for notification messages
  Future<void> updateStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_streak', streak);
    
    // Update notification message for the new streak
    await _updateOptimalNotificationTime();
  }

  /// Get a motivational message based on streak
  String _getMotivationalMessage(int streak) {
    String category;
    if (streak == 0) {
      category = 'noStreak';
    } else if (streak < 7) {
      category = 'building';
    } else if (streak < 30) {
      category = 'weekStar';
    } else {
      category = 'onFire';
    }
    
    final messages = _messages[category]!;
    final message = messages[_random.nextInt(messages.length)];
    
    return message.replaceAll('{streak}', streak.toString());
  }

  /// Schedule a dynamic reminder based on user patterns
  Future<void> scheduleDynamicReminder({
    required TimeOfDay time,
    int streak = 0,
  }) async {
    // Cancel existing reminders
    await AwesomeNotifications().cancelAllSchedules();

    final message = _getMotivationalMessage(streak);
    String title;
    
    if (streak == 0) {
      title = "Time to Journal! 📝";
    } else if (streak < 7) {
      title = "Keep it up! 🌟";
    } else if (streak < 30) {
      title = "$streak Day Streak! 🔥";
    } else {
      title = "🔥 $streak Days Strong! 🔥";
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'daily_reminders',
        title: title,
        body: message,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: time.hour,
        minute: time.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
      ),
    );
    
    // Save the scheduled time for display to user
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_time', '${time.hour}:${time.minute.toString().padLeft(2, '0')}');
  }

  /// Legacy method for backward compatibility - now uses dynamic scheduling
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    String title = "Time to Journal!",
    String body = "Take a moment to reflect on your day.",
  }) async {
    final streak = await _getCurrentStreak();
    await scheduleDynamicReminder(time: time, streak: streak);
  }

  Future<String> getScheduledTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('notification_time') ?? '20:00';
  }

  Future<void> cancelReminders() async {
    await AwesomeNotifications().cancelAllSchedules();
  }
}
