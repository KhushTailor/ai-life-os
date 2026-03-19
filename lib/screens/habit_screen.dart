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
            color: (widget.activeTheme.brightness == Brightness.dark ? const Color(0xFF1A1A2E) : Colors.white),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('New Habit', style: TextStyle(color: widget.activeTheme.brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: TextStyle(color: widget.activeTheme.brightness == Brightness.dark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Habit Name',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                style: TextStyle(color: widget.activeTheme.brightness == Brightness.dark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Category (Health, Work, etc.)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
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
                      });
                      await _db.syncHabits(widget.uid, updatedList);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.activeTheme.accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Start Habit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Habits', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db.streamHabits(widget.uid),
        builder: (context, snapshot) {
          final habits = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(20).copyWith(bottom: 120),
            itemCount: habits.length + 1,
            itemBuilder: (ctx, i) {
              if (i == habits.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: IconButton(
                      onPressed: () => _addHabit(habits),
                      icon: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.activeTheme.accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: widget.activeTheme.accentColor.withOpacity(0.35), blurRadius: 15)],
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                );
              }
              final habit = habits[i];
              return _buildGlassHabitCard(habit, i, habits);
            },
          );
        },
      ),
    );
  }

  Widget _buildGlassHabitCard(Map<String, dynamic> habit, int index, List<Map<String, dynamic>> allHabits) {
    final status = habit['status'] ?? 'todo';
    final isDone = status == 'done';

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
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    final updated = List<Map<String, dynamic>>.from(allHabits);
                    updated[index]['status'] = isDone ? 'todo' : 'done';
                    _db.syncHabits(widget.uid, updated);
                  },
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isDone ? Colors.greenAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
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
                      Text(habit['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(habit['category'], style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_forever_rounded, color: Colors.redAccent.withOpacity(0.4), size: 22),
                  onPressed: () {
                    final updated = List<Map<String, dynamic>>.from(allHabits);
                    updated.removeAt(index);
                    _db.syncHabits(widget.uid, updated);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
