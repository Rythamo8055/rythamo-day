import 'package:flutter/material.dart';
import 'package:flutter_notion_avatar/flutter_notion_avatar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/services/avatar_service.dart';
import 'dart:io';
import 'dart:math';

class AvatarPicker extends StatefulWidget {
  final AvatarConfig? initialConfig;
  final Function(AvatarConfig) onAvatarSelected;
  
  const AvatarPicker({
    super.key,
    this.initialConfig,
    required this.onAvatarSelected,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  late AvatarConfig _selectedConfig;
  final List<AvatarConfig> _presets = AvatarService.getPresets(count: 12);
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    _selectedConfig = widget.initialConfig ?? AvatarConfig.preset(0);
  }
  
  Future<void> _pickCustomPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final config = AvatarConfig.custom(image.path);
      setState(() {
        _selectedConfig = config;
      });
      widget.onAvatarSelected(config);
    }
  }
  
  void _generateRandomAvatar() {
    final randomConfig = AvatarConfig.notion(
      accessories: _random.nextInt(10),
      eyes: _random.nextInt(10),
      eyebrows: _random.nextInt(10),
      face: _random.nextInt(10),
      glasses: _random.nextInt(10),
      hair: _random.nextInt(10),
      mouth: _random.nextInt(10),
      nose: _random.nextInt(10),
      details: _random.nextInt(10),
      beard: _random.nextInt(10),
    );
    
    setState(() {
      _selectedConfig = randomConfig;
    });
    widget.onAvatarSelected(randomConfig);
  }
  
  void _selectPreset(AvatarConfig config) {
    setState(() {
      _selectedConfig = config;
    });
    widget.onAvatarSelected(config);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : RythamoColors.darkCharcoalText;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with current avatar preview
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                "Choose Your Avatar",
                style: RythamoTypography.grSubhead(textColor),
              ),
              const SizedBox(height: 16),
              
              // Current selection preview
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: RythamoColors.salmonOrange, width: 3),
                ),
                child: ClipOval(
                  child: _selectedConfig.isCustom
                      ? Image.file(
                          File(_selectedConfig.customPhotoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildNotionAvatar(_selectedConfig),
                        )
                      : _buildNotionAvatar(_selectedConfig),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionChip(
                    icon: Icons.shuffle,
                    label: "Random",
                    onTap: _generateRandomAvatar,
                  ),
                  const SizedBox(width: 12),
                  _ActionChip(
                    icon: Icons.photo_library,
                    label: "Upload",
                    onTap: _pickCustomPhoto,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Presets grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _presets.length,
            itemBuilder: (context, index) {
              final preset = _presets[index];
              final isSelected = _selectedConfig == preset || 
                  (_selectedConfig.isNotion && 
                   _selectedConfig.accessories == preset.accessories &&
                   _selectedConfig.hair == preset.hair);
              
              return GestureDetector(
                onTap: () => _selectPreset(preset),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: isSelected 
                        ? Border.all(color: RythamoColors.salmonOrange, width: 3)
                        : Border.all(color: textColor.withOpacity(0.1), width: 1),
                  ),
                  child: ClipOval(
                    child: _buildNotionAvatar(preset),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildNotionAvatar(AvatarConfig config) {
    return NotionAvatar(
      key: ValueKey('${config.accessories}_${config.hair}_${config.eyes}'),
      onCreated: (controller) {
        controller.setAccessories(config.accessories ?? 0);
        controller.setEyes(config.eyes ?? 0);
        controller.setEyebrows(config.eyebrows ?? 0);
        controller.setFace(config.face ?? 0);
        controller.setGlasses(config.glasses ?? 0);
        controller.setHair(config.hair ?? 0);
        controller.setMouth(config.mouth ?? 0);
        controller.setNose(config.nose ?? 0);
        controller.setDetails(config.details ?? 0);
        controller.setBeard(config.beard ?? 0);
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: RythamoColors.salmonOrange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: RythamoColors.salmonOrange),
            const SizedBox(width: 6),
            Text(
              label,
              style: RythamoTypography.grBody(RythamoColors.salmonOrange).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to show avatar picker in a bottom sheet
Future<AvatarConfig?> showAvatarPicker(BuildContext context, {AvatarConfig? currentConfig}) {
  return showModalBottomSheet<AvatarConfig>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      AvatarConfig? selected;
      return Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: AvatarPicker(
                initialConfig: currentConfig,
                onAvatarSelected: (config) {
                  selected = config;
                },
              ),
            ),
            // Confirm button
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, selected ?? currentConfig);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RythamoColors.salmonOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Confirm Selection",
                      style: RythamoTypography.grBody(RythamoColors.darkCharcoalText).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
