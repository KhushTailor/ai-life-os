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

                    final todayTasks = tasks.where((t) => t['completed'] != true).take(3).toList();
                    final sortedHabits = List.from(habits)..sort((a,b) => (a['status'] == 'done' ? 1 : 0).compareTo(b['status'] == 'done' ? 1 : 0));
                    final topHabits = sortedHabits.take(3).toList();

                    final totalIncome = finance.where((tx) => (tx['amount'] ?? 0) > 0).fold(0.0, (sum, tx) => sum + (tx['amount'] ?? 0));
                    final totalExpenses = finance.where((tx) => (tx['amount'] ?? 0) < 0).fold(0.0, (sum, tx) => sum + (tx['amount'] ?? 0).abs());
                    final saved = totalIncome - totalExpenses;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20).copyWith(bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_getGreeting(), style: TextStyle(fontSize: 14, color: _textTertiary)),
                                  const SizedBox(height: 4),
                                  Text(widget.userName, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textPrimary)),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => widget.onNavigate(5), // 5 is Settings
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _borderColor),
                                  ),
                                  child: Icon(Icons.settings_rounded, color: _textSecondary, size: 24),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Essential Quick Actions
                          Row(
                            children: [
                              Expanded(child: _buildActionButton('AI Chat', Icons.auto_awesome_rounded, widget.activeTheme.accentColor, 1)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildActionButton('Focus', Icons.timer_rounded, Colors.orangeAccent, 6)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildActionButton('Tasks', Icons.add_task_rounded, Colors.cyanAccent, 2)),
                            ],
                          ),

                          const SizedBox(height: 35),
                          Text('UPCOMING AGENDA', style: TextStyle(color: _textTertiary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          
                          if (todayTasks.isEmpty && topHabits.isEmpty)
                            _buildFastCard(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Text("You're all caught up for today!", style: TextStyle(color: _textSecondary, fontStyle: FontStyle.italic)),
                                ),
                              ),
                            ),

                          if (todayTasks.isNotEmpty) ...[
                            ...todayTasks.map((t) => _buildSimpleTile(t['title'], Icons.square_outlined, Colors.cyanAccent)),
                          ],

                          if (topHabits.isNotEmpty) ...[
                            if (todayTasks.isNotEmpty) const SizedBox(height: 8),
                            ...topHabits.map((h) => _buildSimpleTile(h['name'], h['status'] == 'done' ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, Colors.greenAccent)),
                          ],

                          const SizedBox(height: 35),
                          Text('QUICK STATS', style: TextStyle(color: _textTertiary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(child: _buildStatCard('Net Balance', '${widget.currency}${saved.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, Colors.greenAccent)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard('Habit Streak', '${habits.isNotEmpty ? 1 : 0} Days', Icons.local_fire_department_rounded, Colors.orangeAccent)),
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

  Widget _buildSimpleTile(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _isLight ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, int navIndex) {
    return GestureDetector(
      onTap: () => widget.onNavigate(navIndex),
      child: _buildFastCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return _buildFastCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: _textTertiary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFastCard({required Widget child, EdgeInsetsGeometry? padding}) {
    // Highly optimized card without BackdropFilter for massive speed improvements
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Reduced blur for speed, but kept for aesthetics
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isLight ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2),
            border: Border.all(color: _borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
