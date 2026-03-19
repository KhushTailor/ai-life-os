import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/firebase_service.dart';

class PlannerScreen extends StatefulWidget {
  final String uid;
  const PlannerScreen({super.key, required this.uid});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final FirebaseService _db = FirebaseService();

  void _addTask(List<Map<String, dynamic>> currentTasks) {
    final titleController = TextEditingController();
    final timeController = TextEditingController();

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
              const Text('New Task', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Task title',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Time (e.g. 9:00 AM)',
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
                    if (titleController.text.trim().isNotEmpty) {
                      final updatedList = List<Map<String, dynamic>>.from(currentTasks);
                      updatedList.add({
                        'title': titleController.text.trim(),
                        'time': timeController.text.trim().isNotEmpty ? timeController.text.trim() : 'Anytime',
                        'completed': false,
                      });
                      await _db.syncTasks(widget.uid, updatedList);
                      if (mounted) Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBC13FE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      stream: _db.streamTasks(widget.uid),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFF0F0C29),
          appBar: AppBar(
            title: const Text('Smart Planner', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  _buildCalendarStrip(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Today's Schedule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      Icon(Icons.tune, size: 20, color: Colors.white.withOpacity(0.4)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: tasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_note, size: 60, color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text("No plans scheduled", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                                const SizedBox(height: 8),
                                Text("Tap + to plan your day", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return _buildTaskCard(task, index, tasks);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addTask(tasks),
            backgroundColor: const Color(0xFFBC13FE),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      }
    );
  }

  Widget _buildCalendarStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (index) {
          final date = DateTime.now().add(Duration(days: index - 3));
          final isToday = index == 3;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFFBC13FE) : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isToday ? const Color(0xFFBC13FE) : Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Text(
                  ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                  style: TextStyle(color: isToday ? Colors.white70 : Colors.white.withOpacity(0.4), fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int index, List<Map<String, dynamic>> currentTasks) {
    return GestureDetector(
      onTap: () async {
        final updatedList = List<Map<String, dynamic>>.from(currentTasks);
        updatedList[index]['completed'] = !updatedList[index]['completed'];
        await _db.syncTasks(widget.uid, updatedList);
      },
      onLongPress: () async {
        final updatedList = List<Map<String, dynamic>>.from(currentTasks);
        updatedList.removeAt(index);
        await _db.syncTasks(widget.uid, updatedList);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: task['completed']
                        ? Colors.greenAccent.withOpacity(0.15)
                        : const Color(0xFFBC13FE).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task['time'].toString().split(' ')[0],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: task['completed'] ? Colors.greenAccent : const Color(0xFFBC13FE),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: task['completed'] ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task['completed'] ? 'Completed' : 'Upcoming',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: task['completed'],
                  onChanged: (val) async {
                    final updatedList = List<Map<String, dynamic>>.from(currentTasks);
                    updatedList[index]['completed'] = val ?? false;
                    await _db.syncTasks(widget.uid, updatedList);
                  },
                  activeColor: const Color(0xFFBC13FE),
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
