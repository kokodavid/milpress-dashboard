import 'package:flutter/material.dart';

import '../../../lesson_v2/lesson_v2_models.dart';
import 'step_drafts.dart';

typedef StepFormSetState = void Function(VoidCallback fn);

Widget buildLessonStepTypeFields({
  required BuildContext context,
  required StepDraft step,
  required StepFormSetState setState,
}) {
  // Custom admin-created types use a simple JSON config editor.
  if (step.customStepType != null) {
    return _buildGenericJsonFields(step);
  }

  switch (step.stepType) {
    case LessonStepType.introduction:
      return _buildIntroductionFields(step);
    case LessonStepType.demonstration:
      return _buildDemonstrationFields(context, step, setState);
    case LessonStepType.practice:
      return _buildPracticeFields(context, step, setState);
    case LessonStepType.assessment:
      return _buildAssessmentFields(context, step, setState);
    case LessonStepType.blending:
      return _buildBlendingFields(context, step, setState);
    case LessonStepType.soundDiscrimination:
      return _buildSoundDiscriminationFields(context, step, setState);
    case LessonStepType.soundItemMatching:
      return _buildSoundItemMatchingFields(context, step, setState);
    case LessonStepType.guidedReading:
      return _buildGuidedReadingFields(context, step, setState);
    case LessonStepType.practiceGame:
      return _buildPracticeGameFields(context, step, setState);
    case LessonStepType.soundPresenceCheck:
      return _buildSoundPresenceCheckFields(context, step, setState);
    case LessonStepType.missingLetters:
      return _buildMissingLettersFields(context, step, setState);
    case LessonStepType.matchingWords:
      return _buildMatchingWordsFields(context, step, setState);
    case LessonStepType.wordReading:
      return _buildWordReadingFields(context, step, setState);
    case LessonStepType.sentenceReading:
      return _buildSentenceReadingFields(context, step, setState);
    case LessonStepType.miniStoryCard:
      return _buildMiniStoryCardFields(context, step, setState);
  }
}

