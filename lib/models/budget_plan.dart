import 'package:uuid/uuid.dart';
import 'transaction.dart';

enum PlanType {
  trip,
  event,
  living,
  other
}

enum PlanStatus {
  draft,
  active,
  closed
}

class BudgetPlan {
  final String id;
  final String title;
  final PlanType type;
  final double budgetTotal;
  final Map<Category, double> categoryBudgets;
  final double currentSpent;
  final List<String> referenceLinks;
  final PlanStatus status;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;

  BudgetPlan({
    String? id,
    required this.title,
    this.type = PlanType.other,
    this.budgetTotal = 0,
    this.categoryBudgets = const {},
    this.currentSpent = 0,
    this.referenceLinks = const [],
    this.status = PlanStatus.draft,
    DateTime? createdAt,
    this.startDate,
    this.endDate,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'budgetTotal': budgetTotal,
        'categoryBudgets': categoryBudgets.map((k, v) => MapEntry(k.name, v)),
        'currentSpent': currentSpent,
        'referenceLinks': referenceLinks,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      };

  factory BudgetPlan.fromJson(Map<String, dynamic> json) => BudgetPlan(
        id: json['id'],
        title: json['title'],
        type: PlanType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => PlanType.other,
        ),
        budgetTotal: (json['budgetTotal'] ?? 0).toDouble(),
        categoryBudgets: (json['categoryBudgets'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(
                Category.values.firstWhere((c) => c.name == k, orElse: () => Category.other),
                v.toDouble(),
              ),
            ) ??
            {},
        currentSpent: (json['currentSpent'] ?? 0).toDouble(),
        referenceLinks: List<String>.from(json['referenceLinks'] ?? []),
        status: PlanStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => PlanStatus.draft,
        ),
        createdAt: DateTime.parse(json['createdAt']),
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      );

  BudgetPlan copyWith({
    String? title,
    PlanType? type,
    double? budgetTotal,
    Map<Category, double>? categoryBudgets,
    double? currentSpent,
    List<String>? referenceLinks,
    PlanStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      BudgetPlan(
        id: id,
        title: title ?? this.title,
        type: type ?? this.type,
        budgetTotal: budgetTotal ?? this.budgetTotal,
        categoryBudgets: categoryBudgets ?? this.categoryBudgets,
        currentSpent: currentSpent ?? this.currentSpent,
        referenceLinks: referenceLinks ?? this.referenceLinks,
        status: status ?? this.status,
        createdAt: createdAt,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
      );
}
