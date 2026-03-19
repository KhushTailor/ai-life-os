import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:ui';

class ChatScreen extends StatefulWidget {
  final String userName;
  const ChatScreen({super.key, required this.userName});

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

  @override
  void initState() {
    super.initState();
    _initAI();
  }

  void _initAI() {
    try {
      const apiKey = 'AIzaSyAYfXmUGpvbzT5k_NFPaDOmsm9-WJsjebo';
      
      if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
        setState(() {
          _isAIAvailable = false;
          _errorMessage = 'Gemini API Key is missing or invalid.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFBC13FE), size: 20),
            SizedBox(width: 10),
            Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _initAI,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2)),
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
                        ? const LinearGradient(colors: [Color(0xFFBC13FE), Color(0xFF4A00E0)])
                        : LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : null,
                        bottomLeft: !isUser ? const Radius.circular(0) : null,
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(
                      _messages[i]['content']!,
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Center(child: CircularProgressIndicator(color: Color(0xFFBC13FE))),
            ),
            
          Padding(
            padding: const EdgeInsets.all(16).copyWith(bottom: 100), // Leave space for floating nav
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: _isAIAvailable,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: _isAIAvailable ? 'Ask me anything...' : 'AI offline',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Color(0xFFBC13FE)),
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
