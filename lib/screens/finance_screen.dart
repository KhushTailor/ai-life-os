import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_squircle_fab.dart';
import '../providers/providers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class FinanceScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;
  const FinanceScreen({super.key, this.onNavigate});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'income', 'expense'
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

  void _addTransaction(String uid, List<Map<String, dynamic>> currentTxs, String currency, GlassTheme activeTheme) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isAIProcessing = false;
    final isLight = activeTheme.brightness == Brightness.light;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.1);
    final textPrimary = isLight ? Colors.black87 : Colors.white;
    final textTertiary = isLight ? Colors.black38 : Colors.white38;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
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
                  Text('New Transaction', style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Description',
                      hintStyle: TextStyle(color: textTertiary),
                      filled: true,
                      fillColor: (isLight ? Colors.grey[100] : Colors.grey.withValues(alpha: 0.1)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Amount',
                      hintStyle: TextStyle(color: textTertiary),
                      filled: true,
                      fillColor: (isLight ? Colors.grey[100] : Colors.grey.withValues(alpha: 0.1)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixText: '$currency ',
                      prefixStyle: TextStyle(color: textPrimary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isAIProcessing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: activeTheme.accentColor)),
                          const SizedBox(width: 12),
                          Text('AI is categorizing...', style: TextStyle(color: textTertiary, fontSize: 13)),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: isAIProcessing ? null : () async {
                              if (titleController.text.trim().isNotEmpty && amountController.text.trim().isNotEmpty) {
                                final amount = double.tryParse(amountController.text.trim()) ?? 0;
                                final description = titleController.text.trim();
                                
                                setModalState(() => isAIProcessing = true);
                                final category = await ref.read(aiServiceProvider).categorizeExpense(description);
                                
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                final updatedList = List<Map<String, dynamic>>.from(currentTxs);
                                updatedList.add({
                                  'title': description, 
                                  'amount': amount, 
                                  'date': 'Today',
                                  'category': category,
                                  'type': 'income'
                                });
                                debugPrint("SYNCING FINANCE TO CLOUD for $uid: ${updatedList.length} items");
                                await ref.read(firebaseServiceProvider).syncFinance(uid, updatedList);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.greenAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Income', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isAIProcessing ? null : () async {
                              if (titleController.text.trim().isNotEmpty && amountController.text.trim().isNotEmpty) {
                                final amount = double.tryParse(amountController.text.trim()) ?? 0;
                                final description = titleController.text.trim();

                                setModalState(() => isAIProcessing = true);
                                final category = await ref.read(aiServiceProvider).categorizeExpense(description);

                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                final updatedList = List<Map<String, dynamic>>.from(currentTxs);
                                updatedList.add({
                                  'title': description, 
                                  'amount': -amount, 
                                  'date': 'Today',
                                  'category': category,
                                  'type': 'expense'
                                });
                                debugPrint("SYNCING FINANCE TO CLOUD for $uid: ${updatedList.length} items");
                                await ref.read(firebaseServiceProvider).syncFinance(uid, updatedList);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: activeTheme.accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final settings = ref.watch(settingsProvider);
    final activeTheme = ref.watch(activeThemeProvider);
    final financeAsync = ref.watch(financeProvider);
    
    final uid = user?.uid ?? '';
    final currency = settings.currency;
    final txs = financeAsync.value ?? [];
    final isLoading = financeAsync.isLoading && txs.isEmpty;
    
    final isLight = activeTheme.brightness == Brightness.light;
    final textPrimary = isLight ? Colors.black87 : Colors.white;
    final textSecondary = isLight ? Colors.black54 : Colors.white70;
    final textTertiary = isLight ? Colors.black38 : Colors.white38;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.1);

    if (financeAsync.hasValue) {
       debugPrint("FINANCE LOADED: ${txs.length} items for $uid");
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
                hintText: 'Search transactions...',
                hintStyle: TextStyle(color: textTertiary),
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            )
          : Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu, color: textPrimary),
                  onPressed: () => widget.onNavigate?.call(5),
                ),
                const SizedBox(width: 8),
                Text('Finance', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 22)),
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
                  title: Text('Filter Transactions', style: TextStyle(color: textPrimary)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(title: Text('All', style: TextStyle(color: textPrimary)), onTap: () { setState(() => _filterStatus = 'all'); Navigator.pop(ctx); }),
                      ListTile(title: Text('Income Only', style: TextStyle(color: textPrimary)), onTap: () { setState(() => _filterStatus = 'income'); Navigator.pop(ctx); }),
                      ListTile(title: Text('Expenses Only', style: TextStyle(color: textPrimary)), onTap: () { setState(() => _filterStatus = 'expense'); Navigator.pop(ctx); }),
                    ]
                  ),
                )
              );
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(uid, txs, isLoading, currency, activeTheme, isLight, textPrimary, textSecondary, textTertiary, borderColor),
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
              onPressed: (isLoading || uid.isEmpty) ? () {} : () => _addTransaction(uid, txs, currency, activeTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String uid, List<Map<String, dynamic>> txs, bool isLoading, String currency, GlassTheme theme, bool isLight, Color textPrimary, Color textSecondary, Color textTertiary, Color borderColor) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.accentColor),
            const SizedBox(height: 20),
            Text('Restoring finances from cloud...', style: TextStyle(color: textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    final income = txs.where((tx) => (tx['amount'] ?? 0) > 0).fold(0.0, (s, t) => s + (t['amount'] ?? 0));
    final expenses = txs.where((tx) => (tx['amount'] ?? 0) < 0).fold(0.0, (s, t) => s + (t['amount'] ?? 0).abs());

    var filtered = txs.where((tx) {
      if (_searchQuery.isNotEmpty && !(tx['title'] as String).toLowerCase().contains(_searchQuery)) return false;
      final amount = tx['amount'] ?? 0;
      if (_filterStatus == 'income' && amount <= 0) return false;
      if (_filterStatus == 'expense' && amount >= 0) return false;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20).copyWith(bottom: 180),
      children: [
        _buildGlassCard(
          theme,
          borderColor,
          child: Column(
            children: [
              Text('Net Balance', style: TextStyle(color: textTertiary, fontSize: 12)),
              const SizedBox(height: 8),
              Text('$currency${(income - expenses).toStringAsFixed(0)}', 
                style: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('Income', '$currency${income.toStringAsFixed(0)}', Colors.greenAccent, textTertiary),
                  _buildMiniStat('Expenses', '$currency${expenses.toStringAsFixed(0)}', Colors.redAccent, textTertiary),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSpendingChart(txs, theme, borderColor, textSecondary),
        const SizedBox(height: 24),
        Text('AI CATEGORIES', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
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
                    child: Icon(Icons.account_balance_wallet_outlined, size: 60, color: textPrimary.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 24),
                  Text(_searchQuery.isNotEmpty ? 'No results found' : 'No transactions yet', style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_searchQuery.isNotEmpty ? 'Try a different keyword' : "Add your first expense or income", style: TextStyle(color: textTertiary, fontSize: 14)),
                ],
              ),
            ),
          )
        else
          ...filtered.reversed.map((tx) => _buildTransactionItem(uid, tx, txs.indexOf(tx), txs, currency, theme, isLight, textPrimary, borderColor)),
      ],
    );
  }

  Widget _buildGlassCard(GlassTheme theme, Color borderColor, {required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.cardBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: theme.blur, sigmaY: theme.blur),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: theme.cardGradient),
            borderRadius: BorderRadius.circular(theme.cardBorderRadius),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, Color textTertiary) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: textTertiary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildTransactionItem(String uid, Map<String, dynamic> tx, int index, List<Map<String, dynamic>> allTxs, String currency, GlassTheme theme, bool isLight, Color textPrimary, Color borderColor) {
    final amount = tx['amount'] ?? 0;
    final isExpense = amount < 0;
    final category = tx['category'] ?? 'Other';
    final textTertiary = isLight ? Colors.black38 : Colors.white38;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isExpense ? Colors.redAccent : Colors.greenAccent).withValues(alpha: 0.1),
            child: Icon(isExpense ? Icons.arrow_downward : Icons.arrow_upward, color: isExpense ? Colors.redAccent : Colors.greenAccent, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['title'] ?? 'Unknown', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                Text(category.toUpperCase(), style: TextStyle(color: theme.accentColor.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'}$currency${amount.abs().toStringAsFixed(0)}',
                style: TextStyle(color: isExpense ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  final updated = List<Map<String, dynamic>>.from(allTxs);
                  updated.removeAt(index);
                  ref.read(firebaseServiceProvider).syncFinance(uid, updated);
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.delete_outline, size: 14, color: textTertiary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(List<Map<String, dynamic>> txs, GlassTheme theme, Color borderColor, Color textSecondary) {
    Map<String, double> categories = {};
    for (var tx in txs) {
      if ((tx['amount'] ?? 0) < 0) {
        String cat = tx['category'] ?? 'Other';
        categories[cat] = (categories[cat] ?? 0) + (tx['amount'] as double).abs();
      }
    }
    
    if (categories.isEmpty) return const SizedBox.shrink();

    return _buildGlassCard(
      theme,
      borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SPENDING BREAKDOWN', style: TextStyle(color: textSecondary, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 30,
                sections: categories.entries.map((e) {
                  return PieChartSectionData(
                    color: _getCategoryColor(e.key),
                    value: e.value,
                    radius: 12,
                    showTitle: false,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food': return Colors.orangeAccent;
      case 'Transport': return Colors.blueAccent;
      case 'Shopping': return Colors.purpleAccent;
      case 'Bills': return Colors.redAccent;
      case 'Entertainment': return Colors.greenAccent;
      case 'Health': return Colors.cyanAccent;
      default: return Colors.grey;
    }
  }
}
