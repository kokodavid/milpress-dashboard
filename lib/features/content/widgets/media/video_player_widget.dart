import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../secrets.dart';

class LessonVideoPlayer extends StatefulWidget {
  const LessonVideoPlayer({super.key, required this.url, this.aspectRatio = 16 / 9});
  final String url;
  final double aspectRatio;

  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initFuture;
  bool _error = false;
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _initFuture = _prepare();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return _errorBox('Failed to load video');
    }

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _errorBox('Failed to load video: ${snapshot.error}');
        }
  final controller = _controller!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio == 0
                  ? widget.aspectRatio
                  : controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(controller),
                  _ControlsOverlay(controller: controller),
                  VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _prepare() async {
    try {
      _resolvedUrl = await _resolveUrl(widget.url);
      _controller = VideoPlayerController.networkUrl(Uri.parse(_resolvedUrl!));
      await _controller!.initialize();
    } catch (e) {
      setState(() => _error = true);
    }
  }

  Future<String> _resolveUrl(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw; // already absolute

    // Assume "bucket/path/to/file" format for Supabase Storage
    final parts = raw.split('/');
    if (parts.length < 2) return raw;
    final bucket = parts.first;
    final path = parts.sublist(1).join('/');

    try {
      // Try public URL from storage API (returns String)
      final publicUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
      if (publicUrl.isNotEmpty) return publicUrl;
    } catch (_) {
      // Ignore and try manual fallback
    }

    // Manual public URL fallback
    var base = supabaseUrl;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return '$base/storage/v1/object/public/$bucket/$path';
  }

  Widget _errorBox(String msg) => Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(msg),
      );
}

class _ControlsOverlay extends StatefulWidget {
  const _ControlsOverlay({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<_ControlsOverlay> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _show = !_show),
      child: AnimatedOpacity(
        opacity: _show ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            ),
            Center(
              child: IconButton.filled(
                iconSize: 48,
                onPressed: () async {
                  if (widget.controller.value.isPlaying) {
                    await widget.controller.pause();
                  } else {
                    await widget.controller.play();
                  }
                  setState(() {});
                },
                icon: Icon(widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
            )
          ],
        ),
      ),
    );
  }
}
