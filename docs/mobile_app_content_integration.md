# Mobile App — Content Integration Handover

This document explains the two new Supabase tables that replace the hardcoded
content placeholders, and how to fetch and use them in the Flutter mobile app.

---

## Tables

### `app_content`
One row, always `id = 1`. Stores the video and thumbnail URLs.

| Column                      | Type | Nullable |
|-----------------------------|------|----------|
| `intro_video_url`           | text | yes      |
| `intro_video_thumbnail_url` | text | yes      |
| `help_video_url`            | text | yes      |

### `app_resources`
One row per downloadable resource, ordered by `display_order`.

| Column          | Type | Notes                                   |
|-----------------|------|-----------------------------------------|
| `id`            | uuid | PK                                      |
| `label`         | text | Display name                            |
| `file_url`      | text | PDF or video file (Supabase Storage URL)|
| `audio_url`     | text | Companion audio — MP3 or M4A            |
| `type`          | text | `'pdf'` or `'video'`                    |
| `display_order` | int  | Ascending sort order                    |

---

## Models

```dart
// app_content_model.dart
class AppContent {
  final String? introVideoUrl;
  final String? introVideoThumbnailUrl;
  final String? helpVideoUrl;

  const AppContent({
    this.introVideoUrl,
    this.introVideoThumbnailUrl,
    this.helpVideoUrl,
  });

  factory AppContent.fromMap(Map<String, dynamic> map) => AppContent(
        introVideoUrl: map['intro_video_url'] as String?,
        introVideoThumbnailUrl: map['intro_video_thumbnail_url'] as String?,
        helpVideoUrl: map['help_video_url'] as String?,
      );
}
```

```dart
// app_resource_model.dart
class AppResource {
  final String id;
  final String label;
  final String fileUrl;   // PDF or video file
  final String audioUrl;  // companion audio (MP3/M4A)
  final String type;      // 'pdf' | 'video'
  final int displayOrder;

  const AppResource({
    required this.id,
    required this.label,
    required this.fileUrl,
    required this.audioUrl,
    required this.type,
    required this.displayOrder,
  });

  factory AppResource.fromMap(Map<String, dynamic> map) => AppResource(
        id: map['id'] as String,
        label: map['label'] as String,
        fileUrl: map['file_url'] as String? ?? '',
        audioUrl: map['audio_url'] as String? ?? '',
        type: map['type'] as String? ?? 'pdf',
        displayOrder: map['display_order'] as int? ?? 0,
      );
}
```

---

## Fetching from Supabase

```dart
final client = Supabase.instance.client;

// 1. Fetch the global content config
Future<AppContent> fetchAppContent() async {
  final data = await client
      .from('app_content')
      .select()
      .eq('id', 1)
      .single();
  return AppContent.fromMap(data);
}

// 2. Fetch the ordered resources list
Future<List<AppResource>> fetchResources() async {
  final List data = await client
      .from('app_resources')
      .select()
      .order('display_order', ascending: true);
  return data
      .map((e) => AppResource.fromMap(e as Map<String, dynamic>))
      .toList();
}
```

---

## Where Each Field Is Used

### `intro_video_url` + `intro_video_thumbnail_url`
Used in `home_intro_tile.dart` — the "What is Milpress" card.

```dart
// Replace hardcoded values with:
final content = await fetchAppContent();

// thumbnail
NetworkImage(content.introVideoThumbnailUrl ?? fallbackAsset)

// on tap → open video player
VideoPlayerDialog(url: content.introVideoUrl)
```

### `help_video_url`
Used in `help_video_dialog.dart` — the "Need help?" button in the home header.

```dart
final content = await fetchAppContent();
VideoPlayerDialog(url: content.helpVideoUrl)
```

### `app_resources` (replaces hardcoded Alphabets Chart + Mouth Sync Guide)
Used in `home_intro_tile.dart` — the Milpress Resources section.

```dart
// Replace the hardcoded list with a dynamic fetch:
final resources = await fetchResources();

ListView.builder(
  itemCount: resources.length,
  itemBuilder: (_, i) {
    final r = resources[i];
    return ResourceRow(
      label: r.label,
      fileUrl: r.fileUrl,   // open/download this
      audioUrl: r.audioUrl, // play this audio when the row is tapped
      type: r.type,         // use to pick icon: pdf vs video
    );
  },
)
```

The admin can add, remove, and reorder resources from the dashboard without
any app update required.

---

## Notes

- All fields in `app_content` are nullable — always provide a fallback UI
  (placeholder image, disabled button) in case a URL has not been set yet.
- `app_resources` rows with an empty `file_url` should be hidden or shown as
  disabled in the UI. `audio_url` is optional — only render the audio player
  if it is non-empty.
- Both tables are read-only from the mobile app — write access is restricted
  to authenticated dashboard admins via RLS.
