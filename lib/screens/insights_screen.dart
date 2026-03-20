import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';
import '../providers/providers.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  bool _isLoadingAI = false;
  String _aiAnalysis = 'Tap the button to generate your weekly AI performance analysis.';
  double _lifeScore = 78.0;

  Future<void> _generateInsights() async {
    setState(() => _isLoadingAI = true);
    
    try {
      final habits = ref.read(habitsProvider).value ?? [];
      final finance = ref.read(financeProvider).value ?? [];
      final tasks = ref.read(tasksProvider).value ?? [];
      
      final aiService = ref.read(aiServiceProvider);
      
      final prompt = """
      Analyze my performance based on the following data:
      Habits: ${habits.map((h) => "${h['name']}: ${h['streak']} day streak, status: ${h['status']}").join(', ')}
      Finance: ${finance.length} transactions, total volume: ${finance.fold(0.0, (s, t) => s + (t['amount'] as num).abs())}
      Tasks: ${tasks.where((t) => t['completed'] == true).length} completed out of ${tasks.length} total.
      
      Provide a 'Life Score' (0-100) and a concise summary of my performance and 3 actionable recommendations.
      Format: SCORE: [number] | ANALYSIS: [text]
      """;

      final response = await aiService.getChatResponse(prompt);
      
      // Basic parsing of SCORE: XX | ANALYSIS: ...
      double score = 75.0;
      String analysis = response;

      if (response.contains('SCORE:')) {
        final parts = response.split('|');
        final scorePart = parts[0].replaceAll('SCORE:', '').trim();
        score = double.tryParse(scorePart) ?? 75.0;
        if (parts.length > 1) {
          analysis = parts[1].replaceAll('ANALYSIS:', '').trim();
        }
      }

      setState(() {
        _lifeScore = score;
        _aiAnalysis = analysis;
      });
    } catch (e) {
      if (mounted) setState(() => _aiAnalysis = "Error analyzing your life data: $e");
    } finally {
      if (mounted) setState(() => _isLoadingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(activeThemeProvider);
    final isLight = theme.brightness == Brightness.light;
    final textPrimary = isLight ? Colors.black87 : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('AI Life Insights', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20).copyWith(bottom: 120),
        child: Column(
          children: [
            // Life Score Card
            _buildInsightCard(
              isLight: isLight,
              child: Column(
                children: [
                   Text('YOUR PERFORMANCE SCORE', style: TextStyle(color: textPrimary.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120, height: 120,
                        child: CircularProgressIndicator(
                          value: _lifeScore / 100,
                          strokeWidth: 10,
                          color: theme.accentColor,
                          backgroundColor: textPrimary.withValues(alpha: 0.1),
                        ),
                      ),
                      Text('${_lifeScore.toInt()}', style: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Analyzed by AI Assistant', style: TextStyle(color: textPrimary.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w300)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // AI Analysis Section
            _buildInsightCard(
              isLight: isLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: theme.accentColor, size: 20),
                      const SizedBox(width: 10),
                      Text('AI RECOMMENDATIONS', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingAI)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else
                    Text(
                      _aiAnalysis,
                      style: TextStyle(color: textPrimary.withValues(alpha: 0.8), fontSize: 14, height: 1.6),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoadingAI ? null : _generateInsights,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accentColor,
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
                Expanded(child: _buildSmallCard(theme, isLight, 'Efficiency', '92%', Icons.trending_up_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _buildSmallCard(theme, isLight, 'Consistency', '84%', Icons.check_circle_rounded)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard({required Widget child, required bool isLight}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSmallCard(GlassTheme theme, bool isLight, String label, String value, IconData icon) {
    return _buildInsightCard(
      isLight: isLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.accentColor, size: 20),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: isLight ? Colors.black54 : Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: isLight ? Colors.black87 : Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
