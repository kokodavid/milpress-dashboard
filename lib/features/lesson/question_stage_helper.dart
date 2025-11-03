import 'question_stages.dart';

/// Utility class for working with question stages
class QuestionStageHelper {
  /// Convert question stage string from backend to display name
  static String getDisplayName(String? questionStage) {
    final stage = QuestionStage.fromValue(questionStage);
    return stage?.displayName ?? questionStage ?? 'Unknown';
  }

  /// Validate if a question stage string is valid
  static bool isValidQuestionStage(String? questionStage) {
    return QuestionStage.fromValue(questionStage) != null;
  }

  /// Get all question stage values for backend
  static List<String> getAllValues() {
    return QuestionStage.values.map((e) => e.value).toList();
  }

  /// Get all question stage display names for UI
  static List<String> getAllDisplayNames() {
    return QuestionStage.values.map((e) => e.displayName).toList();
  }

  /// Convert question stage to a color for UI theming
  static String getStageColor(String? questionStage) {
    final stage = QuestionStage.fromValue(questionStage);
    switch (stage) {
      case QuestionStage.wordRecognition:
        return '#4CAF50'; // Green
      case QuestionStage.letterRecognition:
        return '#2196F3'; // Blue
      case QuestionStage.writingAbility:
        return '#FF9800'; // Orange
      case QuestionStage.sentenceComprehension:
        return '#9C27B0'; // Purple
      default:
        return '#757575'; // Grey
    }
  }

  /// Get icon for question stage
  static String getStageIcon(String? questionStage) {
    final stage = QuestionStage.fromValue(questionStage);
    switch (stage) {
      case QuestionStage.wordRecognition:
        return '📝'; // Writing
      case QuestionStage.letterRecognition:
        return '🔤'; // ABC
      case QuestionStage.writingAbility:
        return '✍️'; // Writing hand
      case QuestionStage.sentenceComprehension:
        return '📖'; // Book
      default:
        return '❓'; // Question mark
    }
  }
}