String? validateLessonStepDraft(StepDraft step) {
  if (step.stepKeyCtrl.text.trim().isEmpty) {
    return 'Every step needs a step key';
  }
  if (step.titleCtrl.text.trim().isEmpty) {
    return 'Every step needs a title';
  }

  switch (step.stepType) {
    case LessonStepType.introduction:
      if (step.displayTextCtrl.text.trim().isEmpty) {
        return 'Introduction steps need display text';
      }
      return null;
    case LessonStepType.demonstration:
      return null;
    case LessonStepType.practice:
      if (step.practiceItems.isEmpty) {
        return 'Practice steps need at least one item';
      }
      return null;
    case LessonStepType.assessment:
      if (step.assessmentOptions.isEmpty) {
        return 'Assessment steps need at least one option';
      }
      if (step.assessmentOptions.every((o) => !o.isCorrect)) {
        return 'Assessment steps need at least one correct option';
      }
      if (step.promptCtrl.text.trim().isEmpty) {
        return 'Assessment steps need a prompt';
      }
      return null;
    case LessonStepType.blending:
      if (step.blendingExamples.isEmpty) {
        return 'Blending steps need at least one example';
      }
      if (step.blendingExamples.any((e) => e.wordCtrl.text.trim().isEmpty)) {
        return 'Every blending example needs a word';
      }
      if (step.blendingExamples.any(
        (e) => e.audioUrlCtrl.text.trim().isEmpty,
      )) {
        return 'Every blending example needs a word audio URL';
      }
      if (step.blendingExamples.any((e) => e.phonemes.isEmpty)) {
        return 'Every blending example needs at least one phoneme';
      }
      return null;
    case LessonStepType.soundDiscrimination:
      if (step.targetSoundCtrl.text.trim().isEmpty) {
        return 'Sound discrimination steps need a target sound';
      }
      if (step.referenceWordCtrl.text.trim().isEmpty) {
        return 'Sound discrimination steps need a reference word';
      }
      if (step.soundDiscriminationItems.isEmpty) {
        return 'Sound discrimination steps need at least one item';
      }
      for (final item in step.soundDiscriminationItems) {
        if (item.titleCtrl.text.trim().isEmpty) {
          return 'Every sound discrimination item needs a title';
        }
        if (item.titleAudioCtrl.text.trim().isEmpty) {
          return 'Every sound discrimination item needs a title audio URL';
        }
        if (item.imageUrlCtrl.text.trim().isEmpty) {
          return 'Every sound discrimination item needs an image URL';
        }
        if (item.containsTargetSound &&
            item.highlightedTextCtrl.text.trim().isEmpty) {
          return 'Items that contain the target sound need highlighted text';
        }
      }
      return null;
    case LessonStepType.soundItemMatching:
      if (step.soundItemMatchingActivities.isEmpty) {
        return 'Sound item matching steps need at least one activity';
      }
      for (final activity in step.soundItemMatchingActivities) {
        if (activity.promptCtrl.text.trim().isEmpty) {
          return 'Every sound item matching activity needs a prompt';
        }
        if (activity.contentAudioCtrl.text.trim().isEmpty) {
          return 'Every sound item matching activity needs a content audio URL';
        }
        if (activity.targetSoundCtrl.text.trim().isEmpty) {
          return 'Every sound item matching activity needs a target sound';
        }
        if (activity.options.length < 2) {
          return 'Every sound item matching activity needs at least two options';
        }
        if (activity.options.any(
          (option) => option.labelCtrl.text.trim().isEmpty,
        )) {
          return 'Every sound item matching option needs a label';
        }
        if (activity.options.where((option) => option.isCorrect).length != 1) {
          return 'Every sound item matching activity needs exactly one correct option';
        }
      }
      return null;
    case LessonStepType.guidedReading:
      if (step.guidedReadingActivities.isEmpty) {
        return 'Guided reading steps need at least one activity';
      }
      for (final activity in step.guidedReadingActivities) {
        if (activity.instructionTextCtrl.text.trim().isEmpty) {
          return 'Every guided reading activity needs instruction text';
        }
        if (activity.wordTextCtrl.text.trim().isEmpty) {
          return 'Every guided reading activity needs a word';
        }
        if (activity.wordAudioCtrl.text.trim().isEmpty) {
          return 'Every guided reading activity needs a word audio URL';
        }
        if (activity.segments.isEmpty) {
          return 'Every guided reading activity needs at least one segment';
        }
        for (final segment in activity.segments) {
          if (segment.phonemeLabelCtrl.text.trim().isEmpty) {
            return 'Every guided reading segment needs a phoneme label';
          }
          if (segment.graphemeCtrl.text.trim().isEmpty) {
            return 'Every guided reading segment needs a grapheme';
          }
          if (segment.audioUrlCtrl.text.trim().isEmpty) {
            return 'Every guided reading segment needs an audio URL';
          }
        }
      }
      return null;
    case LessonStepType.practiceGame:
      if (step.practiceGameInstructionCtrl.text.trim().isEmpty) {
        return 'Practice game steps need instruction text';
      }
      if (int.tryParse(step.practiceGameDurationCtrl.text.trim()) == null) {
        return 'Practice game steps need a valid duration in seconds';
      }
      if (int.tryParse(step.practiceGamePassingScoreCtrl.text.trim()) == null) {
        return 'Practice game steps need a valid passing score';
      }
      if (step.practiceGameOptions.length < 2) {
        return 'Practice game steps need at least two options';
      }
      if (step.practiceGameOptions.any(
        (option) => option.titleCtrl.text.trim().isEmpty,
      )) {
        return 'Every practice game option needs a title';
      }
      if (step.practiceGameOptions.any(
        (option) => option.imageUrlCtrl.text.trim().isEmpty,
      )) {
        return 'Every practice game option needs an image URL';
      }
      if (step.practiceGameOptions.any(
        (option) => option.audioUrlCtrl.text.trim().isEmpty,
      )) {
        return 'Every practice game option needs an audio URL';
      }
      if (step.practiceGameOptions.every((option) => !option.isCorrect)) {
        return 'Practice game steps need at least one correct option';
      }
      return null;
    case LessonStepType.soundPresenceCheck:
      if (step.soundPresenceCheckQuestions.isEmpty) {
        return 'Sound presence check steps need at least one question';
      }
      for (final question in step.soundPresenceCheckQuestions) {
        if (question.promptCtrl.text.trim().isEmpty) {
          return 'Every sound presence check question needs a prompt';
        }
        if (question.wordAudioCtrl.text.trim().isEmpty) {
          return 'Every sound presence check question needs a word audio URL';
        }
        if (question.targetSoundCtrl.text.trim().isEmpty) {
          return 'Every sound presence check question needs a target sound';
        }
        if (question.yesLabelCtrl.text.trim().isEmpty) {
          return 'Every sound presence check question needs a yes label';
        }
        if (question.noLabelCtrl.text.trim().isEmpty) {
          return 'Every sound presence check question needs a no label';
        }
      }
      return null;
    case LessonStepType.missingLetters:
      if (step.missingLettersInstructionCtrl.text.trim().isEmpty) {
        return 'Missing letters steps need instruction text';
      }
      if (step.missingLettersActivities.isEmpty) {
        return 'Missing letters steps need at least one activity';
      }
      for (final activity in step.missingLettersActivities) {
        if (activity.promptTextCtrl.text.trim().isEmpty) {
          return 'Every missing letters activity needs prompt text';
        }
        if (activity.targetWordCtrl.text.trim().isEmpty) {
          return 'Every missing letters activity needs a target word';
        }
        if (activity.answerTemplate.isEmpty) {
          return 'Every missing letters activity needs at least one template item';
        }
        if (activity.answerTemplate.any(
          (item) => item.valueCtrl.text.trim().isEmpty,
        )) {
          return 'Every missing letters template item needs a value';
        }
        if (activity.answerTemplate.any(
          (item) => item.kind != 'given' && item.kind != 'missing',
        )) {
          return 'Missing letters template kinds must be given or missing';
        }
        if (activity.answerTemplate.every((item) => item.kind != 'missing')) {
          return 'Every missing letters activity needs at least one missing item';
        }
        final optionValues = activity.options
            .map((option) => option.text.trim())
            .where((option) => option.isNotEmpty)
            .toList();
        if (optionValues.length < 2) {
          return 'Every missing letters activity needs at least two options';
        }
        for (final item in activity.answerTemplate.where(
          (item) => item.kind == 'missing',
        )) {
          if (!optionValues.contains(item.valueCtrl.text.trim())) {
            return 'Every missing template value must appear in the options list';
          }
        }
      }
      return null;
    case LessonStepType.matchingWords:
      if (step.matchingWordsActivities.isEmpty) {
        return 'Matching words steps need at least one activity';
      }
      for (final activity in step.matchingWordsActivities) {
        if (activity.promptTextCtrl.text.trim().isEmpty) {
          return 'Every matching words activity needs prompt text';
        }
        if (activity.mode != 'sound_to_image' &&
            activity.mode != 'image_to_word' &&
            activity.mode != 'sound_to_word') {
          return 'Matching words modes must be sound_to_image, image_to_word, or sound_to_word';
        }
        if (activity.mode == 'image_to_word' &&
            activity.promptImageCtrl.text.trim().isEmpty) {
          return 'Image to word activities need a prompt image URL';
        }
        if ((activity.mode == 'sound_to_image' ||
                activity.mode == 'sound_to_word') &&
            activity.promptAudioCtrl.text.trim().isEmpty) {
          return 'Sound-based matching words activities need a prompt audio URL';
        }
        if (activity.correctOptionIdCtrl.text.trim().isEmpty) {
          return 'Every matching words activity needs a correct option ID';
        }
        if (activity.options.length < 2) {
          return 'Every matching words activity needs at least two options';
        }
        for (final option in activity.options) {
          if (option.idCtrl.text.trim().isEmpty) {
            return 'Every matching words option needs an ID';
          }
          if (option.labelCtrl.text.trim().isEmpty) {
            return 'Every matching words option needs a label';
          }
          if (activity.mode == 'sound_to_image' &&
              option.imageUrlCtrl.text.trim().isEmpty) {
            return 'Sound to image options need an image URL';
          }
        }
        if (!activity.options.any(
          (option) =>
              option.idCtrl.text.trim() ==
              activity.correctOptionIdCtrl.text.trim(),
        )) {
          return 'The correct option ID must match one of the activity options';
        }
      }
      return null;
    case LessonStepType.wordReading:
      if (step.wordReadingItems.isEmpty) {
        return 'Word reading steps need at least one item';
      }
      for (final item in step.wordReadingItems) {
        if (item.wordCtrl.text.trim().isEmpty) {
          return 'Every word reading item needs a word';
        }
        if (item.imageUrlCtrl.text.trim().isEmpty) {
          return 'Every word reading item needs an image URL';
        }
        if (item.wordAudioCtrl.text.trim().isEmpty) {
          return 'Every word reading item needs a word audio URL';
        }
        if (item.segments.isEmpty) {
          return 'Every word reading item needs at least one segment';
        }
        for (final segment in item.segments) {
          if (segment.labelCtrl.text.trim().isEmpty) {
            return 'Every word reading segment needs a label';
          }
          if (segment.audioUrlCtrl.text.trim().isEmpty) {
            return 'Every word reading segment needs an audio URL';
          }
        }
      }
      return null;
    case LessonStepType.sentenceReading:
      if (step.sentenceReadingItems.isEmpty) {
        return 'Sentence reading steps need at least one item';
      }
      for (final item in step.sentenceReadingItems) {
        if (item.sentenceTextCtrl.text.trim().isEmpty) {
          return 'Every sentence reading item needs sentence text';
        }
        final tokens = item.displayTokens
            .map((token) => token.text.trim())
            .where((token) => token.isNotEmpty)
            .toList();
        if (tokens.isEmpty) {
          return 'Every sentence reading item needs at least one display token';
        }
        if (item.sentenceAudioCtrl.text.trim().isEmpty) {
          return 'Every sentence reading item needs a sentence audio URL';
        }
      }
      return null;
    case LessonStepType.miniStoryCard:
      if (step.miniStoryCardItems.isEmpty) {
        return 'Mini story card steps need at least one item';
      }
      for (final item in step.miniStoryCardItems) {
        if (item.headingCtrl.text.trim().isEmpty) {
          return 'Every mini story card item needs a heading';
        }
        final bodyLines = item.bodyLines
            .map((line) => line.text.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        if (bodyLines.isEmpty) {
          return 'Every mini story card item needs at least one body line';
        }
        if (item.storyAudioCtrl.text.trim().isEmpty) {
          return 'Every mini story card item needs a story audio URL';
        }
      }
      return null;
  }
}

Widget _buildIntroductionFields(StepDraft step) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.displayTextCtrl,
        decoration: const InputDecoration(
          labelText: 'Display Text',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.audioBaseUrlCtrl,
        decoration: const InputDecoration(
          labelText: 'Audio Base URL',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: step.audio05Ctrl,
              decoration: const InputDecoration(
                labelText: 'Audio 0.5x URL',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: step.audio1Ctrl,
              decoration: const InputDecoration(
                labelText: 'Audio 1x URL',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: step.audio15Ctrl,
              decoration: const InputDecoration(
                labelText: 'Audio 1.5x URL',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.howToSvgUrlCtrl,
        decoration: const InputDecoration(
          labelText: 'How-to SVG URL',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.practiceTipTextCtrl,
        decoration: const InputDecoration(
          labelText: 'Practice Tip Text',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.practiceTipAudioCtrl,
        decoration: const InputDecoration(
          labelText: 'Practice Tip Audio URL',
          border: OutlineInputBorder(),
        ),
      ),
    ],
  );
}

Widget _buildDemonstrationFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      Text('Image URLs', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.imageUrlCtrls.length; i++)
        _buildUrlRow(
          controller: step.imageUrlCtrls[i],
          onRemove: () => setState(() => step.removeImageUrl(i)),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addImageUrl),
          icon: const Icon(Icons.add),
          label: const Text('Add image'),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.feedbackTitleCtrl,
        decoration: const InputDecoration(
          labelText: 'Feedback Title',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.feedbackBodyCtrl,
        decoration: const InputDecoration(
          labelText: 'Feedback Body',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
    ],
  );
}

Widget _buildPracticeFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      Text('Items', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.practiceItems.length; i++)
        _buildPracticeItemRow(
          item: step.practiceItems[i],
          onRemove: () => setState(() => step.removePracticeItem(i)),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addPracticeItem),
          icon: const Icon(Icons.add),
          label: const Text('Add item'),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.tipTextCtrl,
        decoration: const InputDecoration(
          labelText: 'Tip Text',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.tipSoundCtrl,
        decoration: const InputDecoration(
          labelText: 'Tip Sound URL',
          border: OutlineInputBorder(),
        ),
      ),
    ],
  );
}

