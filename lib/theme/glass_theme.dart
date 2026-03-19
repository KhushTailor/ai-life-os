import 'package:flutter/material.dart';

class GlassTheme {
  final String key;
  final String name;
  final String description;
  final List<Color> backgroundGradient;
  final Color accentColor;
  final double blur;
  final Color cardColor;
  final double cardBorderRadius;
  final Color textColor;
  final Color subtextColor;

  GlassTheme({
    required this.key,
    required this.name,
    required this.description,
    required this.backgroundGradient,
    required this.accentColor,
    this.blur = 20.0,
    required this.cardColor,
    this.cardBorderRadius = 20.0,
    this.textColor = Colors.white,
    this.subtextColor = const Color(0xAAFFFFFF),
  });

  static Map<String, GlassTheme> themes = {
    'neon_dark': GlassTheme(
      key: 'neon_dark',
      name: 'Neon Dark',
      description: 'Deep purple glassmorphism with neon accents',
      backgroundGradient: [const Color(0xFF0F0C29), const Color(0xFF302B63), const Color(0xFF24243E)],
      accentColor: const Color(0xFFBC13FE),
      cardColor: Colors.white.withOpacity(0.08),
      blur: 20.0,
      cardBorderRadius: 20.0,
    ),
    'midnight_ocean': GlassTheme(
      key: 'midnight_ocean',
      name: 'Midnight Ocean',
      description: 'Deep navy with cyan glow & aquatic feel',
      backgroundGradient: [const Color(0xFF0D1B2A), const Color(0xFF1B2838), const Color(0xFF0A192F)],
      accentColor: const Color(0xFF00D4FF),
      cardColor: const Color(0xFF00D4FF).withOpacity(0.08),
      blur: 25.0,
      cardBorderRadius: 16.0,
    ),
    'cyber_punk': GlassTheme(
      key: 'cyber_punk',
      name: 'Cyber Punk',
      description: 'High contrast black & neon red/yellow grid',
      backgroundGradient: [const Color(0xFF0A0A0A), const Color(0xFF1A0A0A), const Color(0xFF0A0505)],
      accentColor: const Color(0xFFFF003C),
      cardColor: const Color(0xFFFF003C).withOpacity(0.06),
      blur: 12.0,
      cardBorderRadius: 8.0,
    ),
    'aurora_frost': GlassTheme(
      key: 'aurora_frost',
      name: 'Aurora Frost',
      description: 'Icy arctic greens with frosted glass panels',
      backgroundGradient: [const Color(0xFF0B1D26), const Color(0xFF122D3E), const Color(0xFF1A3A4A)],
      accentColor: const Color(0xFF00FFA3),
      cardColor: Colors.white.withOpacity(0.12),
      blur: 30.0,
      cardBorderRadius: 24.0,
    ),
    'sunset_blaze': GlassTheme(
      key: 'sunset_blaze',
      name: 'Sunset Blaze',
      description: 'Warm oranges & reds with soft golden glow',
      backgroundGradient: [const Color(0xFF1A0A00), const Color(0xFF2D1810), const Color(0xFF3D1F15)],
      accentColor: const Color(0xFFFF6B35),
      cardColor: const Color(0xFFFF6B35).withOpacity(0.08),
      blur: 18.0,
      cardBorderRadius: 22.0,
    ),
    'minimal_steel': GlassTheme(
      key: 'minimal_steel',
      name: 'Minimal Steel',
      description: 'Clean monochrome with sharp metallic edges',
      backgroundGradient: [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)],
      accentColor: const Color(0xFFE0E0E0),
      cardColor: Colors.white.withOpacity(0.06),
      blur: 15.0,
      cardBorderRadius: 12.0,
    ),
  };
}
