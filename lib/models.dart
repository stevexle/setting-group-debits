import 'package:uuid/uuid.dart';

class Person {
  final String id;
  final String name;
  final String avatarUrl;
  final int colorIndex;

  Person({
    String? id,
    required this.name,
    this.avatarUrl = '',
    int? colorIndex,
  })  : id = id ?? const Uuid().v4(),
        colorIndex = colorIndex ?? (DateTime.now().millisecondsSinceEpoch % 8);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'colorIndex': colorIndex,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'],
        name: json['name'],
        avatarUrl: json['avatarUrl'] ?? '',
        colorIndex: json['colorIndex'] ?? 0,
      );

  Person copyWith({String? name, String? avatarUrl, int? colorIndex}) => Person(
        id: id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        colorIndex: colorIndex ?? this.colorIndex,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

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

class Group {
  final String id;
  final String name;
  final List<Person> people;
  final List<Transaction> transactions;

  Group({
    String? id,
    required this.name,
    this.people = const [],
    this.transactions = const [],
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'people': people.map((p) => p.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'],
        name: json['name'],
        people: (json['people'] as List).map((p) => Person.fromJson(p)).toList(),
        transactions:
            (json['transactions'] as List).map((t) => Transaction.fromJson(t)).toList(),
      );

  Group copyWith(
          {String? name,
          List<Person>? people,
          List<Transaction>? transactions}) =>
      Group(
        id: id,
        name: name ?? this.name,
        people: people ?? this.people,
        transactions: transactions ?? this.transactions,
      );
}
