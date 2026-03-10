import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';

/// A small floating button that opens the Pixy mascot chat.
/// Place this in the MainShellPage's Stack, above the navbar.
class MascotFloatingButton extends StatefulWidget {
  const MascotFloatingButton({super.key});

  @override
  State<MascotFloatingButton> createState() => _MascotFloatingButtonState();
}

class _MascotFloatingButtonState extends State<MascotFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breatheAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _breatheAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => context.push('/mascot-chat'),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text('🤖', style: TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }
}
