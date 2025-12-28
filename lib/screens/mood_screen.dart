import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/widgets/rythamo_card.dart';
import 'package:journal_app/services/storage_service.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:journal_app/widgets/empty_state.dart';


class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  final TextEditingController _noteController = TextEditingController();
  final StorageService _storageService = StorageService();
  List<Map<String, dynamic>> _moodHistory = [];
  String? _selectedMood;

  final List<Map<String, String>> _moods = [
    {'emoji': '😄', 'label': 'Great'},
    {'emoji': '😊', 'label': 'Good'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '😔', 'label': 'Bad'},
    {'emoji': '😢', 'label': 'Terrible'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMoodHistory();
  }

  Future<void> _loadMoodHistory() async {
    final moods = await _storageService.getMoods();
    if (mounted) {
      setState(() {
        _moodHistory = moods;
      });
    }
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null) return;

    final moodEntry = {
      'emoji': _selectedMood,
      'note': _noteController.text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _storageService.saveMood(moodEntry);
    await _loadMoodHistory();

    if (mounted) {
      setState(() {
        _selectedMood = null;
        _noteController.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood saved!'),
          duration: Duration(seconds: 2),
          backgroundColor: RythamoColors.salmonOrange,
        ),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('MOOD TRACKER', style: RythamoTypography.headerDynamic(textColor)),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How are you feeling?',
                style: RythamoTypography.metricBigDynamic(textColor).copyWith(fontSize: 24),
              ),
              const SizedBox(height: 24),
              
              // Mood Selection
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood['emoji'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = mood['emoji'];
                      });
                    },
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 64) / 3,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? RythamoColors.salmonOrange 
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? RythamoColors.salmonOrange 
                              : textColor.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            mood['emoji']!,
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mood['label']!,
                            style: RythamoTypography.bodyDynamic(textColor).copyWith(
                              color: isSelected 
                                  ? RythamoColors.darkCharcoalText 
                                  : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Optional Note
              Text(
                'Add a note (optional)',
                style: RythamoTypography.headerDynamic(textColor),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 140,
                style: RythamoTypography.bodyDynamic(textColor),
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  hintStyle: RythamoTypography.bodyDynamic(textColor).copyWith(
                    color: textColor.withOpacity(0.3),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: RythamoTypography.bodyDynamic(textColor).copyWith(
                    color: textColor.withOpacity(0.5),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMood != null ? _saveMood : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RythamoColors.salmonOrange,
                    disabledBackgroundColor: theme.cardColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Save Mood',
                    style: RythamoTypography.bodyDynamic(textColor).copyWith(
                      color: _selectedMood != null 
                          ? RythamoColors.darkCharcoalText 
                          : textColor.withOpacity(0.3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Mood History
              if (_moodHistory.isNotEmpty) ...[
                Text(
                  'RECENT MOODS',
                  style: RythamoTypography.headerDynamic(textColor),
                ),
                const SizedBox(height: 16),
                ..._moodHistory.take(5).map((entry) {
                  final timestamp = DateTime.parse(entry['timestamp']);
                  final timeAgo = _getTimeAgo(timestamp);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RythamoCard(
                      color: theme.cardColor,
                      child: Row(
                        children: [
                          Text(
                            entry['emoji'],
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (entry['note'].isNotEmpty)
                                  Text(
                                    entry['note'],
                                    style: RythamoTypography.bodyDynamic(textColor),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  timeAgo,
                                  style: RythamoTypography.bodyDynamic(textColor).copyWith(
                                    color: textColor.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ] else ...[
                const SizedBox(height: 24),
                EmptyState(
                  title: "No Moods Yet",
                  message: "Track your first mood above!",
                  lottiePath: 'assets/mascot/thinking.json',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
