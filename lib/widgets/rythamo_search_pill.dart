import 'package:flutter/material.dart';
import 'package:journal_app/theme/rythamo_theme.dart';

class RythamoSearchPill extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const RythamoSearchPill({
    super.key,
    this.hintText = "Search...",
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(100), // Exaggerated pill shape
      ),
      padding: const EdgeInsets.only(left: 24, right: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: RythamoTypography.bodyDynamic(Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: RythamoTypography.bodyDynamic(Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white).copyWith(
                  color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white).withOpacity(0.3),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: RythamoColors.salmonOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search,
              color: RythamoColors.darkCharcoalText,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
