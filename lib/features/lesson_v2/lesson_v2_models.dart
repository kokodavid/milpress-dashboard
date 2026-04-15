import 'package:flutter/material.dart';

enum LessonType { letter, word, sentence }

enum LessonStepType {
  introduction,
  demonstration,
  practice,
  assessment,
  blending,
  soundDiscrimination,
  soundItemMatching,
  guidedReading,
  practiceGame,
  soundPresenceCheck,
  missingLetters,
  matchingWords,
  wordReading,
  sentenceReading,
  miniStoryCard,
}

extension LessonStepTypeX on LessonStepType {
  String get dbValue {
    switch (this) {
      case LessonStepType.soundDiscrimination:
        return 'sound_discrimination';
      case LessonStepType.soundItemMatching:
        return 'sound_item_matching';
      case LessonStepType.guidedReading:
        return 'guided_reading';
      case LessonStepType.practiceGame:
        return 'practice_game';
      case LessonStepType.soundPresenceCheck:
        return 'sound_presence_check';
      case LessonStepType.missingLetters:
        return 'missing_letters';
      case LessonStepType.matchingWords:
        return 'matching_words';
      case LessonStepType.wordReading:
        return 'word_reading';
      case LessonStepType.sentenceReading:
        return 'sentence_reading';
      case LessonStepType.miniStoryCard:
        return 'mini_story_card';
      case LessonStepType.introduction:
      case LessonStepType.demonstration:
      case LessonStepType.practice:
      case LessonStepType.assessment:
      case LessonStepType.blending:
        return name;
    }
  }
}

LessonType lessonTypeFromString(String value) {
  return LessonType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => LessonType.letter,
  );
}

LessonStepType lessonStepTypeFromString(String value) {
  if (value == 'sound_discrimination') {
    return LessonStepType.soundDiscrimination;
  }
  if (value == 'sound_item_matching') {
    return LessonStepType.soundItemMatching;
  }
  if (value == 'guided_reading') {
    return LessonStepType.guidedReading;
  }
  if (value == 'practice_game') {
    return LessonStepType.practiceGame;
  }
  if (value == 'sound_presence_check') {
    return LessonStepType.soundPresenceCheck;
  }
  if (value == 'missing_letters') {
    return LessonStepType.missingLetters;
  }
  if (value == 'matching_words') {
    return LessonStepType.matchingWords;
  }
  if (value == 'word_reading') {
    return LessonStepType.wordReading;
  }
  if (value == 'sentence_reading') {
    return LessonStepType.sentenceReading;
  }
  if (value == 'mini_story_card') {
    return LessonStepType.miniStoryCard;
  }
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
      lessonType: lessonTypeFromString(
        (json['lesson_type'] ?? 'letter') as String,
      ),
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
      stepType: lessonStepTypeFromString(
        (json['step_type'] ?? 'introduction') as String,
      ),
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
      'step_type': stepType.dbValue,
      'position': position,
      'required': required,
      'config': config,
    };
  }
}

class LessonWithSteps {
  final NewLesson lesson;
  final List<LessonStep> steps;

  LessonWithSteps({required this.lesson, required this.steps});
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

  NewLessonUpdate({this.title, this.lessonType, this.displayOrder});

  Map<String, dynamic> toUpdateMap() {
    return {
      if (title != null) 'title': title,
      if (lessonType != null) 'lesson_type': lessonType!.name,
      if (displayOrder != null) 'display_order': displayOrder,
    };
  }
}

// ── Display metadata for the step type picker UI ─────────────────────────────

const _kCatFoundation = 'Foundation';
const _kCatAssessment = 'Assessment';
const _kCatSound = 'Sound & Phonics';
const _kCatReading = 'Reading';
const _kCatStory = 'Story';

extension LessonStepTypeDisplay on LessonStepType {
  String get displayName {
    switch (this) {
      case LessonStepType.introduction:
        return 'Introduction';
      case LessonStepType.demonstration:
        return 'Demonstration';
      case LessonStepType.practice:
        return 'Practice';
      case LessonStepType.assessment:
        return 'Assessment';
      case LessonStepType.practiceGame:
        return 'Practice Game';
      case LessonStepType.blending:
        return 'Blending';
      case LessonStepType.soundDiscrimination:
        return 'Sound Discrimination';
      case LessonStepType.soundItemMatching:
        return 'Sound Item Matching';
      case LessonStepType.soundPresenceCheck:
        return 'Sound Presence Check';
      case LessonStepType.guidedReading:
        return 'Guided Reading';
      case LessonStepType.wordReading:
        return 'Word Reading';
      case LessonStepType.sentenceReading:
        return 'Sentence Reading';
      case LessonStepType.missingLetters:
        return 'Missing Letters';
      case LessonStepType.matchingWords:
        return 'Matching Words';
      case LessonStepType.miniStoryCard:
        return 'Mini Story Card';
    }
  }

