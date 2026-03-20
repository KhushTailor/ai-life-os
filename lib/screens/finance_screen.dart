import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_squircle_fab.dart';

class FinanceScreen extends StatefulWidget {
  final String uid;
  final String currency;
  final GlassTheme activeTheme;
  final Function(int)? onNavigate;
  const FinanceScreen({super.key, required this.uid, required this.currency, required this.activeTheme, this.onNavigate});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final FirebaseService _db = FirebaseService();
  bool _isSearching = false;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'income', 'expense'
  final TextEditingController _searchController = TextEditingController();

  bool get _isLight => widget.activeTheme.brightness == Brightness.light;
  Color get _textPrimary => _isLight ? Colors.black87 : Colors.white;
  Color get _textSecondary => _isLight ? Colors.black54 : Colors.white70;
  Color get _textTertiary => _isLight ? Colors.black38 : Colors.white38;
  Color get _borderColor => _isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.1);

  void _addTransaction(List<Map<String, dynamic>> currentTxs) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isAIProcessing = false;

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
                color: _isLight ? Colors.white : const Color(0xFF1A1A2E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: _isLight ? Colors.grey[300] : Colors.grey[700], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Text('New Transaction', style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Description',
                      hintStyle: TextStyle(color: _textTertiary),
                      filled: true,
                      fillColor: (_isLight ? Colors.grey[100] : Colors.grey.withValues(alpha: 0.1)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Amount',
                      hintStyle: TextStyle(color: _textTertiary),
                      filled: true,
                      fillColor: (_isLight ? Colors.grey[100] : Colors.grey.withValues(alpha: 0.1)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixText: '${widget.currency} ',
                      prefixStyle: TextStyle(color: _textPrimary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isAIProcessing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: widget.activeTheme.accentColor)),
                          const SizedBox(width: 12),
                          Text('AI is categorizing...', style: TextStyle(color: _textTertiary, fontSize: 13)),
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
                                final category = await _db.getAIExpenseCategory(description);
                                
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
                                await _db.syncFinance(widget.uid, updatedList);
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
                                final category = await _db.getAIExpenseCategory(description);

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
                                await _db.syncFinance(widget.uid, updatedList);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.activeTheme.accentColor,
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.streamFinance(widget.uid),
      builder: (context, snapshot) {
        final txs = snapshot.data ?? [];
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
                      hintText: 'Search transactions...',
                      hintStyle: TextStyle(color: _textTertiary),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  )
                : Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.menu, color: _textPrimary),
                        onPressed: () => widget.onNavigate?.call(5),
                      ),
                      const SizedBox(width: 8),
                      Text('Finance', style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary, fontSize: 22)),
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
                        title: Text('Filter Transactions', style: TextStyle(color: _textPrimary)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(title: Text('All', style: TextStyle(color: _textPrimary)), onTap: () { setState(() => _filterStatus = 'all'); Navigator.pop(ctx); }),
                            ListTile(title: Text('Income Only', style: TextStyle(color: _textPrimary)), onTap: () { setState(() => _filterStatus = 'income'); Navigator.pop(ctx); }),
                            ListTile(title: Text('Expenses Only', style: TextStyle(color: _textPrimary)), onTap: () { setState(() => _filterStatus = 'expense'); Navigator.pop(ctx); }),
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
                const SizedBox(width: 8),
              ],
          ),
          body: _buildBody(txs, isLoading),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: GlassSquircleFab(
              theme: widget.activeTheme,
              icon: Icons.add_rounded,
              onPressed: isLoading ? () {} : () => _addTransaction(txs),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> txs, bool isLoading) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: widget.activeTheme.accentColor),
            const SizedBox(height: 20),
            Text('Restoring finances from cloud...', style: TextStyle(color: _textSecondary, fontSize: 13)),
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
          child: Column(
            children: [
              Text('Net Balance', style: TextStyle(color: _textTertiary, fontSize: 12)),
              const SizedBox(height: 8),
              Text('${widget.currency}${(income - expenses).toStringAsFixed(0)}', 
                style: TextStyle(color: _textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('Income', '${widget.currency}${income.toStringAsFixed(0)}', Colors.greenAccent),
                  _buildMiniStat('Expenses', '${widget.currency}${expenses.toStringAsFixed(0)}', Colors.redAccent),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSpendingChart(txs),
        const SizedBox(height: 24),
        Text('AI CATEGORIES', style: TextStyle(color: _textSecondary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
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
                      color: _isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
                    ),
                    child: Icon(Icons.account_balance_wallet_outlined, size: 60, color: _textPrimary.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 24),
                  Text(_searchQuery.isNotEmpty ? 'No results found' : 'No transactions yet', style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_searchQuery.isNotEmpty ? 'Try a different keyword' : "Add your first expense or income", style: TextStyle(color: _textTertiary, fontSize: 14)),
                ],
              ),
            ),
          )
        else
          ...filtered.reversed.map((tx) => _buildTransactionItem(tx, txs.indexOf(tx), txs)),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.activeTheme.cardBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.activeTheme.blur, sigmaY: widget.activeTheme.blur),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.activeTheme.cardGradient),
            borderRadius: BorderRadius.circular(widget.activeTheme.cardBorderRadius),
            border: Border.all(color: _borderColor),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: _textTertiary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx, int index, List<Map<String, dynamic>> allTxs) {
    final amount = tx['amount'] ?? 0;
    final isExpense = amount < 0;
    final category = tx['category'] ?? 'Other';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _borderColor),
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
                Text(tx['title'] ?? 'Unknown', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
                Text(category.toUpperCase(), style: TextStyle(color: widget.activeTheme.accentColor.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'}${widget.currency}${amount.abs().toStringAsFixed(0)}',
                style: TextStyle(color: isExpense ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  final updated = List<Map<String, dynamic>>.from(allTxs);
                  updated.removeAt(index);
                  _db.syncFinance(widget.uid, updated);
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.delete_outline, size: 14, color: _textTertiary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(List<Map<String, dynamic>> txs) {
    Map<String, double> categories = {};
    for (var tx in txs) {
      if ((tx['amount'] ?? 0) < 0) {
        String cat = tx['category'] ?? 'Other';
        categories[cat] = (categories[cat] ?? 0) + (tx['amount'] as double).abs();
      }
    }
    
    if (categories.isEmpty) return const SizedBox.shrink();

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SPENDING BREAKDOWN', style: TextStyle(color: _textSecondary, fontSize: 10, letterSpacing: 2)),
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
