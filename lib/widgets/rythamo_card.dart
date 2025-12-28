import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:journal_app/theme/rythamo_theme.dart';

class RythamoCard extends ConsumerWidget {
  final Widget child;
  final Color? color;
  final double? height;
  final VoidCallback? onTap;
  final bool hasShadow;

  const RythamoCard({
    super.key,
    required this.child,
    this.color,
    this.height,
    this.onTap,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final theme = Theme.of(context);
    
    // Determine card color
    final cardColor = color ?? theme.cardColor;
    
    // Determine shadow color based on theme mode and card color
    Color shadowColor;
    if (themeMode != RythamoThemeMode.latte) {
      shadowColor = Colors.black.withOpacity(0.5); // Dark mode: standard dark shadow
    } else {
      // Light modes: Tone-on-Tone shadow
      // If card is white/light, use a soft grey/color shadow
      // If card is colored, use a darker shade of that color
      if (cardColor == Colors.white) {
        shadowColor = theme.primaryColor.withOpacity(0.2);
      } else {
        // Simple darkening for tone-on-tone
        final hsl = HSLColor.fromColor(cardColor);
        shadowColor = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor().withOpacity(0.4);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: hasShadow ? [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 8),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ] : null,
        ),
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}
