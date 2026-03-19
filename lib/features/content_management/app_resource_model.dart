import 'package:flutter/foundation.dart';

@immutable
class AppResource {
  final String id;
  final String label;
  final String fileUrl;
  final String audioUrl;
  final String type; // 'pdf' | 'video'
  final int displayOrder;
  final DateTime? createdAt;

  const AppResource({
    required this.id,
    required this.label,
    required this.fileUrl,
    required this.audioUrl,
    required this.type,
    required this.displayOrder,
    this.createdAt,
  });

  factory AppResource.fromMap(Map<String, dynamic> map) {
    return AppResource(
      id: map['id'] as String,
      label: map['label'] as String,
      fileUrl: map['file_url'] as String? ?? '',
      audioUrl: map['audio_url'] as String? ?? '',
      type: map['type'] as String? ?? 'pdf',
      displayOrder: map['display_order'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'label': label,
      'file_url': fileUrl,
      'audio_url': audioUrl,
      'type': type,
      'display_order': displayOrder,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'label': label,
      'file_url': fileUrl,
      'audio_url': audioUrl,
      'type': type,
      'display_order': displayOrder,
    };
  }

  AppResource copyWith({
    String? label,
    String? fileUrl,
    String? audioUrl,
    String? type,
    int? displayOrder,
  }) {
    return AppResource(
      id: id,
      label: label ?? this.label,
      fileUrl: fileUrl ?? this.fileUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      type: type ?? this.type,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt,
    );
  }
}
