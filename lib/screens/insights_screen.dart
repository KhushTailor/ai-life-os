import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';

class InsightsScreen extends StatefulWidget {
  final String uid;
  final GlassTheme theme;
  const InsightsScreen({super.key, required this.uid, required this.theme});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final FirebaseService _db = FirebaseService();
  bool _isLoadingAI = false;
  String _aiAnalysis = 'Tap the button to generate your weekly AI performance analysis.';
  double _lifeScore = 78.0;

  bool get _isLight => widget.theme.brightness == Brightness.light;
  Color get _textPrimary => _isLight ? Colors.black87 : Colors.white;

  Future<void> _generateInsights(List<Map<String, dynamic>> habits, List<Map<String, dynamic>> finance) async {
    setState(() => _isLoadingAI = true);
    
    try {
      // Calculate real metrics
      int totalStreaks = habits.fold(0, (s, h) => s + (h['streak'] as int? ?? 0));
      double avgStreak = habits.isEmpty ? 0 : totalStreaks / habits.length;
      
      final totalSpent = finance.where((tx) => (tx['amount'] ?? 0) < 0).fold(0.0, (s, t) => s + (t['amount'] as double).abs());
      final totalIncome = finance.where((tx) => (tx['amount'] ?? 0) > 0).fold(0.0, (s, t) => s + (t['amount'] as double).abs());
      
      // Simulated AI prompt/response logic
      await Future.delayed(const Duration(seconds: 2));
      
      double score = 50 + (avgStreak * 5) - (totalSpent > totalIncome ? 10 : 0);
      score = score.clamp(0, 100);

      setState(() {
        _lifeScore = score;
        _aiAnalysis = "Your 'AI Life OS' shows a score of ${score.toInt()}. Your habits are ${avgStreak > 5 ? 'strong' : 'improving'} with an average streak of ${avgStreak.toStringAsFixed(1)} days. However, your spending (\$${totalSpent.toStringAsFixed(0)}) compared to income (\$${totalIncome.toStringAsFixed(0)}) suggests you could optimize your budget for better focus.";
      });
    } catch (e) {
      setState(() => _aiAnalysis = "Error analyzing your life data: $e");
    } finally {
      setState(() => _isLoadingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('AI Life Insights', style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db.streamHabits(widget.uid),
        builder: (context, habitsSnap) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _db.streamFinance(widget.uid),
            builder: (context, financeSnap) {
              final habits = habitsSnap.data ?? [];
              final finance = financeSnap.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20).copyWith(bottom: 120),
                child: Column(
                  children: [
                    // Life Score Card
                    _buildInsightCard(
                      child: Column(
                        children: [
                          const Text('YOUR PERFORMANCE SCORE', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 120, height: 120,
                                child: CircularProgressIndicator(
                                  value: _lifeScore / 100,
                                  strokeWidth: 10,
                                  color: widget.theme.accentColor,
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              Text('${_lifeScore.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text('You are doing better than 82% of users!', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w300)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // AI Analysis Section
                    _buildInsightCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: widget.theme.accentColor, size: 20),
                              const SizedBox(width: 10),
                              const Text('AI RECOMMENDATIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_isLoadingAI)
                            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                          else
                            Text(
                              _aiAnalysis,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, height: 1.6),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoadingAI ? null : () => _generateInsights(habits, finance),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.theme.accentColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('REGENERATE INSIGHTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Stats
                    Row(
                      children: [
                        Expanded(child: _buildSmallCard('Focus Time', '12.4h', Icons.timer_rounded)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildSmallCard('Consistency', '92%', Icons.trending_up_rounded)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInsightCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (_isLight ? Colors.black : Colors.white).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSmallCard(String label, String value, IconData icon) {
    return _buildInsightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: widget.theme.accentColor, size: 20),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
