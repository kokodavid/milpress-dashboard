import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/content/widgets/media/audio_player_widget.dart';
import '../features/content/widgets/media/video_player_widget.dart';

// ---------------------------------------------------------------------------
// Type detection
// ---------------------------------------------------------------------------

enum _MediaType { video, audio, image, pdf, unknown }

_MediaType _detectType(String url) {
  // Strip query params before reading extension
  final clean = url.split('?').first.toLowerCase();
  final ext = clean.split('.').last;
  if (['mp4', 'mov', 'webm', 'avi', 'mkv'].contains(ext)) {
    return _MediaType.video;
  }
  if (['mp3', 'm4a', 'wav', 'aac', 'ogg', 'opus'].contains(ext)) {
    return _MediaType.audio;
  }
  if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(ext)) {
    return _MediaType.image;
  }
  if (ext == 'pdf') return _MediaType.pdf;
  return _MediaType.unknown;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

class MediaPreviewDialog {
  /// Call this from anywhere to open a media preview dialog.
  ///
  /// ```dart
  /// MediaPreviewDialog.show(context, url: url, label: 'Intro Video');
  /// ```
  static void show(
    BuildContext context, {
    required String url,
    String? label,
  }) {
    if (url.trim().isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (_) => _PreviewDialog(url: url.trim(), label: label),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared suffix icon widget — use inside InputDecoration.suffixIcon
// ---------------------------------------------------------------------------

/// An eye icon that appears inside a TextFormField when the controller has
/// a value. Tapping it opens [MediaPreviewDialog].
class PreviewSuffixIcon extends StatelessWidget {
  const PreviewSuffixIcon({
    super.key,
    required this.ctrl,
    this.label,
  });

  final TextEditingController ctrl;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (context, value, _) {
        if (value.text.trim().isEmpty) return const SizedBox.shrink();
        return IconButton(
          icon: Icon(
            Icons.visibility_outlined,
            size: 18,
            color: Colors.indigo.shade400,
          ),
          tooltip: 'Preview${label != null ? ' $label' : ''}',
          onPressed: () => MediaPreviewDialog.show(
            context,
            url: value.text.trim(),
            label: label,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Internal dialog widget
// ---------------------------------------------------------------------------

class _PreviewDialog extends StatelessWidget {
  const _PreviewDialog({required this.url, this.label});

  final String url;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final type = _detectType(url);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
              child: Row(
                children: [
                  Icon(_iconFor(type), size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label ?? 'Preview',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 18),
            // ── Body ───────────────────────────────────────────────────────
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildBody(context, type),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, _MediaType type) {
    switch (type) {
      case _MediaType.video:
        return LessonVideoPlayer(url: url);
      case _MediaType.audio:
        return LessonAudioPlayer(url: url);
      case _MediaType.image:
        return InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Text('Could not load image'),
            ),
          ),
        );
      case _MediaType.pdf:
      case _MediaType.unknown:
        return _OpenInBrowserFallback(url: url);
    }
  }

  IconData _iconFor(_MediaType type) {
    switch (type) {
      case _MediaType.video:
        return Icons.videocam_outlined;
      case _MediaType.audio:
        return Icons.audio_file_outlined;
      case _MediaType.image:
        return Icons.image_outlined;
      case _MediaType.pdf:
        return Icons.picture_as_pdf_outlined;
      case _MediaType.unknown:
        return Icons.insert_drive_file_outlined;
    }
  }
}

// ---------------------------------------------------------------------------
// PDF / unknown fallback
// ---------------------------------------------------------------------------

class _OpenInBrowserFallback extends StatelessWidget {
  const _OpenInBrowserFallback({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_outlined,
              size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            url.split('/').last.split('?').first,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open in Browser'),
            onPressed: () async {
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}
