import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/firebase_service.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String uid;
  final String activeTheme;
  final Function(int) onNavigate;
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.uid,
    required this.activeTheme,
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
      backgroundColor: const Color(0xFF0F0C29),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
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
                        padding: const EdgeInsets.all(20),
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
                                Row(
                                  children: [
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
                                _buildGlassStatCard('Saved', '\$${saved.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, Colors.cyanAccent),
                                _buildGlassStatCard('Focus', '0h', Icons.psychology_rounded, const Color(0xFFBC13FE)),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // AI Insight Card
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFBC13FE).withOpacity(0.15),
                                        const Color(0xFF4A00E0).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFBC13FE).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFBC13FE).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.auto_awesome, color: Color(0xFFBC13FE), size: 24),
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
                                                  ? 'Welcome! Add tasks and habits to get personalized AI insights.'
                                                  : 'Great job maintaining your logs. You have ${tasks.length} tasks and ${habits.length} habits tracked.',
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Quick Actions
                            Text('Quick Actions', style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildQuickAction('AI Chat', Icons.auto_awesome, const Color(0xFFBC13FE), 1)),
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Daily Objectives', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 20),
                                      if (tasks.isEmpty)
                                        Center(
                                          child: Column(
                                            children: [
                                              Icon(Icons.inbox_rounded, size: 40, color: Colors.white.withOpacity(0.15)),
                                              const SizedBox(height: 10),
                                              Text('No objectives for today', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                                            ],
                                          ),
                                        )
                                      else
                                        ...tasks.take(3).map((task) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Row(
                                            children: [
                                              Icon(
                                                task['completed'] ? Icons.check_circle : Icons.radio_button_unchecked, 
                                                color: task['completed'] ? Colors.greenAccent : const Color(0xFFBC13FE)
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
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
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
      ),
    );
  }

  Widget _buildGlassStatCard(String label, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
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
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, int navIndex) {
    return GestureDetector(
      onTap: () => widget.onNavigate(navIndex),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
