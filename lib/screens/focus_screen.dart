import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../theme/glass_theme.dart';

class FocusScreen extends StatefulWidget {
  final GlassTheme activeTheme;
  const FocusScreen({super.key, required this.activeTheme});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  int _secondsRemaining = 25 * 60; // 25 minutes default
  Timer? _timer;
  bool _isRunning = false;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
            _isRunning = false;
          }
        });
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 25 * 60;
      _isRunning = false;
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.activeTheme.backgroundGradient[0].withValues(alpha: 0.8),
              widget.activeTheme.backgroundGradient[1].withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_outlined, color: Colors.white, size: 60),
            const SizedBox(height: 20),
            const Text(
              'DEEP WORK',
              style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // Timer Display
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _formatTime(_secondsRemaining),
                      style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w200, letterSpacing: -2),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: Icons.refresh_rounded, 
                  onTap: _resetTimer,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 30),
                _buildControlButton(
                  icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  onTap: _toggleTimer,
                  color: widget.activeTheme.accentColor,
                  isLarge: true,
                ),
                const SizedBox(width: 30),
                _buildControlButton(
                  icon: Icons.music_note_rounded,
                  onTap: () {}, // Sound toggle coming soon
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('EXIT CONCENTRATION', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onTap, required Color color, bool isLarge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isLarge ? 80 : 60,
        height: isLarge ? 80 : 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            if (isLarge) BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: isLarge ? 40 : 24),
      ),
    );
  }
}
