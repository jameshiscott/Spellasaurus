class PracticeSession {
  final String id;
  final String childId;
  final String setId;
  final int score;
  final int totalWords;
  final DateTime completedAt;

  const PracticeSession({
    required this.id,
    required this.childId,
    required this.setId,
    required this.score,
    required this.totalWords,
    required this.completedAt,
  });

  factory PracticeSession.fromJson(Map<String, dynamic> json) =>
      PracticeSession(
        id: json['id'] as String,
        childId: json['child_id'] as String,
        setId: json['set_id'] as String,
        score: json['score'] as int,
        totalWords: json['total_words'] as int,
        completedAt: DateTime.parse(json['completed_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'child_id': childId,
        'set_id': setId,
        'score': score,
        'total_words': totalWords,
        'completed_at': completedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is PracticeSession && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class PracticeAnswer {
  final String id;
  final String sessionId;
  final String wordId;
  final String typedAnswer;
  final bool isCorrect;

  const PracticeAnswer({
    required this.id,
    required this.sessionId,
    required this.wordId,
    required this.typedAnswer,
    required this.isCorrect,
  });

  factory PracticeAnswer.fromJson(Map<String, dynamic> json) => PracticeAnswer(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        wordId: json['word_id'] as String,
        typedAnswer: json['typed_answer'] as String,
        isCorrect: json['is_correct'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'word_id': wordId,
        'typed_answer': typedAnswer,
        'is_correct': isCorrect,
      };

  @override
  bool operator ==(Object other) =>
      other is PracticeAnswer && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
