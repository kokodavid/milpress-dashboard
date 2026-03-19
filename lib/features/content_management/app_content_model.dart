import 'package:flutter/foundation.dart';

@immutable
class AppContent {
  final int id;
  final String? introVideoUrl;
  final String? introVideoThumbnailUrl;
  final String? helpVideoUrl;
  final DateTime? updatedAt;

  const AppContent({
    this.id = 1,
    this.introVideoUrl,
    this.introVideoThumbnailUrl,
    this.helpVideoUrl,
    this.updatedAt,
  });

  factory AppContent.fromMap(Map<String, dynamic> map) {
    return AppContent(
      id: map['id'] as int? ?? 1,
      introVideoUrl: map['intro_video_url'] as String?,
      introVideoThumbnailUrl: map['intro_video_thumbnail_url'] as String?,
      helpVideoUrl: map['help_video_url'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'intro_video_url': introVideoUrl,
      'intro_video_thumbnail_url': introVideoThumbnailUrl,
      'help_video_url': helpVideoUrl,
    };
  }

  AppContent copyWith({
    String? introVideoUrl,
    String? introVideoThumbnailUrl,
    String? helpVideoUrl,
  }) {
    return AppContent(
      id: id,
      introVideoUrl: introVideoUrl ?? this.introVideoUrl,
      introVideoThumbnailUrl:
          introVideoThumbnailUrl ?? this.introVideoThumbnailUrl,
      helpVideoUrl: helpVideoUrl ?? this.helpVideoUrl,
      updatedAt: updatedAt,
    );
  }
}
