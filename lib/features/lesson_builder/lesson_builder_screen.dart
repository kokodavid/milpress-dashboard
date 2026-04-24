import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lesson_v2/lesson_v2_repository.dart';
import 'lesson_builder_state.dart';
import 'widgets/learner_preview_panel.dart';
import 'widgets/lesson_builder_app_bar.dart';
import 'widgets/lesson_flow_sidebar.dart';
import 'widgets/step_editor_panel.dart';

/// Full-page 3-panel lesson steps builder.
///
/// Route: /lessons/:lessonId/steps  (outside AppShell — has its own top bar)
///
/// Panels (left → right):
///   [LessonFlowSidebar]    — step list · drag-to-reorder · add step
///   [StepEditorPanel]      — inline field editor for the active step
///   [LearnerPreviewPanel]  — phone/tablet device-frame preview
class LessonStepsBuilderScreen extends ConsumerWidget {
  const LessonStepsBuilderScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonByIdProvider(lessonId));

    return lessonAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Lesson Builder')),
        body: Center(child: Text('Failed to load lesson: $e')),
      ),
      data: (detail) {
        if (detail == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lesson Builder')),
            body: const Center(child: Text('Lesson not found')),
          );
        }

        // Pre-warm the drafts provider as soon as the lesson data is available
        ref.watch(lessonBuilderDraftsProvider(lessonId));

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: LessonBuilderAppBar(
            lessonId: lessonId,
            lessonDetail: detail,
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Lesson Flow Sidebar ─────────────────────────────
              Container(
                width: 280,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                ),
                child: LessonFlowSidebar(lessonId: lessonId),
              ),

              // ── Centre: Step Editor ───────────────────────────────────
              Expanded(
                child: StepEditorPanel(lessonId: lessonId),
              ),

              // ── Right: Learner Preview ────────────────────────────────
              Container(
                width: 320,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: Color(0xFFE5E5E5)),
                  ),
                ),
                child: LearnerPreviewPanel(lessonId: lessonId),
              ),
            ],
          ),
        );
      },
    );
  }
}
