import 'package:uuid/uuid.dart';
import 'person.dart';
import 'transaction.dart';

class Group {
  final String id;
  final String name;
  final List<Person> people;
  final List<Transaction> transactions;
  final String? syncId; // Firestore document ID if synced

  Group({
    String? id,
    required this.name,
    this.people = const [],
    this.transactions = const [],
    this.syncId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'people': people.map((p) => p.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'syncId': syncId,
      };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'],
        name: json['name'],
        people: (json['people'] as List).map((p) => Person.fromJson(p)).toList(),
        transactions:
            (json['transactions'] as List).map((t) => Transaction.fromJson(t)).toList(),
        syncId: json['syncId'],
      );

  Group copyWith(
          {String? name,
          List<Person>? people,
          List<Transaction>? transactions,
          String? syncId}) =>
      Group(
        id: id,
        name: name ?? this.name,
        people: people ?? this.people,
        transactions: transactions ?? this.transactions,
        syncId: syncId ?? this.syncId,
      );
}
