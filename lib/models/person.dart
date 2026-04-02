import 'package:uuid/uuid.dart';

class Person {
  final String id;
  final String name;
  final String avatarUrl;
  final int colorIndex;
  final String? fcmToken;

  Person({
    String? id,
    required this.name,
    this.avatarUrl = '',
    int? colorIndex,
    this.fcmToken,
  })  : id = id ?? const Uuid().v4(),
        colorIndex = colorIndex ?? (DateTime.now().millisecondsSinceEpoch % 8);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'colorIndex': colorIndex,
        'fcmToken': fcmToken,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'],
        name: json['name'],
        avatarUrl: json['avatarUrl'] ?? '',
        colorIndex: json['colorIndex'] ?? 0,
        fcmToken: json['fcmToken'],
      );

  Person copyWith(
          {String? name,
          String? avatarUrl,
          int? colorIndex,
          String? fcmToken}) =>
      Person(
        id: id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        colorIndex: colorIndex ?? this.colorIndex,
        fcmToken: fcmToken ?? this.fcmToken,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
