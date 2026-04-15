/// Represents one row in the `lesson_step_types` Supabase table.
/// System types have [isSystem] = true and are seeded once; they cannot be
/// deleted from the dashboard. Custom types have [isSystem] = false and are
/// fully admin-managed.
class StepTypeDefinition {
  final String id;

  /// Snake-case key stored in `lesson_steps.step_type` (e.g. `phoneme_sort`).
  final String key;
  final String displayName;
  final String description;

  /// One of: Foundation, Assessment, Sound & Phonics, Reading, Story, Custom
  final String category;

  final String? previewUrl;
  final bool isSystem;

  const StepTypeDefinition({
    required this.id,
    required this.key,
    required this.displayName,
    required this.description,
    required this.category,
    this.previewUrl,
    required this.isSystem,
  });

  factory StepTypeDefinition.fromMap(Map<String, dynamic> json) {
    return StepTypeDefinition(
      id: (json['id'] as String?) ?? '',
      key: (json['key'] as String?) ?? '',
      displayName: (json['display_name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'Foundation',
      previewUrl: json['preview_url'] as String?,
      isSystem: (json['is_system'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'key': key,
      'display_name': displayName,
      'description': description,
      'category': category,
      if (previewUrl != null) 'preview_url': previewUrl,
      'is_system': isSystem,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'display_name': displayName,
      'description': description,
      'category': category,
      'preview_url': previewUrl,
    };
  }

  StepTypeDefinition copyWith({
    String? displayName,
    String? description,
    String? category,
    String? previewUrl,
  }) {
    return StepTypeDefinition(
      id: id,
      key: key,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      category: category ?? this.category,
      previewUrl: previewUrl ?? this.previewUrl,
      isSystem: isSystem,
    );
  }
}

/// Category options available when creating a custom step type.
const List<String> kStepTypeCategories = [
  'Foundation',
  'Assessment',
  'Sound & Phonics',
  'Reading',
  'Story',
  'Custom',
];
