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

abstract class BaseTransaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final DateTime? updatedAt;
  final Category category;
  final bool isPayment;
  final String? sourceAccountId; // Source Link (Ví VCB, Vàng...)
  final bool isUnplanned; // Still useful here or just in Personal?

  BaseTransaction({
    String? id,
    required this.description,
    required this.amount,
    DateTime? date,
    this.updatedAt,
    this.category = Category.other,
    this.isPayment = false,
    this.sourceAccountId,
    this.isUnplanned = false,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson();
}

class GroupTransaction extends BaseTransaction {
  final String payerId; // Ai trả
  final List<String> participants; // Ai chịu (string[])
  final bool amountChanged; // Legacy or still needed?
  final Map<String, double>? customAmounts;

  GroupTransaction({
    super.id,
    required super.description,
    required super.amount,
    required this.payerId,
    required this.participants,
    super.date,
    super.updatedAt,
    this.amountChanged = false,
    super.category,
    super.isPayment,
    this.customAmounts,
    super.sourceAccountId,
    this.participantBalances,
  });

  final Map<String, String>? participantBalances; // Map of UID -> Local AccountID

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'payerId': payerId,
        'participants': participants,
        'date': date.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'amountChanged': amountChanged,
        'category': category.name,
        'isPayment': isPayment,
        'customAmounts': customAmounts,
        'sourceAccountId': sourceAccountId,
        'participantBalances': participantBalances,
        'type': 'GROUP_TRANSACTION',
      };

  factory GroupTransaction.fromJson(Map<String, dynamic> json) => GroupTransaction(
        id: json['id'],
        description: json['description'],
        amount: (json['amount'] ?? 0.0).toDouble(),
        payerId: json['payerId'],
        participants: List<String>.from(json['participants'] ?? []),
        date: DateTime.parse(json['date']),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
        amountChanged: json['amountChanged'] ?? false,
        category: Category.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => Category.other,
        ),
        isPayment: json['isPayment'] ?? false,
        customAmounts: json['customAmounts'] != null
            ? Map<String, double>.from(json['customAmounts'].map((k, v) => MapEntry(k, v.toDouble())))
            : null,
        sourceAccountId: json['sourceAccountId'],
        participantBalances: json['participantBalances'] != null
            ? Map<String, String>.from(json['participantBalances'])
            : null,
      );

  GroupTransaction copyWith({
    String? description,
    double? amount,
    String? payerId,
    List<String>? participants,
    DateTime? updatedAt,
    bool? amountChanged,
    Category? category,
    bool? isPayment,
    Map<String, double>? customAmounts,
    String? sourceAccountId,
    Map<String, String>? participantBalances,
  }) =>
      GroupTransaction(
        id: id,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        payerId: payerId ?? this.payerId,
        participants: participants ?? this.participants,
        date: date,
        updatedAt: updatedAt ?? this.updatedAt,
        amountChanged: amountChanged ?? this.amountChanged,
        category: category ?? this.category,
        isPayment: isPayment ?? this.isPayment,
        customAmounts: customAmounts ?? this.customAmounts,
        sourceAccountId: sourceAccountId ?? this.sourceAccountId,
        participantBalances: participantBalances ?? this.participantBalances,
      );
}

class PersonalTransaction extends BaseTransaction {
  final String? planId; // FK: Gắn vào kế hoạch nào?
  final String? payerId; // Always me, but kept for model consistency?

  PersonalTransaction({
    super.id,
    required super.description,
    required super.amount,
    super.date,
    super.updatedAt,
    super.category,
    super.isPayment,
    super.sourceAccountId,
    super.isUnplanned,
    this.planId,
    this.payerId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'category': category.name,
        'isPayment': isPayment,
        'sourceAccountId': sourceAccountId,
        'planId': planId,
        'isUnplanned': isUnplanned,
        'payerId': payerId,
        'type': 'PERSONAL_TRANSACTION',
      };

  factory PersonalTransaction.fromJson(Map<String, dynamic> json) => PersonalTransaction(
        id: json['id'],
        description: json['description'],
        amount: (json['amount'] ?? 0.0).toDouble(),
        date: DateTime.parse(json['date']),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
        category: Category.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => Category.other,
        ),
        isPayment: json['isPayment'] ?? false,
        sourceAccountId: json['sourceAccountId'],
        planId: json['planId'],
        isUnplanned: json['isUnplanned'] ?? false,
        payerId: json['payerId'],
      );

  PersonalTransaction copyWith({
    String? description,
    double? amount,
    DateTime? updatedAt,
    Category? category,
    bool? isPayment,
    String? sourceAccountId,
    String? planId,
    bool? isUnplanned,
    String? payerId,
  }) =>
      PersonalTransaction(
        id: id,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        date: date,
        updatedAt: updatedAt ?? this.updatedAt,
        category: category ?? this.category,
        isPayment: isPayment ?? this.isPayment,
        sourceAccountId: sourceAccountId ?? this.sourceAccountId,
        planId: planId ?? this.planId,
        isUnplanned: isUnplanned ?? this.isUnplanned,
        payerId: payerId ?? this.payerId,
      );
}

class TransactionFactory {
  static BaseTransaction fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'GROUP_TRANSACTION' || (json['participants'] != null && (json['participants'] as List).isNotEmpty)) {
      return GroupTransaction.fromJson(json);
    } else {
      return PersonalTransaction.fromJson(json);
    }
  }
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
        amount: (json['amount'] ?? 0.0).toDouble(),
      );
}
