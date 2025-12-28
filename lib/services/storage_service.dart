import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:journal_app/models/journal_entry.dart';
import 'package:journal_app/models/daily_entry.dart';

class StorageService {
  static const String _journalsFileName = 'journals.json';
  static const String _dailyEntriesFileName = 'daily_entries.json';
  static const String _moodsFileName = 'moods.json';
  
  // The 4 daily questions
  static const List<String> dailyQuestions = [
    "What made you smile today?",
    "What is one thing you learned today?",
    "What are you grateful for right now?",
    "How did you take care of yourself today?",
  ];

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _journalsFile async {
    final path = await _localPath;
    return File('$path/$_journalsFileName');
  }

  Future<File> get _moodsFile async {
    final path = await _localPath;
    return File('$path/$_moodsFileName');
  }

  // Journal Entry Methods
  Future<void> saveEntry(JournalEntry entry) async {
    List<JournalEntry> entries;
    try {
      entries = await getEntries();
    } catch (e) {
      print('Error reading journals: $e');
      // Try to recover from backup
      try {
        entries = await _getEntriesFromBackup();
        print('Recovered from backup');
        // If we recovered from backup, we should probably save this state immediately to main file
        // to "fix" the corruption.
      } catch (e) {
        // If backup also fails, we are in a critical state.
        // We should NOT overwrite the main file if it exists and has content.
        final file = await _journalsFile;
        if (await file.exists() && (await file.length()) > 0) {
           // File exists and is not empty, but we can't read it.
           // DO NOT OVERWRITE.
           // Maybe save to a "rescue" file?
           final rescueFile = File('${file.path}.rescue.${DateTime.now().millisecondsSinceEpoch}.json');
           final String encodedData = jsonEncode([entry.toJson()]);
           await rescueFile.writeAsString(encodedData);
           print('CRITICAL: Saved to rescue file ${rescueFile.path} to avoid data loss.');
           return; 
        }
        // If file doesn't exist or is empty, start fresh.
        entries = [];
      }
    }
    
    entries.add(entry);
    
    final file = await _journalsFile;
    
    // Create backup before writing if file exists
    if (await file.exists()) {
      try {
        await file.copy('${file.path}.bak');
      } catch (e) {
        print('Failed to create backup: $e');
      }
    }
    
    final String encodedData = jsonEncode(entries.map((e) => e.toJson()).toList());
    await file.writeAsString(encodedData);
  }

  Future<List<JournalEntry>> getEntries() async {
    try {
      final file = await _journalsFile;
      if (!await file.exists()) {
        return [];
      }
      
      final String data = await file.readAsString();
      if (data.isEmpty) return [];
      
      try {
        final List<dynamic> decodedData = jsonDecode(data);
        return decodedData.map((e) => JournalEntry.fromJson(e)).toList();
      } catch (e) {
        print("JSON Decode Error: $e");
        throw Exception("Corrupted JSON");
      }
    } catch (e) {
      print('Error reading journals: $e');
      throw Exception('Failed to read journals: $e');
    }
  }

  Future<List<JournalEntry>> _getEntriesFromBackup() async {
    try {
      final file = await _journalsFile;
      final backupFile = File('${file.path}.bak');
      if (!await backupFile.exists()) {
        return [];
      }
      
      final String data = await backupFile.readAsString();
      if (data.isEmpty) return [];
      
      final List<dynamic> decodedData = jsonDecode(data);
      return decodedData.map((e) => JournalEntry.fromJson(e)).toList();
    } catch (e) {
      print('Error reading backup journals: $e');
      throw Exception('Failed to read backup journals: $e');
    }
  }

  Future<void> deleteEntry(String id) async {
    final entries = await getEntries();
    entries.removeWhere((e) => e.id == id);
    
    final file = await _journalsFile;
    // Backup before write
    if (await file.exists()) {
       await file.copy('${file.path}.bak');
    }
    
    final String encodedData = jsonEncode(entries.map((e) => e.toJson()).toList());
    await file.writeAsString(encodedData);
  }

