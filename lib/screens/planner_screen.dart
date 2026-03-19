import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';

class PlannerScreen extends StatefulWidget {
  final String uid;
  final GlassTheme activeTheme;
  const PlannerScreen({super.key, required this.uid, required this.activeTheme});

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
            color: (widget.activeTheme.brightness == Brightness.dark ? const Color(0xFF1A1A2E) : Colors.white),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('New Plan', style: TextStyle(color: widget.activeTheme.brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: TextStyle(color: widget.activeTheme.brightness == Brightness.dark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                style: TextStyle(color: widget.activeTheme.brightness == Brightness.dark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Time (e.g. 9:00 AM)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.access_time_rounded, color: widget.activeTheme.accentColor),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isNotEmpty) {
                      final title = titleController.text.trim();
                      final time = timeController.text.trim().isNotEmpty ? timeController.text.trim() : 'Anytime';
                      
                      Navigator.pop(ctx);

                      final updatedList = List<Map<String, dynamic>>.from(currentTasks);
                      updatedList.add({
                        'title': title,
                        'time': time,
                        'completed': false,
                      });
                      await _db.syncTasks(widget.uid, updatedList);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.activeTheme.accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
        final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Planner', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : tasks.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text('No plans for today', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20).copyWith(bottom: 120),
                      itemCount: tasks.length,
                      itemBuilder: (ctx, i) {
                        return _buildGlassTaskTile(tasks[i], i, tasks);
                      },
                    ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: isLoading ? null : () => _addTask(tasks),
            backgroundColor: widget.activeTheme.accentColor,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('New Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildGlassTaskTile(Map<String, dynamic> task, int index, List<Map<String, dynamic>> allTasks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.activeTheme.cardBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.activeTheme.blur, sigmaY: widget.activeTheme.blur),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.activeTheme.cardGradient),
              borderRadius: BorderRadius.circular(widget.activeTheme.cardBorderRadius),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    final updated = List<Map<String, dynamic>>.from(allTasks);
                    updated[index]['completed'] = !updated[index]['completed'];
                    _db.syncTasks(widget.uid, updated);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: task['completed'] ? Colors.greenAccent : widget.activeTheme.accentColor),
                    ),
                    child: Icon(
                      task['completed'] ? Icons.check_circle : Icons.radio_button_off,
                      size: 20,
                      color: task['completed'] ? Colors.greenAccent : widget.activeTheme.accentColor,
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
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task['completed'] ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white54,
                        )
                      ),
                      Text(task['time'], style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.white.withOpacity(0.3), size: 20),
                  onPressed: () {
                    final updated = List<Map<String, dynamic>>.from(allTasks);
                    updated.removeAt(index);
                    _db.syncTasks(widget.uid, updated);
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
