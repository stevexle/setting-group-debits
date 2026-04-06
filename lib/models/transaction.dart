
enum Category { food, drink, shopping, transport, entertainment, home, health, other, travel, grocery, bills, education }

enum TransactionStatus { pending, confirmed, rejected }

abstract class BaseTransaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final DateTime? updatedAt;
  final Category category;
  final bool isPayment;
  final String? sourceAccountId;

  BaseTransaction({
    String? id,
    required this.description,
    required this.amount,
    DateTime? date,
    this.updatedAt,
    this.category = Category.other,
    this.isPayment = false,
    this.sourceAccountId,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson();
}

class GroupTransaction extends BaseTransaction {
  final String payerId;
  final List<String> participants;
  final bool amountChanged;
  final Map<String, double>? customAmounts;
  final TransactionStatus status;
  final String? planId;
  final Map<String, String>? participantBalances;
  final String? creatorId;

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
    this.planId,
    this.status = TransactionStatus.confirmed,
    this.creatorId,
  });

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
        'planId': planId,
        'status': status.name,
        'creatorId': creatorId,
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
        planId: json['planId'],
        status: TransactionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TransactionStatus.confirmed,
        ),
        creatorId: json['creatorId'],
      );

  GroupTransaction copyWith({
    String? id,
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
    String? planId,
    TransactionStatus? status,
    String? creatorId,
    DateTime? date,
  }) {
    return GroupTransaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      payerId: payerId ?? this.payerId,
      participants: participants ?? this.participants,
      updatedAt: updatedAt ?? this.updatedAt,
      amountChanged: amountChanged ?? this.amountChanged,
      category: category ?? this.category,
      isPayment: isPayment ?? this.isPayment,
      customAmounts: customAmounts ?? this.customAmounts,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      participantBalances: participantBalances ?? this.participantBalances,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      date: date ?? this.date,
    );
  }
}

class PersonalTransaction extends BaseTransaction {
  final String? planId; // FK: Gắn vào kế hoạch nào?
  final String? payerId; // Always me, but kept for model consistency?
  final String? groupId; // ID of group if shared
  final bool isShared; // Is this a split/share transaction?

  PersonalTransaction({
    super.id,
    required super.description,
    required super.amount,
    super.date,
    super.updatedAt,
    super.category,
    this.planId,
    this.payerId,
    super.isPayment,
    super.sourceAccountId,
    this.groupId,
    this.isShared = false,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'category': category.name,
        'planId': planId,
        'payerId': payerId,
        'isPayment': isPayment,
        'sourceAccountId': sourceAccountId,
        'groupId': groupId,
        'isShared': isShared,
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
        planId: json['planId'],
        payerId: json['payerId'],
        isPayment: json['isPayment'] ?? false,
        sourceAccountId: json['sourceAccountId'],
        groupId: json['groupId'],
        isShared: json['isShared'] ?? false,
      );

  PersonalTransaction copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    DateTime? updatedAt,
    Category? category,
    String? planId,
    String? payerId,
    bool? isPayment,
    String? sourceAccountId,
    String? groupId,
    bool? isShared,
  }) =>
      PersonalTransaction(
        id: id ?? this.id,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        updatedAt: updatedAt ?? this.updatedAt,
        category: category ?? this.category,
        planId: planId ?? this.planId,
        payerId: payerId ?? this.payerId,
        isPayment: isPayment ?? this.isPayment,
        sourceAccountId: sourceAccountId ?? this.sourceAccountId,
        groupId: groupId ?? this.groupId,
        isShared: isShared ?? this.isShared,
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
}
