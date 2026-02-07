import 'package:flutter/material.dart';

import '../../../lesson_v2/lesson_v2_models.dart';

class StepDraft {
  StepDraft({
    required int position,
    required String stepKey,
  })  : position = position,
        stepType = LessonStepType.introduction,
        stepKeyCtrl = TextEditingController(text: stepKey),
        titleCtrl = TextEditingController(),
        displayTextCtrl = TextEditingController(),
        audioBaseUrlCtrl = TextEditingController(),
        audio05Ctrl = TextEditingController(),
        audio1Ctrl = TextEditingController(),
        audio15Ctrl = TextEditingController(),
        howToSvgUrlCtrl = TextEditingController(),
        practiceTipTextCtrl = TextEditingController(),
        practiceTipAudioCtrl = TextEditingController(),
        feedbackTitleCtrl = TextEditingController(),
        feedbackBodyCtrl = TextEditingController(),
        tipTextCtrl = TextEditingController(),
        tipSoundCtrl = TextEditingController(),
        promptCtrl = TextEditingController(),
        soundInstructionCtrl = TextEditingController();

  factory StepDraft.fromStep(LessonStep step) {
    final draft = StepDraft(
      position: step.position,
      stepKey: step.stepKey,
    );
    draft.stepType = step.stepType;
    draft.required = step.required;
    final config = step.config ?? const <String, dynamic>{};
    final title = config['title'];
    if (title is String) {
      draft.titleCtrl.text = title;
    }
    switch (step.stepType) {
      case LessonStepType.introduction:
        final displayText = config['display_text'];
        if (displayText is String) {
          draft.displayTextCtrl.text = displayText;
        }
        final audio = config['audio'];
        if (audio is Map) {
          final baseUrl = audio['base_url'];
          if (baseUrl is String) {
            draft.audioBaseUrlCtrl.text = baseUrl;
          }
          final speed = audio['speed_variants'];
          if (speed is Map) {
            final v05 = speed['0.5x'];
            final v1 = speed['1x'];
            final v15 = speed['1.5x'];
            if (v05 is String) draft.audio05Ctrl.text = v05;
            if (v1 is String) draft.audio1Ctrl.text = v1;
            if (v15 is String) draft.audio15Ctrl.text = v15;
          }
        }
        final howTo = config['how_to_svg_url'];
        if (howTo is String) {
          draft.howToSvgUrlCtrl.text = howTo;
        }
        final practiceTip = config['practice_tip'];
        if (practiceTip is Map) {
          final tipText = practiceTip['text'];
          final tipAudio = practiceTip['audio_url'];
          if (tipText is String) draft.practiceTipTextCtrl.text = tipText;
          if (tipAudio is String) draft.practiceTipAudioCtrl.text = tipAudio;
        }
        break;
      case LessonStepType.demonstration:
        final images = config['image_urls'];
        if (images is List) {
          for (final url in images) {
            if (url is String) {
              draft.imageUrlCtrls.add(TextEditingController(text: url));
            }
          }
        }
        final feedbackTitle = config['feedbackTitle'];
        if (feedbackTitle is String) {
          draft.feedbackTitleCtrl.text = feedbackTitle;
        }
        final feedbackBody = config['feedbackBody'];
        if (feedbackBody is String) {
          draft.feedbackBodyCtrl.text = feedbackBody;
        }
        break;
      case LessonStepType.practice:
        final items = config['items'];
        if (items is List) {
          for (final item in items) {
            if (item is Map) {
              final draftItem = PracticeItemDraft();
              final label = item['label'];
              final imageUrl = item['image_url'];
              final soundUrl = item['sound_url'];
              if (label is String) draftItem.labelCtrl.text = label;
              if (imageUrl is String) draftItem.imageUrlCtrl.text = imageUrl;
              if (soundUrl is String) draftItem.soundUrlCtrl.text = soundUrl;
              draft.practiceItems.add(draftItem);
            }
          }
        }
        final tip = config['tip'];
        if (tip is Map) {
          final tipText = tip['text'];
          final tipSound = tip['sound_url'];
          if (tipText is String) draft.tipTextCtrl.text = tipText;
          if (tipSound is String) draft.tipSoundCtrl.text = tipSound;
        }
        break;
      case LessonStepType.assessment:
        final prompt = config['prompt'];
        if (prompt is String) {
          draft.promptCtrl.text = prompt;
        }
        final soundInstruction = config['sound_instruction_url'];
        if (soundInstruction is String) {
          draft.soundInstructionCtrl.text = soundInstruction;
        }
        final options = config['options'];
        if (options is List) {
          for (final option in options) {
            if (option is Map) {
              final draftOption = AssessmentOptionDraft();
              final label = option['label'];
              final imageUrl = option['image_url'];
              final isCorrect = option['is_correct'];
              if (label is String) draftOption.labelCtrl.text = label;
              if (imageUrl is String) draftOption.imageUrlCtrl.text = imageUrl;
              if (isCorrect is bool) draftOption.isCorrect = isCorrect;
              draft.assessmentOptions.add(draftOption);
            }
          }
        }
        break;
    }
    return draft;
  }

