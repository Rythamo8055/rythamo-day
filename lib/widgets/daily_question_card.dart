import 'package:flutter/material.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/widgets/rythamo_card.dart';
import 'package:journal_app/widgets/rythamo_button.dart';

class DailyQuestionCard extends StatelessWidget {
  final String question;
  final VoidCallback onAnswer;

  const DailyQuestionCard({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return RythamoCard(
      color: RythamoColors.salmonOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DAILY QUESTION",
            style: RythamoTypography.header.copyWith(
              color: RythamoColors.darkCharcoalText.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question,
            style: RythamoTypography.metricBig.copyWith(
              fontSize: 32,
              color: RythamoColors.darkCharcoalText,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          RythamoButton(
            text: "Answer",
            onPressed: onAnswer,
            backgroundColor: RythamoColors.darkCharcoalText,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
