import 'package:flutter/material.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final List<Map<String, dynamic>> _habits = [
    {'name': 'Meditate', 'status': 'completed', 'category': 'Health'},
    {'name': 'Read 15 Pages', 'status': 'todo', 'category': 'Growth'},
    {'name': 'Coding Session', 'status': 'todo', 'category': 'Work'},
    {'name': 'Morning Jog', 'status': 'missed', 'category': 'Fitness'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeeklyStats(isDark),
            const SizedBox(height: 24),
            Text(
              "Today's Progress",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _habits.length,
                itemBuilder: (context, index) {
                  final habit = _habits[index];
                  return _buildHabitItem(habit, isDark);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWeeklyStats(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCircle('M', true),
          _buildStatCircle('T', true),
          _buildStatCircle('W', true),
          _buildStatCircle('T', false),
          _buildStatCircle('F', false),
          _buildStatCircle('S', false),
          _buildStatCircle('S', false),
        ],
      ),
    );
  }

  Widget _buildStatCircle(String day, bool completed) {
    return Column(
      children: [
        Text(day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? Colors.blue : Colors.transparent,
            border: Border.all(color: Colors.blue),
          ),
          child: completed ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
        ),
      ],
    );
  }

  Widget _buildHabitItem(Map<String, dynamic> habit, bool isDark) {
    Color statusColor;
    IconData statusIcon;

    switch (habit['status']) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'missed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.radio_button_unchecked;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  habit['category'],
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert, size: 20),
        ],
      ),
    );
  }
}
