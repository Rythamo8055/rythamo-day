import 'dart:io';
import 'package:flutter/material.dart';

enum MediaType { image, video, audio }

class MediaItem extends StatelessWidget {
  final String path;
  final MediaType type;
  final VoidCallback? onDelete;

  const MediaItem({
    super.key,
    required this.path,
    required this.type,
    this.onDelete,
  });

  void _showFullScreenImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.file(File(path)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildContent(context),
        ),
        if (onDelete != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
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
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (type) {
      case MediaType.image:
        return GestureDetector(
          onTap: () => _showFullScreenImage(context),
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );
      case MediaType.video:
        // Video playback removed - show thumbnail placeholder
        return const Center(
          child: Icon(Icons.videocam, color: Colors.grey, size: 40),
        );
      case MediaType.audio:
        // Audio playback removed - show placeholder
        return const Center(
          child: Icon(Icons.audiotrack, color: Colors.grey, size: 40),
        );
    }
  }
}
