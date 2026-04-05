import 'package:uuid/uuid.dart';
import 'person.dart';
import 'transaction.dart';
import 'budget_plan.dart';

enum GroupType {
  settlement,
  planning,
  asset
}

class Group {
  final String id;
  final String name;
  final List<Person> people;
  final List<GroupTransaction> groupTransactions;
  final List<BudgetPlan> plans;
  final GroupType type;
  final String? syncId; // Firestore document ID if synced

  Group({
    String? id,
    required this.name,
    this.people = const [],
    this.groupTransactions = const [],
    this.plans = const [],
    this.type = GroupType.settlement,
    this.syncId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'people': people.map((p) => p.toJson()).toList(),
        'groupTransactions': groupTransactions.map((t) => t.toJson()).toList(),
        'plans': plans.map((p) => p.toJson()).toList(),
        'type': type.name,
        'syncId': syncId,
      };

  // Firestore only needs metadata (name, people, memberUids)
  // Transactions are stored in a separate subcollection for efficiency.
  Map<String, dynamic> toFirestoreMetadata() => {
        'id': id,
        'name': name,
        'type': type.name,
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
        groupTransactions: json['groupTransactions'] is List
            ? (json['groupTransactions'] as List)
                .map((t) => GroupTransaction.fromJson(t))
                .toList()
            : const [],
        plans: json['plans'] is List
            ? (json['plans'] as List).map((p) => BudgetPlan.fromJson(p)).toList()
            : const [],
        type: GroupType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => GroupType.settlement,
        ),
        syncId: json['syncId'],
      );

  Group copyWith(
          {String? name,
          List<Person>? people,
          List<GroupTransaction>? groupTransactions,
          List<BudgetPlan>? plans,
          GroupType? type,
          String? syncId}) =>
      Group(
        id: id,
        name: name ?? this.name,
        people: people ?? this.people,
        groupTransactions: groupTransactions ?? this.groupTransactions,
        plans: plans ?? this.plans,
        type: type ?? this.type,
        syncId: syncId ?? this.syncId,
      );
}
