import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/glass_theme.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  final GlassTheme activeTheme;
  const ChatScreen({super.key, required this.userName, required this.activeTheme});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  late GenerativeModel _model;
  bool _isAIAvailable = false;
  String _errorMessage = '';
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  bool get _isLight => widget.activeTheme.brightness == Brightness.light;
  Color get _textPrimary => _isLight ? Colors.black87 : Colors.white;
  Color get _textTertiary => _isLight ? Colors.black38 : Colors.white38;
  Color get _borderColor => _isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.1);

  @override
  void initState() {
    super.initState();
    _initAI();
  }

  Future<void> _initAI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('gemini_api_key');
      
      const defaultKey = 'AIzaSyAYfXmUGpvbzT5k_NFPaDOmsm9-WJsjebo';
      final apiKey = (savedKey != null && savedKey.isNotEmpty) ? savedKey : defaultKey;
      
      if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
        setState(() {
          _isAIAvailable = false;
          _errorMessage = 'Gemini API Key is missing or invalid. Please check Settings.';
        });
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
      
      setState(() {
        _isAIAvailable = true;
        _errorMessage = '';
      });
      
      _messages.add({
        'role': 'ai',
        'content': 'Hello ${widget.userName}! I am your AI Life Assistant. How can I help you optimize your day today?'
      });
    } catch (e) {
      setState(() {
        _isAIAvailable = false;
        _errorMessage = 'Error initializing AI: $e';
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty || !_isAIAvailable) return;

    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
      _controller.clear();
    });

    try {
      final content = [Content.text(userMessage)];
      final response = await _model.generateContent(content);
      
      setState(() {
        _messages.add({'role': 'ai', 'content': response.text ?? 'I am sorry, I could not generate a response.'});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'content': 'Error connecting to AI: \n\nCheck your internet connection or API Key. Details: $e'});
        _isLoading = false;
      });
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: widget.activeTheme.accentColor, size: 20),
            const SizedBox(width: 10),
            Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (!_isAIAvailable)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _initAI,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.2)),
                    child: const Text('Retry Connection', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          
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
                        ? LinearGradient(colors: [widget.activeTheme.accentColor, widget.activeTheme.accentColor.withValues(alpha: 0.7)])
                        : LinearGradient(colors: [
                            _isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.1),
                            _isLight ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
                          ]),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : null,
                        bottomLeft: !isUser ? const Radius.circular(0) : null,
                      ),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Text(
                      _messages[i]['content']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : _textPrimary,
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
              child: Center(child: CircularProgressIndicator(color: widget.activeTheme.accentColor)),
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
                    color: _isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: _isAIAvailable,
                          style: TextStyle(color: _textPrimary),
                          decoration: InputDecoration(
                            hintText: _isAIAvailable ? 'Ask me anything...' : 'AI offline',
                            hintStyle: TextStyle(color: _textTertiary),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none_rounded, color: _isListening ? Colors.redAccent : widget.activeTheme.accentColor),
                        onPressed: _listen,
                      ),
                      IconButton(
                        icon: Icon(Icons.send_rounded, color: widget.activeTheme.accentColor),
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