Widget _buildAssessmentFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.promptCtrl,
        decoration: const InputDecoration(
          labelText: 'Prompt',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.soundInstructionCtrl,
        decoration: const InputDecoration(
          labelText: 'Sound Instruction URL',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      Text('Options', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.assessmentOptions.length; i++)
        _buildAssessmentOptionRow(
          option: step.assessmentOptions[i],
          onRemove: () => setState(() => step.removeAssessmentOption(i)),
          setState: setState,
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addAssessmentOption),
          icon: const Icon(Icons.add),
          label: const Text('Add option'),
        ),
      ),
    ],
  );
}

Widget _buildBlendingFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.instructionCtrl,
        decoration: const InputDecoration(
          labelText: 'Instruction',
          hintText: 'e.g. Tap each letter to hear its sound, then tap "Blend"',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.instructionAudioCtrl,
        decoration: const InputDecoration(
          labelText: 'Instruction Audio URL',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Text('Examples', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var exIdx = 0; exIdx < step.blendingExamples.length; exIdx++)
        _buildBlendingExampleCard(context, step, exIdx, setState),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addBlendingExample),
          icon: const Icon(Icons.add),
          label: const Text('Add example'),
        ),
      ),
    ],
  );
}

Widget _buildSoundDiscriminationFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Does it have /a/?',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.titleAudioCtrl,
        decoration: const InputDecoration(
          labelText: 'Title Audio URL',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: step.targetSoundCtrl,
              decoration: const InputDecoration(
                labelText: 'Target Sound',
                hintText: '/a/',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: step.referenceWordCtrl,
              decoration: const InputDecoration(
                labelText: 'Reference Word',
                hintText: 'apple',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.soundDiscriminationTipCtrl,
        decoration: const InputDecoration(
          labelText: 'Tip Text',
          hintText:
              "Listen to the word. Does it have the /a/ sound, like in 'apple'?",
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.soundDiscriminationInstructionCtrl,
        decoration: const InputDecoration(
          labelText: 'Instruction Text',
          hintText: 'Tap YES if the word has the sound, NO if it does not.',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 12),
      Text('Items', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.soundDiscriminationItems.length; i++)
        _buildSoundDiscriminationItemCard(
          context: context,
          item: step.soundDiscriminationItems[i],
          index: i,
          onRemove: () => setState(() => step.removeSoundDiscriminationItem(i)),
          setState: setState,
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addSoundDiscriminationItem),
          icon: const Icon(Icons.add),
          label: const Text('Add item'),
        ),
      ),
    ],
  );
}

