import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/widgets/rythamo_card.dart';
import 'package:journal_app/services/storage_service.dart';
import 'package:journal_app/models/daily_entry.dart';
import 'package:journal_app/widgets/media_item.dart';
import 'package:journal_app/screens/daily_questions_screen.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:journal_app/utils/page_transitions.dart';
import 'package:journal_app/widgets/empty_state.dart';
import 'package:lottie/lottie.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final StorageService _storageService = StorageService();
  List<DailyEntry> _entries = [];
  List<Map<String, dynamic>> _moodHistory = [];
  bool _isLoading = true;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Track which dates have entries
  final Map<DateTime, List<String>> _eventMarkers = {}; // 'journal' or 'mood'
  bool _isCalendarExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadEntries(),
      _loadMoodHistory(),
    ]);
    _buildEventMarkers();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadEntries() async {
    final entries = await _storageService.getDailyEntries();
    _entries = entries.reversed.toList();
  }

  Future<void> _loadMoodHistory() async {
    _moodHistory = await _storageService.getMoods();
  }

  void _buildEventMarkers() {
    _eventMarkers.clear();
    
    // Add journal entries
    for (var entry in _entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      _eventMarkers.putIfAbsent(date, () => []);
      if (!_eventMarkers[date]!.contains('journal')) {
        _eventMarkers[date]!.add('journal');
      }
    }
    
    // Add mood entries
    for (var mood in _moodHistory) {
      final timestamp = DateTime.parse(mood['timestamp']);
      final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
      _eventMarkers.putIfAbsent(date, () => []);
      if (!_eventMarkers[date]!.contains('mood')) {
        _eventMarkers[date]!.add('mood');
      }
    }
  }

  List<DailyEntry> _getFilteredJournalEntries() {
    if (_selectedDay == null) return _entries;
    
    return _entries.where((entry) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      return entryDate == selectedDate;
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredMoodEntries() {
    if (_selectedDay == null) return [];
    
    return _moodHistory.where((mood) {
      final timestamp = DateTime.parse(mood['timestamp']);
      final moodDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
      final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      return moodDate == selectedDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredJournalEntries = _getFilteredJournalEntries();
    final filteredMoodEntries = _getFilteredMoodEntries();
    final hasFilteredContent = filteredJournalEntries.isNotEmpty || filteredMoodEntries.isNotEmpty;
    
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode != RythamoThemeMode.latte;
    final textColor = isDark ? Colors.white : RythamoColors.darkCharcoalText;

    return SafeArea(
      bottom: false,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RythamoColors.salmonOrange))
          : CustomScrollView(
              slivers: [
                // Hero Section - similar to home screen with big mascot
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      children: [
                        // Top row with title and show all
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "YOUR MEMORIES",
                              style: RythamoTypography.grCaption(textColor).copyWith(
                                letterSpacing: 2,
                                color: RythamoColors.salmonOrange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_selectedDay != null)
                              TextButton(
                                onPressed: () => setState(() => _selectedDay = null),
                                child: Text(
                                  'Show All',
                                  style: RythamoTypography.grBody(RythamoColors.salmonOrange).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Big mascot and stats
                        Row(
                          children: [
                            // Large mascot like home screen
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: Lottie.asset('assets/mascot/reading.json'),
                            ),
                            const SizedBox(width: 16),
                            // Stats column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${_entries.length}",
                                    style: RythamoTypography.grDisplay(textColor).copyWith(
                                      fontSize: RythamoTypography.displaySize * 0.6,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    _entries.length == 1 ? "Entry" : "Entries",
                                    style: RythamoTypography.grSubhead(textColor).copyWith(
                                      color: textColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Calendar (Collapsible)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RythamoCard(
                      color: theme.cardColor,
                      child: AnimatedCrossFade(
                        duration: const Duration(milliseconds: 300),
                        crossFadeState: _isCalendarExpanded 
                            ? CrossFadeState.showSecond 
                            : CrossFadeState.showFirst,
                        firstChild: GestureDetector(
                          onTap: () => setState(() => _isCalendarExpanded = true),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            color: Colors.transparent, // Hit test
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE').format(_selectedDay ?? DateTime.now()).toUpperCase(),
                                  style: RythamoTypography.headerDynamic(textColor).copyWith(
                                    fontSize: 22, // Base size
                                    letterSpacing: 1.2,
                                    color: RythamoColors.salmonOrange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('d MMMM yyyy').format(_selectedDay ?? DateTime.now()),
                                  style: RythamoTypography.metricBigDynamic(textColor).copyWith(
                                    fontSize: 35, // ~22 * 1.618
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.touch_app, size: 16, color: textColor.withOpacity(0.5)),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Tap to expand calendar",
                                      style: RythamoTypography.bodyDynamic(textColor).copyWith(
                                        fontSize: 12,
                                        color: textColor.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        secondChild: Column(
                          children: [
                            TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                  // Optional: Collapse on select? User didn't specify, but usually nice.
                                  // Let's keep it expanded so they can browse, but maybe add a collapse button.
                                });
                              },
                              calendarFormat: CalendarFormat.month,
                              headerVisible: true,
                              daysOfWeekVisible: true,
                              calendarStyle: CalendarStyle(
                                outsideDaysVisible: false,
                                weekendTextStyle: RythamoTypography.bodyDynamic(textColor).copyWith(
                                  color: textColor.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                                defaultTextStyle: RythamoTypography.bodyDynamic(textColor).copyWith(
                                  color: textColor,
                                  fontSize: 14,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(color: RythamoColors.salmonOrange, width: 1),
                                  shape: BoxShape.circle,
                                ),
                                todayTextStyle: RythamoTypography.bodyDynamic(textColor).copyWith(
                                  color: textColor,
                                  fontSize: 14,
                                ),
                                selectedDecoration: const BoxDecoration(
                                  color: RythamoColors.salmonOrange,
                                  shape: BoxShape.circle,
                                ),
                                selectedTextStyle: RythamoTypography.body.copyWith(
                                  color: RythamoColors.darkCharcoalText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                markerDecoration: const BoxDecoration(
                                  color: RythamoColors.mintGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              headerStyle: HeaderStyle(
                                titleTextStyle: RythamoTypography.bodyDynamic(textColor).copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                formatButtonVisible: false,
                                titleCentered: true,
                                leftChevronIcon: Icon(Icons.chevron_left, color: textColor.withOpacity(0.54), size: 20),
                                rightChevronIcon: Icon(Icons.chevron_right, color: textColor.withOpacity(0.54), size: 20),
                                headerPadding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekendStyle: RythamoTypography.bodyDynamic(textColor).copyWith(
                                  color: textColor.withOpacity(0.38),
                                  fontSize: 11,
                                ),
                                weekdayStyle: RythamoTypography.bodyDynamic(textColor).copyWith(
                                  color: textColor.withOpacity(0.38),
                                  fontSize: 11,
                                ),
                              ),
                              eventLoader: (day) {
                                final normalizedDay = DateTime(day.year, day.month, day.day);
                                return _eventMarkers[normalizedDay] ?? [];
                              },
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, day, events) {
                                  if (events.isEmpty) return null;
                                  
                                  return Positioned(
                                    bottom: 2,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (events.contains('journal'))
                                          Container(
                                            width: 3,
                                            height: 3,
                                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                            decoration: const BoxDecoration(
                                              color: RythamoColors.salmonOrange,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        if (events.contains('mood'))
                                          Container(
                                            width: 3,
                                            height: 3,
                                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                            decoration: const BoxDecoration(
                                              color: RythamoColors.mintGreen,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _isCalendarExpanded = false),
                              icon: const Icon(Icons.keyboard_arrow_up),
                              color: textColor.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // Content List
                if (_selectedDay != null && !hasFilteredContent)
                  SliverFillRemaining(
                    child: EmptyState(
                      title: "Quiet Day",
                      message: "No entries found for this date.",
                      lottiePath: 'assets/mascot/sad.json',
                    ),
                  )
                else if (_selectedDay == null && _entries.isEmpty && _moodHistory.isEmpty)
                  SliverFillRemaining(
                    child: EmptyState(
                      title: "No History Yet",
                      message: "Your journey begins with a single entry.\nStart capturing your moments today!",
                      lottiePath: 'assets/mascot/reading.json',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // Calculate total items: mood entries + journal entries
                          final moodCount = _selectedDay != null ? filteredMoodEntries.length : 0;
                          final journalCount = filteredJournalEntries.length;
                          
                          // Show mood section header
                          if (_selectedDay != null && filteredMoodEntries.isNotEmpty) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('MOODS', style: RythamoTypography.headerDynamic(textColor).copyWith(fontSize: 12)),
                              );
                            }
                            
                            // Show mood entries
                            if (index <= moodCount) {
                              final mood = filteredMoodEntries[index - 1];
                              final timestamp = DateTime.parse(mood['timestamp']);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: RythamoCard(
                                  color: theme.cardColor,
                                  child: Row(
                                    children: [
                                      Text(mood['emoji'], style: const TextStyle(fontSize: 28)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (mood['note'].isNotEmpty)
                                              Text(mood['note'], style: RythamoTypography.bodyDynamic(textColor).copyWith(fontSize: 14)),
                                            Text(
                                              DateFormat('h:mm a').format(timestamp),
                                              style: RythamoTypography.bodyDynamic(textColor).copyWith(
                                                color: textColor.withOpacity(0.5),
                                                fontSize: 11,
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
                            
                            // Journal section header
                            if (index == moodCount + 1 && journalCount > 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 8),
                                child: Text('JOURNAL', style: RythamoTypography.headerDynamic(textColor).copyWith(fontSize: 12)),
                              );
                            }
                            
                            // Journal entries
                            final journalIndex = index - moodCount - 2;
                            if (journalIndex >= 0 && journalIndex < journalCount) {
                              return _buildJournalCard(filteredJournalEntries[journalIndex], textColor, theme.cardColor);
                            }
                          } else {
                            // No filtering or no moods, just show journal entries
                            if (index < journalCount) {
                              return _buildJournalCard(filteredJournalEntries[index], textColor, theme.cardColor);
                            }
                          }
                          
                          return const SizedBox.shrink();
                        },
                        childCount: _selectedDay != null && filteredMoodEntries.isNotEmpty
                            ? 1 + filteredMoodEntries.length + (filteredJournalEntries.isNotEmpty ? 1 : 0) + filteredJournalEntries.length
                            : filteredJournalEntries.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildJournalCard(DailyEntry entry, Color textColor, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RythamoCard(
        color: cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: RythamoColors.salmonOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(entry.date),
                        style: RythamoTypography.grCaption(RythamoColors.salmonOrange).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${entry.answeredCount}/${entry.responses.length} answered",
                      style: RythamoTypography.grCaption(textColor).copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('h:mm a').format(entry.date),
                  style: RythamoTypography.grCaption(textColor),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // All Q&A pairs
            ...entry.responses.where((r) => r.hasAnswer).map((qa) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                          color: RythamoColors.salmonOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          qa.question,
                          style: RythamoTypography.grCaption(textColor).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      qa.answer,
                      style: RythamoTypography.grBody(textColor).copyWith(
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),

            // Mascot
            if (entry.mascot != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Lottie.asset(entry.mascot!),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Feeling ${entry.mascot!.split('/').last.replaceAll('.json', '')}",
                      style: RythamoTypography.grCaption(textColor).copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            // Media
            if (entry.mediaPaths.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: entry.mediaPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final path = entry.mediaPaths[index];
                    MediaType type = MediaType.image;
                    if (path.endsWith('.mp4') || path.endsWith('.mov')) {
                      type = MediaType.video;
                    } else if (path.endsWith('.aac') || path.endsWith('.m4a')) {
                      type = MediaType.audio;
                    }
                    
                    return MediaItem(
                      path: path,
                      type: type,
                    );
                  },
                ),
              ),
            ],
            
            // Actions
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: textColor.withOpacity(0.38), size: 20),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      PageTransitions.slideRight(
                        DailyQuestionsScreen(existingEntry: entry),
                      ),
                    );
                    _loadData();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: RythamoColors.salmonOrange, size: 20),
                  onPressed: () async {
                    await _storageService.deleteDailyEntry(entry.id);
                    _loadData();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

