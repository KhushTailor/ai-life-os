import 'package:flutter/material.dart';

class AIInsightCard extends StatelessWidget {
  final String content;
  final bool isLoading;

  const AIInsightCard({
    super.key,
    required this.content,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0095F6).withValues(alpha: 0.05),
        border: Border.all(color: const Color(0xFF0095F6).withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF0095F6), size: 18),
              SizedBox(width: 8),
              Text(
                'AI Insight',
                style: TextStyle(
                  color: Color(0xFF0095F6),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0095F6)),
            )
          else
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
