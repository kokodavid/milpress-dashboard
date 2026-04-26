import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/content/widgets/media/audio_player_widget.dart';
import '../features/content/widgets/media/video_player_widget.dart';

// ---------------------------------------------------------------------------
// Type detection
// ---------------------------------------------------------------------------

enum _MediaType { video, audio, image, pdf, unknown }

_MediaType _detectType(String url) {
  final clean = url.split('?').first.toLowerCase();
  final ext = clean.split('.').last;
  if (['mp4', 'mov', 'webm', 'avi', 'mkv'].contains(ext)) return _MediaType.video;
  if (['mp3', 'm4a', 'wav', 'aac', 'ogg', 'opus'].contains(ext)) return _MediaType.audio;
  if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(ext)) return _MediaType.image;
  if (ext == 'pdf') return _MediaType.pdf;
  return _MediaType.unknown;
}

// ---------------------------------------------------------------------------
// Type helpers
// ---------------------------------------------------------------------------

Color _mediaAccent(_MediaType type) {
  switch (type) {
    case _MediaType.video:
      return const Color(0xFFE85D04);
    case _MediaType.audio:
      return const Color(0xFF7C3AED);
    case _MediaType.image:
      return const Color(0xFF4F46E5);
    case _MediaType.pdf:
      return const Color(0xFFD97706);
    case _MediaType.unknown:
      return const Color(0xFF6B7280);
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

String _typeLabel(_MediaType type) {
  switch (type) {
    case _MediaType.video:
      return 'VIDEO';
    case _MediaType.audio:
      return 'AUDIO';
    case _MediaType.image:
      return 'IMAGE';
    case _MediaType.pdf:
      return 'PDF';
    case _MediaType.unknown:
      return 'FILE';
  }
}

// ---------------------------------------------------------------------------
// Studio design tokens  (Direction B — Confident Studio)
// ---------------------------------------------------------------------------

const Color _kSurface = Color(0xFF13151B);
const Color _kDivider = Color(0x0FFFFFFF); // rgba(255,255,255,.06)
const Color _kCardBg = Color(0x0AFFFFFF); // rgba(255,255,255,.04)
const Color _kFg = Color(0xFFE2E4E9);
const Color _kFgMuted = Color(0xFF8A8F9C);
const Color _kFgFaint = Color(0xFF3A3F4C);
const Color _kBorder = Color(0xFF252830);

// ---------------------------------------------------------------------------
// Public API — same call surface as before
// ---------------------------------------------------------------------------

class MediaPreviewDialog {
  /// Opens the Confident Studio slide-over panel from the right edge.
  ///
  /// ```dart
  /// MediaPreviewDialog.show(context, url: url, label: 'Intro Video');
  /// ```
  static Future<void> show(
    BuildContext context, {
    required String url,
    String? label,
  }) {
    if (url.trim().isEmpty) return Future.value();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close preview',
      barrierColor: const Color(0x52000000), // 32 % scrim
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, _, __) => _StudioPanel(url: url.trim(), label: label),
      transitionBuilder: (ctx, anim, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// PreviewSuffixIcon — kept for backward compat
// ---------------------------------------------------------------------------

/// Minimal eye-icon inside a TextFormField suffix.
/// Prefer [ThumbnailChip] as a sibling widget for new or updated fields.
class PreviewSuffixIcon extends StatelessWidget {
  const PreviewSuffixIcon({super.key, required this.ctrl, this.label});

  final TextEditingController ctrl;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (context, value, _) {
        if (value.text.trim().isEmpty) return const SizedBox.shrink();
        return IconButton(
          icon: Icon(Icons.visibility_outlined, size: 18, color: Colors.indigo.shade400),
          tooltip: 'Preview${label != null ? ' $label' : ''}',
          onPressed: () =>
              MediaPreviewDialog.show(context, url: value.text.trim(), label: label),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// ThumbnailChip — coloured pill sibling trigger
// ---------------------------------------------------------------------------

/// A pill-shaped chip that sits next to a URL input field as a sibling widget.
/// Handles its own 8 px left margin; the parent Row needs no gap widget.
/// Hidden (SizedBox.shrink) when the field is empty.
///
/// ```dart
/// Row(children: [
///   Expanded(child: TextFormField(...)),
///   ThumbnailChip(ctrl: _myCtrl, label: 'Cover Image'),
/// ])
/// ```
class ThumbnailChip extends StatelessWidget {
  const ThumbnailChip({super.key, required this.ctrl, this.label});

  final TextEditingController ctrl;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (context, value, _) {
        if (value.text.trim().isEmpty) return const SizedBox.shrink();
        final url = value.text.trim();
        final type = _detectType(url);
        final accent = _mediaAccent(type);
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _ChipButton(
            type: type,
            accent: accent,
            onTap: () => MediaPreviewDialog.show(context, url: url, label: label),
          ),
        );
      },
    );
  }
}

class _ChipButton extends StatefulWidget {
  const _ChipButton({
    required this.type,
    required this.accent,
    required this.onTap,
  });

  final _MediaType type;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_ChipButton> createState() => _ChipButtonState();
}

class _ChipButtonState extends State<_ChipButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
          decoration: BoxDecoration(
            color: _hovered ? accent.withOpacity(0.14) : accent.withOpacity(0.08),
            border: Border.all(
              color: _hovered ? accent.withOpacity(0.45) : accent.withOpacity(0.25),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(_iconFor(widget.type), size: 13, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Text(
                'Preview',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: accent,
                ),
              ),
              const SizedBox(width: 1),
              Icon(Icons.chevron_right, size: 14, color: accent.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Studio slide-over panel (Direction B — Confident Studio)
// ---------------------------------------------------------------------------

class _StudioPanel extends StatelessWidget {
  const _StudioPanel({required this.url, this.label});

  final String url;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final type = _detectType(url);
    final accent = _mediaAccent(type);
    final filename = url.split('/').last.split('?').first;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: _kSurface,
        child: SizedBox(
          width: 560,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PanelHeader(
                  type: type,
                  accent: accent,
                  filename: filename,
                  label: label,
                  onClose: () => Navigator.of(context).pop(),
                ),
                _ActionBar(url: url),
                const Divider(color: _kDivider, height: 1, thickness: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MediaCanvas(url: url, type: type, accent: accent),
                        const SizedBox(height: 16),
                        _SpecGrid(filename: filename, type: type),
                        const SizedBox(height: 12),
                        _UrlBlock(url: url),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panel header
// ---------------------------------------------------------------------------

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.type,
    required this.accent,
    required this.filename,
    required this.onClose,
    this.label,
  });

  final _MediaType type;
  final Color accent;
  final String filename;
  final String? label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Type chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconFor(type), size: 12, color: accent),
                const SizedBox(width: 4),
                Text(
                  _typeLabel(type),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Title + monospace filename
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kFg,
                      height: 1.2,
                    ),
                  ),
                Text(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: _kFgMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Close pill
          SizedBox(
            width: 32,
            height: 32,
            child: Material(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onClose,
                child: const Icon(Icons.close, size: 16, color: _kFgMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action toolbar
// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          _ActionBtn(
            icon: Icons.copy_outlined,
            label: 'Copy URL',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL copied to clipboard'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          _ActionBtn(
            icon: Icons.open_in_new,
            label: 'Open in tab',
            onTap: () async {
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

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? _kCardBg : Colors.transparent,
            border: Border.all(color: _hovered ? _kBorder : _kFgFaint),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: _hovered ? _kFg : _kFgMuted),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  color: _hovered ? _kFg : _kFgMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Media canvas
// ---------------------------------------------------------------------------

class _MediaCanvas extends StatelessWidget {
  const _MediaCanvas({required this.url, required this.type, required this.accent});

  final String url;
  final _MediaType type;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: _kCardBg,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (type) {
      case _MediaType.video:
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: LessonVideoPlayer(url: url),
        );

      case _MediaType.audio:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(type), size: 28, color: accent),
              ),
              LessonAudioPlayer(url: url),
            ],
          ),
        );

      case _MediaType.image:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _CheckerPainter()),
              ),
              InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Could not load image',
                        style: TextStyle(color: _kFgMuted, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case _MediaType.pdf:
      case _MediaType.unknown:
        return _PdfFallback(url: url);
    }
  }
}

/// Checkerboard background — reveals image transparency.
class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tileSize = 12.0;
    final paintA = Paint()..color = const Color(0xFF1C1F28);
    final paintB = Paint()..color = const Color(0xFF22252F);
    final cols = (size.width / tileSize).ceil();
    final rows = (size.height / tileSize).ceil();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * tileSize, r * tileSize, tileSize, tileSize),
          (r + c).isEven ? paintA : paintB,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter old) => false;
}

