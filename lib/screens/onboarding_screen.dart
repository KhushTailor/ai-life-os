import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/glass_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'AI LIFE OS',
      'subtitle': 'The intelligent core for your modern existence.',
      'description': 'A Super-App that thinks, plans, and executes on your behalf.',
    },
    {
      'title': 'GLOBAL VOICE',
      'subtitle': 'Control everything with natural speech.',
      'description': 'Just speak to add tasks, log expenses, or switch themes.',
    },
    {
      'title': 'ZEN IMMERSION',
      'subtitle': 'Peak focus in a glassmorphic world.',
      'description': 'Enter deep work states with breathing guides and nature sounds.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _animController.reverse().then((_) {
        setState(() => _currentPage++);
        _animController.forward();
      });
    } else {
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFF1A1A2E), Colors.black],
                  center: Alignment.center,
                  radius: 1.5,
                ),
              ),
            ),
          ),
          
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _pages[_currentPage]['title']!,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _pages[_currentPage]['subtitle']!,
                      style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w300),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _pages[_currentPage]['description']!,
                      style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index ? Colors.white : Colors.white24,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'GET STARTED' : 'CONTINUE',
                      style: const TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
