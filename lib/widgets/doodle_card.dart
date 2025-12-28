import 'package:flutter/material.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/screens/mood_screen.dart';
import 'package:journal_app/utils/page_transitions.dart';
import 'package:lottie/lottie.dart';

class DoodleCard extends StatelessWidget {
  final Color? cardColor;
  
  const DoodleCard({super.key, this.cardColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : RythamoColors.darkCharcoalText;
    final bgColor = cardColor ?? RythamoColors.mintGreen;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransitions.slideUp(const MoodScreen()),
        );
      },
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: RythamoColors.mintGreen.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "MOOD",
              style: RythamoTypography.grCaption(textColor).copyWith(
                color: RythamoColors.mintGreen,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Center(
              child: SizedBox(
                width: 70,
                height: 70,
                // Use network Lottie for animated emoji
                child: Lottie.network(
                  'https://assets5.lottiefiles.com/packages/lf20_UJNc2t.json', // Smiling emoji
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      size: 60,
                      color: RythamoColors.mintGreen,
                    );
                  },
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                "How are you feeling?",
                style: RythamoTypography.grCaption(textColor).copyWith(
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
