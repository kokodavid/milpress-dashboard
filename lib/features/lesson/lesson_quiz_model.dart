class LessonQuiz {
  final String id;
  final String lessonId;
  final String? stage;
  final String? questionType;
  final String? questionContent;
  final String? soundFileUrl;
  final String? correctAnswer;
  final Map<String, dynamic>? options; // jsonb
  final int? difficultyLevel; // int4
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LessonQuiz({
    required this.id,
    required this.lessonId,
    this.stage,
    this.questionType,
    this.questionContent,
    this.soundFileUrl,
    this.correctAnswer,
    this.options,
    this.difficultyLevel,
    this.createdAt,
    this.updatedAt,
  });

  factory LessonQuiz.fromMap(Map<String, dynamic> json) {
    return LessonQuiz(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      stage: json['stage'] as String?,
      questionType: json['question_type'] as String?,
      questionContent: json['question_content'] as String?,
      soundFileUrl: json['sound_file_url'] as String?,
      correctAnswer: json['correct_answer'] as String?,
      options: json['options'] as Map<String, dynamic>?,
      difficultyLevel: json['difficulty_level'] as int?,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'stage': stage,
      'question_type': questionType,
      'question_content': questionContent,
      'sound_file_url': soundFileUrl,
      'correct_answer': correctAnswer,
      'options': options,
      'difficulty_level': difficultyLevel,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class LessonQuizCreate {
  final String lessonId;
  final String? stage;
  final String? questionType;
  final String? questionContent;
  final String? soundFileUrl;
  final String? correctAnswer;
  final Map<String, dynamic>? options;
  final int? difficultyLevel;

  LessonQuizCreate({
    required this.lessonId,
    this.stage,
    this.questionType,
    this.questionContent,
    this.soundFileUrl,
    this.correctAnswer,
    this.options,
    this.difficultyLevel,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'lesson_id': lessonId,
      if (stage != null) 'stage': stage,
      if (questionType != null) 'question_type': questionType,
      if (questionContent != null) 'question_content': questionContent,
      if (soundFileUrl != null) 'sound_file_url': soundFileUrl,
      if (correctAnswer != null) 'correct_answer': correctAnswer,
      if (options != null) 'options': options,
      if (difficultyLevel != null) 'difficulty_level': difficultyLevel,
    };
  }
}

class LessonQuizUpdate {
  final String? stage;
  final String? questionType;
  final String? questionContent;
  final String? soundFileUrl;
  final String? correctAnswer;
  final Map<String, dynamic>? options;
  final int? difficultyLevel;

  LessonQuizUpdate({
    this.stage,
    this.questionType,
    this.questionContent,
    this.soundFileUrl,
    this.correctAnswer,
    this.options,
    this.difficultyLevel,
  });

  Map<String, dynamic> toUpdateMap() {
    return {
      if (stage != null) 'stage': stage,
      if (questionType != null) 'question_type': questionType,
      if (questionContent != null) 'question_content': questionContent,
      if (soundFileUrl != null) 'sound_file_url': soundFileUrl,
      if (correctAnswer != null) 'correct_answer': correctAnswer,
      if (options != null) 'options': options,
      if (difficultyLevel != null) 'difficulty_level': difficultyLevel,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