Widget _buildSoundItemMatchingFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Sound-Letter Match',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Text('Activities', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.soundItemMatchingActivities.length; i++)
        _buildSoundItemMatchingActivityCard(
          context: context,
          activity: step.soundItemMatchingActivities[i],
          index: i,
          onRemove: () =>
              setState(() => step.removeSoundItemMatchingActivity(i)),
          setState: setState,
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addSoundItemMatchingActivity),
          icon: const Icon(Icons.add),
          label: const Text('Add activity'),
        ),
      ),
    ],
  );
}

Widget _buildGuidedReadingFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Guided Word Reading',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Text('Activities', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.guidedReadingActivities.length; i++)
        _buildGuidedReadingActivityCard(
          context: context,
          activity: step.guidedReadingActivities[i],
          index: i,
          onRemove: () => setState(() => step.removeGuidedReadingActivity(i)),
          setState: setState,
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addGuidedReadingActivity),
          icon: const Icon(Icons.add),
          label: const Text('Add activity'),
        ),
      ),
    ],
  );
}

Widget _buildPracticeGameFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Quick Pick: /a/ Words',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.practiceGameInstructionCtrl,
        decoration: const InputDecoration(
          labelText: 'Instruction Text',
          hintText: 'Tap the word with /a/ sound. Skip the others',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.practiceGameInstructionAudioCtrl,
        decoration: const InputDecoration(
          labelText: 'Instruction Audio URL',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: step.practiceGameTargetSoundCtrl,
              decoration: const InputDecoration(
                labelText: 'Target Sound',
                hintText: '/a/',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: step.practiceGameDurationCtrl,
              decoration: const InputDecoration(
                labelText: 'Duration (seconds)',
                hintText: '60',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: step.practiceGamePassingScoreCtrl,
              decoration: const InputDecoration(
                labelText: 'Passing Score',
                hintText: '6',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Options', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.practiceGameOptions.length; i++)
        _buildPracticeGameOptionCard(
          context: context,
          option: step.practiceGameOptions[i],
          index: i,
          onRemove: () => setState(() => step.removePracticeGameOption(i)),
          setState: setState,
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addPracticeGameOption),
          icon: const Icon(Icons.add),
          label: const Text('Add option'),
        ),
      ),
    ],
  );
}

Widget _buildSoundPresenceCheckFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Sound Presence Check',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Text('Questions', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.soundPresenceCheckQuestions.length; i++)
        _buildSoundPresenceCheckQuestionCard(
          context: context,
          question: step.soundPresenceCheckQuestions[i],
          index: i,
          onRemove: () =>
              setState(() => step.removeSoundPresenceCheckQuestion(i)),
          setState: setState,
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addSoundPresenceCheckQuestion),
          icon: const Icon(Icons.add),
          label: const Text('Add question'),
        ),
      ),
    ],
  );
}

Widget _buildMissingLettersFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Build the Word',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.missingLettersInstructionCtrl,
        decoration: const InputDecoration(
          labelText: 'Instruction Text',
          hintText: 'Select missing letters',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.missingLettersInstructionAudioCtrl,
        decoration: const InputDecoration(
          labelText: 'Instruction Audio URL',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Text('Activities', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.missingLettersActivities.length; i++)
        _buildMissingLettersActivityCard(
          context: context,
          activity: step.missingLettersActivities[i],
          index: i,
          onRemove: () => setState(() => step.removeMissingLettersActivity(i)),
          setState: setState,
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addMissingLettersActivity),
          icon: const Icon(Icons.add),
          label: const Text('Add activity'),
        ),
      ),
    ],
  );
}

Widget _buildMatchingWordsFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Check Your Learning',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.matchingWordsInstructionAudioCtrl,
        decoration: const InputDecoration(
          labelText: 'Instruction Audio URL',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Text('Activities', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.matchingWordsActivities.length; i++)
        _buildMatchingWordsActivityCard(
          context: context,
          activity: step.matchingWordsActivities[i],
          index: i,
          onRemove: () => setState(() => step.removeMatchingWordsActivity(i)),
          setState: setState,
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addMatchingWordsActivity),
          icon: const Icon(Icons.add),
          label: const Text('Add activity'),
        ),
      ),
    ],
  );
}

Widget _buildWordReadingFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Read the Word',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.wordReadingInstructionAudioCtrl,
        decoration: const InputDecoration(
          labelText: 'Instruction Audio URL',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Text('Items', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.wordReadingItems.length; i++)
        _buildWordReadingItemCard(
          context: context,
          item: step.wordReadingItems[i],
          index: i,
          onRemove: () => setState(() => step.removeWordReadingItem(i)),
          setState: setState,
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addWordReadingItem),
          icon: const Icon(Icons.add),
          label: const Text('Add item'),
        ),
      ),
    ],
  );
}

Widget _buildSentenceReadingFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Read the Sentence',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.sentenceReadingInstructionAudioCtrl,
        decoration: const InputDecoration(
          labelText: 'Instruction Audio URL',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Text('Items', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.sentenceReadingItems.length; i++)
        _buildSentenceReadingItemCard(
          context: context,
          item: step.sentenceReadingItems[i],
          index: i,
          onRemove: () => setState(() => step.removeSentenceReadingItem(i)),
          setState: setState,
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addSentenceReadingItem),
          icon: const Icon(Icons.add),
          label: const Text('Add item'),
        ),
      ),
    ],
  );
}

