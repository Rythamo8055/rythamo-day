import 'package:flutter/material.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/widgets/rythamo_card.dart';

class ConversationalInsightCard extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const ConversationalInsightCard({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return RythamoCard(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.smart_toy_rounded, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    message,
                    style: RythamoTypography.body.copyWith(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ActionChip(
              label: Text(actionLabel),
              onPressed: onAction,
              backgroundColor: RythamoColors.salmonOrange,
              labelStyle: RythamoTypography.buttonText.copyWith(fontSize: 12),
              shape: const StadiumBorder(),
              side: BorderSide.none,
            ),
          ),
        ],
      ),
    );
  }
}
