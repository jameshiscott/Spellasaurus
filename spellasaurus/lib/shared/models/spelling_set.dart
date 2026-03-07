class SpellingSet {
  final String id;
  final String? classId;
  final String? childId;
  final String createdBy;
  final String name;
  final int? weekNumber;
  final DateTime? weekStart;
  final DateTime createdAt;

  const SpellingSet({
    required this.id,
    this.classId,
    this.childId,
    required this.createdBy,
    required this.name,
    this.weekNumber,
    this.weekStart,
    required this.createdAt,
  });

  factory SpellingSet.fromJson(Map<String, dynamic> json) => SpellingSet(
        id: json['id'] as String,
        classId: json['class_id'] as String?,
        childId: json['child_id'] as String?,
        createdBy: json['created_by'] as String,
        name: json['name'] as String,
        weekNumber: json['week_number'] as int?,
        weekStart: json['week_start'] == null
            ? null
            : DateTime.parse(json['week_start'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (classId != null) 'class_id': classId,
        if (childId != null) 'child_id': childId,
        'created_by': createdBy,
        'name': name,
        if (weekNumber != null) 'week_number': weekNumber,
        if (weekStart != null) 'week_start': weekStart!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  SpellingSet copyWith({
    String? id,
    String? classId,
    String? childId,
    String? createdBy,
    String? name,
    int? weekNumber,
    DateTime? weekStart,
    DateTime? createdAt,
  }) =>
      SpellingSet(
        id: id ?? this.id,
        classId: classId ?? this.classId,
        childId: childId ?? this.childId,
        createdBy: createdBy ?? this.createdBy,
        name: name ?? this.name,
        weekNumber: weekNumber ?? this.weekNumber,
        weekStart: weekStart ?? this.weekStart,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) => other is SpellingSet && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