// ---------------------------------------------------------------------------
// PDF / unknown fallback (dark-themed)
// ---------------------------------------------------------------------------

class _PdfFallback extends StatelessWidget {
  const _PdfFallback({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final filename = url.split('/').last.split('?').first;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 52,
            color: const Color(0xFFD97706).withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          Text(
            filename,
            style: const TextStyle(fontSize: 13, color: _kFgMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.open_in_new, size: 15),
            label: const Text('Open in browser'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
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

// ---------------------------------------------------------------------------
// Spec grid — metadata sheet
// ---------------------------------------------------------------------------

class _SpecGrid extends StatelessWidget {
  const _SpecGrid({required this.filename, required this.type});

  final String filename;
  final _MediaType type;

  @override
  Widget build(BuildContext context) {
    final ext = filename.contains('.') ? filename.split('.').last.toUpperCase() : '—';
    final truncated =
        filename.length > 36 ? '${filename.substring(0, 33)}…' : filename;

    final cells = <(String, String)>[
      ('Filename', truncated),
      ('Format', ext),
      ('Size', '—'),
      if (type == _MediaType.image) ('Dimensions', '—'),
      if (type == _MediaType.video || type == _MediaType.audio) ('Duration', '—'),
      if (type == _MediaType.video) ('Resolution', '—'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kDivider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const Divider(color: _kDivider, height: 1, thickness: 1),
            _SpecRow(label: cells[i].$1, value: cells[i].$2),
          ],
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _kFgMuted,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: _kFg,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// URL block with inline copy button
// ---------------------------------------------------------------------------

class _UrlBlock extends StatelessWidget {
  const _UrlBlock({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kDivider),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          const Icon(Icons.link, size: 14, color: _kFgMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: _kFgMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 30,
            height: 30,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL copied'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Icon(Icons.copy_outlined, size: 14, color: _kFgMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
