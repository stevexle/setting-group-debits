import 'package:uuid/uuid.dart';

enum AccountType {
  cash,
  bank,
  creditCard,
  asset, // For Gold, Stocks, etc.
  other
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final double currentBalance;
  final String? currency;
  final String? icon;

  Account({
    String? id,
    required this.name,
    this.type = AccountType.cash,
    this.initialBalance = 0,
    double? currentBalance,
    this.currency = 'VND',
    this.icon,
  })  : id = id ?? const Uuid().v4(),
        currentBalance = currentBalance ?? initialBalance;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'initialBalance': initialBalance,
        'currentBalance': currentBalance,
        'currency': currency,
        'icon': icon,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'],
        name: json['name'],
        type: AccountType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => AccountType.cash,
        ),
        initialBalance: (json['initialBalance'] ?? 0).toDouble(),
        currentBalance: (json['currentBalance'] ?? 0).toDouble(),
        currency: json['currency'],
        icon: json['icon'],
      );

  Account copyWith({
    String? name,
    AccountType? type,
    double? initialBalance,
    double? currentBalance,
    String? currency,
    String? icon,
  }) =>
      Account(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        initialBalance: initialBalance ?? this.initialBalance,
        currentBalance: currentBalance ?? this.currentBalance,
        currency: currency ?? this.currency,
        icon: icon ?? this.icon,
      );
}