Widget _buildMiniStoryCardFields(
  BuildContext context,
  StepDraft step,
  StepFormSetState setState,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: step.titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Title',
          hintText: 'Mini-Story Card',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.miniStoryCardInstructionAudioCtrl,
        decoration: const InputDecoration(
          labelText: 'Instruction Audio URL',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Text('Items', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 6),
      for (var i = 0; i < step.miniStoryCardItems.length; i++)
        _buildMiniStoryCardItemCard(
          context: context,
          item: step.miniStoryCardItems[i],
          index: i,
          onRemove: () => setState(() => step.removeMiniStoryCardItem(i)),
          setState: setState,
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(step.addMiniStoryCardItem),
          icon: const Icon(Icons.add),
          label: const Text('Add item'),
        ),
      ),
    ],
  );
}

Widget _buildBlendingExampleCard(
  BuildContext context,
  StepDraft step,
  int exIdx,
  StepFormSetState setState,
) {
  final ex = step.blendingExamples[exIdx];
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Example ${exIdx + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    setState(() => step.removeBlendingExample(exIdx)),
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: ex.wordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Word',
                    hintText: 'e.g. man',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: ex.audioUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Word Audio URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Phonemes', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          for (var phIdx = 0; phIdx < ex.phonemes.length; phIdx++)
            _buildPhonemeRow(context, ex, phIdx, setState),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(ex.addPhoneme),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add phoneme'),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSoundDiscriminationItemCard({
  required BuildContext context,
  required SoundDiscriminationItemDraft item,
  required int index,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Word Title',
                    hintText: 'cat',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: item.titleAudioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Word Audio URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.imageUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: item.containsTargetSound,
                    onChanged: (value) => setState(
                      () => item.containsTargetSound = value ?? false,
                    ),
                  ),
                  const Text('Contains target sound'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.highlightedTextCtrl,
            decoration: const InputDecoration(
              labelText: 'Highlighted Text',
              hintText: 'a',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSoundItemMatchingActivityCard({
  required BuildContext context,
  required SoundItemMatchingActivityDraft activity,
  required int index,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Activity ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: activity.promptCtrl,
            decoration: const InputDecoration(
              labelText: 'Prompt',
              hintText: 'Tap the word that has the /a/ sound',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: activity.promptAudioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prompt Audio URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: activity.contentAudioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Content Audio URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: activity.tipCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tip Text',
                    hintText: 'Find the /a/ sound',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: activity.targetSoundCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Target Sound',
                    hintText: '/a/',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Options', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          for (var i = 0; i < activity.options.length; i++)
            _buildSoundItemMatchingOptionRow(
              option: activity.options[i],
              onRemove: () => setState(() => activity.removeOption(i)),
              setState: setState,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(activity.addOption),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add option'),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSoundItemMatchingOptionRow({
  required SoundItemMatchingOptionDraft option,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: option.labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Option Label',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            Checkbox(
              value: option.isCorrect,
              onChanged: (value) =>
                  setState(() => option.isCorrect = value ?? false),
            ),
            const Text('Correct'),
          ],
        ),
        IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
      ],
    ),
  );
}

Widget _buildGuidedReadingActivityCard({
  required BuildContext context,
  required GuidedReadingActivityDraft activity,
  required int index,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Activity ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: activity.instructionTextCtrl,
            decoration: const InputDecoration(
              labelText: 'Instruction Text',
              hintText: 'Listen to the sounds. Then hear the whole word',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: activity.instructionAudioCtrl,
            decoration: const InputDecoration(
              labelText: 'Instruction Audio URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: activity.wordTextCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Word Text',
                    hintText: 'man',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: activity.wordAudioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Word Audio URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Segments', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          for (var i = 0; i < activity.segments.length; i++)
            _buildGuidedReadingSegmentRow(
              context: context,
              segment: activity.segments[i],
              onRemove: () => setState(() => activity.removeSegment(i)),
              setState: setState,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(activity.addSegment),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add segment'),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildGuidedReadingSegmentRow({
  required BuildContext context,
  required GuidedReadingSegmentDraft segment,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: segment.phonemeLabelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phoneme Label',
                  hintText: '/m/',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: segment.graphemeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Grapheme',
                  hintText: 'm',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: segment.audioUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Segment Audio URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Checkbox(
                  value: segment.isFocus,
                  onChanged: (value) =>
                      setState(() => segment.isFocus = value ?? false),
                ),
                const Text('Focus'),
              ],
            ),
            IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
          ],
        ),
      ],
    ),
  );
}

