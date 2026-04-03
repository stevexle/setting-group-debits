import 'package:uuid/uuid.dart';

enum Category {
  food,
  drink,
  shopping,
  transport,
  entertainment,
  home,
  health,
  other
}

class Transaction {
  final String id;
  final String description;
  final double amount;
  final String payerId;
  final List<String> participantIds;
  final DateTime date;
  final DateTime? updatedAt;
  final Category category;
  final bool isPayment;
  final Map<String, double>? customAmounts; // null = split equally

  Transaction({
    String? id,
    required this.description,
    required this.amount,
    required this.payerId,
    required this.participantIds,
    DateTime? date,
    this.updatedAt,
    this.category = Category.other,
    this.isPayment = false,
    this.customAmounts,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'payerId': payerId,
        'participantIds': participantIds,
        'date': date.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'category': category.name,
        'isPayment': isPayment,
        'customAmounts': customAmounts,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        description: json['description'],
        amount: json['amount'].toDouble(),
        payerId: json['payerId'],
        participantIds: List<String>.from(json['participantIds']),
        date: DateTime.parse(json['date']),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        category: Category.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => Category.other,
        ),
        isPayment: json['isPayment'] ?? false,
        customAmounts: json['customAmounts'] != null
            ? Map<String, double>.from(json['customAmounts']
                .map((k, v) => MapEntry(k, v.toDouble())))
            : null,
      );

  Transaction copyWith({
    String? description,
    double? amount,
    String? payerId,
    List<String>? participantIds,
    DateTime? updatedAt,
    Category? category,
    bool? isPayment,
    Map<String, double>? customAmounts,
  }) =>
      Transaction(
        id: id,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        payerId: payerId ?? this.payerId,
        participantIds: participantIds ?? this.participantIds,
        date: date,
        updatedAt: updatedAt ?? this.updatedAt,
        category: category ?? this.category,
        isPayment: isPayment ?? this.isPayment,
        customAmounts: customAmounts ?? this.customAmounts,
      );
}

class Settlement {
  final String fromId;
  final String toId;
  final double amount;

  Settlement({
    required this.fromId,
    required this.toId,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'fromId': fromId,
        'toId': toId,
        'amount': amount,
      };

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
        fromId: json['fromId'],
        toId: json['toId'],
        amount: json['amount'].toDouble(),
      );
}
