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
  double _healthScore = 82.0;
  String _financeTrend = 'Analyzing...';
  String _healthTrend = 'Analyzing...';

  Future<void> _generateInsights() async {
    setState(() => _isLoadingAI = true);
    debugPrint("GENERATING AI INSIGHTS...");
    
    try {
      final habits = ref.read(habitsProvider).value ?? [];
      final finance = ref.read(financeProvider).value ?? [];
      final tasks = ref.read(tasksProvider).value ?? [];
      
      final aiService = ref.read(aiServiceProvider);
      
      final prompt = """
      Analyze my performance based on this raw data:
      Habits: ${habits.map((h) => "${h['name']}: ${h['streak']} streak, ${h['status']}").join(', ')}
      Finance: ${finance.length} transactions, total volume: ${finance.fold(0.0, (s, t) => s + (t['amount'] as num).abs())}
      Tasks: ${tasks.where((t) => t['completed'] == true).length} / ${tasks.length} done.

      Provide 4 specific findings:
      1. Life Score (0-100)
      2. Health Score (0-100 based on habits)
      3. Financial Trend (forecast vs current spend)
      4. Detailed Analysis with 3 actionable tips.

      Format strictly as:
      LIFE_SCORE: [number] | HEALTH_SCORE: [number] | FINANCE_TREND: [text] | HEALTH_TREND: [text] | ANALYSIS: [text]
      """;

      final response = await aiService.getChatResponse(prompt);
      debugPrint("AI INSIGHT RESPONSE: $response");
      
      double lifeScore = 75.0;
      double healthScore = 80.0;
      String fTrend = 'Stable';
      String hTrend = 'Consistency is good.';
      String analysis = response;

      try {
        final parts = response.split('|');
        for (var part in parts) {
           final entry = part.toUpperCase();
           if (entry.contains('LIFE_SCORE:')) _lifeScore = double.tryParse(part.split(':')[1].trim()) ?? 75.0;
           if (entry.contains('HEALTH_SCORE:')) _healthScore = double.tryParse(part.split(':')[1].trim()) ?? 80.0;
           if (entry.contains('FINANCE_TREND:')) _financeTrend = part.split(':')[1].trim();
           if (entry.contains('HEALTH_TREND:')) _healthTrend = part.split(':')[1].trim();
           if (entry.contains('ANALYSIS:')) _aiAnalysis = part.split(':')[1].trim();
        }
      } catch (e) {
        debugPrint("PARSING ERROR: $e");
        _aiAnalysis = response; // Fallback to raw response if parsing fails
      }

      setState(() {});
    } catch (e) {
      if (mounted) setState(() => _aiAnalysis = "Error: $e");
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
                Expanded(child: _buildSmallCard(theme, isLight, 'Efficiency', '${(_lifeScore * 1.1).toInt().clamp(0, 100)}%', Icons.trending_up_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _buildSmallCard(theme, isLight, 'Consistency', '${_healthScore.toInt()}%', Icons.check_circle_rounded)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Forecast Section
            _buildInsightCard(
              isLight: isLight,
              child: Row(
                children: [
                  Icon(Icons.timeline_rounded, color: theme.accentColor, size: 30),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FINANCIAL OUTLOOK', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(_financeTrend, style: TextStyle(color: textPrimary.withValues(alpha: 0.6), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildInsightCard(
              isLight: isLight,
              child: Row(
                children: [
                  Icon(Icons.spa_rounded, color: Colors.greenAccent, size: 30),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HEALTH TRENDS', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(_healthTrend, style: TextStyle(color: textPrimary.withValues(alpha: 0.6), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
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
