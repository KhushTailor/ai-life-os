import 'package:flutter/material.dart';
import '../widgets/stat_card.dart';
import '../widgets/life_os_card.dart';
import '../widgets/ai_insight_card.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;
  final Function(int) onNavigate;

  const DashboardScreen({
    super.key, 
    required this.userName, 
    required this.isDarkMode, 
    required this.onToggleTheme,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.sync, size: 20, color: Colors.blue),
            tooltip: 'Cloud Synced',
          ),
          IconButton(
            onPressed: widget.onToggleTheme, 
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
              currentAccountPicture: CircleAvatar(
                backgroundColor: const Color(0xFF0095F6),
                child: Text(widget.userName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              accountName: Text(widget.userName, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
              accountEmail: Text('🔥 7 day streak', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            _buildModuleTile(
              context,
              title: 'Smart Planner',
              subtitle: 'Next: Meeting at 11:00 AM',
              icon: Icons.calendar_today_outlined,
              color: Colors.blue,
              onTap: () => widget.onNavigate(5),
            ),
            _buildModuleTile(
              context,
              title: 'Habit Tracker',
              subtitle: '4 habits pending for today',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              onTap: () => widget.onNavigate(3),
            ),
            _buildModuleTile(
              context,
              title: 'Finance Hub',
              subtitle: 'Weekly spend: \$420.00',
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.orange,
              onTap: () => widget.onNavigate(4),
            ),
            _buildModuleTile(
              context,
              title: 'AI Agent',
              subtitle: 'Ask anything about your life',
              icon: Icons.auto_awesome,
              color: Colors.purple,
              onTap: () => widget.onNavigate(2),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: widget.onLogout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good evening, ${widget.userName}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Wednesday, March 18, 2026', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: const [
                StatCard(label: 'Tasks Done', value: '4/7', color: Colors.green, icon: Icons.check_circle),
                StatCard(label: 'Streak', value: '7 days', color: Colors.orange, icon: Icons.local_fire_department),
                StatCard(label: 'Saved', value: '₹4,200', color: Colors.blue, icon: Icons.account_balance_wallet),
                StatCard(label: 'Focus', value: '2.5h', color: Colors.purple, icon: Icons.psychology),
              ],
            ),
            const SizedBox(height: 24),
            const AIInsightCard(
              content: 'Your system metrics are stable. You have a 120min focus session planned for tonight.',
            ),
            const SizedBox(height: 16),
            const LifeOSCard(
              title: 'Daily Objectives',
              child: Column(
                children: [
                  _TaskItem(title: 'Study Physics Ch.12', time: '09:00', isDone: true),
                  _TaskItem(title: 'App Store Submission', time: '14:00', isDone: false),
                  _TaskItem(title: 'Workout session', time: '18:00', isDone: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String title;
  final String time;
  final bool isDone;

  const _TaskItem({required this.title, required this.time, required this.isDone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.green : theme.textTheme.bodyMedium?.color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? theme.textTheme.bodyMedium?.color : theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Text(time, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
