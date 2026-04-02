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
