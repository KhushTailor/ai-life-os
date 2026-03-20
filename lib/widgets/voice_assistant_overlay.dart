import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:ui';
import '../services/voice_service.dart';
import '../theme/glass_theme.dart';

class VoiceAssistantOverlay extends StatefulWidget {
  final GlassTheme theme;
  final Function(VoiceCommand) onCommand;

  const VoiceAssistantOverlay({super.key, required this.theme, required this.onCommand});

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay> with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  String _lastWords = '';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      await _voiceService.listen(
        onResult: (words) {
          setState(() {
            _lastWords = words;
            _isListening = false;
          });
          final command = _voiceService.parseCommand(words);
          widget.onCommand(command);
        },
        onDone: () {
          if (mounted) setState(() => _isListening = false);
        },
      );
    } else {
      _voiceService.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.theme.brightness == Brightness.light;
    final accentColor = widget.theme.accentColor;

    return Positioned(
      right: 20,
      bottom: 110, // Above bottom nav
      child: GestureDetector(
        onLongPressStart: (_) => _listen(),
        onLongPressEnd: (_) => _voiceService.stop(),
        onTap: _listen,
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            double scale = 1.0 + (_isListening ? _animController.value * 0.2 : 0);
            return Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isListening)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: _isListening ? 20 : 10,
                          spreadRadius: _isListening ? 4 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
