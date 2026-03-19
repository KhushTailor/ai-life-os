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
                                    Text('${_getGreeting()},', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
                                    const SizedBox(height: 4),
                                    Text(widget.userName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => widget.onNavigate(5),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Icon(Icons.settings_rounded, color: Colors.white.withOpacity(0.7), size: 22),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(_getFormattedDate(), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),

                          const SizedBox(height: 28),

                          // Lifecycle Report Chart (Visual Upgrade)
                          Text('LIFECYCLE OVERVIEW', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
                                    color: widget.activeTheme.accentColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.psychology_rounded, color: widget.activeTheme.accentColor, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('AI Focus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('Ready for a deep work session?', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => widget.onNavigate(6), // Focus Screen
                                  child: Text('EXPLORE', style: TextStyle(color: widget.activeTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Quick Actions
                          Row(
                            children: [
                              Expanded(child: _buildQuickAction('AI AI', Icons.auto_awesome, widget.activeTheme.accentColor, 1)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildQuickAction('Plan', Icons.calendar_today_rounded, Colors.cyanAccent, 2)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildQuickAction('Deep', Icons.track_changes_rounded, Colors.greenAccent, 3)),
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
        PieChartSectionData(color: Colors.grey.withOpacity(0.2), value: 1, radius: 20, title: ''),
      ];
    }

    return [
      PieChartSectionData(
        color: Colors.redAccent.withOpacity(0.6),
        value: expenses,
        radius: 25,
        title: '',
        badgeWidget: const Icon(Icons.trending_down, color: Colors.white, size: 14),
        badgePositionPercentageOffset: 1.3,
      ),
      PieChartSectionData(
        color: Colors.greenAccent.withOpacity(0.6),
        value: income,
        radius: 25,
        title: '',
        badgeWidget: const Icon(Icons.trending_up, color: Colors.white, size: 14),
        badgePositionPercentageOffset: 1.3,
      ),
    ];
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
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
            border: Border.all(color: Colors.white.withOpacity(0.12)),
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
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
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
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
