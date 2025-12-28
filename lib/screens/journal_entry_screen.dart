
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/widgets/rythamo_button.dart';
import 'package:journal_app/widgets/media_item.dart';
import 'package:journal_app/services/media_service.dart';
import 'package:journal_app/services/storage_service.dart';
import 'package:journal_app/models/journal_entry.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  final String question;
  final JournalEntry? entry;

  const JournalEntryScreen({
    super.key, 
    required this.question,
    this.entry,
  });

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  final TextEditingController _answerController = TextEditingController();
  final int _charLimit = 280;
  final MediaService _mediaService = MediaService();
  final StorageService _storageService = StorageService();
  
  List<String> _mediaPaths = [];
  String? _selectedMascot;


  final List<String> _mascots = [
    'assets/mascot/celebrating.json',
    'assets/mascot/confused.json',
    'assets/mascot/excited.json',
    'assets/mascot/greeting.json',
    'assets/mascot/idle.json',
    'assets/mascot/jumping.json',
    'assets/mascot/loading.json',
    'assets/mascot/reading.json',
    'assets/mascot/sad.json',
    'assets/mascot/sleeping.json',
    'assets/mascot/teaching.json',
    'assets/mascot/thinking.json',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _answerController.text = widget.entry!.answer;
      _mediaPaths = List.from(widget.entry!.mediaPaths);
      _selectedMascot = widget.entry!.mascot;
    }
  }

  @override
  void dispose() {
    _mediaService.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final path = await _mediaService.pickImage(source);
    if (path != null) {
      setState(() {
        _mediaPaths.add(path);
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final path = await _mediaService.pickVideo(source);
    if (path != null) {
      setState(() {
        _mediaPaths.add(path);
      });
    }
  }



  void _pickMascot() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Choose a Mascot",
                style: RythamoTypography.headerDynamic(Theme.of(context).textTheme.bodyMedium!.color!),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _mascots.length,
                itemBuilder: (context, index) {
                  final mascot = _mascots[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMascot = mascot;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: _selectedMascot == mascot
                            ? Border.all(color: RythamoColors.salmonOrange, width: 2)
                            : null,
                      ),
                      child: Lottie.asset(mascot),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEntry() async {
    if (_answerController.text.isEmpty && _mediaPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write something or add media!")),
      );
      return;
    }

    final entry = JournalEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      date: widget.entry?.date ?? DateTime.now(),
      question: widget.question,
      answer: _answerController.text,
      mediaPaths: _mediaPaths,
      mascot: _selectedMascot,
    );

    if (widget.entry != null) {
      await _storageService.updateEntry(entry);
    } else {
      await _storageService.saveEntry(entry);
    }

    if (mounted) {
      Navigator.pop(context);
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
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S QUESTION",
                      style: RythamoTypography.headerDynamic(textColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.question,
                      style: RythamoTypography.metricBigDynamic(textColor).copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      height: 400, // Fixed height for input area to ensure scrolling
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _answerController,
                              maxLength: _charLimit,
                              maxLines: null,
                              style: RythamoTypography.handwritingDynamic(textColor).copyWith(fontSize: 24, height: 1.5),
                              decoration: InputDecoration(
                                hintText: "Type your answer here...",
                                hintStyle: RythamoTypography.bodyDynamic(textColor).copyWith(
                                  color: textColor.withOpacity(0.3),
                                ),
                                border: InputBorder.none,
                                counterStyle: RythamoTypography.headerDynamic(textColor),
                              ),
                            ),
                          ),
                         // Media Grid
              if (_mediaPaths.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mediaPaths.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_mediaPaths[index]),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _mediaPaths.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Media Buttons Row (Centered)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: textColor.withOpacity(0.1)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MediaButton(
                          icon: Icons.camera_alt_rounded, 
                          onTap: () => _pickImage(ImageSource.camera),
                          color: textColor,
                        ),
                        const SizedBox(width: 8),
                        _MediaButton(
                          icon: Icons.videocam_rounded, 
                          onTap: () => _pickVideo(ImageSource.camera),
                          color: textColor,
                        ),
                        const SizedBox(width: 8),
                        _MediaButton(
                          icon: Icons.photo_library_rounded, 
                          onTap: () => _pickImage(ImageSource.gallery),
                          color: textColor,
                        ),
                      ],
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveEntry,
        backgroundColor: RythamoColors.salmonOrange,
        icon: const Icon(Icons.check, color: RythamoColors.darkCharcoalText),
        label: Text(
          "SAVE ENTRY",
          style: RythamoTypography.body.copyWith(
            color: RythamoColors.darkCharcoalText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final Color color;

  const _MediaButton({
    required this.icon, 
    required this.onTap,
    this.isActive = false,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? RythamoColors.salmonOrange : color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? RythamoColors.darkCharcoalText : color,
          size: 20,
        ),
      ),
    );
  }
}
