import 'package:uuid/uuid.dart';

class Person {
  final String id;
  final String name;
  final String avatarUrl;
  final int colorIndex;
  final String? fcmToken;
  final String? userId; // For identifying "Me" via Google/Firebase UID
  final String? email;
  final String? bankId; // NAPAS/VietQR Bank ID (BIN)
  final String? accountNo;
  final String? bankQrUrl;

  Person({
    String? id,
    required this.name,
    this.avatarUrl = '',
    int? colorIndex,
    this.fcmToken,
    this.userId,
    this.email,
    this.bankId,
    this.accountNo,
    this.bankQrUrl,
  })  : id = id ?? const Uuid().v4(),
        colorIndex = colorIndex ?? (DateTime.now().millisecondsSinceEpoch % 8);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'colorIndex': colorIndex,
        'fcmToken': fcmToken,
        'userId': userId,
        'email': email,
        'bankId': bankId,
        'accountNo': accountNo,
        'bankQrUrl': bankQrUrl,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'],
        name: json['name'],
        avatarUrl: json['avatarUrl'] ?? '',
        colorIndex: json['colorIndex'] ?? 0,
        fcmToken: json['fcmToken'],
        userId: json['userId'],
        email: json['email'],
        bankId: json['bankId'],
        accountNo: json['accountNo'],
        bankQrUrl: json['bankQrUrl'],
      );

  Person copyWith({
    String? name,
    String? avatarUrl,
    int? colorIndex,
    String? fcmToken,
    String? userId,
    String? email,
    String? bankId,
    String? accountNo,
    String? bankQrUrl,
  }) =>
      Person(
        id: id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        colorIndex: colorIndex ?? this.colorIndex,
        fcmToken: fcmToken ?? this.fcmToken,
        userId: userId ?? this.userId,
        email: email ?? this.email,
        bankId: bankId ?? this.bankId,
        accountNo: accountNo ?? this.accountNo,
        bankQrUrl: bankQrUrl ?? this.bankQrUrl,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
