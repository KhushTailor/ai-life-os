class TaskModel {
  final String id;
  final String title;
  final String time;
  final String priority;
  final String category;
  final bool isDone;

  TaskModel({
    required this.id,
    required this.title,
    required this.time,
    required this.priority,
    required this.category,
    this.isDone = false,
  });
}

class GoalModel {
  final String id;
  final String title;
  final double progress;
  final String deadline;

  GoalModel({
    required this.id,
    required this.title,
    required this.progress,
    required this.deadline,
  });
}

class TransactionModel {
  final String id;
  final double amount;
  final String category;
  final String type; // 'income' or 'expense'
  final String date;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
  });
}
