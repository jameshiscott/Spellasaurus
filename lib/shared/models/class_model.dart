class ClassModel {
  final String id;
  final String schoolId;
  final String? teacherId;
  final String name;
  final int schoolYear;
  final DateTime createdAt;

  const ClassModel({
    required this.id,
    required this.schoolId,
    this.teacherId,
    required this.name,
    required this.schoolYear,
    required this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        teacherId: json['teacher_id'] as String?,
        name: json['name'] as String,
        schoolYear: json['school_year'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'school_id': schoolId,
        if (teacherId != null) 'teacher_id': teacherId,
        'name': name,
        'school_year': schoolYear,
        'created_at': createdAt.toIso8601String(),
      };

  ClassModel copyWith({
    String? id,
    String? schoolId,
    String? teacherId,
    String? name,
    int? schoolYear,
    DateTime? createdAt,
  }) =>
      ClassModel(
        id: id ?? this.id,
        schoolId: schoolId ?? this.schoolId,
        teacherId: teacherId ?? this.teacherId,
        name: name ?? this.name,
        schoolYear: schoolYear ?? this.schoolYear,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) => other is ClassModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
