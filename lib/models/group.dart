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

  // Firestore only needs metadata (name, people, memberUids)
  // Transactions are stored in a separate subcollection for efficiency.
  Map<String, dynamic> toFirestoreMetadata() => {
        'id': id,
        'name': name,
        'people': people.map((p) => p.toJson()).toList(),
        'syncId': syncId,
        'memberUids': people
            .where((p) => p.userId != null)
            .map((p) => p.userId!)
            .toList(),
      };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'],
        name: json['name'],
        people: json['people'] is List
            ? (json['people'] as List).map((p) => Person.fromJson(p)).toList()
            : const [],
        transactions: json['transactions'] is List
            ? (json['transactions'] as List)
                .map((t) => Transaction.fromJson(t))
                .toList()
            : const [],
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
