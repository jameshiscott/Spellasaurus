class ChildPracticeSettings {
  final String childId;
  final bool showDescription;
  final bool showExampleSentence;
  final bool playTtsAudio;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChildPracticeSettings({
    required this.childId,
    this.showDescription = true,
    this.showExampleSentence = true,
    this.playTtsAudio = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChildPracticeSettings.defaultsFor(String childId) =>
      ChildPracticeSettings(
        childId: childId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory ChildPracticeSettings.fromJson(Map<String, dynamic> json) =>
      ChildPracticeSettings(
        childId: json['child_id'] as String,
        showDescription: (json['show_description'] as bool?) ?? true,
        showExampleSentence:
            (json['show_example_sentence'] as bool?) ?? true,
        playTtsAudio: (json['play_tts_audio'] as bool?) ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        'show_description': showDescription,
        'show_example_sentence': showExampleSentence,
        'play_tts_audio': playTtsAudio,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  ChildPracticeSettings copyWith({
    String? childId,
    bool? showDescription,
    bool? showExampleSentence,
    bool? playTtsAudio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ChildPracticeSettings(
        childId: childId ?? this.childId,
        showDescription: showDescription ?? this.showDescription,
        showExampleSentence:
            showExampleSentence ?? this.showExampleSentence,
        playTtsAudio: playTtsAudio ?? this.playTtsAudio,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      other is ChildPracticeSettings && other.childId == childId;

  @override
  int get hashCode => childId.hashCode;
}
