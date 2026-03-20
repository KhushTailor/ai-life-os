import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_squircle_fab.dart';
import '../providers/providers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class PlannerScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;

  const PlannerScreen({super.key, this.onNavigate});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  bool _isSearching = false;
  bool _isSyncing = false;
  String _searchQuery = '';
  String _filterStatus = 'all';
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final TextEditingController _searchController = TextEditingController();

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          if (val.finalResult) {
            setState(() {
              _isListening = false;
              _searchQuery = val.recognizedWords.toLowerCase();
              _searchController.text = val.recognizedWords;
              _isSearching = true;
            });
          }
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _addTask(String uid, List<Map<String, dynamic>> currentTasks, GlassTheme activeTheme) {
    final titleController = TextEditingController();
    final timeController = TextEditingController();
    final isLight = activeTheme.brightness == Brightness.light;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12);
    final textPrimary = isLight ? Colors.black87 : Colors.white;
    final textTertiary = isLight ? Colors.black38 : Colors.white38;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: isLight ? Colors.grey[300] : Colors.grey[700], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('New Task', style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: TextStyle(color: textTertiary),
                  filled: true,
                  fillColor: (isLight ? Colors.grey[100] : Colors.grey.withValues(alpha: 0.1)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Time (e.g. 9:00 AM)',
                  hintStyle: TextStyle(color: textTertiary),
                  filled: true,
                  fillColor: (isLight ? Colors.grey[100] : Colors.grey.withValues(alpha: 0.1)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.access_time_rounded, color: activeTheme.accentColor),
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
                      
                      debugPrint("SYNCING TASKS TO CLOUD for $uid: ${updatedList.length} items");
                      await ref.read(firebaseServiceProvider).syncTasks(uid, updatedList);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeTheme.accentColor,
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
    final user = ref.watch(authStateProvider).value;
    final activeTheme = ref.watch(activeThemeProvider);
    final tasksAsync = ref.watch(tasksProvider);
    
    final uid = user?.uid ?? '';
    final tasks = tasksAsync.value ?? [];
    final isLoading = tasksAsync.isLoading && tasks.isEmpty;
    
    final isLight = activeTheme.brightness == Brightness.light;
    final textPrimary = isLight ? Colors.black87 : Colors.white;
    final textSecondary = isLight ? Colors.black54 : Colors.white70;
    final textTertiary = isLight ? Colors.black38 : Colors.white38;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12);

    if (tasksAsync.hasValue) {
       debugPrint("TASKS LOADED: ${tasks.length} items for $uid");
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: _isSearching 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: TextStyle(color: textTertiary),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              )
            : Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu_rounded, color: textPrimary),
                    onPressed: () => widget.onNavigate?.call(5), 
                  ),
                  const SizedBox(width: 8),
                  Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 24)),
                ],
              ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search_rounded, color: textPrimary), 
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
              icon: Icon(Icons.filter_list_rounded, color: _filterStatus != 'all' ? activeTheme.accentColor : textPrimary), 
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isLight ? Colors.white : const Color(0xFF1A1A2E),
                    title: Text('Filter Tasks', style: TextStyle(color: textPrimary)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(title: Text('All Tasks', style: TextStyle(color: textPrimary)), onTap: () { setState(() => _filterStatus = 'all'); Navigator.pop(ctx); }),
                        ListTile(title: Text('Completed', style: TextStyle(color: textPrimary)), onTap: () { setState(() => _filterStatus = 'done'); Navigator.pop(ctx); }),
                        ListTile(title: Text('Incomplete', style: TextStyle(color: textPrimary)), onTap: () { setState(() => _filterStatus = 'todo'); Navigator.pop(ctx); }),
                      ]
                    ),
                  )
                );
              }
            ),
            IconButton(
              icon: Icon(Icons.auto_awesome, color: activeTheme.accentColor),
              onPressed: _isSyncing || uid.isEmpty ? null : () => _autoSchedule(uid, tasks),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            indicatorColor: activeTheme.accentColor,
            indicatorWeight: 3,
            labelColor: textPrimary,
            unselectedLabelColor: textTertiary,
            dividerColor: borderColor,
            tabs: const [
              Tab(text: "Single tasks"),
              Tab(text: "Recurring tasks"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTasksList(uid, tasks, isLoading, activeTheme, textPrimary, textSecondary, textTertiary, borderColor),
            _buildEmptyState("No recurring tasks", "You have not set up any recurring tasks yet.", isLight, textPrimary, textTertiary),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90, right: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassSquircleFab(
                theme: activeTheme,
                icon: _isListening ? Icons.mic : Icons.mic_none_rounded,
                onPressed: _listen,
                color: _isListening ? Colors.redAccent : activeTheme.accentColor.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              GlassSquircleFab(
                theme: activeTheme,
                icon: Icons.add_rounded,
                onPressed: (isLoading || uid.isEmpty) ? () {} : () => _addTask(uid, tasks, activeTheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _autoSchedule(String uid, List<Map<String, dynamic>> tasks) async {
    setState(() => _isSyncing = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      final updated = List<Map<String, dynamic>>.from(tasks);
      
      updated.sort((a, b) {
        final pMap = {'High': 0, 'Medium': 1, 'Low': 2};
        return (pMap[a['priority']] ?? 2).compareTo(pMap[b['priority']] ?? 2);
      });

      for (int i = 0; i < updated.length; i++) {
        final hour = 9 + i;
        updated[i]['time'] = '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}';
      }

      await ref.read(firebaseServiceProvider).syncTasks(uid, updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI optimized your schedule!'), backgroundColor: Colors.indigoAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Widget _buildTasksList(String uid, List<Map<String, dynamic>> tasks, bool isLoading, GlassTheme theme, Color textPrimary, Color textSecondary, Color textTertiary, Color borderColor) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.accentColor),
            const SizedBox(height: 20),
            Text('Restoring tasks from cloud...', style: TextStyle(color: textSecondary, fontSize: 13)),
          ],
        ),
      );
    }
    
    var filtered = tasks.where((t) {
      if (_searchQuery.isNotEmpty && !(t['title'] as String).toLowerCase().contains(_searchQuery)) return false;
      if (_filterStatus == 'done' && t['completed'] != true) return false;
      if (_filterStatus == 'todo' && t['completed'] == true) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(_searchQuery.isNotEmpty ? "No results found" : "No tasks", _searchQuery.isNotEmpty ? "Try another search term" : "There are no upcoming tasks", theme.brightness == Brightness.light, textPrimary, textTertiary);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20).copyWith(bottom: 180),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final originalIndex = tasks.indexOf(filtered[i]);
        return _buildGlassTaskTile(uid, filtered[i], originalIndex, tasks, theme, textPrimary, textTertiary, borderColor);
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, bool isLight, Color textPrimary, Color textTertiary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
            ),
            child: Icon(Icons.assignment_turned_in_rounded, size: 60, color: textPrimary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: textTertiary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildGlassTaskTile(String uid, Map<String, dynamic> task, int index, List<Map<String, dynamic>> allTasks, GlassTheme theme, Color textPrimary, Color textTertiary, Color borderColor) {
    final isDone = task['completed'] == true;
    final isLight = theme.brightness == Brightness.light;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLight ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  final updatedList = List<Map<String, dynamic>>.from(allTasks);
                  updatedList[index]['completed'] = !isDone;
                  ref.read(firebaseServiceProvider).syncTasks(uid, updatedList);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? theme.accentColor : Colors.transparent,
                    border: Border.all(color: isDone ? theme.accentColor : textTertiary, width: 2),
                  ),
                  child: isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  task['title'] ?? 'Untitled Task',
                  style: TextStyle(
                    color: isDone ? textTertiary : textPrimary,
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
                  ref.read(firebaseServiceProvider).syncTasks(uid, updatedList);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
