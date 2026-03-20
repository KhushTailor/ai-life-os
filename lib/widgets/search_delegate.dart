import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';
import 'dart:ui';

class GlobalSearchDelegate extends SearchDelegate {
  final String uid;
  final GlassTheme theme;
  final FirebaseService _db = FirebaseService();

  GlobalSearchDelegate({required this.uid, required this.theme});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black, elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white54),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear, color: Colors.white), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Container(color: Colors.black, child: const Center(child: Text('Search tasks, habits, or expenses...', style: TextStyle(color: Colors.white54))));
    }

    return Container(
      color: Colors.black,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db.streamTasks(uid),
        builder: (context, tasksSnap) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _db.streamHabits(uid),
            builder: (context, habitsSnap) {
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _db.streamFinance(uid),
                builder: (context, financeSnap) {
                  final tasks = tasksSnap.data?.where((t) => t['title'].toString().toLowerCase().contains(query.toLowerCase())).toList() ?? [];
                  final habits = habitsSnap.data?.where((h) => h['name'].toString().toLowerCase().contains(query.toLowerCase())).toList() ?? [];
                  final finance = financeSnap.data?.where((f) => f['title'].toString().toLowerCase().contains(query.toLowerCase())).toList() ?? [];

                  if (tasks.isEmpty && habits.isEmpty && finance.isEmpty) {
                    return const Center(child: Text('No results found.', style: TextStyle(color: Colors.white54)));
                  }

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (tasks.isNotEmpty) ...[
                        _buildSectionHeader('TASKS'),
                        ...tasks.map((t) => _buildResultTile(t['title'], 'Task', Icons.check_circle_outline)),
                        const SizedBox(height: 20),
                      ],
                      if (habits.isNotEmpty) ...[
                        _buildSectionHeader('HABITS'),
                        ...habits.map((h) => _buildResultTile(h['name'], 'Habit', Icons.repeat_rounded)),
                        const SizedBox(height: 20),
                      ],
                      if (finance.isNotEmpty) ...[
                        _buildSectionHeader('FINANCE'),
                        ...finance.map((f) => _buildResultTile(f['title'], 'Transaction: ${f['amount']}', Icons.attach_money_rounded)),
                      ],
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title, style: TextStyle(color: theme.accentColor, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildResultTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ),
    );
  }
}
