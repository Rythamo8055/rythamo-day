import 'package:flutter/material.dart';
import 'package:journal_app/theme/rythamo_theme.dart';

class RythamoButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const RythamoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? RythamoColors.salmonOrange,
        foregroundColor: textColor ?? RythamoColors.darkCharcoalText,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: RythamoTypography.buttonText,
      ),
      child: Text(text),
    );
  }
}

class RythamoFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const RythamoFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: RythamoColors.salmonOrange,
      foregroundColor: RythamoColors.darkCharcoalText,
      elevation: 0,
      shape: const CircleBorder(),
      child: Icon(icon, size: 32),
    );
  }
}
