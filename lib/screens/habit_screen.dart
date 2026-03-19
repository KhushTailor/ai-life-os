import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';

class HabitScreen extends StatefulWidget {
  final String uid;
  final GlassTheme activeTheme;
  const HabitScreen({super.key, required this.uid, required this.activeTheme});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final FirebaseService _db = FirebaseService();

  bool get _isLight => widget.activeTheme.brightness == Brightness.light;
  Color get _textPrimary => _isLight ? Colors.black87 : Colors.white;
  Color get _textSecondary => _isLight ? Colors.black54 : Colors.white70;
  Color get _textTertiary => _isLight ? Colors.black38 : Colors.white38;
  Color get _borderColor => _isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.1);

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
                  fillColor: (_isLight ? Colors.grey[100] : Colors.grey.withValues(alpha: 0.1)),
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
                  fillColor: (_isLight ? Colors.grey[100] : Colors.grey.withValues(alpha: 0.1)),
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

  void _evolveHabit(int index, List<Map<String, dynamic>> allHabits) {
    final habit = allHabits[index];
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
            title: Text('Habit Evolution', style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  onPressed: isLoading ? null : () => _addHabit(habits),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.activeTheme.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.activeTheme.accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.add_rounded, color: widget.activeTheme.accentColor, size: 20),
                  ),
                ),
              ),
            ],
          ),
          body: isLoading 
              ? Center(child: CircularProgressIndicator(color: _textPrimary))
              : habits.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.track_changes_rounded, size: 64, color: _textTertiary),
                          const SizedBox(height: 16),
                          Text('No habits tracked yet', style: TextStyle(color: _textTertiary, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Tap + to start building habits', style: TextStyle(color: _textTertiary, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20).copyWith(bottom: 120),
                      itemCount: habits.length,
                      itemBuilder: (ctx, i) {
                        return _buildGlassHabitCard(habits[i], i, habits);
                      },
                    ),
        );
      },
    );
  }

  Widget _buildGlassHabitCard(Map<String, dynamic> habit, int index, List<Map<String, dynamic>> allHabits) {
    final status = habit['status'] ?? 'todo';
    final isDone = status == 'done';
    final streak = habit['streak'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.activeTheme.cardBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.activeTheme.blur, sigmaY: widget.activeTheme.blur),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.activeTheme.cardGradient),
              borderRadius: BorderRadius.circular(widget.activeTheme.cardBorderRadius),
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
                          _evolveHabit(index, updated);
                        }
                      },
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: isDone ? Colors.greenAccent.withValues(alpha: 0.2) : widget.activeTheme.accentColor.withValues(alpha: 0.05),
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
                          Text(habit['category'], style: TextStyle(color: _textTertiary, fontSize: 11, letterSpacing: 0.5)),
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
                        color: _isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (streak / 7 > 1 ? 1 : streak / 7),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.5), blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
