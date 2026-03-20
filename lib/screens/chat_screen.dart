import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/glass_theme.dart';
import '../providers/providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Initial message will be added in first build to have the name
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
      _controller.clear();
    });

    try {
      debugPrint("GENERATING AI RESPONSE for: $userMessage");
      final tasks = ref.read(tasksProvider).value ?? [];
      final habits = ref.read(habitsProvider).value ?? [];
      final finance = ref.read(financeProvider).value ?? [];

      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.getChatResponse(
        userMessage,
        context: {
          'tasks': tasks,
          'habits': habits,
          'finance': finance,
        },
      );
      
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'content': response});
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'content': 'Error connecting to AI: $e'});
          _isLoading = false;
        });
      }
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _controller.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = ref.watch(activeThemeProvider);
    final userName = settings.userName;
    
    if (_messages.isEmpty) {
      _messages.add({
        'role': 'ai',
        'content': 'Hello $userName! I am your AI Life Assistant. How can I help you optimize your day today?'
      });
    }

    final isLight = theme.brightness == Brightness.light;
    final textPrimary = isLight ? Colors.black87 : Colors.white;
    final textTertiary = isLight ? Colors.black38 : Colors.white38;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.accentColor, size: 20),
            const SizedBox(width: 10),
            Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ) : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final isUser = _messages[i]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isUser 
                        ? LinearGradient(colors: [theme.accentColor, theme.accentColor.withValues(alpha: 0.7)])
                        : LinearGradient(colors: [
                            isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.1),
                            isLight ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
                          ]),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : null,
                        bottomLeft: !isUser ? const Radius.circular(0) : null,
                      ),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      _messages[i]['content']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Center(child: CircularProgressIndicator(color: theme.accentColor)),
            ),
            
          Padding(
            padding: const EdgeInsets.all(16).copyWith(bottom: 100),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Ask me anything...',
                            hintStyle: TextStyle(color: textTertiary),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none_rounded, color: _isListening ? Colors.redAccent : theme.accentColor),
                        onPressed: _listen,
                      ),
                      IconButton(
                        icon: Icon(Icons.send_rounded, color: theme.accentColor),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
