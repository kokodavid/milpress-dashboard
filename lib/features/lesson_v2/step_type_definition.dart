import 'dart:convert';

// ── Field type enum ───────────────────────────────────────────────────────────

/// The kind of input rendered for a single field in the visual form builder.
enum StepFieldType {
  text,
  imageUrl,
  audioUrl,

  /// A list of activity rows, each containing its own set of sub-fields.
  /// Rendered as an add/remove card list in the step form.
  repeatingGroup;

  /// Value stored in the `field_schema` JSONB column.
  String get dbValue {
    switch (this) {
      case StepFieldType.text:
        return 'text';
      case StepFieldType.imageUrl:
        return 'image_url';
      case StepFieldType.audioUrl:
        return 'audio_url';
      case StepFieldType.repeatingGroup:
        return 'repeating_group';
    }
  }

  /// Label shown in the field-type selector.
  String get displayName {
    switch (this) {
      case StepFieldType.text:
        return 'Text';
      case StepFieldType.imageUrl:
        return 'Image';
      case StepFieldType.audioUrl:
        return 'Audio';
      case StepFieldType.repeatingGroup:
        return 'Activities';
    }
  }

  static StepFieldType fromDbValue(String value) {
    switch (value) {
      case 'image_url':
        return StepFieldType.imageUrl;
      case 'audio_url':
        return StepFieldType.audioUrl;
      case 'repeating_group':
        return StepFieldType.repeatingGroup;
      default:
        return StepFieldType.text;
    }
  }
}

// ── Field definition model ────────────────────────────────────────────────────

/// Defines a single field in a custom step type's visual form.
/// Stored as a JSONB array in `lesson_step_types.field_schema`.
class StepFieldDefinition {
  /// Snake-case key written to the config JSON (e.g. `instruction_text`).
  final String name;

  /// Human-readable label shown to admins filling in the step (e.g. `Instruction`).
  final String label;

  final StepFieldType fieldType;

  /// Whether the field must be filled before the step can be saved.
  final bool isRequired;

  /// Optional hint text rendered beneath the input.
  final String? hint;

  /// Sub-fields for [StepFieldType.repeatingGroup] fields.
  /// Each element defines one column within every activity row.
  /// Ignored for all other field types.
  final List<StepFieldDefinition> subFields;

  const StepFieldDefinition({
    required this.name,
    required this.label,
    required this.fieldType,
    this.isRequired = false,
    this.hint,
    this.subFields = const [],
  });

  factory StepFieldDefinition.fromJson(Map<String, dynamic> json) {
    final rawSub = json['sub_fields'];
    final subFields = rawSub is List
        ? rawSub
            .whereType<Map<String, dynamic>>()
            .map(StepFieldDefinition.fromJson)
            .toList()
        : <StepFieldDefinition>[];

    return StepFieldDefinition(
      name: (json['name'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      fieldType:
          StepFieldType.fromDbValue((json['field_type'] as String?) ?? 'text'),
      isRequired: (json['is_required'] as bool?) ?? false,
      hint: json['hint'] as String?,
      subFields: subFields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'field_type': fieldType.dbValue,
      'is_required': isRequired,
      if (hint != null && hint!.isNotEmpty) 'hint': hint,
      if (subFields.isNotEmpty)
        'sub_fields': subFields.map((f) => f.toJson()).toList(),
    };
  }

  StepFieldDefinition copyWith({
    String? name,
    String? label,
    StepFieldType? fieldType,
    bool? isRequired,
    String? hint,
    List<StepFieldDefinition>? subFields,
  }) {
    return StepFieldDefinition(
      name: name ?? this.name,
      label: label ?? this.label,
      fieldType: fieldType ?? this.fieldType,
      isRequired: isRequired ?? this.isRequired,
      hint: hint ?? this.hint,
      subFields: subFields ?? this.subFields,
    );
  }

  /// Derives a snake_case key from a display label.
  static String deriveNameFromLabel(String label) {
    return label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}

// ── Step type definition model ────────────────────────────────────────────────

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

  /// Visual form fields for this custom step type.
  /// Empty for system types (they use hand-coded forms).
  final List<StepFieldDefinition> fields;

  const StepTypeDefinition({
    required this.id,
    required this.key,
    required this.displayName,
    required this.description,
    required this.category,
    this.previewUrl,
    required this.isSystem,
    this.fields = const [],
  });

  factory StepTypeDefinition.fromMap(Map<String, dynamic> json) {
    final fields = _parseFieldSchema(json['field_schema']);
    return StepTypeDefinition(
      id: (json['id'] as String?) ?? '',
      key: (json['key'] as String?) ?? '',
      displayName: (json['display_name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'Foundation',
      previewUrl: json['preview_url'] as String?,
      isSystem: (json['is_system'] as bool?) ?? false,
      fields: fields,
    );
  }

  static List<StepFieldDefinition> _parseFieldSchema(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(StepFieldDefinition.fromJson)
          .toList();
    }
    if (raw is String && raw.isNotEmpty) {
      // Supabase may return JSONB columns as a raw string in some SDK versions.
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map(StepFieldDefinition.fromJson)
              .toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'key': key,
      'display_name': displayName,
      'description': description,
      'category': category,
      if (previewUrl != null) 'preview_url': previewUrl,
      'is_system': isSystem,
      'field_schema': fields.map((f) => f.toJson()).toList(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'display_name': displayName,
      'description': description,
      'category': category,
      'preview_url': previewUrl,
      'field_schema': fields.map((f) => f.toJson()).toList(),
    };
  }

  StepTypeDefinition copyWith({
    String? displayName,
    String? description,
    String? category,
    String? previewUrl,
    List<StepFieldDefinition>? fields,
  }) {
    return StepTypeDefinition(
      id: id,
      key: key,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      category: category ?? this.category,
      previewUrl: previewUrl ?? this.previewUrl,
      isSystem: isSystem,
      fields: fields ?? this.fields,
    );
  }
}

// ── Category list ─────────────────────────────────────────────────────────────

/// Category options available when creating a custom step type.
const List<String> kStepTypeCategories = [
  'Foundation',
  'Assessment',
  'Sound & Phonics',
  'Reading',
  'Story',
  'Custom',
];
