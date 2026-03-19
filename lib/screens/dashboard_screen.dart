import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String uid;
  final GlassTheme activeTheme;
  final String currency;
  final Function(int) onNavigate;
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.uid,
    required this.activeTheme,
    required this.currency,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _db = FirebaseService();

  bool get _isLight => widget.activeTheme.brightness == Brightness.light;
  Color get _textPrimary => _isLight ? Colors.black87 : Colors.white;
  Color get _textSecondary => _isLight ? Colors.black54 : Colors.white70;
  Color get _textTertiary => _isLight ? Colors.black38 : Colors.white38;
  Color get _borderColor => _isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _db.streamTasks(widget.uid),
          builder: (ctx, tasksSnap) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.streamHabits(widget.uid),
              builder: (ctx, habitsSnap) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _db.streamFinance(widget.uid),
                  builder: (ctx, financeSnap) {
                    
                    final tasks = tasksSnap.data ?? [];
                    final habits = habitsSnap.data ?? [];
                    final finance = financeSnap.data ?? [];

                    final tasksDone = tasks.where((t) => t['completed'] == true).length;
                    final streak = habits.isNotEmpty ? 1 : 0; 
                    
                    final totalIncome = finance.where((tx) => (tx['amount'] ?? 0) > 0).fold(0.0, (sum, tx) => sum + (tx['amount'] ?? 0));
                    final totalExpenses = finance.where((tx) => (tx['amount'] ?? 0) < 0).fold(0.0, (sum, tx) => sum + (tx['amount'] ?? 0).abs());
                    final saved = totalIncome - totalExpenses;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20).copyWith(bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header 
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${_getGreeting()},', style: TextStyle(fontSize: 14, color: _textTertiary)),
                                    const SizedBox(height: 4),
                                    Text(widget.userName, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textPrimary)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => widget.onNavigate(5),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _borderColor),
                                  ),
                                  child: Icon(Icons.settings_rounded, color: _textSecondary, size: 22),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(_getFormattedDate(), style: TextStyle(color: _textTertiary, fontSize: 13)),

                          const SizedBox(height: 28),

                          // Lifecycle Report Chart
                          Text('LIFECYCLE OVERVIEW', style: TextStyle(color: _textTertiary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 16),
                          _buildPremiumCard(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 180,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 40,
                                      sections: _buildChartSections(finance),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildLegendItem('Spending', Colors.redAccent),
                                    const SizedBox(width: 20),
                                    _buildLegendItem('Saving', Colors.greenAccent),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Stats Grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.6,
                            children: [
                              _buildGlassStatCard('Tasks Done', '$tasksDone', Icons.check_circle_rounded, Colors.greenAccent),
                              _buildGlassStatCard('Streak', '$streak days', Icons.local_fire_department_rounded, Colors.orangeAccent),
                              _buildGlassStatCard('Saved', '${widget.currency}${saved.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, Colors.cyanAccent),
                              _buildGlassStatCard('Focus', '0h', Icons.psychology_rounded, widget.activeTheme.accentColor),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // AI Brain Quick Input
                          _buildPremiumCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: widget.activeTheme.accentColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.psychology_rounded, color: widget.activeTheme.accentColor, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('AI Focus', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('Ready for a deep work session?', style: TextStyle(color: _textTertiary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => widget.onNavigate(6),
                                  child: Text('EXPLORE', style: TextStyle(color: widget.activeTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Quick Actions
                          Row(
                            children: [
                              Expanded(child: _buildQuickAction('AI Chat', Icons.auto_awesome, widget.activeTheme.accentColor, 1)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildQuickAction('Plan', Icons.calendar_today_rounded, Colors.cyanAccent, 2)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildQuickAction('Habits', Icons.track_changes_rounded, Colors.greenAccent, 3)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                );
              }
            );
          }
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(List<Map<String, dynamic>> finance) {
    final expenses = finance.where((tx) => (tx['amount'] ?? 0) < 0).fold(0.0, (s, t) => s + (t['amount'] ?? 0).abs());
    final income = finance.where((tx) => (tx['amount'] ?? 0) > 0).fold(0.0, (s, t) => s + (t['amount'] ?? 0));
    
    if (expenses == 0 && income == 0) {
      return [
        PieChartSectionData(color: (_isLight ? Colors.grey[300]! : Colors.grey).withValues(alpha: 0.2), value: 1, radius: 20, title: ''),
      ];
    }

    return [
      PieChartSectionData(
        color: Colors.redAccent.withValues(alpha: 0.6),
        value: expenses,
        radius: 25,
        title: '',
        badgeWidget: Icon(Icons.trending_down, color: _textPrimary, size: 14),
        badgePositionPercentageOffset: 1.3,
      ),
      PieChartSectionData(
        color: Colors.greenAccent.withValues(alpha: 0.6),
        value: income,
        radius: 25,
        title: '',
        badgeWidget: Icon(Icons.trending_up, color: _textPrimary, size: 14),
        badgePositionPercentageOffset: 1.3,
      ),
    ];
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: _textTertiary, fontSize: 12)),
      ],
    );
  }

  Widget _buildPremiumCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.activeTheme.cardBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.activeTheme.blur, sigmaY: widget.activeTheme.blur),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.activeTheme.cardGradient,
            ),
            borderRadius: BorderRadius.circular(widget.activeTheme.cardBorderRadius),
            border: Border.all(color: _borderColor),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassStatCard(String label, String value, IconData icon, Color color) {
    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          Text(label, style: TextStyle(color: _textTertiary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, int navIndex) {
    return GestureDetector(
      onTap: () => widget.onNavigate(navIndex),
      child: _buildPremiumCard(
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
