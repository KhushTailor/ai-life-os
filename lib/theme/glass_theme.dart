import 'package:flutter/material.dart';

class GlassTheme {
  final String key;
  final String name;
  final List<Color> backgroundGradient;
  final Color accentColor;
  final double blur;
  final Color cardColor;

  GlassTheme({
    required this.key,
    required this.name,
    required this.backgroundGradient,
    required this.accentColor,
    this.blur = 20.0,
    required this.cardColor,
  });

  static Map<String, GlassTheme> themes = {
    'neon_dark': GlassTheme(
      key: 'neon_dark',
      name: 'Neon Dark (Default)',
      backgroundGradient: [const Color(0xFF0F0C29), const Color(0xFF302B63), const Color(0xFF24243E)],
      accentColor: const Color(0xFFBC13FE),
      cardColor: Colors.white.withOpacity(0.1),
    ),
    'teal_glimmer': GlassTheme(
      key: 'teal_glimmer',
      name: 'Teal Glimmer',
      backgroundGradient: [const Color(0xFF134E5E), const Color(0xFF71B280)],
      accentColor: const Color(0xFF00F260),
      cardColor: Colors.white.withOpacity(0.15),
    ),
    'sunset_beach': GlassTheme(
      key: 'sunset_beach',
      name: 'Sunset Beach',
      backgroundGradient: [const Color(0xFF4CA1AF), const Color(0xFFC4E0E5)],
      accentColor: const Color(0xFFFF512F),
      cardColor: Colors.white.withOpacity(0.2),
    ),
    'pastel_sky': GlassTheme(
      key: 'pastel_sky',
      name: 'Pastel Sky',
      backgroundGradient: [const Color(0xFFEBB1FE), const Color(0xFFAD67CF)],
      accentColor: Colors.white,
      cardColor: Colors.white.withOpacity(0.3),
    ),
  };
}
