class School {
  final String id;
  final String name;
  final String? address;
  final String? adminId;
  final DateTime createdAt;

  const School({
    required this.id,
    required this.name,
    this.address,
    this.adminId,
    required this.createdAt,
  });

  factory School.fromJson(Map<String, dynamic> json) => School(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        adminId: json['admin_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (address != null) 'address': address,
        if (adminId != null) 'admin_id': adminId,
        'created_at': createdAt.toIso8601String(),
      };

  School copyWith({
    String? id,
    String? name,
    String? address,
    String? adminId,
    DateTime? createdAt,
  }) =>
      School(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        adminId: adminId ?? this.adminId,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) => other is School && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
