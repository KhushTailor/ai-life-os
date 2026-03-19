import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/firebase_service.dart';

class HabitScreen extends StatefulWidget {
  final String uid;
  const HabitScreen({super.key, required this.uid});

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
            color: const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('New Habit', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Habit name (e.g. Meditate)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Category (e.g. Health)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      final name = nameController.text.trim();
                      final category = categoryController.text.trim().isNotEmpty ? categoryController.text.trim() : 'General';
                      
                      // Optimistic Pop: Close modal immediately
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
                    backgroundColor: const Color(0xFFBC13FE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Habit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.streamHabits(widget.uid),
      builder: (context, snapshot) {
        final habits = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFF0F0C29),
          appBar: AppBar(
            title: const Text('Habit Tracker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeeklyStats(),
                  const SizedBox(height: 24),
                  const Text("Today's Progress", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: habits.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.track_changes, size: 60, color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text("No habits tracked yet", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                                const SizedBox(height: 8),
                                Text("Tap + to add your first habit", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: habits.length,
                            itemBuilder: (context, index) {
                              final habit = habits[index];
                              return _buildHabitItem(habit, index, habits);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addHabit(habits),
            backgroundColor: const Color(0xFFBC13FE),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      }
    );
  }

  Widget _buildWeeklyStats() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCircle('M', false),
              _buildStatCircle('T', false),
              _buildStatCircle('W', false),
              _buildStatCircle('T', false),
              _buildStatCircle('F', false),
              _buildStatCircle('S', false),
              _buildStatCircle('S', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCircle(String day, bool completed) {
    return Column(
      children: [
        Text(day, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7))),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? const Color(0xFFBC13FE) : Colors.transparent,
            border: Border.all(color: const Color(0xFFBC13FE).withOpacity(0.5)),
          ),
          child: completed ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
        ),
      ],
    );
  }

  Widget _buildHabitItem(Map<String, dynamic> habit, int index, List<Map<String, dynamic>> currentHabits) {
    Color statusColor;
    IconData statusIcon;

    switch (habit['status']) {
      case 'completed':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle;
        break;
      case 'missed':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = const Color(0xFFBC13FE);
        statusIcon = Icons.radio_button_unchecked;
    }

    return GestureDetector(
      onTap: () async {
        final updatedList = List<Map<String, dynamic>>.from(currentHabits);
        if (habit['status'] == 'todo') {
          updatedList[index]['status'] = 'completed';
        } else if (habit['status'] == 'completed') {
          updatedList[index]['status'] = 'missed';
        } else {
          updatedList[index]['status'] = 'todo';
        }
        await _db.syncHabits(widget.uid, updatedList);
      },
      onLongPress: () async {
        final updatedList = List<Map<String, dynamic>>.from(currentHabits);
        updatedList.removeAt(index);
        await _db.syncHabits(widget.uid, updatedList);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(habit['category'], style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, size: 20, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
