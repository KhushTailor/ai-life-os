import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/glass_theme.dart';

class GlassSquircleFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final GlassTheme theme;

  const GlassSquircleFab({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.accentColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20), // Squircle effect
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.85), // Almost solid but still slightly glassy
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
