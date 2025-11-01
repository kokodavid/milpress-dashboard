import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../secrets.dart';
import '../../../../utils/app_colors.dart';

class LessonAudioPlayer extends StatefulWidget {
  const LessonAudioPlayer({super.key, required this.url});
  final String url;

  @override
  State<LessonAudioPlayer> createState() => _LessonAudioPlayerState();
}

class _LessonAudioPlayerState extends State<LessonAudioPlayer> {
  final _player = AudioPlayer();
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  PlayerState _state = PlayerState.stopped;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) => setState(() => _state = s));
    _player.onPositionChanged.listen((p) => setState(() => _pos = p));
    _player.onDurationChanged.listen((d) => setState(() => _dur = d));
    _player.onPlayerComplete.listen((_) => setState(() => _pos = _dur));
    _init();
  }

  Future<void> _init() async {
    try {
      final url = await _resolveUrl(widget.url);
      // Hint the MIME type on web to avoid MEDIA_ELEMENT_ERROR (Code 4)
      final mime = _guessMimeType(url);
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setSource(UrlSource(url, mimeType: mime));
    } catch (_) {
      setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const Text('Failed to load audio');
    }

    final isPlaying = _state == PlayerState.playing;
    final progress = _dur.inMilliseconds == 0 ? 0.0 : _pos.inMilliseconds / _dur.inMilliseconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: () async {
                if (isPlaying) {
                  await _player.pause();
                } else {
                  await _player.resume();
                }
                setState(() {});
              },
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            Expanded(
              child: Slider(
                value: progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0),
                activeColor: AppColors.primaryColor,
                onChanged: (v) async {
                  if (_dur.inMilliseconds > 0) {
                    final newPos = Duration(milliseconds: (_dur.inMilliseconds * v).round());
                    await _player.seek(newPos);
                  }
                },
              ),
            ),
            Text(_fmt(_pos)),
            const SizedBox(width: 8),
            Text(_fmt(_dur)),
          ],
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  Future<String> _resolveUrl(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw;
    final parts = raw.split('/');
    if (parts.length < 2) return raw;
    final bucket = parts.first;
    final path = parts.sublist(1).join('/');
    try {
      final publicUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
      if (publicUrl.isNotEmpty) return publicUrl;
    } catch (_) {}
    var base = supabaseUrl;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return '$base/storage/v1/object/public/$bucket/$path';
  }

  String? _guessMimeType(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('?')) {
      // Strip query params for extension check
      final idx = lower.indexOf('?');
      url = lower.substring(0, idx);
    } else {
      url = lower;
    }
    if (url.endsWith('.mp3')) return 'audio/mpeg';
    if (url.endsWith('.wav')) return 'audio/wav';
    if (url.endsWith('.m4a') || url.endsWith('.mp4')) return 'audio/mp4';
    if (url.endsWith('.aac')) return 'audio/aac';
    if (url.endsWith('.ogg') || url.endsWith('.oga')) return 'audio/ogg';
    if (url.endsWith('.opus')) return 'audio/opus';
    if (url.endsWith('.weba') || url.endsWith('.webm')) return 'audio/webm';
    return null; // Let browser try to infer
  }
}
