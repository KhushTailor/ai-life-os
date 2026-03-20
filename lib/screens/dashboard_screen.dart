import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/search_delegate.dart';
import '../providers/providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogout;
  final Function(int) onNavigate;

  const DashboardScreen({
    super.key,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final financeAsync = ref.watch(financeProvider);
    final settings = ref.watch(settingsProvider);
    final activeTheme = ref.watch(activeThemeProvider);

    final userName = settings.userName;
    final currency = settings.currency;
    final isLight = activeTheme.brightness == Brightness.light;
    
    final textPrimary = isLight ? Colors.black87 : Colors.white;
    final textSecondary = isLight ? Colors.black54 : Colors.white70;
    final textTertiary = isLight ? Colors.black38 : Colors.white38;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12);

    final tasks = tasksAsync.value ?? [];
    final habits = habitsAsync.value ?? [];
    final finance = financeAsync.value ?? [];

    if (tasksAsync.hasValue || habitsAsync.hasValue || financeAsync.hasValue) {
      debugPrint("DASHBOARD DATA LOADED: ${tasks.length} tasks, ${habits.length} habits, ${finance.length} txs");
    }

    final todayTasks = tasks.where((t) => t['completed'] != true).take(3).toList();
    final sortedHabits = List.from(habits)..sort((a,b) => (a['status'] == 'done' ? 1 : 0).compareTo(b['status'] == 'done' ? 1 : 0));
    final topHabits = sortedHabits.take(3).toList();

    final totalIncome = finance.where((tx) => (tx['amount'] ?? 0) > 0).fold(0.0, (sum, tx) => sum + (tx['amount'] ?? 0));
    final totalExpenses = finance.where((tx) => (tx['amount'] ?? 0) < 0).fold(0.0, (sum, tx) => sum + (tx['amount'] ?? 0).abs());
    final saved = totalIncome - totalExpenses;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Search
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI LIFE OS', style: TextStyle(color: isLight ? Colors.black54 : Colors.white54, fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(userName.toUpperCase(), style: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.search_rounded, color: textPrimary),
                    onPressed: () {
                      final user = ref.read(authStateProvider).value;
                      if (user != null) {
                        showSearch(
                          context: context,
                          delegate: GlobalSearchDelegate(uid: user.uid, theme: activeTheme),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Greeting
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getGreeting(), style: TextStyle(fontSize: 14, color: textTertiary)),
                            const SizedBox(height: 4),
                            Text(userName, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => widget.onNavigate(5), // Settings
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor),
                            ),
                            child: Icon(Icons.settings_rounded, color: textSecondary, size: 24),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(child: _buildActionButton('AI Chat', Icons.auto_awesome_rounded, activeTheme.accentColor, 1, textPrimary, borderColor, isLight)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildActionButton('Focus', Icons.timer_rounded, Colors.orangeAccent, 6, textPrimary, borderColor, isLight)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildActionButton('Insights', Icons.auto_graph_rounded, Colors.greenAccent, 7, textPrimary, borderColor, isLight)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildActionButton('Tasks', Icons.add_task_rounded, Colors.cyanAccent, 2, textPrimary, borderColor, isLight)),
                      ],
                    ),

                    const SizedBox(height: 35),
                    Text('UPCOMING AGENDA', style: TextStyle(color: textTertiary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    
                    if (todayTasks.isEmpty && topHabits.isEmpty)
                      _buildFastCard(
                        isLight: isLight,
                        borderColor: borderColor,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text("You're all caught up for today!", style: TextStyle(color: textSecondary, fontStyle: FontStyle.italic)),
                          ),
                        ),
                      ),

                    if (todayTasks.isNotEmpty) ...[
                      ...todayTasks.map((t) => _buildSimpleTile(t['title'], Icons.square_outlined, Colors.cyanAccent, isLight, borderColor, textPrimary)),
                    ],

                    if (topHabits.isNotEmpty) ...[
                      if (todayTasks.isNotEmpty) const SizedBox(height: 8),
                      ...topHabits.map((h) => _buildSimpleTile(h['name'], h['status'] == 'done' ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, Colors.greenAccent, isLight, borderColor, textPrimary)),
                    ],

                    const SizedBox(height: 35),
                    Text('QUICK STATS', style: TextStyle(color: textTertiary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Net Balance', '$currency${saved.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, Colors.greenAccent, isLight, borderColor, textPrimary, textTertiary)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Habit Streak', '${habits.isNotEmpty ? 1 : 0} Days', Icons.local_fire_department_rounded, Colors.orangeAccent, isLight, borderColor, textPrimary, textTertiary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTile(String title, IconData icon, Color color, bool isLight, Color borderColor, Color textPrimary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isLight ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, int navIndex, Color textPrimary, Color borderColor, bool isLight) {
    return GestureDetector(
      onTap: () => widget.onNavigate(navIndex),
      child: _buildFastCard(
        isLight: isLight,
        borderColor: borderColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isLight, Color borderColor, Color textPrimary, Color textTertiary) {
    return _buildFastCard(
      isLight: isLight,
      borderColor: borderColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: textTertiary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFastCard({required Widget child, EdgeInsetsGeometry? padding, required bool isLight, required Color borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLight ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
