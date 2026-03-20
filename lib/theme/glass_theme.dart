import 'package:flutter/material.dart';

class GlassTheme {
  final String key;
  final String name;
  final String description;
  final List<Color> backgroundGradient; // Scaffold background
  final List<Color> cardGradient;       // Card background
  final Color accentColor;
  final double blur;
  final double opacity;
  final double cardBorderRadius;
  final Brightness brightness;

  GlassTheme({
    required this.key,
    required this.name,
    required this.description,
    required this.backgroundGradient,
    required this.cardGradient,
    required this.accentColor,
    this.blur = 20.0,
    this.opacity = 0.1,
    this.cardBorderRadius = 24.0,
    this.brightness = Brightness.dark,
  });

  bool get isLight => brightness == Brightness.light;
  Color get textPrimary => isLight ? Colors.black87 : Colors.white;
  Color get textSecondary => isLight ? Colors.black54 : Colors.white70;
  Color get textTertiary => isLight ? Colors.black38 : Colors.white54;

  static Map<String, GlassTheme> themes = {
    'nebula_deep': GlassTheme(
      key: 'nebula_deep',
      name: 'Nebula Deep',
      description: 'Cosmic purples with frosted high-blur glass',
      backgroundGradient: [const Color(0xFF0F0C29), const Color(0xFF302B63), const Color(0xFF24243E)],
      cardGradient: [Colors.white.withValues(alpha: 0.12), Colors.white.withValues(alpha: 0.04)],
      accentColor: const Color(0xFFBC13FE),
      blur: 30.0,
      opacity: 0.15,
    ),
    'emerald_frost': GlassTheme(
      key: 'emerald_frost',
      name: 'Emerald Frost',
      description: 'Crisp arctic greens with subtle crystal edges',
      backgroundGradient: [const Color(0xFF0D1F1F), const Color(0xFF1A3A3A), const Color(0xFF0B1A1A)],
      cardGradient: [const Color(0xFF00FFA3).withValues(alpha: 0.1), const Color(0xFF00FFA3).withValues(alpha: 0.02)],
      accentColor: const Color(0xFF00FFA3),
      blur: 20.0,
      opacity: 0.08,
    ),
    'ruby_neon': GlassTheme(
      key: 'ruby_neon',
      name: 'Ruby Neon',
      description: 'High-energy red pulse with sleek dark glass',
      backgroundGradient: [const Color(0xFF1A0505), const Color(0xFF2D0A0A), const Color(0xFF0F0505)],
      cardGradient: [const Color(0xFFFF003C).withValues(alpha: 0.08), const Color(0xFFFF003C).withValues(alpha: 0.01)],
      accentColor: const Color(0xFFFF003C),
      blur: 15.0,
      opacity: 0.06,
      cardBorderRadius: 12.0,
    ),
    'crystal_light': GlassTheme(
      key: 'crystal_light',
      name: 'Crystal Light',
      description: 'Clean, airy glass on a soft morning sky',
      backgroundGradient: [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)],
      cardGradient: [Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0.3)],
      accentColor: const Color(0xFF4A90E2),
      blur: 25.0,
      opacity: 0.4,
      brightness: Brightness.light,
    ),
    'onyx_stealth': GlassTheme(
      key: 'onyx_stealth',
      name: 'Onyx Stealth',
      description: 'Pure black depths with vibrant neon borders',
      backgroundGradient: [Colors.black, const Color(0xFF0A0A0A)],
      cardGradient: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
      accentColor: const Color(0xFF00D4FF),
      blur: 10.0,
      opacity: 0.04,
      cardBorderRadius: 16.0,
    ),
  };
}
