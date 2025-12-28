import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/providers/theme_provider.dart';
import 'package:journal_app/theme/rythamo_theme.dart';

class FloatingDock extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isVisible;

  const FloatingDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final theme = Theme.of(context);
    
    // Determine dock colors based on theme
    Color dockColor;
    Color iconColor;
    Color activeIconColor;
    
    if (themeMode == RythamoThemeMode.latte) {
      dockColor = Colors.white.withOpacity(0.8);
      iconColor = RythamoColors.darkCharcoalText.withOpacity(0.5);
      activeIconColor = RythamoColors.darkCharcoalText;
    } else {
      dockColor = theme.cardColor.withOpacity(0.8);
      iconColor = Colors.white.withOpacity(0.5);
      activeIconColor = Colors.white;
    }

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      offset: isVisible ? Offset.zero : const Offset(0, 2),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24), // Consistent bottom margin
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 72, // Fixed height
              width: 280,
              decoration: BoxDecoration(
                color: dockColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: themeMode != RythamoThemeMode.latte 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.black.withOpacity(0.05), 
                  width: 1
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DockIcon(
                    icon: Icons.home_rounded, 
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                    color: iconColor,
                    activeColor: activeIconColor,
                  ),
                  _DockIcon(
                    icon: Icons.calendar_today_rounded, 
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                    color: iconColor,
                    activeColor: activeIconColor,
                  ),
                  _DockIcon(
                    icon: Icons.person_rounded, 
                    isSelected: currentIndex == 2,
                    onTap: () => onTap(2),
                    color: iconColor,
                    activeColor: activeIconColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final Color activeColor;

  const _DockIcon({
    required this.icon, 
    required this.isSelected,
    required this.onTap,
    required this.color,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Icon(
          icon,
          color: isSelected ? activeColor : color,
          size: 24,
        ),
      ),
    );
  }
}