  int position;
  LessonStepType stepType;
  bool required = true;

  final TextEditingController stepKeyCtrl;
  final TextEditingController titleCtrl;

  final TextEditingController displayTextCtrl;
  final TextEditingController audioBaseUrlCtrl;
  final TextEditingController audio05Ctrl;
  final TextEditingController audio1Ctrl;
  final TextEditingController audio15Ctrl;
  final TextEditingController howToSvgUrlCtrl;
  final TextEditingController practiceTipTextCtrl;
  final TextEditingController practiceTipAudioCtrl;

  final TextEditingController feedbackTitleCtrl;
  final TextEditingController feedbackBodyCtrl;
  final List<TextEditingController> imageUrlCtrls = [];

  final List<PracticeItemDraft> practiceItems = [];
  final TextEditingController tipTextCtrl;
  final TextEditingController tipSoundCtrl;

  final TextEditingController promptCtrl;
  final TextEditingController soundInstructionCtrl;
  final List<AssessmentOptionDraft> assessmentOptions = [];

  void setStepType(LessonStepType type) {
    stepType = type;
    if (type == LessonStepType.demonstration && imageUrlCtrls.isEmpty) {
      addImageUrl();
    }
    if (type == LessonStepType.practice && practiceItems.isEmpty) {
      addPracticeItem();
    }
    if (type == LessonStepType.assessment && assessmentOptions.isEmpty) {
      addAssessmentOption();
    }
  }

  void addImageUrl() => imageUrlCtrls.add(TextEditingController());
  void removeImageUrl(int index) {
    imageUrlCtrls[index].dispose();
    imageUrlCtrls.removeAt(index);
  }

  void addPracticeItem() => practiceItems.add(PracticeItemDraft());
  void removePracticeItem(int index) {
    practiceItems[index].dispose();
    practiceItems.removeAt(index);
  }

  void addAssessmentOption() => assessmentOptions.add(AssessmentOptionDraft());
  void removeAssessmentOption(int index) {
    assessmentOptions[index].dispose();
    assessmentOptions.removeAt(index);
  }

  LessonStepInput toInput() {
    return LessonStepInput(
      stepKey: stepKeyCtrl.text.trim(),
      stepType: stepType,
      position: position,
      required: required,
      config: _buildConfig(),
    );
  }

