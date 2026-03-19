import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/firebase_service.dart';
import '../theme/glass_theme.dart';

class FinanceScreen extends StatefulWidget {
  final String uid;
  final String currency;
  final GlassTheme activeTheme;
  const FinanceScreen({super.key, required this.uid, required this.currency, required this.activeTheme});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final FirebaseService _db = FirebaseService();

  void _addTransaction(List<Map<String, dynamic>> currentTxs, {bool isExpense = true}) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

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
              Text(
                isExpense ? 'Add Expense' : 'Add Income',
                style: TextStyle(color: widget.activeTheme.brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: TextStyle(color: widget.activeTheme.brightness == Brightness.dark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Description',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: widget.activeTheme.brightness == Brightness.dark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Amount',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixText: '${widget.currency} ',
                  prefixStyle: TextStyle(color: widget.activeTheme.brightness == Brightness.dark ? Colors.white : Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () async {
                          if (titleController.text.trim().isNotEmpty && amountController.text.trim().isNotEmpty) {
                            final amount = double.tryParse(amountController.text.trim()) ?? 0;
                            Navigator.pop(ctx);
                            final updatedList = List<Map<String, dynamic>>.from(currentTxs);
                            updatedList.add({'title': titleController.text.trim(), 'amount': amount, 'date': 'Today'});
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
                        onPressed: () async {
                          if (titleController.text.trim().isNotEmpty && amountController.text.trim().isNotEmpty) {
                            final amount = double.tryParse(amountController.text.trim()) ?? 0;
                            Navigator.pop(ctx);
                            final updatedList = List<Map<String, dynamic>>.from(currentTxs);
                            updatedList.add({'title': titleController.text.trim(), 'amount': -amount, 'date': 'Today'});
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Finance Tracker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _db.streamFinance(widget.uid),
        builder: (context, snapshot) {
          final txs = snapshot.data ?? [];
          final income = txs.where((tx) => tx['amount'] > 0).fold(0.0, (s, t) => s + t['amount']);
          final expenses = txs.where((tx) => tx['amount'] < 0).fold(0.0, (s, t) => s + t['amount'].abs());

          return ListView(
            padding: const EdgeInsets.all(20).copyWith(bottom: 120),
            children: [
              _buildGlassCard(
                child: Column(
                  children: [
                    Text('Net Balance', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    const SizedBox(height: 8),
                    Text('${widget.currency}${(income - expenses).toStringAsFixed(0)}', 
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Transactions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(onPressed: () => _addTransaction(txs), icon: Icon(Icons.add_circle_outline_rounded, color: widget.activeTheme.accentColor)),
                ],
              ),
              ...txs.reversed.map((tx) => _buildTransactionItem(tx)),
            ],
          );
        },
      ),
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
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final isExpense = tx['amount'] < 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isExpense ? Colors.redAccent : Colors.greenAccent).withOpacity(0.1),
            child: Icon(isExpense ? Icons.arrow_downward : Icons.arrow_upward, color: isExpense ? Colors.redAccent : Colors.greenAccent, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(tx['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Text(
            '${isExpense ? '-' : '+'}${widget.currency}${tx['amount'].abs().toStringAsFixed(0)}',
            style: TextStyle(color: isExpense ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