Widget _buildPracticeGameOptionCard({
  required BuildContext context,
  required PracticeGameOptionDraft option,
  required int index,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Option ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: option.titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Option Title',
              hintText: 'apple',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: option.imageUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: option.audioUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'Audio URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: option.isCorrect,
                onChanged: (value) =>
                    setState(() => option.isCorrect = value ?? false),
              ),
              const Text('Correct target word'),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildSoundPresenceCheckQuestionCard({
  required BuildContext context,
  required SoundPresenceCheckQuestionDraft question,
  required int index,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: question.promptCtrl,
            decoration: const InputDecoration(
              labelText: 'Prompt',
              hintText: 'Does "man" have the /a/ sound?',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: question.promptAudioCtrl,
            decoration: const InputDecoration(
              labelText: 'Prompt Audio URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: question.wordTextCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Word Text',
                    hintText: 'man',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: question.wordAudioCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Word Audio URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: question.targetSoundCtrl,
            decoration: const InputDecoration(
              labelText: 'Target Sound',
              hintText: '/a/',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: question.yesLabelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Yes Button Label',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: question.noLabelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'No Button Label',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<bool>(
            initialValue: question.correctAnswer,
            decoration: const InputDecoration(
              labelText: 'Correct Answer',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: true, child: Text('Yes')),
              DropdownMenuItem(value: false, child: Text('No')),
            ],
            onChanged: (value) =>
                setState(() => question.correctAnswer = value ?? true),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMissingLettersActivityCard({
  required BuildContext context,
  required MissingLettersActivityDraft activity,
  required int index,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Activity ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: activity.promptTextCtrl,
            decoration: const InputDecoration(
              labelText: 'Prompt Text',
              hintText: 'Make "cat"',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: activity.targetWordCtrl,
            decoration: const InputDecoration(
              labelText: 'Target Word',
              hintText: 'cat',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text('Answer Template', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          for (var i = 0; i < activity.answerTemplate.length; i++)
            _buildMissingLettersTemplateRow(
              item: activity.answerTemplate[i],
              onRemove: () => setState(() => activity.removeTemplateItem(i)),
              setState: setState,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(activity.addTemplateItem),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add template item'),
            ),
          ),
          const SizedBox(height: 12),
          Text('Options', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          for (var i = 0; i < activity.options.length; i++)
            _buildMissingLettersOptionRow(
              controller: activity.options[i],
              onRemove: () => setState(() => activity.removeOption(i)),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(activity.addOption),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add option'),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMissingLettersTemplateRow({
  required MissingLettersTemplateItemDraft item,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: item.valueCtrl,
            decoration: const InputDecoration(
              labelText: 'Value',
              hintText: 'c or /a/',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: item.kind,
            decoration: const InputDecoration(
              labelText: 'Kind',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'missing', child: Text('Missing')),
              DropdownMenuItem(value: 'given', child: Text('Given')),
            ],
            onChanged: (value) =>
                setState(() => item.kind = value ?? 'missing'),
          ),
        ),
        IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
      ],
    ),
  );
}

Widget _buildMissingLettersOptionRow({
  required TextEditingController controller,
  required VoidCallback onRemove,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Option',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
      ],
    ),
  );
}

Widget _buildMatchingWordsActivityCard({
  required BuildContext context,
  required MatchingWordsActivityDraft activity,
  required int index,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  final isSoundMode =
      activity.mode == 'sound_to_image' || activity.mode == 'sound_to_word';
  final needsImageOptions = activity.mode == 'sound_to_image';
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Activity ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: activity.mode,
            decoration: const InputDecoration(
              labelText: 'Mode',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'sound_to_image',
                child: Text('Sound to image'),
              ),
              DropdownMenuItem(
                value: 'image_to_word',
                child: Text('Image to word'),
              ),
              DropdownMenuItem(
                value: 'sound_to_word',
                child: Text('Sound to word'),
              ),
            ],
            onChanged: (value) =>
                setState(() => activity.mode = value ?? 'sound_to_image'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: activity.promptTextCtrl,
            decoration: const InputDecoration(
              labelText: 'Prompt Text',
              hintText: 'Select "cat"',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          if (isSoundMode) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: activity.promptAudioCtrl,
              decoration: const InputDecoration(
                labelText: 'Prompt Audio URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (activity.mode == 'image_to_word') ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: activity.promptImageCtrl,
              decoration: const InputDecoration(
                labelText: 'Prompt Image URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextFormField(
            controller: activity.correctOptionIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Correct Option ID',
              hintText: 'cat',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text('Options', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          for (var i = 0; i < activity.options.length; i++)
            _buildMatchingWordsOptionCard(
              context: context,
              option: activity.options[i],
              showImageField: needsImageOptions,
              onRemove: () => setState(() => activity.removeOption(i)),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(activity.addOption),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add option'),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMatchingWordsOptionCard({
  required BuildContext context,
  required MatchingWordsOptionDraft option,
  required bool showImageField,
  required VoidCallback onRemove,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: option.idCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Option ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: option.labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Option Label',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
            ],
          ),
          if (showImageField) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: option.imageUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildWordReadingItemCard({
  required BuildContext context,
  required WordReadingItemDraft item,
  required int index,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.wordCtrl,
            decoration: const InputDecoration(
              labelText: 'Word',
              hintText: 'cat',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.imageUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.wordAudioCtrl,
            decoration: const InputDecoration(
              labelText: 'Word Audio URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.modelReadingLabelCtrl,
            decoration: const InputDecoration(
              labelText: 'Model Reading Label',
              hintText: 'Tap here word for model reading',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text('Segments', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          for (var i = 0; i < item.segments.length; i++)
            _buildWordReadingSegmentRow(
              segment: item.segments[i],
              onRemove: () => setState(() => item.removeSegment(i)),
              setState: setState,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(item.addSegment),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add segment'),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildWordReadingSegmentRow({
  required WordReadingSegmentDraft segment,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: segment.labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Segment Label',
                  hintText: '/c/',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: segment.audioUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Segment Audio URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: segment.highlighted,
              onChanged: (value) =>
                  setState(() => segment.highlighted = value ?? false),
            ),
            const Text('Highlighted'),
          ],
        ),
      ],
    ),
  );
}

Widget _buildSentenceReadingItemCard({
  required BuildContext context,
  required SentenceReadingItemDraft item,
  required int index,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.sentenceTextCtrl,
            decoration: const InputDecoration(
              labelText: 'Sentence Text',
              hintText: 'The cat is on the mat',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.sentenceAudioCtrl,
            decoration: const InputDecoration(
              labelText: 'Sentence Audio URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.selfReadLabelCtrl,
            decoration: const InputDecoration(
              labelText: 'Self Read Label',
              hintText: 'Read by myself',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text('Display Tokens', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          for (var i = 0; i < item.displayTokens.length; i++)
            _buildSentenceReadingTokenRow(
              controller: item.displayTokens[i],
              onRemove: () => setState(() => item.removeDisplayToken(i)),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(item.addDisplayToken),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add token'),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSentenceReadingTokenRow({
  required TextEditingController controller,
  required VoidCallback onRemove,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Token',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
      ],
    ),
  );
}

Widget _buildMiniStoryCardItemCard({
  required BuildContext context,
  required MiniStoryCardItemDraft item,
  required int index,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.headingCtrl,
            decoration: const InputDecoration(
              labelText: 'Heading',
              hintText: 'The Man and the Cat',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.headingAudioCtrl,
            decoration: const InputDecoration(
              labelText: 'Heading Audio URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.storyAudioCtrl,
            decoration: const InputDecoration(
              labelText: 'Story Audio URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: item.ctaLabelCtrl,
            decoration: const InputDecoration(
              labelText: 'CTA Label',
              hintText: 'Listen to the sentence',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text('Body Lines', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          for (var i = 0; i < item.bodyLines.length; i++)
            _buildMiniStoryCardBodyLineRow(
              controller: item.bodyLines[i],
              onRemove: () => setState(() => item.removeBodyLine(i)),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(item.addBodyLine),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add body line'),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMiniStoryCardBodyLineRow({
  required TextEditingController controller,
  required VoidCallback onRemove,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Body Line',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
      ],
    ),
  );
}

Widget _buildPhonemeRow(
  BuildContext context,
  BlendingExampleDraft ex,
  int phIdx,
  StepFormSetState setState,
) {
  final ph = ex.phonemes[phIdx];
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: ph.labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Phoneme',
              hintText: '/m/',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: ph.audioUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'Audio URL',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Column(
          children: [
            Checkbox(
              value: ph.highlighted,
              onChanged: (v) => setState(() => ph.highlighted = v ?? false),
            ),
            Text(
              'Highlight',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
        IconButton(
          onPressed: () => setState(() => ex.removePhoneme(phIdx)),
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    ),
  );
}

Widget _buildUrlRow({
  required TextEditingController controller,
  required VoidCallback onRemove,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
      ],
    ),
  );
}

Widget _buildPracticeItemRow({
  required PracticeItemDraft item,
  required VoidCallback onRemove,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: item.labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: item.imageUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: item.soundUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sound URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: item.highlightedLettersCtrl,
                decoration: const InputDecoration(
                  labelText: 'Highlighted Letters',
                  hintText: 'e.g. a',
                  helperText: 'Defaults to first letter if left empty',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
          ],
        ),
      ],
    ),
  );
}

Widget _buildAssessmentOptionRow({
  required AssessmentOptionDraft option,
  required VoidCallback onRemove,
  required StepFormSetState setState,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: option.labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: option.imageUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Row(
              children: [
                Checkbox(
                  value: option.isCorrect,
                  onChanged: (value) =>
                      setState(() => option.isCorrect = value ?? false),
                ),
                const Text('Correct'),
              ],
            ),
            const Spacer(),
            IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
          ],
        ),
      ],
    ),
  );
}

// ── Generic JSON config editor (custom step types) ────────────────────────────

Widget _buildGenericJsonFields(StepDraft step) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Step Config (JSON)',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Enter the configuration for this custom step as a JSON object.',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: step.customConfigCtrl,
        decoration: const InputDecoration(
          hintText: '{}',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        maxLines: 6,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    ],
  );
}
