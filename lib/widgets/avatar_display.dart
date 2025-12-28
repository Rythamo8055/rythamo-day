import 'package:flutter/material.dart';
import 'package:flutter_notion_avatar/flutter_notion_avatar.dart';
import 'package:journal_app/services/avatar_service.dart';
import 'dart:io';

/// A widget that displays an avatar based on AvatarConfig
/// Can show either a Notion Avatar or a custom photo
class AvatarDisplay extends StatelessWidget {
  final AvatarConfig config;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  
  const AvatarDisplay({
    super.key,
    required this.config,
    this.size = 80,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.cardColor,
        shape: BoxShape.circle,
        border: showBorder 
            ? Border.all(color: borderColor ?? theme.primaryColor, width: 3)
            : null,
      ),
      child: ClipOval(
        child: config.isCustom && config.customPhotoPath != null
            ? Image.file(
                File(config.customPhotoPath!),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => _buildNotionAvatar(),
              )
            : _buildNotionAvatar(),
      ),
    );
  }
  
  Widget _buildNotionAvatar() {
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

/// A stateful wrapper that loads avatar config automatically
class AvatarDisplayAsync extends StatefulWidget {
  final double size;
  final bool showBorder;
  final Color? borderColor;
  
  const AvatarDisplayAsync({
    super.key,
    this.size = 80,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  State<AvatarDisplayAsync> createState() => _AvatarDisplayAsyncState();
}

class _AvatarDisplayAsyncState extends State<AvatarDisplayAsync> {
  AvatarConfig? _config;
  
  @override
  void initState() {
    super.initState();
    _loadConfig();
  }
  
  Future<void> _loadConfig() async {
    final config = await AvatarService.loadAvatar();
    if (mounted) {
      setState(() {
        _config = config;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_config == null) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    return AvatarDisplay(
      config: _config!,
      size: widget.size,
      showBorder: widget.showBorder,
      borderColor: widget.borderColor,
    );
  }
}
