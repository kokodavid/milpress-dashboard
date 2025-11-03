enum QuestionStage {
  wordRecognition('word_recognition', 'Word Recognition'),
  letterRecognition('letter_recognition', 'Letter Recognition'),
  writingAbility('writing_ability', 'Writing Ability'),
  sentenceComprehension('sentence_comprehension', 'Sentence Comprehension');

  const QuestionStage(this.value, this.displayName);

  final String value;
  final String displayName;

  /// Get QuestionStage from string value
  static QuestionStage? fromValue(String? value) {
    if (value == null) return null;
    for (QuestionStage stage in QuestionStage.values) {
      if (stage.value == value) return stage;
    }
    return null;
  }

  /// Get all question stages as a list
  static List<QuestionStage> get all => QuestionStage.values;

  /// Get display names for dropdown
  static List<String> get displayNames => QuestionStage.values.map((e) => e.displayName).toList();
}