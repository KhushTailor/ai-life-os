import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  final String baseUrl;

  AIService({this.baseUrl = 'http://localhost:5000'});

  Future<String> getChatResponse(String message, {Map<String, dynamic>? context}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'context': context,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? 'No response from AI';
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  Future<String> categorizeExpense(String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/categorize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': description}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['category'] ?? 'Other';
      }
      return 'Other';
    } catch (e) {
      return 'Other';
    }
  }
}
