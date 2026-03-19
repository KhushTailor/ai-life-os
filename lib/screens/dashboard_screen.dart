import 'package:flutter/material.dart';
import 'dart:ui';
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
                    
                    final totalIncome = finance.where((tx) => tx['amount'] > 0).fold(0.0, (sum, tx) => sum + tx['amount']);
                    final totalExpenses = finance.where((tx) => tx['amount'] < 0).fold(0.0, (sum, tx) => sum + tx['amount'].abs());
                    final saved = totalIncome - totalExpenses;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20).copyWith(bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_getGreeting()},',
                                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.userName,
                                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => widget.onNavigate(5), // Settings
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

                          const SizedBox(height: 24),

                          // AI Insight Card
                          _buildPremiumCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: widget.activeTheme.accentColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.auto_awesome, color: widget.activeTheme.accentColor, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('AI Insight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text(
                                        tasks.isEmpty && habits.isEmpty
                                            ? 'Add tasks to get personalized AI insights.'
                                            : 'You have ${tasks.length} objectives today.',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Quick Actions
                          Text('Quick Actions', style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildQuickAction('AI Chat', Icons.auto_awesome, widget.activeTheme.accentColor, 1)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildQuickAction('Planner', Icons.calendar_today_rounded, Colors.cyanAccent, 2)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildQuickAction('Habits', Icons.track_changes_rounded, Colors.greenAccent, 3)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildQuickAction('Finance', Icons.account_balance_wallet_rounded, Colors.orangeAccent, 4)),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Daily Objectives
                          _buildPremiumCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Daily Objectives', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 20),
                                if (tasks.isEmpty)
                                  Center(
                                    child: Text('No objectives for today', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                                  )
                                else
                                  ...tasks.take(3).map((task) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          task['completed'] ? Icons.check_circle : Icons.radio_button_unchecked, 
                                          color: task['completed'] ? Colors.greenAccent : widget.activeTheme.accentColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          task['title'], 
                                          style: TextStyle(
                                            color: Colors.white, 
                                            decoration: task['completed'] ? TextDecoration.lineThrough : null
                                          )
                                        ),
                                      ],
                                    ),
                                  )),
                              ],
                            ),
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
