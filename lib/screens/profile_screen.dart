import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/widgets/rythamo_card.dart';
import 'package:journal_app/widgets/rythamo_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:journal_app/services/storage_service.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:journal_app/services/avatar_service.dart';
import 'package:journal_app/widgets/avatar_picker.dart';
import 'package:journal_app/widgets/avatar_display.dart';
import 'package:journal_app/services/notification_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final StorageService _storageService = StorageService();
  String _userName = "Rythamo User";
  String _userBio = "Journaling Enthusiast";
  String _myWhy = "I want to remember the small moments that make life beautiful.";
  
  int _totalEntries = 0;
  int _streak = 0;
  AvatarConfig? _avatarConfig;
  String _notificationTime = "20:00";

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _storageService.getDailyEntries();
    final streak = await _storageService.calculateStreak();
    final avatarConfig = await AvatarService.loadAvatar();
    final notifTime = await RythamoNotificationService().getScheduledTime();
    
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? "Rythamo User";
        _userBio = prefs.getString('user_bio') ?? "Journaling Enthusiast";
        _myWhy = prefs.getString('my_why') ?? "I want to remember the small moments that make life beautiful.";
        _totalEntries = entries.length;
        _streak = streak;
        _avatarConfig = avatarConfig;
        _notificationTime = notifTime;
      });
    }
  }

  Future<void> _editAvatar() async {
    final newConfig = await showAvatarPicker(context, currentConfig: _avatarConfig);
    if (newConfig != null) {
      await AvatarService.saveAvatar(newConfig);
      setState(() {
        _avatarConfig = newConfig;
      });
    }
  }

  Future<void> _editProfile() async {
    final formKey = GlobalKey<FormState>();
    String tempName = _userName;
    String tempBio = _userBio;
    
    final theme = Theme.of(context);
    final themeMode = ref.read(themeNotifierProvider);
    final isDark = themeMode != RythamoThemeMode.latte;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Edit Profile", 
          style: RythamoTypography.grSubhead(isDark ? Colors.white : RythamoColors.darkCharcoalText)
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: tempName,
                style: RythamoTypography.grBody(isDark ? Colors.white : RythamoColors.darkCharcoalText),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => tempName = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: tempBio,
                style: RythamoTypography.grBody(isDark ? Colors.white : RythamoColors.darkCharcoalText),
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => tempBio = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_name', tempName);
              await prefs.setString('user_bio', tempBio);
              if (mounted) {
                setState(() {
                  _userName = tempName;
                  _userBio = tempBio;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RythamoColors.salmonOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Save", style: TextStyle(color: RythamoColors.darkCharcoalText)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog() async {
    final theme = Theme.of(context);
    final themeMode = ref.read(themeNotifierProvider);
    final isDark = themeMode != RythamoThemeMode.latte;
    final textColor = isDark ? Colors.white : RythamoColors.darkCharcoalText;
    
    String tempWhy = _myWhy;

    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Edit My Why", 
          style: RythamoTypography.grSubhead(textColor)
        ),
        content: TextField(
          maxLines: 4,
          style: RythamoTypography.grBody(textColor),
          controller: TextEditingController(text: _myWhy),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) => tempWhy = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('my_why', tempWhy);
              if (mounted) {
                setState(() => _myWhy = tempWhy);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RythamoColors.salmonOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Save", style: TextStyle(color: RythamoColors.darkCharcoalText)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode != RythamoThemeMode.latte;
    final textColor = isDark ? Colors.white : RythamoColors.darkCharcoalText;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('PROFILE', style: RythamoTypography.grCaption(textColor).copyWith(
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        )),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "THEME",
                  style: RythamoTypography.grCaption(textColor).copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButton<RythamoThemeMode>(
                    value: themeMode,
                    underline: const SizedBox(),
                    isDense: true,
                    dropdownColor: theme.cardColor,
                    onChanged: (RythamoThemeMode? newValue) {
                      if (newValue != null) {
                        ref.read(themeNotifierProvider.notifier).setMode(newValue);
                      }
                    },
                    items: RythamoThemeMode.values.map((mode) {
                      String label;
                      switch (mode) {
                        case RythamoThemeMode.latte:
                          label = 'Latte ☀️';
                          break;
                        case RythamoThemeMode.frappe:
                          label = 'Frappé 🫐';
                          break;
                        case RythamoThemeMode.macchiato:
                          label = 'Macchiato ☕';
                          break;
                        case RythamoThemeMode.mocha:
                          label = 'Mocha 🍫';
                          break;
                      }
                      return DropdownMenuItem<RythamoThemeMode>(
                        value: mode,
                        child: Text(
                          label,
                          style: RythamoTypography.grBody(textColor).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Avatar and Name Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with edit button
                GestureDetector(
                  onTap: _editAvatar,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: RythamoColors.salmonOrange,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: _avatarConfig != null
                              ? AvatarDisplay(config: _avatarConfig!, size: 120)
                              : AvatarDisplay(config: AvatarConfig.preset(0), size: 120),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: RythamoColors.salmonOrange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                
                // Name and Bio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: RythamoTypography.grHeadline(textColor).copyWith(
                          fontSize: RythamoTypography.headlineSize * 0.7,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userBio,
                        style: RythamoTypography.grBody(textColor).copyWith(
                          color: textColor.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // My Why Card
            RythamoCard(
              color: theme.cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "MY WHY",
                        style: RythamoTypography.grCaption(textColor).copyWith(
                          letterSpacing: 2,
                          color: RythamoColors.salmonOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showEditDialog,
                        child: Icon(Icons.edit, color: textColor.withOpacity(0.5), size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _myWhy,
                    style: RythamoTypography.grBody(textColor).copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: "ENTRIES",
                    value: "$_totalEntries",
                    textColor: textColor,
                    cardColor: theme.cardColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    label: "STREAK",
                    value: "$_streak",
                    textColor: textColor,
                    cardColor: theme.cardColor,
                    icon: Icons.local_fire_department,
                    iconColor: RythamoColors.salmonOrange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Notification Time Card
            RythamoCard(
              color: theme.cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DAILY REMINDER",
                        style: RythamoTypography.grCaption(textColor).copyWith(
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Smart notifications at $_notificationTime",
                        style: RythamoTypography.grBody(textColor).copyWith(
                          color: textColor.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: RythamoColors.salmonOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _notificationTime,
                      style: RythamoTypography.grBody(RythamoColors.salmonOrange).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Edit Profile Button
            RythamoButton(
              text: "Edit Profile",
              onPressed: _editProfile,
              backgroundColor: theme.cardColor,
              textColor: textColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color cardColor;
  final IconData? icon;
  final Color? iconColor;
  
  const _StatCard({
    required this.label,
    required this.value,
    required this.textColor,
    required this.cardColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return RythamoCard(
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label, 
                style: RythamoTypography.grCaption(textColor).copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 16, color: iconColor),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value, 
            style: RythamoTypography.grHeadline(textColor).copyWith(
              fontSize: RythamoTypography.headlineSize * 0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
