enum UserRole { schoolAdmin, teacher, parent, child }

extension UserRoleX on UserRole {
  String get value => switch (this) {
        UserRole.schoolAdmin => 'school_admin',
        UserRole.teacher => 'teacher',
        UserRole.parent => 'parent',
        UserRole.child => 'child',
      };

  static UserRole fromString(String s) => switch (s) {
        'school_admin' => UserRole.schoolAdmin,
        'teacher' => UserRole.teacher,
        'parent' => UserRole.parent,
        'child' => UserRole.child,
        _ => throw ArgumentError('Unknown role: $s'),
      };
}

class Profile {
  final String id;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final int coinBalance;
  final String? displayName;
  final String? dinoType;
  final String? dinoColor;
  final bool onboardingComplete;

  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.dateOfBirth,
    required this.createdAt,
    this.coinBalance = 0,
    this.displayName,
    this.dinoType,
    this.dinoColor,
    this.onboardingComplete = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        role: UserRoleX.fromString(json['role'] as String),
        avatarUrl: json['avatar_url'] as String?,
        dateOfBirth: json['date_of_birth'] == null
            ? null
            : DateTime.parse(json['date_of_birth'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        coinBalance: (json['coin_balance'] as int?) ?? 0,
        displayName: json['display_name'] as String?,
        dinoType: json['dino_type'] as String?,
        dinoColor: json['dino_color'] as String?,
        onboardingComplete: (json['onboarding_complete'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'role': role.value,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'coin_balance': coinBalance,
        if (displayName != null) 'display_name': displayName,
        if (dinoType != null) 'dino_type': dinoType,
        if (dinoColor != null) 'dino_color': dinoColor,
        'onboarding_complete': onboardingComplete,
      };

  Profile copyWith({
    String? id,
    String? fullName,
    UserRole? role,
    String? avatarUrl,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    int? coinBalance,
    String? displayName,
    String? dinoType,
    String? dinoColor,
    bool? onboardingComplete,
  }) =>
      Profile(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        createdAt: createdAt ?? this.createdAt,
        coinBalance: coinBalance ?? this.coinBalance,
        displayName: displayName ?? this.displayName,
        dinoType: dinoType ?? this.dinoType,
        dinoColor: dinoColor ?? this.dinoColor,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      );

  @override
  bool operator ==(Object other) =>
      other is Profile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
