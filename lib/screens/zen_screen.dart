import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:async';
import '../theme/glass_theme.dart';
import 'package:just_audio/just_audio.dart';

class ZenScreen extends ConsumerStatefulWidget {
  final GlassTheme theme;
  const ZenScreen({super.key, required this.theme});

  @override
  ConsumerState<ZenScreen> createState() => _ZenScreenState();
}

class _ZenScreenState extends ConsumerState<ZenScreen> with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;
  String _phase = 'Inhale';
  int _seconds = 0;
  Timer? _timer;
  late AudioPlayer _audioPlayer;

  final List<Map<String, dynamic>> _sounds = [
    {
      'name': 'Rain', 
      'icon': Icons.grain_rounded, 
      'color': Colors.blue,
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3' // Placeholder, actually should be a loop
    },
    {
      'name': 'Forest', 
      'icon': Icons.forest_rounded, 
      'color': Colors.green,
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'
    },
    {
      'name': 'Waves', 
      'icon': Icons.waves_rounded, 
      'color': Colors.cyan,
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'
    },
    {
      'name': 'Fire', 
      'icon': Icons.fireplace_rounded, 
      'color': Colors.orange,
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3'
    },
  ];
  int _selectedSound = -1; // -1 for none

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setLoopMode(LoopMode.one);

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breatheAnimation = Tween<double>(begin: 0.6, end: 1.1).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _breatheController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _phase = 'Exhale');
        _breatheController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (mounted) setState(() => _phase = 'Inhale');
        _breatheController.forward();
      }
    });

    _breatheController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _playSelectedSound(int index) async {
    if (_selectedSound == index) {
      await _audioPlayer.stop();
      setState(() => _selectedSound = -1);
      return;
    }

    setState(() => _selectedSound = index);
    try {
      await _audioPlayer.setUrl(_sounds[index]['url']);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _timer?.cancel();
    _audioPlayer.dispose();
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
          
          LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final circleSize = (availableHeight * 0.4).clamp(150.0, 300.0);

              return SafeArea(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availableHeight - MediaQuery.of(context).padding.top),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
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
                              width: circleSize * _breatheAnimation.value,
                              height: circleSize * _breatheAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: widget.theme.accentColor.withValues(alpha: 0.3), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.theme.accentColor.withValues(alpha: 0.1),
                                    blurRadius: (circleSize / 7.5) * _breatheAnimation.value,
                                    spreadRadius: (circleSize / 30) * _breatheAnimation.value,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: circleSize * 0.65,
                                  height: circleSize * 0.65,
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
                                          style: TextStyle(color: Colors.white, fontSize: circleSize * 0.08, fontWeight: FontWeight.w300, letterSpacing: 2),
                                        ),
                                        SizedBox(height: circleSize * 0.02),
                                        Text(
                                          '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: circleSize * 0.045),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: _sounds.asMap().entries.map((e) {
                                final i = e.key;
                                final s = e.value;
                                final isSelected = _selectedSound == i;
                                return GestureDetector(
                                  onTap: () => _playSelectedSound(i),
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
                        ),
                        
                        const SizedBox(height: 20),
                        
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
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
}