  Map<String, dynamic> _buildConfig() {
    switch (stepType) {
      case LessonStepType.introduction:
        final speedVariants = <String, String>{};
        if (audio05Ctrl.text.trim().isNotEmpty) {
          speedVariants['0.5x'] = audio05Ctrl.text.trim();
        }
        if (audio1Ctrl.text.trim().isNotEmpty) {
          speedVariants['1x'] = audio1Ctrl.text.trim();
        }
        if (audio15Ctrl.text.trim().isNotEmpty) {
          speedVariants['1.5x'] = audio15Ctrl.text.trim();
        }
        final audio = <String, dynamic>{};
        if (audioBaseUrlCtrl.text.trim().isNotEmpty) {
          audio['base_url'] = audioBaseUrlCtrl.text.trim();
        }
        if (speedVariants.isNotEmpty) {
          audio['speed_variants'] = speedVariants;
        }
        final practiceTip = <String, dynamic>{};
        if (practiceTipTextCtrl.text.trim().isNotEmpty) {
          practiceTip['text'] = practiceTipTextCtrl.text.trim();
        }
        if (practiceTipAudioCtrl.text.trim().isNotEmpty) {
          practiceTip['audio_url'] = practiceTipAudioCtrl.text.trim();
        }
        return {
          'title': titleCtrl.text.trim(),
          'display_text': displayTextCtrl.text.trim(),
          if (audio.isNotEmpty) 'audio': audio,
          if (howToSvgUrlCtrl.text.trim().isNotEmpty)
            'how_to_svg_url': howToSvgUrlCtrl.text.trim(),
          if (practiceTip.isNotEmpty) 'practice_tip': practiceTip,
        };
      case LessonStepType.demonstration:
        final images = imageUrlCtrls
            .map((c) => c.text.trim())
            .where((v) => v.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          if (images.isNotEmpty) 'image_urls': images,
          if (feedbackTitleCtrl.text.trim().isNotEmpty)
            'feedbackTitle': feedbackTitleCtrl.text.trim(),
          if (feedbackBodyCtrl.text.trim().isNotEmpty)
            'feedbackBody': feedbackBodyCtrl.text.trim(),
        };
      case LessonStepType.practice:
        final items = practiceItems
            .map((item) => item.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        final tip = <String, dynamic>{};
        if (tipTextCtrl.text.trim().isNotEmpty) {
          tip['text'] = tipTextCtrl.text.trim();
        }
        if (tipSoundCtrl.text.trim().isNotEmpty) {
          tip['sound_url'] = tipSoundCtrl.text.trim();
        }
        return {
          'title': titleCtrl.text.trim(),
          if (items.isNotEmpty) 'items': items,
          if (tip.isNotEmpty) 'tip': tip,
        };
      case LessonStepType.assessment:
        final options = assessmentOptions
            .map((option) => option.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          'prompt': promptCtrl.text.trim(),
          if (soundInstructionCtrl.text.trim().isNotEmpty)
            'sound_instruction_url': soundInstructionCtrl.text.trim(),
          if (options.isNotEmpty) 'options': options,
        };
    }
  }

  void dispose() {
    stepKeyCtrl.dispose();
    titleCtrl.dispose();
    displayTextCtrl.dispose();
    audioBaseUrlCtrl.dispose();
    audio05Ctrl.dispose();
    audio1Ctrl.dispose();
    audio15Ctrl.dispose();
    howToSvgUrlCtrl.dispose();
    practiceTipTextCtrl.dispose();
    practiceTipAudioCtrl.dispose();
    feedbackTitleCtrl.dispose();
    feedbackBodyCtrl.dispose();
    for (final ctrl in imageUrlCtrls) {
      ctrl.dispose();
    }
    for (final item in practiceItems) {
      item.dispose();
    }
    tipTextCtrl.dispose();
    tipSoundCtrl.dispose();
    promptCtrl.dispose();
    soundInstructionCtrl.dispose();
    for (final option in assessmentOptions) {
      option.dispose();
    }
  }
}

class PracticeItemDraft {
  final TextEditingController labelCtrl = TextEditingController();
  final TextEditingController imageUrlCtrl = TextEditingController();
  final TextEditingController soundUrlCtrl = TextEditingController();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (labelCtrl.text.trim().isNotEmpty) {
      map['label'] = labelCtrl.text.trim();
    }
    if (imageUrlCtrl.text.trim().isNotEmpty) {
      map['image_url'] = imageUrlCtrl.text.trim();
    }
    if (soundUrlCtrl.text.trim().isNotEmpty) {
      map['sound_url'] = soundUrlCtrl.text.trim();
    }
    return map;
  }

  void dispose() {
    labelCtrl.dispose();
    imageUrlCtrl.dispose();
    soundUrlCtrl.dispose();
  }
}

class AssessmentOptionDraft {
  final TextEditingController labelCtrl = TextEditingController();
  final TextEditingController imageUrlCtrl = TextEditingController();
  bool isCorrect = false;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (labelCtrl.text.trim().isNotEmpty) {
      map['label'] = labelCtrl.text.trim();
    }
    if (imageUrlCtrl.text.trim().isNotEmpty) {
      map['image_url'] = imageUrlCtrl.text.trim();
    }
    map['is_correct'] = isCorrect;
    return map;
  }

  void dispose() {
    labelCtrl.dispose();
    imageUrlCtrl.dispose();
  }
}

class EditedStep {
  const EditedStep({required this.input});

  final LessonStepInput input;

  LessonStepInput copyWithPosition(int position) {
    return LessonStepInput(
      stepKey: input.stepKey,
      stepType: input.stepType,
      position: position,
      required: input.required,
      config: input.config,
    );
  }
}

LessonStepInput stepToInput(LessonStep step, {required int position}) {
  return LessonStepInput(
    stepKey: step.stepKey,
    stepType: step.stepType,
    position: position,
    required: step.required,
    config: step.config,
  );
}
