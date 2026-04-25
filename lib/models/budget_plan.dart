import 'package:uuid/uuid.dart';
import 'transaction.dart';

enum PlanType { trip, event, living, other }

enum PlanStatus { draft, active, closed }

enum PlanTaskStatus { toDo, inProgress, done, cancelled }

enum PlanPriority { low, medium, high }

class PlanItineraryItem {
  final String id;
  final int day; // e.g., 1 for Day 1
  final String time; // e.g., "08:00"
  final String activity;
  final String? location;
  final String? mapLink;
  final List<String> suggestions;
  final double estimatedCost;
  final String? note;
  final List<String> socialLinks;
  final List<String> attachments;

  PlanItineraryItem({
    String? id,
    this.day = 1,
    required this.time,
    required this.activity,
    this.location,
    this.mapLink,
    this.suggestions = const [],
    this.estimatedCost = 0,
    this.note,
    this.socialLinks = const [],
    this.attachments = const [],
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'time': time,
        'activity': activity,
        'location': location,
        'mapLink': mapLink,
        'suggestions': suggestions,
        'estimatedCost': estimatedCost,
        'note': note,
        'socialLinks': socialLinks,
        'attachments': attachments,
      };

  factory PlanItineraryItem.fromJson(Map<String, dynamic> json) =>
      PlanItineraryItem(
        id: json['id'],
        day: json['day'] ?? 1,
        time: json['time'],
        activity: json['activity'],
        location: json['location'],
        mapLink: json['mapLink'],
        suggestions: List<String>.from(json['suggestions'] ?? []),
        estimatedCost: (json['estimatedCost'] ?? 0).toDouble(),
        note: json['note'],
        socialLinks: List<String>.from(json['socialLinks'] ?? []),
        attachments: List<String>.from(json['attachments'] ?? []),
      );

  PlanItineraryItem copyWith({
    int? day,
    String? time,
    String? activity,
    String? location,
    String? mapLink,
    List<String>? suggestions,
    double? estimatedCost,
    String? note,
    List<String>? socialLinks,
    List<String>? attachments,
  }) =>
      PlanItineraryItem(
        id: id,
        day: day ?? this.day,
        time: time ?? this.time,
        activity: activity ?? this.activity,
        location: location ?? this.location,
        mapLink: mapLink ?? this.mapLink,
        suggestions: suggestions ?? this.suggestions,
        estimatedCost: estimatedCost ?? this.estimatedCost,
        note: note ?? this.note,
        socialLinks: socialLinks ?? this.socialLinks,
        attachments: attachments ?? this.attachments,
      );
}

class PlanTask {
  final String id;
  final String title;
  final PlanTaskStatus status;
  final PlanPriority priority;
  final String? note;
  final String? contact; // Phone or name
  final String? assignedTo; // Person ID
  final DateTime? dueDate;
  final double estimatedCost;
  final Category category;
  final String? linkedTransactionId;
  final List<String> attachments;

  PlanTask({
    String? id,
    required this.title,
    this.status = PlanTaskStatus.toDo,
    this.priority = PlanPriority.medium,
    this.note,
    this.contact,
    this.assignedTo,
    this.dueDate,
    this.estimatedCost = 0,
    this.category = Category.other,
    this.linkedTransactionId,
    this.attachments = const [],
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status.name,
        'priority': priority.name,
        'note': note,
        'contact': contact,
        'assignedTo': assignedTo,
        'dueDate': dueDate?.toIso8601String(),
        'estimatedCost': estimatedCost,
        'category': category.name,
        'linkedTransactionId': linkedTransactionId,
        'attachments': attachments,
      };

  factory PlanTask.fromJson(Map<String, dynamic> json) => PlanTask(
        id: json['id'],
        title: json['title'],
        status: PlanTaskStatus.values.firstWhere(
            (s) => s.name == json['status'],
            orElse: () => PlanTaskStatus.toDo),
        priority: PlanPriority.values.firstWhere(
            (p) => p.name == (json['priority'] ?? 'medium'),
            orElse: () => PlanPriority.medium),
        note: json['note'],
        contact: json['contact'],
        assignedTo: json['assignedTo'],
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        estimatedCost: (json['estimatedCost'] ?? 0).toDouble(),
        category: Category.values.firstWhere((c) => c.name == json['category'], orElse: () => Category.other),
        linkedTransactionId: json['linkedTransactionId'],
        attachments: List<String>.from(json['attachments'] ?? []),
      );

  PlanTask copyWith({
    String? title,
    PlanTaskStatus? status,
    PlanPriority? priority,
    String? note,
    String? contact,
    String? assignedTo,
    DateTime? dueDate,
    double? estimatedCost,
    Category? category,
    String? linkedTransactionId,
    List<String>? attachments,
  }) =>
      PlanTask(
        id: id,
        title: title ?? this.title,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        note: note ?? this.note,
        contact: contact ?? this.contact,
        assignedTo: assignedTo ?? this.assignedTo,
        dueDate: dueDate ?? this.dueDate,
        estimatedCost: estimatedCost ?? this.estimatedCost,
        category: category ?? this.category,
        linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
        attachments: attachments ?? this.attachments,
      );
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
  final List<PlanItineraryItem> itinerary;
  final List<PlanTask> checklist;
  final String? linkedGroupId;
  final String? destination;

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
    this.itinerary = const [],
    this.checklist = const [],
    this.linkedGroupId,
    this.destination,
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
        'itinerary': itinerary.map((i) => i.toJson()).toList(),
        'checklist': checklist.map((t) => t.toJson()).toList(),
        'linkedGroupId': linkedGroupId,
        'destination': destination,
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
                Category.values.firstWhere((c) => c.name == k,
                    orElse: () => Category.other),
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
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'])
            : null,
        endDate:
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        itinerary: (json['itinerary'] as List?)
                ?.map((i) => PlanItineraryItem.fromJson(i))
                .toList() ??
            [],
        checklist: (json['checklist'] as List?)
                ?.map((t) => PlanTask.fromJson(t))
                .toList() ??
            [],
        linkedGroupId: json['linkedGroupId'],
        destination: json['destination'],
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
    List<PlanItineraryItem>? itinerary,
    List<PlanTask>? checklist,
    String? linkedGroupId,
    String? destination,
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
        itinerary: itinerary ?? this.itinerary,
        checklist: checklist ?? this.checklist,
        linkedGroupId: linkedGroupId ?? this.linkedGroupId,
        destination: destination ?? this.destination,
      );
}
