import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/media_preview_dialog.dart';
import '../app_content_model.dart';
import '../content_management_providers.dart';
import '../content_management_repository.dart';

class VideoFieldsSection extends ConsumerStatefulWidget {
  const VideoFieldsSection({super.key});

  @override
  ConsumerState<VideoFieldsSection> createState() => _VideoFieldsSectionState();
}

class _VideoFieldsSectionState extends ConsumerState<VideoFieldsSection> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _introVideoCtrl;
  late TextEditingController _thumbnailCtrl;
  late TextEditingController _helpVideoCtrl;
  bool _initialised = false;

  @override
  void dispose() {
    _introVideoCtrl.dispose();
    _thumbnailCtrl.dispose();
    _helpVideoCtrl.dispose();
    super.dispose();
  }

  void _initControllers(AppContent content) {
    if (_initialised) return;
    _introVideoCtrl =
        TextEditingController(text: content.introVideoUrl ?? '');
    _thumbnailCtrl =
        TextEditingController(text: content.introVideoThumbnailUrl ?? '');
    _helpVideoCtrl =
        TextEditingController(text: content.helpVideoUrl ?? '');
    _initialised = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = AppContent(
      introVideoUrl: _introVideoCtrl.text.trim().isEmpty
          ? null
          : _introVideoCtrl.text.trim(),
      introVideoThumbnailUrl: _thumbnailCtrl.text.trim().isEmpty
          ? null
          : _thumbnailCtrl.text.trim(),
      helpVideoUrl: _helpVideoCtrl.text.trim().isEmpty
          ? null
          : _helpVideoCtrl.text.trim(),
    );
    await ref.read(updateAppContentProvider.notifier).save(updated);
    ref.invalidate(appContentProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video URLs saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(appContentProvider);
    final saveState = ref.watch(updateAppContentProvider);

    return contentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading content: $e'),
      data: (content) {
        _initControllers(content);
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Videos & Thumbnail',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _UrlField(
                controller: _introVideoCtrl,
                label: 'Intro Video URL',
                hint: 'https://…/intro.mp4',
                helperText: 'MP4 — "What is Milpress" video',
              ),
              const SizedBox(height: 12),
              _UrlField(
                controller: _thumbnailCtrl,
                label: 'Intro Video Thumbnail URL',
                hint: 'https://…/thumbnail.jpg',
                helperText: 'JPG or PNG, 16:9 ratio',
              ),
              const SizedBox(height: 12),
              _UrlField(
                controller: _helpVideoCtrl,
                label: 'Help Video URL',
                hint: 'https://…/help.mp4',
                helperText: 'MP4 — "Need help?" button on Home screen',
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Videos',
                backgroundColor: AppColors.primaryColor,
                onPressed: saveState is AsyncLoading ? null : _save,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UrlField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String helperText;

  const _UrlField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        suffixIcon: PreviewSuffixIcon(ctrl: controller, label: label),
      ),
      keyboardType: TextInputType.url,
    );
  }
}
