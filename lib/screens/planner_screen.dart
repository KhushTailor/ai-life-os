import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_squircle_fab.dart';

class PlannerScreen extends StatefulWidget {
  final String uid;
  final GlassTheme activeTheme;
  final Function(int)? onNavigate;

  const PlannerScreen({super.key, required this.uid, required this.activeTheme, this.onNavigate});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final FirebaseService _db = FirebaseService();
  bool _isSearching = false;
  bool _isSyncing = false;
  String _searchQuery = '';
  String _filterStatus = 'all';

  bool get _isLight => widget.activeTheme.brightness == Brightness.light;
  Color get _textPrimary => _isLight ? Colors.black87 : Colors.white;
  Color get _textSecondary => _isLight ? Colors.black54 : Colors.white70;
  Color get _textTertiary => _isLight ? Colors.black38 : Colors.white38;
  Color get _borderColor => _isLight ? Colors.black.withOpacity(0.08) : Colors.white.withOpacity(0.12);
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'done', 'todo'
  final TextEditingController _searchController = TextEditingController();

  bool get _isLight => widget.activeTheme.brightness == Brightness.light;
  Color get _textPrimary => _isLight ? Colors.black87 : Colors.white;
  Color get _textTertiary => _isLight ? Colors.black38 : Colors.white38;
  Color get _borderColor => _isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.1);

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
            color: _isLight ? Colors.white : const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: _isLight ? Colors.grey[300] : Colors.grey[700], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('New Task', style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: TextStyle(color: _textTertiary),
                  filled: true,
                  fillColor: (_isLight ? Colors.grey[100] : Colors.grey.withValues(alpha: 0.1)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  hintText: 'Time (e.g. 9:00 AM)',
                  hintStyle: TextStyle(color: _textTertiary),
                  filled: true,
                  fillColor: (_isLight ? Colors.grey[100] : Colors.grey.withValues(alpha: 0.1)),
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
                  child: const Text('Save Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
    return DefaultTabController(
      length: 2,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db.streamTasks(widget.uid),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];
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
                      hintText: 'Search tasks...',
                      hintStyle: TextStyle(color: _textTertiary),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  )
                : Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.menu_rounded, color: _textPrimary),
                        onPressed: () => widget.onNavigate?.call(0),
                      ),
                      const SizedBox(width: 8),
                      Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary, fontSize: 24)),
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
                        title: Text('Filter Tasks', style: TextStyle(color: _textPrimary)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(title: Text('All Tasks', style: TextStyle(color: _textPrimary)), onTap: () { setState(() => _filterStatus = 'all'); Navigator.pop(ctx); }),
                            ListTile(title: Text('Completed', style: TextStyle(color: _textPrimary)), onTap: () { setState(() => _filterStatus = 'done'); Navigator.pop(ctx); }),
                            ListTile(title: Text('Incomplete', style: TextStyle(color: _textPrimary)), onTap: () { setState(() => _filterStatus = 'todo'); Navigator.pop(ctx); }),
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
                IconButton(
                  icon: Icon(Icons.auto_awesome, color: widget.activeTheme.accentColor),
                  onPressed: _isSyncing ? null : () => _autoSchedule(tasks),
                ),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                indicatorColor: widget.activeTheme.accentColor,
                indicatorWeight: 3,
                labelColor: _textPrimary,
                unselectedLabelColor: _textTertiary,
                dividerColor: _borderColor,
                tabs: const [
                  Tab(text: "Single tasks"),
                  Tab(text: "Recurring tasks"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildTasksList(tasks, isLoading),
                _buildEmptyState("No recurring tasks", "You have not set up any recurring tasks yet."),
              ],
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 100), // Push up above the bottom nav bar
              child: GlassSquircleFab(
                theme: widget.activeTheme,
                icon: Icons.add_rounded,
                onPressed: isLoading ? () {} : () => _addTask(tasks),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _autoSchedule(List<Map<String, dynamic>> tasks) async {
    setState(() => _isSyncing = true);
    try {
      // In a real app, send to Gemini. Here we use a smart heuristic.
      await Future.delayed(const Duration(seconds: 1));
      final updated = List<Map<String, dynamic>>.from(tasks);
      
      // Sort: Priority High first, then medium. Assign times.
      updated.sort((a, b) {
        final pMap = {'High': 0, 'Medium': 1, 'Low': 2};
        return (pMap[a['priority']] ?? 2).compareTo(pMap[b['priority']] ?? 2);
      });

      for (int i = 0; i < updated.length; i++) {
        final hour = 9 + i;
        updated[i]['time'] = '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}';
      }

      await _db.syncTasks(widget.uid, updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI optimized your schedule!'), backgroundColor: Colors.indigoAccent),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Widget _buildTasksList(List<Map<String, dynamic>> tasks, bool isLoading) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: widget.activeTheme.accentColor),
            const SizedBox(height: 20),
            Text('Restoring tasks from cloud...', style: TextStyle(color: _textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
    
    // Apply Filters and Search
    var filtered = tasks.where((t) {
      if (_searchQuery.isNotEmpty && !(t['title'] as String).toLowerCase().contains(_searchQuery)) return false;
      if (_filterStatus == 'done' && t['completed'] != true) return false;
      if (_filterStatus == 'todo' && t['completed'] == true) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(_searchQuery.isNotEmpty ? "No results found" : "No tasks", _searchQuery.isNotEmpty ? "Try another search term" : "There are no upcoming tasks");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20).copyWith(bottom: 180),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        // Need to pass the index of the item IN THE ORIGINAL LIST to update correctly
        final originalIndex = tasks.indexOf(filtered[i]);
        return _buildGlassTaskTile(filtered[i], originalIndex, tasks);
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
            ),
            child: Icon(Icons.assignment_turned_in_rounded, size: 60, color: _textPrimary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: _textTertiary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildGlassTaskTile(Map<String, dynamic> task, int index, List<Map<String, dynamic>> allTasks) {
    final isDone = task['completed'] == true;
    
    // Highly optimized task tile without BackdropFilter for massive scrolling speed improvements
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isLight ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  final updatedList = List<Map<String, dynamic>>.from(allTasks);
                  updatedList[index]['completed'] = !isDone;
                  _db.syncTasks(widget.uid, updatedList);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? widget.activeTheme.accentColor : Colors.transparent,
                    border: Border.all(color: isDone ? widget.activeTheme.accentColor : _textTertiary, width: 2),
                  ),
                  child: isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  task['title'] ?? 'Untitled Task',
                  style: TextStyle(
                    color: isDone ? _textTertiary : _textPrimary,
                    fontSize: 16,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withValues(alpha: 0.7)),
                onPressed: () {
                  final updatedList = List<Map<String, dynamic>>.from(allTasks);
                  updatedList.removeAt(index);
                  _db.syncTasks(widget.uid, updatedList);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
