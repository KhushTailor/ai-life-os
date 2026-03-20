import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

enum VoiceIntent {
  addTask,
  addHabit,
  addExpense,
  navigate,
  changeTheme,
  startFocus,
  askAI,
  queryData,
  unknown,
}

class VoiceCommand {
  final VoiceIntent intent;
  final String? payload;
  final Map<String, dynamic>? data;

  VoiceCommand({required this.intent, this.payload, this.data});
}

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (val) => debugPrint('Error: $val'),
      onStatus: (val) => debugPrint('Status: $val'),
    );
    return _isInitialized;
  }

  Future<void> listen({required Function(String) onResult, required VoidCallback onDone}) async {
    if (!_isInitialized) await initialize();
    
    await _speech.listen(
      onResult: (val) {
        if (val.finalResult) {
          onResult(val.recognizedWords);
          onDone();
        }
      },
    );
  }

  void stop() {
    _speech.stop();
  }

  VoiceCommand parseCommand(String text) {
    text = text.toLowerCase();

    // Navigation
    if (text.contains('go to') || text.contains('show') || text.contains('open')) {
      if (text.contains('habit')) return VoiceCommand(intent: VoiceIntent.navigate, payload: '3');
      if (text.contains('finance') || text.contains('money')) return VoiceCommand(intent: VoiceIntent.navigate, payload: '4');
      if (text.contains('task') || text.contains('plan')) return VoiceCommand(intent: VoiceIntent.navigate, payload: '2');
      if (text.contains('chat') || text.contains('ai')) return VoiceCommand(intent: VoiceIntent.navigate, payload: '1');
      if (text.contains('setting')) return VoiceCommand(intent: VoiceIntent.navigate, payload: '5');
      if (text.contains('home') || text.contains('dash')) return VoiceCommand(intent: VoiceIntent.navigate, payload: '0');
      if (text.contains('zen')) return VoiceCommand(intent: VoiceIntent.navigate, payload: '6');
      if (text.contains('insight') || text.contains('score')) return VoiceCommand(intent: VoiceIntent.navigate, payload: '7');
    }

    // Focus Control
    if (text.contains('start focus') || text.contains('start timer') || text.contains('start work')) {
      return VoiceCommand(intent: VoiceIntent.startFocus, payload: '25'); // Default 25 min
    }

    // AI Trigger
    if (text.contains('ask ai') || text.contains('tell me')) {
      String query = text.replaceAll('ask ai', '').replaceAll('tell me', '').trim();
      return VoiceCommand(intent: VoiceIntent.askAI, payload: query);
    }

    // Queries
    if (text.contains('how many task') || text.contains('what is my next task')) {
      return VoiceCommand(intent: VoiceIntent.queryData, payload: 'tasks');
    }
    if (text.contains('how much') || text.contains('spending')) {
      return VoiceCommand(intent: VoiceIntent.queryData, payload: 'finance');
    }

    // Theme
    if (text.contains('theme') || text.contains('look')) {
      if (text.contains('nebula')) return VoiceCommand(intent: VoiceIntent.changeTheme, payload: 'nebula_deep');
      if (text.contains('midnight')) return VoiceCommand(intent: VoiceIntent.changeTheme, payload: 'midnight_glow');
      if (text.contains('amethyst')) return VoiceCommand(intent: VoiceIntent.changeTheme, payload: 'amethyst_dusk');
      if (text.contains('sunrise')) return VoiceCommand(intent: VoiceIntent.changeTheme, payload: 'solar_sunrise');
    }

    // Add Task
    if (text.contains('add task') || text.contains('remind me to')) {
      String task = text.replaceAll('add task', '').replaceAll('remind me to', '').trim();
      return VoiceCommand(intent: VoiceIntent.addTask, payload: task);
    }

    // Add Habit
    if (text.contains('add habit') || text.contains('start habit')) {
      String habit = text.replaceAll('add habit', '').replaceAll('start habit', '').trim();
      return VoiceCommand(intent: VoiceIntent.addHabit, payload: habit);
    }

    // Add Expense
    if (text.contains('log expense') || text.contains('spent')) {
      // Regex to find numbers
      final regex = RegExp(r'\d+');
      final match = regex.firstMatch(text);
      if (match != null) {
        double? amount = double.tryParse(match.group(0)!);
        String desc = text.replaceAll(regex, '').replaceAll('log expense', '').replaceAll('spent', '').trim();
        return VoiceCommand(intent: VoiceIntent.addExpense, data: {'amount': -(amount ?? 0), 'title': desc});
      }
    }

    return VoiceCommand(intent: VoiceIntent.unknown, payload: text);
  }
}
