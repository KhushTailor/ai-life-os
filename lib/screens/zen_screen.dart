import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../theme/glass_theme.dart';

class ZenScreen extends StatefulWidget {
  final GlassTheme theme;
  const ZenScreen({super.key, required this.theme});

  @override
  State<ZenScreen> createState() => _ZenScreenState();
}

class _ZenScreenState extends State<ZenScreen> with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;
  String _phase = 'Inhale';
  int _seconds = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _sounds = [
    {'name': 'Rain', 'icon': Icons.grain_rounded, 'color': Colors.blue},
    {'name': 'Forest', 'icon': Icons.forest_rounded, 'color': Colors.green},
    {'name': 'Waves', 'icon': Icons.waves_rounded, 'color': Colors.cyan},
    {'name': 'Fire', 'icon': Icons.fireplace_rounded, 'color': Colors.orange},
  ];
  int _selectedSound = 0;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breatheAnimation = Tween<double>(begin: 0.6, end: 1.1).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _breatheController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _phase = 'Exhale');
        _breatheController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _phase = 'Inhale');
        _breatheController.forward();
      }
    });

    _breatheController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated Background
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    widget.theme.accentColor.withValues(alpha: 0.15),
                    Colors.black,
                  ],
                  center: Alignment.center,
                  radius: 1.5,
                ),
              ),
            ),
          ),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Text(
                'ZEN MODE',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), letterSpacing: 8, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              
              // Breathing Circle
              AnimatedBuilder(
                animation: _breatheAnimation,
                builder: (context, child) {
                  return Container(
                    width: 300 * _breatheAnimation.value,
                    height: 300 * _breatheAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.theme.accentColor.withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: widget.theme.accentColor.withValues(alpha: 0.1),
                          blurRadius: 40 * _breatheAnimation.value,
                          spreadRadius: 10 * _breatheAnimation.value,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.theme.accentColor.withValues(alpha: 0.05),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _phase,
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300, letterSpacing: 2),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const Spacer(),
              
              // Sound Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: _sounds.asMap().entries.map((e) {
                    final i = e.key;
                    final s = e.value;
                    final isSelected = _selectedSound == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSound = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? s['color'].withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? s['color'] : Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Icon(s['icon'], color: isSelected ? s['color'] : Colors.white, size: 24),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 50),
              
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text('EXIT SILENCE', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11, letterSpacing: 3)),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ],
      ),
    );
  }
}