  String get description {
    switch (this) {
      case LessonStepType.introduction:
        return 'Introduces the lesson with display text and audio';
      case LessonStepType.demonstration:
        return 'Shows visual demonstrations with images and feedback';
      case LessonStepType.practice:
        return 'Practice exercises with labeled image and sound pairs';
      case LessonStepType.assessment:
        return 'Multiple-choice quiz with correct/incorrect options';
      case LessonStepType.practiceGame:
        return 'Timed game for students to identify correct options';
      case LessonStepType.blending:
        return 'Students tap and blend phonemes into words';
      case LessonStepType.soundDiscrimination:
        return 'Students identify if a target sound appears in a word';
      case LessonStepType.soundItemMatching:
        return 'Students match sounds to the correct items';
      case LessonStepType.soundPresenceCheck:
        return 'Yes/no questions about whether a sound appears in a word';
      case LessonStepType.guidedReading:
        return 'Word-by-word guided reading with phoneme breakdown';
      case LessonStepType.wordReading:
        return 'Students read individual words aloud';
      case LessonStepType.sentenceReading:
        return 'Students read full sentences token by token';
      case LessonStepType.missingLetters:
        return 'Fill-in-the-blank letter exercises';
      case LessonStepType.matchingWords:
        return 'Match words to images, sounds, or other words';
      case LessonStepType.miniStoryCard:
        return 'Short story cards with audio and optional call-to-action';
    }
  }

  IconData get icon {
    switch (this) {
      case LessonStepType.introduction:
        return Icons.info_outline;
      case LessonStepType.demonstration:
        return Icons.play_circle_outline;
      case LessonStepType.practice:
        return Icons.edit_outlined;
      case LessonStepType.assessment:
        return Icons.quiz_outlined;
      case LessonStepType.practiceGame:
        return Icons.videogame_asset_outlined;
      case LessonStepType.blending:
        return Icons.merge_type;
      case LessonStepType.soundDiscrimination:
        return Icons.hearing;
      case LessonStepType.soundItemMatching:
        return Icons.compare_arrows;
      case LessonStepType.soundPresenceCheck:
        return Icons.record_voice_over_outlined;
      case LessonStepType.guidedReading:
        return Icons.menu_book_outlined;
      case LessonStepType.wordReading:
        return Icons.text_fields;
      case LessonStepType.sentenceReading:
        return Icons.subject;
      case LessonStepType.missingLetters:
        return Icons.spellcheck;
      case LessonStepType.matchingWords:
        return Icons.swap_horiz;
      case LessonStepType.miniStoryCard:
        return Icons.auto_stories_outlined;
    }
  }

  String get category {
    switch (this) {
      case LessonStepType.introduction:
      case LessonStepType.demonstration:
      case LessonStepType.practice:
        return _kCatFoundation;
      case LessonStepType.assessment:
      case LessonStepType.practiceGame:
        return _kCatAssessment;
      case LessonStepType.blending:
      case LessonStepType.soundDiscrimination:
      case LessonStepType.soundItemMatching:
      case LessonStepType.soundPresenceCheck:
        return _kCatSound;
      case LessonStepType.guidedReading:
      case LessonStepType.wordReading:
      case LessonStepType.sentenceReading:
      case LessonStepType.missingLetters:
      case LessonStepType.matchingWords:
        return _kCatReading;
      case LessonStepType.miniStoryCard:
        return _kCatStory;
    }
  }

  /// Path to the PNG preview illustration for this step type.
  /// Currently uses a shared placeholder; replace with per-type paths or
  /// switch to [previewUrl] when production assets are ready.
  String get assetPath => 'assets/step_type_previews/guided_reading.png';

  /// Production preview URL. When set per-type, [step_type_picker.dart] will
  /// use [Image.network] instead of [Image.asset]. Leave null until assets
  /// are hosted.
  String? get previewUrl => null;
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
      'step_type': stepType.dbValue,
      'position': position,
      'required': required,
      'config': config,
    };
  }
}