  Future<void> updateEntry(JournalEntry updatedEntry) async {
    final entries = await getEntries();
    final index = entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      entries[index] = updatedEntry;
      final file = await _journalsFile;
      // Backup before write
      if (await file.exists()) {
         await file.copy('${file.path}.bak');
      }
      final String encodedData = jsonEncode(entries.map((e) => e.toJson()).toList());
      await file.writeAsString(encodedData);
    }
  }

  // Mood Methods
  Future<void> saveMood(Map<String, dynamic> mood) async {
    final moods = await getMoods();
    moods.insert(0, mood);
    
    final file = await _moodsFile;
    final String encodedData = jsonEncode(moods);
    await file.writeAsString(encodedData);
  }

  Future<List<Map<String, dynamic>>> getMoods() async {
    try {
      final file = await _moodsFile;
      if (!await file.exists()) {
        return [];
      }
      
      final String data = await file.readAsString();
      if (data.isEmpty) return [];
      
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error reading moods: $e');
      return [];
    }
  }

  // ============ DAILY ENTRY METHODS (NEW MULTI-QUESTION FORMAT) ============

  Future<File> get _dailyEntriesFile async {
    final path = await _localPath;
    return File('$path/$_dailyEntriesFileName');
  }

  /// Migrate old JournalEntry format to new DailyEntry format
  Future<void> migrateToNewFormat() async {
    try {
      final file = await _dailyEntriesFile;
      
      // Skip if already migrated
      if (await file.exists()) {
        final data = await file.readAsString();
        if (data.isNotEmpty) return;
      }
      
      // Get old entries
      final oldEntries = await getEntries();
      if (oldEntries.isEmpty) return;
      
      // Group old entries by date
      final Map<String, List<JournalEntry>> groupedByDate = {};
      for (var entry in oldEntries) {
        final dateKey = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
        groupedByDate.putIfAbsent(dateKey, () => []);
        groupedByDate[dateKey]!.add(entry);
      }
      
      // Convert to DailyEntry format
      final List<DailyEntry> newEntries = [];
      for (var dateKey in groupedByDate.keys) {
        final entriesForDay = groupedByDate[dateKey]!;
        
        // Create responses list from old entries
        final responses = <QuestionAnswer>[];
        for (var q in dailyQuestions) {
          // Find if there's an answer for this question
          final matching = entriesForDay.where((e) => e.question == q).toList();
          if (matching.isNotEmpty) {
            responses.add(QuestionAnswer(
              question: q,
              answer: matching.first.answer,
            ));
          } else {
            responses.add(QuestionAnswer(question: q, answer: ''));
          }
        }
        
        // Collect all media and mascots
        final allMedia = entriesForDay.expand((e) => e.mediaPaths).toList();
        final mascot = entriesForDay.where((e) => e.mascot != null).isNotEmpty
            ? entriesForDay.firstWhere((e) => e.mascot != null).mascot
            : null;
        
        newEntries.add(DailyEntry(
          id: entriesForDay.first.id,
          date: entriesForDay.first.date,
          responses: responses,
          mediaPaths: allMedia,
          mascot: mascot,
        ));
      }
      
      // Save migrated entries
      final String encodedData = jsonEncode(newEntries.map((e) => e.toJson()).toList());
      await file.writeAsString(encodedData);
      print('Migration complete: ${newEntries.length} daily entries created');
    } catch (e) {
      print('Migration error: $e');
    }
  }

  /// Save a new daily entry
  Future<void> saveDailyEntry(DailyEntry entry) async {
    List<DailyEntry> entries = await getDailyEntries();
    entries.add(entry);
    
    final file = await _dailyEntriesFile;
    
    // Create backup before writing
    if (await file.exists()) {
      try {
        await file.copy('${file.path}.bak');
      } catch (e) {
        print('Failed to create backup: $e');
      }
    }
    
    final String encodedData = jsonEncode(entries.map((e) => e.toJson()).toList());
    await file.writeAsString(encodedData);
  }

  /// Get all daily entries
  Future<List<DailyEntry>> getDailyEntries() async {
    try {
      final file = await _dailyEntriesFile;
      if (!await file.exists()) {
        // Try migration first
        await migrateToNewFormat();
        if (!await file.exists()) return [];
      }
      
      final String data = await file.readAsString();
      if (data.isEmpty) return [];
      
      final List<dynamic> decodedData = jsonDecode(data);
      return decodedData.map((e) => DailyEntry.fromJson(e)).toList();
    } catch (e) {
      print('Error reading daily entries: $e');
      return [];
    }
  }

  /// Update an existing daily entry
  Future<void> updateDailyEntry(DailyEntry updatedEntry) async {
    final entries = await getDailyEntries();
    final index = entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      entries[index] = updatedEntry;
      final file = await _dailyEntriesFile;
      
      // Backup before write
      if (await file.exists()) {
        await file.copy('${file.path}.bak');
      }
      
      final String encodedData = jsonEncode(entries.map((e) => e.toJson()).toList());
      await file.writeAsString(encodedData);
    }
  }

  /// Delete a daily entry
  Future<void> deleteDailyEntry(String id) async {
    final entries = await getDailyEntries();
    entries.removeWhere((e) => e.id == id);
    
    final file = await _dailyEntriesFile;
    
    // Backup before write
    if (await file.exists()) {
      await file.copy('${file.path}.bak');
    }
    
    final String encodedData = jsonEncode(entries.map((e) => e.toJson()).toList());
    await file.writeAsString(encodedData);
  }

  /// Get entry for a specific date
  Future<DailyEntry?> getDailyEntryForDate(DateTime date) async {
    final entries = await getDailyEntries();
    final targetDate = DateTime(date.year, date.month, date.day);
    
    try {
      return entries.firstWhere((e) {
        final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
        return entryDate.isAtSameMomentAs(targetDate);
      });
    } catch (e) {
      return null;
    }
  }

  /// Check if today's entry exists
  Future<bool> hasTodayEntry() async {
    final entry = await getDailyEntryForDate(DateTime.now());
    return entry != null && entry.hasAnyAnswer;
  }

  Future<int> calculateStreak() async {
    try {
      // Try new format first
      var dailyEntries = await getDailyEntries();
      
      if (dailyEntries.isEmpty) {
        // Fallback to old format
        final oldEntries = await getEntries();
        if (oldEntries.isEmpty) return 0;
        
        // Sort entries by date descending
        oldEntries.sort((a, b) => b.date.compareTo(a.date));
        return _calculateStreakFromDates(oldEntries.map((e) => e.date).toList());
      }
      
      // Sort daily entries by date descending
      dailyEntries.sort((a, b) => b.date.compareTo(a.date));
      return _calculateStreakFromDates(dailyEntries.map((e) => e.date).toList());
    } catch (e) {
      return 0;
    }
  }

  int _calculateStreakFromDates(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    
    int streak = 0;
    DateTime? lastDate;

    // Get today's date at midnight
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final date in dates) {
      final entryDate = DateTime(date.year, date.month, date.day);

      if (lastDate == null) {
        // If the most recent entry is today or yesterday, start streak
        if (entryDate.isAtSameMomentAs(today) || entryDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
          streak = 1;
          lastDate = entryDate;
        } else {
          // Streak broken if last entry is older than yesterday
          return 0;
        }
      } else {
        // Check if this entry is exactly 1 day before the last processed date
        if (entryDate.isAtSameMomentAs(lastDate.subtract(const Duration(days: 1)))) {
          streak++;
          lastDate = entryDate;
        } else if (entryDate.isBefore(lastDate.subtract(const Duration(days: 1)))) {
          // Gap detected
          break;
        }
        // If same day, ignore (multiple entries per day don't increase streak)
      }
    }

    return streak;
  }
}

