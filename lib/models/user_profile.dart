class UserProfile {
  final String uid;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? bankId;
  final String? accountNo;
  final String? bankQrUrl;

  UserProfile({
    required this.uid,
    required this.name,
    this.email,
    this.avatarUrl,
    this.bankId,
    this.accountNo,
    this.bankQrUrl,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'bankId': bankId,
        'accountNo': accountNo,
        'bankQrUrl': bankQrUrl,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] ?? '',
        name: json['name'] ?? '',
        email: json['email'],
        avatarUrl: json['avatarUrl'],
        bankId: json['bankId'],
        accountNo: json['accountNo'],
        bankQrUrl: json['bankQrUrl'],
      );

  UserProfile copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? bankId,
    String? accountNo,
    String? bankQrUrl,
  }) =>
      UserProfile(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bankId: bankId ?? this.bankId,
        accountNo: accountNo ?? this.accountNo,
        bankQrUrl: bankQrUrl ?? this.bankQrUrl,
      );
}
