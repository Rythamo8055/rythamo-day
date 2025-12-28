import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:journal_app/theme/rythamo_theme.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String lottiePath;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.lottiePath = 'assets/mascot/idle.json',
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // We can access theme mode via provider if needed, but for now we'll use context theme colors
    // Assuming the parent passes correct context or we use Theme.of(context)
    
    // Determine text color - simple heuristic or passed in
    final textColor = theme.brightness == Brightness.dark ? Colors.white : RythamoColors.darkCharcoalText;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 250,
                width: 250,
                child: Lottie.asset(lottiePath),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: RythamoTypography.headerDynamic(textColor),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: RythamoTypography.bodyDynamic(textColor).copyWith(
                  color: textColor.withOpacity(0.7),
                ),
              ),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RythamoColors.salmonOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: RythamoTypography.bodyDynamic(RythamoColors.darkCharcoalText).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
