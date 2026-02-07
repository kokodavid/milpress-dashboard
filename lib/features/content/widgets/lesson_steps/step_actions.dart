import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lesson_v2/lesson_v2_models.dart';
import '../../../lesson_v2/lesson_v2_repository.dart';
import 'step_dialogs.dart';
import 'step_drafts.dart';

Future<void> editStep(
  BuildContext context,
  WidgetRef ref,
  String lessonId,
  List<LessonStep> steps,
  int index,
) async {
  final updated = await showEditLessonStepDialog(
    context: context,
    step: steps[index],
  );
  if (updated == null) return;
  final inputs = <LessonStepInput>[];
  for (var i = 0; i < steps.length; i++) {
    if (i == index) {
      inputs.add(updated.copyWithPosition(i + 1));
    } else {
      inputs.add(stepToInput(steps[i], position: i + 1));
    }
  }
  await ref.read(saveLessonProvider.notifier).updateSteps(lessonId, inputs);
  ref.invalidate(lessonByIdProvider(lessonId));
}

Future<void> deleteStep(
  BuildContext context,
  WidgetRef ref,
  String lessonId,
  List<LessonStep> steps,
  int index,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete step'),
      content: const Text('Are you sure you want to delete this step?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final updatedSteps = List<LessonStep>.from(steps)..removeAt(index);
  final inputs = <LessonStepInput>[];
  for (var i = 0; i < updatedSteps.length; i++) {
    inputs.add(stepToInput(updatedSteps[i], position: i + 1));
  }
  await ref.read(saveLessonProvider.notifier).updateSteps(lessonId, inputs);
  ref.invalidate(lessonByIdProvider(lessonId));
}
