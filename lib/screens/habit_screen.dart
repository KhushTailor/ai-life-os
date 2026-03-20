import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_squircle_fab.dart';
import '../providers/providers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HabitScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;

  const HabitScreen({super.key, this.onNavigate});

  @override
  ConsumerState<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends ConsumerState<HabitScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'done', 'todo'
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

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

  void _addHabit(String uid, List<Map<String, dynamic>> currentHabits, GlassTheme activeTheme) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final isLight = activeTheme.brightness == Brightness.light;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.1);
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
              Text('New Habit', style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'What is your goal?',
                  hintStyle: TextStyle(color: textTertiary),
                  filled: true,
                  fillColor: (isLight ? Colors.grey[100] : Colors.grey.withValues(alpha: 0.1)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'Category (e.g. Health, Work)',
                  hintStyle: TextStyle(color: textTertiary),
                  filled: true,
                  fillColor: (isLight ? Colors.grey[100] : Colors.grey.withValues(alpha: 0.1)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.category_rounded, color: activeTheme.accentColor),
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
                        'difficulty': 'Easy',
                      });
                      
                      debugPrint("SYNCING HABITS TO CLOUD for $uid: ${updatedList.length} items");
                      await ref.read(firebaseServiceProvider).syncHabits(uid, updatedList);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeTheme.accentColor,
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

  void _showEvolveDialog(String uid, Map<String, dynamic> habit, int index, List<Map<String, dynamic>> allHabits, GlassTheme activeTheme, bool isLight, Color textPrimary, Color textSecondary, Color textTertiary) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isLight ? Colors.white : const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Habit Evolution! 🔥', style: TextStyle(color: textPrimary)),
        content: Text(
          'Your ${habit['name']} streak is ${habit['streak']}! \n\nAI suggests increasing your difficulty level for faster growth.',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Not Yet', style: TextStyle(color: textTertiary))),
          ElevatedButton(
            onPressed: () {
              final updated = List<Map<String, dynamic>>.from(allHabits);
              updated[index]['name'] = '${habit['name']} (LVL UP)';
              updated[index]['streak'] = 0;
              updated[index]['difficulty'] = 'Medium';
              ref.read(firebaseServiceProvider).syncHabits(uid, updated);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: activeTheme.accentColor),
            child: const Text('EVOLVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final activeTheme = ref.watch(activeThemeProvider);
    final habitsAsync = ref.watch(habitsProvider);
    
    final uid = user?.uid ?? '';
    final habits = habitsAsync.value ?? [];
    final isLoading = habitsAsync.isLoading && habits.isEmpty;
    
    final isLight = activeTheme.brightness == Brightness.light;
    final textPrimary = isLight ? Colors.black87 : Colors.white;
    final textSecondary = isLight ? Colors.black54 : Colors.white70;
    final textTertiary = isLight ? Colors.black38 : Colors.white38;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.1);

    if (habitsAsync.hasValue) {
       debugPrint("HABITS LOADED: ${habits.length} items for $uid");
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search habits...',
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
                Text('Habits', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 24)),
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
                  title: Text('Filter Habits', style: TextStyle(color: textPrimary)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(title: Text('All Habits', style: TextStyle(color: textPrimary)), onTap: () { setState(() => _filterStatus = 'all'); Navigator.pop(ctx); }),
                      ListTile(title: Text('Completed Today', style: TextStyle(color: textPrimary)), onTap: () { setState(() => _filterStatus = 'done'); Navigator.pop(ctx); }),
                      ListTile(title: Text('To Do', style: TextStyle(color: textPrimary)), onTap: () { setState(() => _filterStatus = 'todo'); Navigator.pop(ctx); }),
                    ]
                  ),
                )
              );
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(uid, habits, isLoading, activeTheme, isLight, textPrimary, textSecondary, textTertiary, borderColor),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90, right: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassSquircleFab(
              theme: activeTheme,
              icon: _isListening ? Icons.mic : Icons.mic_none_rounded,
              onPressed: _listen,
            ),
            const SizedBox(height: 16),
            GlassSquircleFab(
              theme: activeTheme,
              icon: Icons.add_rounded,
              onPressed: (isLoading || uid.isEmpty) ? () {} : () => _addHabit(uid, habits, activeTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String uid, List<Map<String, dynamic>> habits, bool isLoading, GlassTheme theme, bool isLight, Color textPrimary, Color textSecondary, Color textTertiary, Color borderColor) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.accentColor),
            const SizedBox(height: 20),
            Text('Restoring habits from cloud...', style: TextStyle(color: textSecondary, fontSize: 13)),
          ],
        ),
      );
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
                    color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Icon(Icons.emoji_events_rounded, size: 60, color: Colors.orangeAccent.withValues(alpha: 0.8)),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10, right: 10),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(_searchQuery.isNotEmpty ? 'No results found' : 'There are no active habits', style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_searchQuery.isNotEmpty ? 'Try another search term' : "It's always a good day for a new start", style: TextStyle(color: textTertiary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20).copyWith(bottom: 180),
      children: [
        _buildHabitSummaryChart(habits, theme),
        const SizedBox(height: 24),
        ...filtered.asMap().entries.map((e) {
          final originalIndex = habits.indexOf(e.value);
          return _buildGlassHabitCard(uid, e.value, originalIndex, habits, theme, isLight, textPrimary, textSecondary, textTertiary, borderColor);
        }),
      ],
    );
  }

  Widget _buildHabitSummaryChart(List<Map<String, dynamic>> habits, GlassTheme theme) {
    if (habits.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HABIT CONSISTENCY', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 15),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: habits.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['streak'] as int? ?? 0).toDouble())).toList(),
                    isCurved: true,
                    color: theme.accentColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.accentColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassHabitCard(String uid, Map<String, dynamic> habit, int index, List<Map<String, dynamic>> allHabits, GlassTheme theme, bool isLight, Color textPrimary, Color textSecondary, Color textTertiary, Color borderColor) {
    final streak = habit['streak'] ?? 0;
    final isDone = habit['status'] == 'done';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isLight ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.2),
            border: Border.all(color: borderColor),
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
                      ref.read(firebaseServiceProvider).syncHabits(uid, updated);
                      
                      if (!isDone && (streak + 1) >= 7) {
                        _showEvolveDialog(uid, updated[index], index, updated, theme, isLight, textPrimary, textSecondary, textTertiary);
                      }
                    },
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: isDone ? Colors.greenAccent.withValues(alpha: 0.2) : theme.accentColor.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDone ? Colors.greenAccent : theme.accentColor, width: 2),
                      ),
                      child: isDone ? const Icon(Icons.check, color: Colors.greenAccent, size: 20) : null,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit['name'], style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(habit['category'] ?? 'General', style: TextStyle(color: textTertiary, fontSize: 11, letterSpacing: 0.5)),
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
                      color: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
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
    );
  }
}
