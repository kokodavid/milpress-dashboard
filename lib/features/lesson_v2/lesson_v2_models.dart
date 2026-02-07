enum LessonType {
  letter,
  word,
  sentence,
}

enum LessonStepType {
  introduction,
  demonstration,
  practice,
  assessment,
}

LessonType lessonTypeFromString(String value) {
  return LessonType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => LessonType.letter,
  );
}

LessonStepType lessonStepTypeFromString(String value) {
  return LessonStepType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => LessonStepType.introduction,
  );
}

class NewLesson {
  final String id;
  final String moduleId;
  final String title;
  final LessonType lessonType;
  final int displayOrder;

  NewLesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.lessonType,
    required this.displayOrder,
  });

  factory NewLesson.fromMap(Map<String, dynamic> json) {
    return NewLesson(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      title: (json['title'] ?? '') as String,
      lessonType: lessonTypeFromString((json['lesson_type'] ?? 'letter') as String),
      displayOrder: (json['display_order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'lesson_type': lessonType.name,
      'display_order': displayOrder,
    };
  }
}

class LessonStep {
  final String id;
  final String lessonId;
  final String stepKey;
  final LessonStepType stepType;
  final int position;
  final bool required;
  final Map<String, dynamic>? config;

  LessonStep({
    required this.id,
    required this.lessonId,
    required this.stepKey,
    required this.stepType,
    required this.position,
    required this.required,
    required this.config,
  });

  factory LessonStep.fromMap(Map<String, dynamic> json) {
    return LessonStep(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      stepKey: (json['step_key'] ?? '') as String,
      stepType: lessonStepTypeFromString((json['step_type'] ?? 'introduction') as String),
      position: (json['position'] as int?) ?? 0,
      required: (json['required'] as bool?) ?? false,
      config: (json['config'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'step_key': stepKey,
      'step_type': stepType.name,
      'position': position,
      'required': required,
      'config': config,
    };
  }
}

class LessonWithSteps {
  final NewLesson lesson;
  final List<LessonStep> steps;

  LessonWithSteps({
    required this.lesson,
    required this.steps,
  });
}

class NewLessonCreate {
  final String moduleId;
  final String title;
  final LessonType lessonType;
  final int displayOrder;

  NewLessonCreate({
    required this.moduleId,
    required this.title,
    required this.lessonType,
    required this.displayOrder,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'module_id': moduleId,
      'title': title,
      'lesson_type': lessonType.name,
      'display_order': displayOrder,
    };
  }
}

class NewLessonUpdate {
  final String? title;
  final LessonType? lessonType;
  final int? displayOrder;

  NewLessonUpdate({
    this.title,
    this.lessonType,
    this.displayOrder,
  });

  Map<String, dynamic> toUpdateMap() {
    return {
      if (title != null) 'title': title,
      if (lessonType != null) 'lesson_type': lessonType!.name,
      if (displayOrder != null) 'display_order': displayOrder,
    };
  }
}

class LessonStepInput {
  final String stepKey;
  final LessonStepType stepType;
  final int position;
  final bool required;
  final Map<String, dynamic>? config;

  LessonStepInput({
    required this.stepKey,
    required this.stepType,
    required this.position,
    required this.required,
    required this.config,
  });

  Map<String, dynamic> toInsertMap(String lessonId) {
    return {
      'lesson_id': lessonId,
      'step_key': stepKey,
      'step_type': stepType.name,
      'position': position,
      'required': required,
      'config': config,
    };
  }
}
