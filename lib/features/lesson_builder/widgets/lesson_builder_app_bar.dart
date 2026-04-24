import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/content/state/lessons_list_controller.dart';
import '../../../features/course/course_models.dart';
import '../../../features/lesson_v2/lesson_v2_models.dart';
import '../../../features/modules/modules_repository.dart';
import '../lesson_builder_state.dart';
import '../lesson_builder_theme.dart';
import '../../../features/lesson_v2/lesson_v2_repository.dart';

/// Full top bar for the lesson steps builder.
///
/// Shows: ← back · breadcrumb · lesson title · draft-saved indicator
///        · Preview all · Publish lesson
class LessonBuilderAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const LessonBuilderAppBar({
    super.key,
    required this.lessonId,
    required this.lessonDetail,
  });

  final String lessonId;
  final LessonWithSteps lessonDetail;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saveStatus = ref.watch(lessonBuilderSaveStatusProvider(lessonId));
    final saveTime = ref.watch(lessonBuilderSaveTimeProvider(lessonId));
    final courseAsync = ref.watch(selectedCourseProvider);
    final moduleAsync =
        ref.watch(moduleByIdProvider(lessonDetail.lesson.moduleId));

    final breadcrumb = _buildBreadcrumb(
      course: courseAsync.valueOrNull,
      module: moduleAsync.valueOrNull,
      lessonTitle: lessonDetail.lesson.title,
    );

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      leading: _BackButton(lessonId: lessonId),
      leadingWidth: 120,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            breadcrumb,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: LessonBuilderTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            lessonDetail.lesson.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        _SaveIndicator(status: saveStatus, saveTime: saveTime),
        const SizedBox(width: 8),
        _PreviewAllButton(lessonId: lessonId),
        const SizedBox(width: 8),
        _PublishButton(lessonId: lessonId),
        const SizedBox(width: 16),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: LessonBuilderTheme.surfaceBorder),
      ),
    );
  }

  static String _buildBreadcrumb({
    required Course? course,
    required dynamic module, // Module?
    required String lessonTitle,
  }) {
    final parts = <String>[];
    if (course != null) parts.add(course.title.toUpperCase());
    if (module != null) parts.add('MODULE ${module.position}');
    if (parts.isEmpty) parts.add('LESSON');
    return parts.join(' · ');
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _BackButton extends ConsumerWidget {
  const _BackButton({required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () {
        // Restore lesson selection so the detail pane re-opens correctly
        ref.read(selectedLessonIdProvider.notifier).state = lessonId;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/lessons');
        }
      },
      icon: const Icon(Icons.arrow_back, size: 16),
      label: const Text('Lessons', style: TextStyle(fontSize: 13)),
      style: TextButton.styleFrom(
        foregroundColor: LessonBuilderTheme.textDark,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({
    required this.status,
    required this.saveTime,
  });

  final AutoSaveStatus status;
  final DateTime? saveTime;

  @override
  Widget build(BuildContext context) {
    if (status == AutoSaveStatus.idle) return const SizedBox.shrink();

    final (icon, label, color) = _resolveDisplay(status, saveTime);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  static (IconData?, String, Color) _resolveDisplay(
    AutoSaveStatus status,
    DateTime? saveTime,
  ) {
    switch (status) {
      case AutoSaveStatus.saving:
        return (null, 'Saving…', LessonBuilderTheme.textMuted);
      case AutoSaveStatus.saved:
        return (Icons.check, _savedAgo(saveTime), LessonBuilderTheme.textMuted);
      case AutoSaveStatus.error:
        return (Icons.error_outline, 'Save failed', Colors.red.shade600);
      case AutoSaveStatus.idle:
        return (null, '', LessonBuilderTheme.textMuted);
    }
  }

  static String _savedAgo(DateTime? time) {
    if (time == null) return 'Draft saved';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 5) return 'Draft saved · just now';
    if (diff.inSeconds < 60) return 'Draft saved · ${diff.inSeconds}s ago';
    return 'Draft saved · ${diff.inMinutes}m ago';
  }
}

class _PreviewAllButton extends StatelessWidget {
  const _PreviewAllButton({required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {}, // wired up when preview-all flow is built
      icon: const Icon(Icons.visibility_outlined, size: 15),
      label: const Text('Preview all', style: TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: LessonBuilderTheme.textDark,
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _PublishButton extends ConsumerStatefulWidget {
  const _PublishButton({required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<_PublishButton> createState() => _PublishButtonState();
}

class _PublishButtonState extends ConsumerState<_PublishButton> {
  Future<void> _onPublish() async {
    try {
      await ref
          .read(lessonBuilderDraftsProvider(widget.lessonId).notifier)
          .publish();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson published successfully'),
          backgroundColor: Color(0xFF22C55E),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Publish failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final publishStatus =
        ref.watch(lessonBuilderPublishStatusProvider(widget.lessonId));
    final isPublishing = publishStatus == PublishStatus.publishing;

    return ElevatedButton(
      onPressed: isPublishing ? null : _onPublish,
      style: ElevatedButton.styleFrom(
        backgroundColor: LessonBuilderTheme.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: LessonBuilderTheme.primary.withOpacity(0.7),
        disabledForegroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isPublishing
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Publish lesson',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
    );
  }
}
