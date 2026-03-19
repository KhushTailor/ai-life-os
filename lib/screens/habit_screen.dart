import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_squircle_fab.dart';

class HabitScreen extends StatefulWidget {
  final String uid;
  final GlassTheme activeTheme;
  final Function(int)? onNavigate;

  const HabitScreen({super.key, required this.uid, required this.activeTheme, this.onNavigate});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final FirebaseService _db = FirebaseService();
  bool _isSearching = false;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'done', 'todo'
  final TextEditingController _searchController = TextEditingController();

  bool get _isLight => widget.activeTheme.brightness == Brightness.light;
  Color get _textPrimary => _isLight ? Colors.black87 : Colors.white;
  Color get _textSecondary => _isLight ? Colors.black54 : Colors.white70;
  Color get _textTertiary => _isLight ? Colors.black38 : Colors.white38;
  Color get _borderColor => _isLight ? Colors.black.withOpacity(0.08) : Colors.white.withOpacity(0.1);

  void _addHabit(List<Map<String, dynamic>> currentHabits) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isLight ? Colors.white : const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: _isLight ? Colors.grey[300] : Colors.grey[700], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('New Habit', style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'What is your goal?',
                  hintStyle: TextStyle(color: _textTertiary),
                  filled: true,
                  fillColor: (_isLight ? Colors.grey[100] : Colors.grey.withOpacity(0.1)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'Category (e.g. Health, Work)',
                  hintStyle: TextStyle(color: _textTertiary),
                  filled: true,
                  fillColor: (_isLight ? Colors.grey[100] : Colors.grey.withOpacity(0.1)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.category_rounded, color: widget.activeTheme.accentColor),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      final name = nameController.text.trim();
                      final category = categoryController.text.trim().isNotEmpty ? categoryController.text.trim() : 'General';
                      
                      Navigator.pop(ctx);

                      final updatedList = List<Map<String, dynamic>>.from(currentHabits);
                      updatedList.add({
                        'name': name,
                        'category': category,
                        'status': 'todo',
                        'streak': 0,
                        'target': 1,
                        'difficulty': 'Easy', // Default difficulty
                      });
                      await _db.syncHabits(widget.uid, updatedList);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.activeTheme.accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Start Evolution', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEvolveDialog(Map<String, dynamic> habit, int index, List<Map<String, dynamic>> allHabits) {
    final currentStreak = habit['streak'] ?? 0;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isLight ? Colors.white : const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Habit Evolution! 🔥', style: TextStyle(color: _textPrimary)),
        content: Text(
          'Your ${habit['name']} streak is $currentStreak! \n\nAI suggests increasing your difficulty level for faster growth.',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Not Yet', style: TextStyle(color: _textTertiary))),
          ElevatedButton(
            onPressed: () {
              final updated = List<Map<String, dynamic>>.from(allHabits);
              updated[index]['name'] = '${habit['name']} (LVL UP)';
              updated[index]['streak'] = 0;
              updated[index]['difficulty'] = 'Medium'; // Increase difficulty
              _db.syncHabits(widget.uid, updated);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.activeTheme.accentColor),
            child: const Text('EVOLVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.streamHabits(widget.uid),
      builder: (context, snapshot) {
        final habits = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

        return Scaffold(
          backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: _isSearching 
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search habits...',
                      hintStyle: TextStyle(color: _textTertiary),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  )
                : Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.menu_rounded, color: _textPrimary),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      const SizedBox(width: 8),
                      Text('Habits', style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary, fontSize: 24)),
                    ],
                  ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search_rounded, color: _textPrimary), 
                  onPressed: () {
                    setState(() {
                      if (_isSearching) {
                        _searchQuery = '';
                        _searchController.clear();
                      }
                      _isSearching = !_isSearching;
                    });
                  }
                ),
                IconButton(
                  icon: Icon(Icons.filter_list_rounded, color: _filterStatus != 'all' ? widget.activeTheme.accentColor : _textPrimary), 
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: _isLight ? Colors.white : const Color(0xFF1A1A2E),
                        title: Text('Filter Habits', style: TextStyle(color: _textPrimary)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(title: Text('All Habits', style: TextStyle(color: _textPrimary)), onTap: () { setState(() => _filterStatus = 'all'); Navigator.pop(ctx); }),
                            ListTile(title: Text('Completed Today', style: TextStyle(color: _textPrimary)), onTap: () { setState(() => _filterStatus = 'done'); Navigator.pop(ctx); }),
                            ListTile(title: Text('To Do', style: TextStyle(color: _textPrimary)), onTap: () { setState(() => _filterStatus = 'todo'); Navigator.pop(ctx); }),
                          ]
                        ),
                      )
                    );
                  }
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today_rounded, color: _textPrimary), 
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (!context.mounted) return;
                    if (picked != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected date: ${picked.toString().substring(0,10)}')));
                    }
                  }
                ),
                const SizedBox(width: 8),
              ],
          ),
          body: _buildBody(habits, isLoading),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: GlassSquircleFab(
              theme: widget.activeTheme,
              icon: Icons.add_rounded,
              onPressed: isLoading ? () {} : () => _addHabit(habits),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> habits, bool isLoading) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: widget.activeTheme.accentColor));
    }
    
    var filtered = habits.where((h) {
      if (_searchQuery.isNotEmpty && !(h['name'] as String).toLowerCase().contains(_searchQuery)) return false;
      if (_filterStatus == 'done' && h['status'] != 'done') return false;
      if (_filterStatus == 'todo' && h['status'] == 'done') return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.05),
                  ),
                  child: Icon(Icons.emoji_events_rounded, size: 60, color: Colors.orangeAccent.withOpacity(0.8)),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10, right: 10),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: widget.activeTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(_searchQuery.isNotEmpty ? 'No results found' : 'There are no active habits', style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_searchQuery.isNotEmpty ? 'Try another search term' : "It's always a good day for a new start", style: TextStyle(color: _textTertiary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20).copyWith(bottom: 180),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final originalIndex = habits.indexOf(filtered[i]);
        return _buildGlassHabitCard(filtered[i], originalIndex, habits);
      },
    );
  }

  Widget _buildGlassHabitCard(Map<String, dynamic> habit, int index, List<Map<String, dynamic>> allHabits) {
    final streak = habit['streak'] ?? 0;
    final isDone = habit['status'] == 'done';
    final difficulty = habit['difficulty'] ?? 'Easy';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _isLight ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.2),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final updated = List<Map<String, dynamic>>.from(allHabits);
                      if (!isDone) {
                        updated[index]['status'] = 'done';
                        updated[index]['streak'] = streak + 1;
                      } else {
                        updated[index]['status'] = 'todo';
                        updated[index]['streak'] = streak > 0 ? streak - 1 : 0;
                      }
                      _db.syncHabits(widget.uid, updated);
                      
                      if (!isDone && (streak + 1) >= 7) {
                        _showEvolveDialog(updated[index], index, updated);
                      }
                    },
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: isDone ? Colors.greenAccent.withOpacity(0.2) : widget.activeTheme.accentColor.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDone ? Colors.greenAccent : widget.activeTheme.accentColor, width: 2),
                      ),
                      child: isDone ? const Icon(Icons.check, color: Colors.greenAccent, size: 20) : null,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit['name'], style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(habit['category'] ?? 'General', style: TextStyle(color: _textTertiary, fontSize: 11, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('$streak', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text('DAY STREAK', style: TextStyle(color: Colors.orangeAccent, fontSize: 7, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              if (streak >= 5)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (streak / 7 > 1 ? 1 : streak / 7),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.5), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
