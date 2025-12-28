import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/widgets/rythamo_button.dart';
import 'package:journal_app/services/media_service.dart';
import 'package:journal_app/services/storage_service.dart';
import 'package:journal_app/models/daily_entry.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';

class DailyQuestionsScreen extends ConsumerStatefulWidget {
  final DailyEntry? existingEntry;

  const DailyQuestionsScreen({
    super.key,
    this.existingEntry,
  });

  @override
  ConsumerState<DailyQuestionsScreen> createState() => _DailyQuestionsScreenState();
}

class _DailyQuestionsScreenState extends ConsumerState<DailyQuestionsScreen> {
  final List<TextEditingController> _answerControllers = [];
  final int _charLimit = 280;
  final MediaService _mediaService = MediaService();
  final StorageService _storageService = StorageService();
  
  List<String> _mediaPaths = [];
  String? _selectedMascot;
  bool _isSaving = false;

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
    
    // Initialize controllers for all 4 questions
    for (int i = 0; i < StorageService.dailyQuestions.length; i++) {
      _answerControllers.add(TextEditingController());
    }
    
    // Load existing entry if editing
    if (widget.existingEntry != null) {
      for (int i = 0; i < widget.existingEntry!.responses.length && i < _answerControllers.length; i++) {
        _answerControllers[i].text = widget.existingEntry!.responses[i].answer;
      }
      _mediaPaths = List.from(widget.existingEntry!.mediaPaths);
      _selectedMascot = widget.existingEntry!.mascot;
    }
  }

  @override
  void dispose() {
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    _mediaService.dispose();
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
                "How are you feeling?",
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
    // Check if at least one question is answered
    bool hasAnyAnswer = _answerControllers.any((c) => c.text.trim().isNotEmpty);
    
    if (!hasAnyAnswer && _mediaPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please answer at least one question or add media!")),
      );
      return;
    }

    // Build responses list
    final responses = <QuestionAnswer>[];
    for (int i = 0; i < StorageService.dailyQuestions.length; i++) {
      responses.add(QuestionAnswer(
        question: StorageService.dailyQuestions[i],
        answer: _answerControllers[i].text.trim(),
      ));
    }

    final entry = DailyEntry(
      id: widget.existingEntry?.id ?? const Uuid().v4(),
      date: widget.existingEntry?.date ?? DateTime.now(),
      responses: responses,
      mediaPaths: _mediaPaths,
      mascot: _selectedMascot,
    );

    if (widget.existingEntry != null) {
      await _storageService.updateDailyEntry(entry);
    } else {
      await _storageService.saveDailyEntry(entry);
    }

    if (mounted) {
      Navigator.pop(context, true);
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
        title: Text(
          "TODAY'S REFLECTION",
          style: RythamoTypography.headerDynamic(textColor),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _selectedMascot != null ? Icons.sentiment_satisfied_alt : Icons.add_reaction_outlined,
              color: _selectedMascot != null ? RythamoColors.salmonOrange : textColor,
            ),
            onPressed: _pickMascot,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected mascot preview
                    if (_selectedMascot != null) ...[
                      Center(
                        child: SizedBox(
                          height: 80,
                          width: 80,
                          child: Lottie.asset(_selectedMascot!),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Questions list
                    ...List.generate(StorageService.dailyQuestions.length, (index) {
                      return _buildQuestionCard(
                        index: index + 1,
                        question: StorageService.dailyQuestions[index],
                        controller: _answerControllers[index],
                        textColor: textColor,
                        cardColor: theme.cardColor,
                      );
                    }),
                    
                    const SizedBox(height: 24),
                    
                    // Media section
                    if (_mediaPaths.isNotEmpty) ...[
                      Text(
                        "ATTACHED MEDIA",
                        style: RythamoTypography.headerDynamic(textColor),
                      ),
                      const SizedBox(height: 12),
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
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: theme.cardColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.audio_file, color: textColor),
                                        );
                                      },
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
                      const SizedBox(height: 24),
                    ],
                    
                    // Media buttons
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
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
                    
                    const SizedBox(height: 100), // Space for FAB
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
          "SAVE REFLECTION",
          style: RythamoTypography.body.copyWith(
            color: RythamoColors.darkCharcoalText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildQuestionCard({
    required int index,
    required String question,
    required TextEditingController controller,
    required Color textColor,
    required Color cardColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: RythamoColors.salmonOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "$index",
                      style: RythamoTypography.bodyDynamic(RythamoColors.salmonOrange).copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    style: RythamoTypography.bodyDynamic(textColor).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLength: _charLimit,
              maxLines: 3,
              minLines: 1,
              style: RythamoTypography.handwritingDynamic(textColor).copyWith(
                fontSize: 18,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: "Your answer...",
                hintStyle: RythamoTypography.bodyDynamic(textColor).copyWith(
                  color: textColor.withOpacity(0.3),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                counterStyle: RythamoTypography.headerDynamic(textColor).copyWith(fontSize: 10),
              ),
            ),
          ],
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
