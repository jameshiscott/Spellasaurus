class SpellingWord {
  final String id;
  final String setId;
  final String word;
  final String? hint;
  final String? aiDescription;
  final String? aiExampleSentence;
  final String? audioUrl;
  final DateTime? aiGeneratedAt;
  final int sortOrder;
  final DateTime createdAt;

  const SpellingWord({
    required this.id,
    required this.setId,
    required this.word,
    this.hint,
    this.aiDescription,
    this.aiExampleSentence,
    this.audioUrl,
    this.aiGeneratedAt,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory SpellingWord.fromJson(Map<String, dynamic> json) => SpellingWord(
        id: json['id'] as String,
        setId: json['set_id'] as String,
        word: json['word'] as String,
        hint: json['hint'] as String?,
        aiDescription: json['ai_description'] as String?,
        aiExampleSentence: json['ai_example_sentence'] as String?,
        audioUrl: json['audio_url'] as String?,
        aiGeneratedAt: json['ai_generated_at'] == null
            ? null
            : DateTime.parse(json['ai_generated_at'] as String),
        sortOrder: (json['sort_order'] as int?) ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'set_id': setId,
        'word': word,
        if (hint != null) 'hint': hint,
        if (aiDescription != null) 'ai_description': aiDescription,
        if (aiExampleSentence != null)
          'ai_example_sentence': aiExampleSentence,
        if (audioUrl != null) 'audio_url': audioUrl,
        if (aiGeneratedAt != null)
          'ai_generated_at': aiGeneratedAt!.toIso8601String(),
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };

  SpellingWord copyWith({
    String? id,
    String? setId,
    String? word,
    String? hint,
    String? aiDescription,
    String? aiExampleSentence,
    String? audioUrl,
    DateTime? aiGeneratedAt,
    int? sortOrder,
    DateTime? createdAt,
  }) =>
      SpellingWord(
        id: id ?? this.id,
        setId: setId ?? this.setId,
        word: word ?? this.word,
        hint: hint ?? this.hint,
        aiDescription: aiDescription ?? this.aiDescription,
        aiExampleSentence: aiExampleSentence ?? this.aiExampleSentence,
        audioUrl: audioUrl ?? this.audioUrl,
        aiGeneratedAt: aiGeneratedAt ?? this.aiGeneratedAt,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) => other is SpellingWord && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
