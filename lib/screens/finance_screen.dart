import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/firebase_service.dart';

class FinanceScreen extends StatefulWidget {
  final String uid;
  final String currency;
  const FinanceScreen({super.key, required this.uid, required this.currency});

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
            color: const Color(0xFF1A1A2E),
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
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Description',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Amount',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixText: '${widget.currency} ',
                  prefixStyle: const TextStyle(color: Colors.white),
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
                            final title = titleController.text.trim();
                            
                            // Optimistic Pop: Close keyboard and modal immediately
                            Navigator.pop(ctx);
                            
                            final updatedList = List<Map<String, dynamic>>.from(currentTxs);
                            updatedList.add({
                              'title': title,
                              'amount': amount,
                              'date': 'Today',
                            });
                            await _db.syncFinance(widget.uid, updatedList);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
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
                            final title = titleController.text.trim();

                            // Optimistic Pop
                            Navigator.pop(ctx);

                            final updatedList = List<Map<String, dynamic>>.from(currentTxs);
                            updatedList.add({
                              'title': title,
                              'amount': -amount,
                              'date': 'Today',
                            });
                            await _db.syncFinance(widget.uid, updatedList);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBC13FE),
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.streamFinance(widget.uid),
      builder: (context, snapshot) {
        final txs = snapshot.data ?? [];
        
        final totalIncome = txs.where((tx) => tx['amount'] > 0).fold(0.0, (sum, tx) => sum + tx['amount']);
        final totalExpenses = txs.where((tx) => tx['amount'] < 0).fold(0.0, (sum, tx) => sum + tx['amount'].abs());
        final balance = totalIncome - totalExpenses;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0C29),
          appBar: AppBar(
            title: const Text('Finance Hub', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(balance, totalIncome, totalExpenses),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      TextButton(
                        onPressed: () {},
                        child: Text("See All", style: TextStyle(color: const Color(0xFFBC13FE).withOpacity(0.8))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  txs.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long, size: 60, color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text("No transactions recorded", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                                const SizedBox(height: 8),
                                Text("Tap + to add your first transaction", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: txs.length,
                          itemBuilder: (context, index) {
                            final tx = txs[index];
                            return _buildTransactionItem(tx, index, txs);
                          },
                        ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addTransaction(txs),
            backgroundColor: const Color(0xFFBC13FE),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      }
    );
  }

  Widget _buildBalanceCard(double balance, double income, double expenses) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFBC13FE).withOpacity(0.2),
                const Color(0xFF4A00E0).withOpacity(0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFBC13FE).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Balance', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '\$${balance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBalanceStat('Income', '+\$${income.toStringAsFixed(0)}', Colors.greenAccent),
                  _buildBalanceStat('Expenses', '\$${expenses.toStringAsFixed(0)}', Colors.orangeAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceStat(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 4),
        Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx, int index, List<Map<String, dynamic>> currentTxs) {
    final bool isIncome = tx['amount'] > 0;

    return GestureDetector(
      onLongPress: () async {
        final updatedList = List<Map<String, dynamic>>.from(currentTxs);
        updatedList.removeAt(index);
        await _db.syncFinance(widget.uid, updatedList);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isIncome ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? Colors.greenAccent : Colors.redAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(tx['date'], style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                    ],
                  ),
                ),
                Text(
                  (isIncome ? '+' : '-') + '\$${tx['amount'].abs().toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.greenAccent : Colors.redAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
