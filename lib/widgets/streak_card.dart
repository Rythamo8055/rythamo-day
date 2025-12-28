import 'package:flutter/material.dart';
import 'package:journal_app/theme/rythamo_theme.dart';
import 'package:journal_app/widgets/rythamo_card.dart';
import 'package:lottie/lottie.dart';

class StreakCard extends StatefulWidget {
  final int streakDays;

  const StreakCard({super.key, required this.streakDays});

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fireController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the number - always animate
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _getPulseDuration()),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: _getPulseIntensity()).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Fire animation controller
    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _fireController, curve: Curves.easeInOut),
    );
    
    // Always start animations (even at 0 for encouragement)
    _pulseController.repeat(reverse: true);
    _fireController.repeat(reverse: true);
  }


  // More intense pulse as streak increases
  double _getPulseIntensity() {
    if (widget.streakDays >= 100) return 1.15;
    if (widget.streakDays >= 30) return 1.12;
    if (widget.streakDays >= 7) return 1.10;
    return 1.06;
  }

  // Faster pulse as streak increases  
  int _getPulseDuration() {
    if (widget.streakDays >= 100) return 800;
    if (widget.streakDays >= 30) return 1000;
    if (widget.streakDays >= 7) return 1200;
    return 1500;
  }

  // Animation size increases with streak
  double _getAnimationSize() {
    if (widget.streakDays >= 100) return 80;
    if (widget.streakDays >= 30) return 70;
    if (widget.streakDays >= 7) return 60;
    if (widget.streakDays > 0) return 50;
    return 40;
  }

  // Get fill color based on streak level - solid colors, more intense as streak grows
  Color _getFillColor() {
    if (widget.streakDays >= 100) return const Color(0xFFFF3B30); // Bright red
    if (widget.streakDays >= 30) return const Color(0xFFFF6B4A); // Coral red
    if (widget.streakDays >= 7) return const Color(0xFFFF8C69); // Salmon
    if (widget.streakDays > 0) return RythamoColors.salmonOrange;
    return Colors.grey.shade700;
  }

  // Opacity increases with streak
  double _getColorOpacity() {
    if (widget.streakDays >= 100) return 1.0;
    if (widget.streakDays >= 30) return 0.9;
    if (widget.streakDays >= 7) return 0.8;
    if (widget.streakDays > 0) return 0.7;
    return 0.3;
  }

  String? _getMilestoneBadge() {
    if (widget.streakDays >= 100) return '💯 LEGEND!';
    if (widget.streakDays >= 30) return '🔥 ON FIRE!';
    if (widget.streakDays >= 7) return '⭐ WEEK STAR';
    if (widget.streakDays >= 3) return '✨ RISING';
    return null;
  }

  @override
  void didUpdateWidget(StreakCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animation parameters when streak changes
    if (oldWidget.streakDays != widget.streakDays) {
      _pulseController.duration = Duration(milliseconds: _getPulseDuration());
      _pulseAnimation = Tween<double>(begin: 1.0, end: _getPulseIntensity()).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );
    }
    
    // Always keep animations running
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
      _fireController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : RythamoColors.darkCharcoalText;
    final milestoneBadge = _getMilestoneBadge();
    final fillColor = _getFillColor();
    final animationSize = _getAnimationSize();

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _fireController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: fillColor.withOpacity(_getColorOpacity()),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: fillColor.withOpacity(0.4),
                blurRadius: 16 + (widget.streakDays.clamp(0, 30) * 0.5),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.streakDays == 0 ? "START" : "STREAK",
                          style: RythamoTypography.grCaption(
                            Colors.white,
                          ).copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Text(
                            "${widget.streakDays}",
                            style: RythamoTypography.grDisplay(
                              Colors.white,
                            ).copyWith(
                              fontSize: RythamoTypography.displaySize * 0.8,
                              fontWeight: FontWeight.w900,
                              shadows: widget.streakDays >= 7 ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ] : null,
                            ),
                          ),
                        ),
                        Text(
                          widget.streakDays == 0 ? "Today!" : (widget.streakDays == 1 ? "Day" : "Days"),
                          style: RythamoTypography.grBody(
                            Colors.white.withOpacity(0.8),
                          ).copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Animation - shows at all levels
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: SizedBox(
                        width: animationSize,
                        height: animationSize,
                        child: widget.streakDays == 0
                            ? Lottie.asset(
                                'assets/mascot/greeting.json',
                                fit: BoxFit.contain,
                              )
                            : Lottie.network(
                                'https://assets2.lottiefiles.com/packages/lf20_xsnczm6v.json', // Fire animation
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to mascot if network fails
                              return Lottie.asset(
                                'assets/mascot/excited.json',
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                if (milestoneBadge != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      milestoneBadge,
                      style: RythamoTypography.grCaption(Colors.white).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
