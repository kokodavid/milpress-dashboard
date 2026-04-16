import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../lesson_v2/lesson_v2_models.dart';
import '../../../lesson_v2/step_type_definition.dart';

class StepDraft {
  StepDraft({required this.position, required String stepKey})
    : stepType = LessonStepType.introduction,
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
      soundInstructionCtrl = TextEditingController(),
      instructionCtrl = TextEditingController(),
      instructionAudioCtrl = TextEditingController(),
      titleAudioCtrl = TextEditingController(),
      targetSoundCtrl = TextEditingController(),
      referenceWordCtrl = TextEditingController(),
      soundDiscriminationTipCtrl = TextEditingController(),
      practiceGameInstructionCtrl = TextEditingController(),
      practiceGameInstructionAudioCtrl = TextEditingController(),
      practiceGameTargetSoundCtrl = TextEditingController(),
      practiceGameDurationCtrl = TextEditingController(),
      practiceGamePassingScoreCtrl = TextEditingController(),
      missingLettersInstructionCtrl = TextEditingController(),
      missingLettersInstructionAudioCtrl = TextEditingController(),
      matchingWordsInstructionAudioCtrl = TextEditingController(),
      wordReadingInstructionAudioCtrl = TextEditingController(),
      sentenceReadingInstructionAudioCtrl = TextEditingController(),
      miniStoryCardInstructionAudioCtrl = TextEditingController();

  factory StepDraft.fromStep(LessonStep step) {
    final draft = StepDraft(position: step.position, stepKey: step.stepKey);
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
              final highlightedLetters = item['highlighted_letters'];
              if (label is String) draftItem.labelCtrl.text = label;
              if (imageUrl is String) draftItem.imageUrlCtrl.text = imageUrl;
              if (soundUrl is String) draftItem.soundUrlCtrl.text = soundUrl;
              // Default to first letter of label when the field is absent
              // (backwards-compatibility for existing data).
              if (highlightedLetters is String) {
                draftItem.highlightedLettersCtrl.text = highlightedLetters;
              } else if (label is String && label.isNotEmpty) {
                draftItem.highlightedLettersCtrl.text = label[0];
              }
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
      case LessonStepType.blending:
        final instruction = config['instruction'];
        if (instruction is String) draft.instructionCtrl.text = instruction;
        final instrAudio = config['instruction_audio_url'];
        if (instrAudio is String) draft.instructionAudioCtrl.text = instrAudio;
        final examples = config['examples'];
        if (examples is List) {
          for (final ex in examples) {
            if (ex is Map) {
              final exDraft = BlendingExampleDraft();
              final word = ex['word'];
              final wordAudioUrl = ex['word_audio_url'] ?? ex['audio_url'];
              if (word is String) exDraft.wordCtrl.text = word;
              if (wordAudioUrl is String) {
                exDraft.audioUrlCtrl.text = wordAudioUrl;
              }
              final phonemes = ex['phonemes'];
              if (phonemes is List) {
                for (final ph in phonemes) {
                  if (ph is Map) {
                    final phDraft = PhonemeDraft();
                    final label = ph['label'];
                    final phAudio = ph['audio_url'];
                    final highlighted = ph['highlighted'];
                    if (label is String) phDraft.labelCtrl.text = label;
                    if (phAudio is String) phDraft.audioUrlCtrl.text = phAudio;
                    if (highlighted is bool) phDraft.highlighted = highlighted;
                    exDraft.phonemes.add(phDraft);
                  }
                }
              }
              draft.blendingExamples.add(exDraft);
            }
          }
        }
        break;
      case LessonStepType.soundDiscrimination:
        final titleAudio = config['title_audio_url'];
        if (titleAudio is String) draft.titleAudioCtrl.text = titleAudio;
        final targetSound = config['target_sound'];
        if (targetSound is String) draft.targetSoundCtrl.text = targetSound;
        final referenceWord = config['reference_word'];
        if (referenceWord is String) {
          draft.referenceWordCtrl.text = referenceWord;
        }
        final tipText = config['tip_text'];
        if (tipText is String) {
          draft.soundDiscriminationTipCtrl.text = tipText;
        }
        final items = config['items'];
        if (items is List) {
          for (final item in items) {
            if (item is Map) {
              final draftItem = SoundDiscriminationItemDraft();
              final itemTitle = item['title'];
              final itemTitleAudio = item['title_audio_url'];
              final imageUrl = item['image_url'];
              final containsTargetSound = item['contains_target_sound'];
              final highlightedText = item['highlighted_text'];
              if (itemTitle is String) draftItem.titleCtrl.text = itemTitle;
              if (itemTitleAudio is String) {
                draftItem.titleAudioCtrl.text = itemTitleAudio;
              }
              if (imageUrl is String) draftItem.imageUrlCtrl.text = imageUrl;
              if (containsTargetSound is bool) {
                draftItem.containsTargetSound = containsTargetSound;
              }
              if (highlightedText is String) {
                draftItem.highlightedTextCtrl.text = highlightedText;
              }
              draft.soundDiscriminationItems.add(draftItem);
            }
          }
        }
        break;
      case LessonStepType.soundItemMatching:
        final activities = config['activities'];
        if (activities is List) {
          for (final activity in activities) {
            if (activity is Map) {
              final draftActivity = SoundItemMatchingActivityDraft();
              final prompt = activity['prompt'];
              final promptAudio = activity['prompt_audio_url'];
              final contentAudio = activity['content_audio_url'];
              final tipText = activity['tip_text'];
              final targetSound = activity['target_sound'];
              if (prompt is String) draftActivity.promptCtrl.text = prompt;
              if (promptAudio is String) {
                draftActivity.promptAudioCtrl.text = promptAudio;
              }
              if (contentAudio is String) {
                draftActivity.contentAudioCtrl.text = contentAudio;
              }
              if (tipText is String) draftActivity.tipCtrl.text = tipText;
              if (targetSound is String) {
                draftActivity.targetSoundCtrl.text = targetSound;
              }
              final options = activity['options'];
              if (options is List) {
                for (final option in options) {
                  if (option is Map) {
                    final draftOption = SoundItemMatchingOptionDraft();
                    final label = option['label'];
                    final isCorrect = option['is_correct'];
                    if (label is String) draftOption.labelCtrl.text = label;
                    if (isCorrect is bool) draftOption.isCorrect = isCorrect;
                    draftActivity.options.add(draftOption);
                  }
                }
              }
              draft.soundItemMatchingActivities.add(draftActivity);
            }
          }
        }
        break;
      case LessonStepType.guidedReading:
        final activities = config['activities'];
        if (activities is List) {
          for (final activity in activities) {
            if (activity is Map) {
              final draftActivity = GuidedReadingActivityDraft();
              final instructionText = activity['instruction_text'];
              final instructionAudio = activity['instruction_audio_url'];
              final wordText = activity['word_text'];
              final wordAudio = activity['word_audio_url'];
              if (instructionText is String) {
                draftActivity.instructionTextCtrl.text = instructionText;
              }
              if (instructionAudio is String) {
                draftActivity.instructionAudioCtrl.text = instructionAudio;
              }
              if (wordText is String) {
                draftActivity.wordTextCtrl.text = wordText;
              }
              if (wordAudio is String) {
                draftActivity.wordAudioCtrl.text = wordAudio;
              }
              final segments = activity['segments'];
              if (segments is List) {
                for (final segment in segments) {
                  if (segment is Map) {
                    final draftSegment = GuidedReadingSegmentDraft();
                    final phonemeLabel = segment['phoneme_label'];
                    final grapheme = segment['grapheme'];
                    final audioUrl = segment['audio_url'];
                    final isFocus = segment['is_focus'];
                    if (phonemeLabel is String) {
                      draftSegment.phonemeLabelCtrl.text = phonemeLabel;
                    }
                    if (grapheme is String) {
                      draftSegment.graphemeCtrl.text = grapheme;
                    }
                    if (audioUrl is String) {
                      draftSegment.audioUrlCtrl.text = audioUrl;
                    }
                    if (isFocus is bool) {
                      draftSegment.isFocus = isFocus;
                    }
                    draftActivity.segments.add(draftSegment);
                  }
                }
              }
              draft.guidedReadingActivities.add(draftActivity);
            }
          }
        }
        break;
      case LessonStepType.practiceGame:
        final instructionText = config['instruction_text'];
        final instructionAudio = config['instruction_audio_url'];
        final targetSound = config['target_sound'];
        final durationSeconds = config['duration_seconds'];
        final passingScore = config['passing_score'];
        if (instructionText is String) {
          draft.practiceGameInstructionCtrl.text = instructionText;
        }
        if (instructionAudio is String) {
          draft.practiceGameInstructionAudioCtrl.text = instructionAudio;
        }
        if (targetSound is String) {
          draft.practiceGameTargetSoundCtrl.text = targetSound;
        }
        if (durationSeconds != null) {
          draft.practiceGameDurationCtrl.text = durationSeconds.toString();
        }
        if (passingScore != null) {
          draft.practiceGamePassingScoreCtrl.text = passingScore.toString();
        }
        final options = config['options'];
        if (options is List) {
          for (final option in options) {
            if (option is Map) {
              final draftOption = PracticeGameOptionDraft();
              final optionTitle = option['title'];
              final imageUrl = option['image_url'];
              final audioUrl = option['audio_url'];
              final isCorrect = option['is_correct'];
              if (optionTitle is String) {
                draftOption.titleCtrl.text = optionTitle;
              }
              if (imageUrl is String) {
                draftOption.imageUrlCtrl.text = imageUrl;
              }
              if (audioUrl is String) {
                draftOption.audioUrlCtrl.text = audioUrl;
              }
              if (isCorrect is bool) {
                draftOption.isCorrect = isCorrect;
              }
              draft.practiceGameOptions.add(draftOption);
            }
          }
        }
        break;
      case LessonStepType.soundPresenceCheck:
        final questions = config['questions'];
        if (questions is List) {
          for (final question in questions) {
            if (question is Map) {
              final draftQuestion = SoundPresenceCheckQuestionDraft();
              final prompt = question['prompt'];
              final promptAudioUrl = question['prompt_audio_url'];
              final wordText = question['word_text'];
              final wordAudioUrl = question['word_audio_url'];
              final targetSound = question['target_sound'];
              final correctAnswer = question['correct_answer'];
              final yesLabel = question['yes_label'];
              final noLabel = question['no_label'];
              if (prompt is String) draftQuestion.promptCtrl.text = prompt;
              if (promptAudioUrl is String) {
                draftQuestion.promptAudioCtrl.text = promptAudioUrl;
              }
              if (wordText is String) {
                draftQuestion.wordTextCtrl.text = wordText;
              }
              if (wordAudioUrl is String) {
                draftQuestion.wordAudioCtrl.text = wordAudioUrl;
              }
              if (targetSound is String) {
                draftQuestion.targetSoundCtrl.text = targetSound;
              }
              if (correctAnswer is bool) {
                draftQuestion.correctAnswer = correctAnswer;
              }
              if (yesLabel is String) {
                draftQuestion.yesLabelCtrl.text = yesLabel;
              }
              if (noLabel is String) {
                draftQuestion.noLabelCtrl.text = noLabel;
              }
              draft.soundPresenceCheckQuestions.add(draftQuestion);
            }
          }
        }
        break;
      case LessonStepType.missingLetters:
        final instructionText = config['instruction_text'];
        final instructionAudio = config['instruction_audio_url'];
        if (instructionText is String) {
          draft.missingLettersInstructionCtrl.text = instructionText;
        }
        if (instructionAudio is String) {
          draft.missingLettersInstructionAudioCtrl.text = instructionAudio;
        }
        final activities = config['activities'];
        if (activities is List) {
          for (final activity in activities) {
            if (activity is Map) {
              final draftActivity = MissingLettersActivityDraft();
              final promptText = activity['prompt_text'];
              final targetWord = activity['target_word'];
              if (promptText is String) {
                draftActivity.promptTextCtrl.text = promptText;
              }
              if (targetWord is String) {
                draftActivity.targetWordCtrl.text = targetWord;
              }
              final answerTemplate = activity['answer_template'];
              if (answerTemplate is List) {
                for (final item in answerTemplate) {
                  if (item is Map) {
                    final draftItem = MissingLettersTemplateItemDraft();
                    final value = item['value'];
                    final kind = item['kind'];
                    if (value is String) {
                      draftItem.valueCtrl.text = value;
                    }
                    if (kind is String) {
                      draftItem.kind = kind;
                    }
                    draftActivity.answerTemplate.add(draftItem);
                  }
                }
              }
              final options = activity['options'];
              if (options is List) {
                for (final option in options) {
                  if (option is String) {
                    draftActivity.options.add(
                      TextEditingController(text: option),
                    );
                  }
                }
              }
              draft.missingLettersActivities.add(draftActivity);
            }
          }
        }
        break;
      case LessonStepType.matchingWords:
        final instructionAudio = config['instruction_audio_url'];
        if (instructionAudio is String) {
          draft.matchingWordsInstructionAudioCtrl.text = instructionAudio;
        }
        final activities = config['activities'];
        if (activities is List) {
          for (final activity in activities) {
            if (activity is Map) {
              final draftActivity = MatchingWordsActivityDraft();
              final mode = activity['mode'];
              final promptText = activity['prompt_text'];
              final promptAudioUrl = activity['prompt_audio_url'];
              final promptImageUrl = activity['prompt_image_url'];
              final correctOptionId = activity['correct_option_id'];
              if (mode is String) draftActivity.mode = mode;
              if (promptText is String) {
                draftActivity.promptTextCtrl.text = promptText;
              }
              if (promptAudioUrl is String) {
                draftActivity.promptAudioCtrl.text = promptAudioUrl;
              }
              if (promptImageUrl is String) {
                draftActivity.promptImageCtrl.text = promptImageUrl;
              }
              if (correctOptionId is String) {
                draftActivity.correctOptionIdCtrl.text = correctOptionId;
              }
              final options = activity['options'];
              if (options is List) {
                for (final option in options) {
                  if (option is Map) {
                    final draftOption = MatchingWordsOptionDraft();
                    final id = option['id'];
                    final label = option['label'];
                    final imageUrl = option['image_url'];
                    if (id is String) draftOption.idCtrl.text = id;
                    if (label is String) draftOption.labelCtrl.text = label;
                    if (imageUrl is String) {
                      draftOption.imageUrlCtrl.text = imageUrl;
                    }
                    draftActivity.options.add(draftOption);
                  }
                }
              }
              draft.matchingWordsActivities.add(draftActivity);
            }
          }
        }
        break;
      case LessonStepType.wordReading:
        final instructionAudio = config['instruction_audio_url'];
        if (instructionAudio is String) {
          draft.wordReadingInstructionAudioCtrl.text = instructionAudio;
        }
        final items = config['items'];
        if (items is List) {
          for (final item in items) {
            if (item is Map) {
              final draftItem = WordReadingItemDraft();
              final word = item['word'];
              final imageUrl = item['image_url'];
              final wordAudioUrl = item['word_audio_url'];
              final modelReadingLabel = item['model_reading_label'];
              if (word is String) draftItem.wordCtrl.text = word;
              if (imageUrl is String) draftItem.imageUrlCtrl.text = imageUrl;
              if (wordAudioUrl is String) {
                draftItem.wordAudioCtrl.text = wordAudioUrl;
              }
              if (modelReadingLabel is String) {
                draftItem.modelReadingLabelCtrl.text = modelReadingLabel;
              }
              final segments = item['segments'];
              if (segments is List) {
                for (final segment in segments) {
                  if (segment is Map) {
                    final draftSegment = WordReadingSegmentDraft();
                    final label = segment['label'];
                    final audioUrl = segment['audio_url'];
                    final highlighted = segment['highlighted'];
                    if (label is String) {
                      draftSegment.labelCtrl.text = label;
                    }
                    if (audioUrl is String) {
                      draftSegment.audioUrlCtrl.text = audioUrl;
                    }
                    if (highlighted is bool) {
                      draftSegment.highlighted = highlighted;
                    }
                    draftItem.segments.add(draftSegment);
                  }
                }
              }
              draft.wordReadingItems.add(draftItem);
            }
          }
        }
        break;
      case LessonStepType.sentenceReading:
        final instructionAudio = config['instruction_audio_url'];
        if (instructionAudio is String) {
          draft.sentenceReadingInstructionAudioCtrl.text = instructionAudio;
        }
        final items = config['items'];
        if (items is List) {
          for (final item in items) {
            if (item is Map) {
              final draftItem = SentenceReadingItemDraft();
              final sentenceText = item['sentence_text'];
              final sentenceAudioUrl = item['sentence_audio_url'];
              final selfReadLabel = item['self_read_label'];
              if (sentenceText is String) {
                draftItem.sentenceTextCtrl.text = sentenceText;
              }
              if (sentenceAudioUrl is String) {
                draftItem.sentenceAudioCtrl.text = sentenceAudioUrl;
              }
              if (selfReadLabel is String) {
                draftItem.selfReadLabelCtrl.text = selfReadLabel;
              }
              final displayTokens = item['display_tokens'];
              if (displayTokens is List) {
                for (final token in displayTokens) {
                  if (token is String) {
                    draftItem.displayTokens.add(
                      TextEditingController(text: token),
                    );
                  }
                }
              }
              draft.sentenceReadingItems.add(draftItem);
            }
          }
        }
        break;
      case LessonStepType.miniStoryCard:
        final instructionAudio = config['instruction_audio_url'];
        if (instructionAudio is String) {
          draft.miniStoryCardInstructionAudioCtrl.text = instructionAudio;
        }
        final items = config['items'];
        if (items is List) {
          for (final item in items) {
            if (item is Map) {
              final draftItem = MiniStoryCardItemDraft();
              final heading = item['heading'];
              final headingAudioUrl = item['heading_audio_url'];
              final storyAudioUrl = item['story_audio_url'];
              final ctaLabel = item['cta_label'];
              if (heading is String) draftItem.headingCtrl.text = heading;
              if (headingAudioUrl is String) {
                draftItem.headingAudioCtrl.text = headingAudioUrl;
              }
              if (storyAudioUrl is String) {
                draftItem.storyAudioCtrl.text = storyAudioUrl;
              }
              if (ctaLabel is String) {
                draftItem.ctaLabelCtrl.text = ctaLabel;
              }
              final bodyLines = item['body_lines'];
              if (bodyLines is List) {
                for (final line in bodyLines) {
                  if (line is String) {
                    draftItem.bodyLines.add(TextEditingController(text: line));
                  }
                }
              }
              draft.miniStoryCardItems.add(draftItem);
            }
          }
        }
        break;
    }
    return draft;
  }

  int position;
  LessonStepType stepType;

  /// Set when this step uses an admin-created custom type. When non-null,
  /// the step form shows a generic JSON config editor instead of the
  /// specialised form, and [toInput] writes this type's key to the DB.
  StepTypeDefinition? customStepType;

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

  final TextEditingController instructionCtrl;
  final TextEditingController instructionAudioCtrl;
  final List<BlendingExampleDraft> blendingExamples = [];

  final TextEditingController titleAudioCtrl;
  final TextEditingController targetSoundCtrl;
  final TextEditingController referenceWordCtrl;
  final TextEditingController soundDiscriminationTipCtrl;
  final List<SoundDiscriminationItemDraft> soundDiscriminationItems = [];
  final List<SoundItemMatchingActivityDraft> soundItemMatchingActivities = [];
  final List<GuidedReadingActivityDraft> guidedReadingActivities = [];
  final TextEditingController practiceGameInstructionCtrl;
  final TextEditingController practiceGameInstructionAudioCtrl;
  final TextEditingController practiceGameTargetSoundCtrl;
  final TextEditingController practiceGameDurationCtrl;
  final TextEditingController practiceGamePassingScoreCtrl;
  final List<PracticeGameOptionDraft> practiceGameOptions = [];
  final List<SoundPresenceCheckQuestionDraft> soundPresenceCheckQuestions = [];
  final TextEditingController missingLettersInstructionCtrl;
  final TextEditingController missingLettersInstructionAudioCtrl;
  final List<MissingLettersActivityDraft> missingLettersActivities = [];
  final TextEditingController matchingWordsInstructionAudioCtrl;
  final List<MatchingWordsActivityDraft> matchingWordsActivities = [];
  final TextEditingController wordReadingInstructionAudioCtrl;
  final List<WordReadingItemDraft> wordReadingItems = [];
  final TextEditingController sentenceReadingInstructionAudioCtrl;
  final List<SentenceReadingItemDraft> sentenceReadingItems = [];
  final TextEditingController miniStoryCardInstructionAudioCtrl;
  final List<MiniStoryCardItemDraft> miniStoryCardItems = [];

  /// JSON config editor for custom step types. Pre-filled with `{}`.
  final TextEditingController customConfigCtrl =
      TextEditingController(text: '{}');

  void setStepType(LessonStepType type) {
    customStepType = null;
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
    if (type == LessonStepType.blending && blendingExamples.isEmpty) {
      addBlendingExample();
    }
    if (type == LessonStepType.soundDiscrimination &&
        soundDiscriminationItems.isEmpty) {
      addSoundDiscriminationItem();
    }
    if (type == LessonStepType.soundItemMatching &&
        soundItemMatchingActivities.isEmpty) {
      addSoundItemMatchingActivity();
    }
    if (type == LessonStepType.guidedReading &&
        guidedReadingActivities.isEmpty) {
      addGuidedReadingActivity();
    }
    if (type == LessonStepType.practiceGame && practiceGameOptions.isEmpty) {
      addPracticeGameOption();
      addPracticeGameOption();
    }
    if (type == LessonStepType.soundPresenceCheck &&
        soundPresenceCheckQuestions.isEmpty) {
      addSoundPresenceCheckQuestion();
    }
    if (type == LessonStepType.missingLetters &&
        missingLettersActivities.isEmpty) {
      addMissingLettersActivity();
    }
    if (type == LessonStepType.matchingWords &&
        matchingWordsActivities.isEmpty) {
      addMatchingWordsActivity();
    }
    if (type == LessonStepType.wordReading && wordReadingItems.isEmpty) {
      addWordReadingItem();
    }
    if (type == LessonStepType.sentenceReading &&
        sentenceReadingItems.isEmpty) {
      addSentenceReadingItem();
    }
    if (type == LessonStepType.miniStoryCard && miniStoryCardItems.isEmpty) {
      addMiniStoryCardItem();
    }
  }

  /// Sets this step to a custom (admin-created) type. Clears any previously
  /// selected system type and resets the JSON config to `{}`.
  void setCustomType(StepTypeDefinition def) {
    customStepType = def;
    customConfigCtrl.text = '{}';
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

  void addBlendingExample() => blendingExamples.add(BlendingExampleDraft());
  void removeBlendingExample(int index) {
    blendingExamples[index].dispose();
    blendingExamples.removeAt(index);
  }

  void addSoundDiscriminationItem() {
    soundDiscriminationItems.add(SoundDiscriminationItemDraft());
  }

  void removeSoundDiscriminationItem(int index) {
    soundDiscriminationItems[index].dispose();
    soundDiscriminationItems.removeAt(index);
  }

  void addSoundItemMatchingActivity() {
    final activity = SoundItemMatchingActivityDraft();
    activity.addOption();
    activity.addOption();
    soundItemMatchingActivities.add(activity);
  }

  void removeSoundItemMatchingActivity(int index) {
    soundItemMatchingActivities[index].dispose();
    soundItemMatchingActivities.removeAt(index);
  }

  void addGuidedReadingActivity() {
    final activity = GuidedReadingActivityDraft();
    activity.addSegment();
    guidedReadingActivities.add(activity);
  }

  void removeGuidedReadingActivity(int index) {
    guidedReadingActivities[index].dispose();
    guidedReadingActivities.removeAt(index);
  }

  void addPracticeGameOption() =>
      practiceGameOptions.add(PracticeGameOptionDraft());
  void removePracticeGameOption(int index) {
    practiceGameOptions[index].dispose();
    practiceGameOptions.removeAt(index);
  }

  void addSoundPresenceCheckQuestion() {
    final question = SoundPresenceCheckQuestionDraft();
    question.yesLabelCtrl.text = 'Yes';
    question.noLabelCtrl.text = 'No';
    soundPresenceCheckQuestions.add(question);
  }

  void removeSoundPresenceCheckQuestion(int index) {
    soundPresenceCheckQuestions[index].dispose();
    soundPresenceCheckQuestions.removeAt(index);
  }

  void addMissingLettersActivity() {
    final activity = MissingLettersActivityDraft();
    activity.addTemplateItem();
    activity.addTemplateItem();
    activity.addOption();
    activity.addOption();
    missingLettersActivities.add(activity);
  }

  void removeMissingLettersActivity(int index) {
    missingLettersActivities[index].dispose();
    missingLettersActivities.removeAt(index);
  }

  void addMatchingWordsActivity() {
    final activity = MatchingWordsActivityDraft();
    activity.addOption();
    activity.addOption();
    matchingWordsActivities.add(activity);
  }

  void removeMatchingWordsActivity(int index) {
    matchingWordsActivities[index].dispose();
    matchingWordsActivities.removeAt(index);
  }

  void addWordReadingItem() {
    final item = WordReadingItemDraft();
    item.addSegment();
    wordReadingItems.add(item);
  }

  void removeWordReadingItem(int index) {
    wordReadingItems[index].dispose();
    wordReadingItems.removeAt(index);
  }

  void addSentenceReadingItem() {
    final item = SentenceReadingItemDraft();
    item.addDisplayToken();
    sentenceReadingItems.add(item);
  }

  void removeSentenceReadingItem(int index) {
    sentenceReadingItems[index].dispose();
    sentenceReadingItems.removeAt(index);
  }

  void addMiniStoryCardItem() {
    final item = MiniStoryCardItemDraft();
    item.addBodyLine();
    miniStoryCardItems.add(item);
  }

  void removeMiniStoryCardItem(int index) {
    miniStoryCardItems[index].dispose();
    miniStoryCardItems.removeAt(index);
  }

  LessonStepInput toInput() {
    return LessonStepInput(
      stepKey: stepKeyCtrl.text.trim(),
      stepType: stepType,
      customStepTypeKey: customStepType?.key,
      position: position,
      required: required,
      config: _buildConfig(),
    );
  }

  Map<String, dynamic> _buildConfig() {
    if (customStepType != null) {
      // Try to parse user-entered JSON; fall back to empty map on error.
      try {
        final raw = customConfigCtrl.text.trim();
        if (raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        }
      } catch (_) {}
      return {};
    }
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
      case LessonStepType.blending:
        return {
          'title': titleCtrl.text.trim(),
          if (instructionCtrl.text.trim().isNotEmpty)
            'instruction': instructionCtrl.text.trim(),
          if (instructionAudioCtrl.text.trim().isNotEmpty)
            'instruction_audio_url': instructionAudioCtrl.text.trim(),
          'examples': blendingExamples.map((e) => e.toMap()).toList(),
        };
      case LessonStepType.soundDiscrimination:
        final items = soundDiscriminationItems
            .map((item) => item.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          if (titleAudioCtrl.text.trim().isNotEmpty)
            'title_audio_url': titleAudioCtrl.text.trim(),
          if (targetSoundCtrl.text.trim().isNotEmpty)
            'target_sound': targetSoundCtrl.text.trim(),
          if (referenceWordCtrl.text.trim().isNotEmpty)
            'reference_word': referenceWordCtrl.text.trim(),
          if (soundDiscriminationTipCtrl.text.trim().isNotEmpty)
            'tip_text': soundDiscriminationTipCtrl.text.trim(),
          if (items.isNotEmpty) 'items': items,
        };
      case LessonStepType.soundItemMatching:
        final activities = soundItemMatchingActivities
            .map((activity) => activity.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          if (activities.isNotEmpty) 'activities': activities,
        };
      case LessonStepType.guidedReading:
        final activities = guidedReadingActivities
            .map((activity) => activity.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          if (activities.isNotEmpty) 'activities': activities,
        };
      case LessonStepType.practiceGame:
        final options = practiceGameOptions
            .map((option) => option.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        final durationSeconds = int.tryParse(
          practiceGameDurationCtrl.text.trim(),
        );
        final passingScore = int.tryParse(
          practiceGamePassingScoreCtrl.text.trim(),
        );
        return {
          'title': titleCtrl.text.trim(),
          if (practiceGameInstructionCtrl.text.trim().isNotEmpty)
            'instruction_text': practiceGameInstructionCtrl.text.trim(),
          if (practiceGameInstructionAudioCtrl.text.trim().isNotEmpty)
            'instruction_audio_url': practiceGameInstructionAudioCtrl.text
                .trim(),
          if (practiceGameTargetSoundCtrl.text.trim().isNotEmpty)
            'target_sound': practiceGameTargetSoundCtrl.text.trim(),
          if (durationSeconds != null) 'duration_seconds': durationSeconds,
          if (passingScore != null) 'passing_score': passingScore,
          if (options.isNotEmpty) 'options': options,
        };
      case LessonStepType.soundPresenceCheck:
        final questions = soundPresenceCheckQuestions
            .map((question) => question.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          if (questions.isNotEmpty) 'questions': questions,
        };
      case LessonStepType.missingLetters:
        final activities = missingLettersActivities
            .map((activity) => activity.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          if (missingLettersInstructionCtrl.text.trim().isNotEmpty)
            'instruction_text': missingLettersInstructionCtrl.text.trim(),
          if (missingLettersInstructionAudioCtrl.text.trim().isNotEmpty)
            'instruction_audio_url': missingLettersInstructionAudioCtrl.text
                .trim(),
          if (activities.isNotEmpty) 'activities': activities,
        };
      case LessonStepType.matchingWords:
        final activities = matchingWordsActivities
            .map((activity) => activity.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          if (matchingWordsInstructionAudioCtrl.text.trim().isNotEmpty)
            'instruction_audio_url': matchingWordsInstructionAudioCtrl.text
                .trim(),
          if (activities.isNotEmpty) 'activities': activities,
        };
      case LessonStepType.wordReading:
        final items = wordReadingItems
            .map((item) => item.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          if (wordReadingInstructionAudioCtrl.text.trim().isNotEmpty)
            'instruction_audio_url': wordReadingInstructionAudioCtrl.text
                .trim(),
          if (items.isNotEmpty) 'items': items,
        };
      case LessonStepType.sentenceReading:
        final items = sentenceReadingItems
            .map((item) => item.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          if (sentenceReadingInstructionAudioCtrl.text.trim().isNotEmpty)
            'instruction_audio_url': sentenceReadingInstructionAudioCtrl.text
                .trim(),
          if (items.isNotEmpty) 'items': items,
        };
      case LessonStepType.miniStoryCard:
        final items = miniStoryCardItems
            .map((item) => item.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          if (miniStoryCardInstructionAudioCtrl.text.trim().isNotEmpty)
            'instruction_audio_url': miniStoryCardInstructionAudioCtrl.text
                .trim(),
          if (items.isNotEmpty) 'items': items,
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
    instructionCtrl.dispose();
    instructionAudioCtrl.dispose();
    for (final ex in blendingExamples) {
      ex.dispose();
    }
    titleAudioCtrl.dispose();
    targetSoundCtrl.dispose();
    referenceWordCtrl.dispose();
    soundDiscriminationTipCtrl.dispose();
    practiceGameInstructionCtrl.dispose();
    practiceGameInstructionAudioCtrl.dispose();
    practiceGameTargetSoundCtrl.dispose();
    practiceGameDurationCtrl.dispose();
    practiceGamePassingScoreCtrl.dispose();
    missingLettersInstructionCtrl.dispose();
    missingLettersInstructionAudioCtrl.dispose();
    matchingWordsInstructionAudioCtrl.dispose();
    wordReadingInstructionAudioCtrl.dispose();
    sentenceReadingInstructionAudioCtrl.dispose();
    miniStoryCardInstructionAudioCtrl.dispose();
    for (final item in soundDiscriminationItems) {
      item.dispose();
    }
    for (final activity in soundItemMatchingActivities) {
      activity.dispose();
    }
    for (final activity in guidedReadingActivities) {
      activity.dispose();
    }
    for (final option in practiceGameOptions) {
      option.dispose();
    }
    for (final question in soundPresenceCheckQuestions) {
      question.dispose();
    }
    for (final activity in missingLettersActivities) {
      activity.dispose();
    }
    for (final activity in matchingWordsActivities) {
      activity.dispose();
    }
    for (final item in wordReadingItems) {
      item.dispose();
    }
    for (final item in sentenceReadingItems) {
      item.dispose();
    }
    for (final item in miniStoryCardItems) {
      item.dispose();
    }
    customConfigCtrl.dispose();
  }
}

class PracticeItemDraft {
  final TextEditingController labelCtrl = TextEditingController();
  final TextEditingController imageUrlCtrl = TextEditingController();
  final TextEditingController soundUrlCtrl = TextEditingController();
  final TextEditingController highlightedLettersCtrl = TextEditingController();

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
    // Always persist highlighted_letters so the app can render the highlight.
    // Fall back to the first character of the label when the field is empty.
    final highlighted = highlightedLettersCtrl.text.trim();
    final label = labelCtrl.text.trim();
    map['highlighted_letters'] =
        highlighted.isNotEmpty ? highlighted : (label.isNotEmpty ? label[0] : '');
    return map;
  }

  void dispose() {
    labelCtrl.dispose();
    imageUrlCtrl.dispose();
    soundUrlCtrl.dispose();
    highlightedLettersCtrl.dispose();
  }
}

class PhonemeDraft {
  final TextEditingController labelCtrl = TextEditingController();
  final TextEditingController audioUrlCtrl = TextEditingController();
  bool highlighted = false;

  Map<String, dynamic> toMap() => {
    'label': labelCtrl.text.trim(),
    'audio_url': audioUrlCtrl.text.trim(),
    'highlighted': highlighted,
  };

  void dispose() {
    labelCtrl.dispose();
    audioUrlCtrl.dispose();
  }
}

class BlendingExampleDraft {
  final TextEditingController wordCtrl = TextEditingController();
  final TextEditingController audioUrlCtrl = TextEditingController();
  final List<PhonemeDraft> phonemes = [];

  void addPhoneme() => phonemes.add(PhonemeDraft());
  void removePhoneme(int index) {
    phonemes[index].dispose();
    phonemes.removeAt(index);
  }

  Map<String, dynamic> toMap() => {
    'word': wordCtrl.text.trim(),
    'word_audio_url': audioUrlCtrl.text.trim(),
    'phonemes': phonemes.map((p) => p.toMap()).toList(),
  };

  void dispose() {
    wordCtrl.dispose();
    audioUrlCtrl.dispose();
    for (final p in phonemes) {
      p.dispose();
    }
  }
}

class SoundDiscriminationItemDraft {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController titleAudioCtrl = TextEditingController();
  final TextEditingController imageUrlCtrl = TextEditingController();
  final TextEditingController highlightedTextCtrl = TextEditingController();
  bool containsTargetSound = false;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (titleCtrl.text.trim().isNotEmpty) {
      map['title'] = titleCtrl.text.trim();
    }
    if (titleAudioCtrl.text.trim().isNotEmpty) {
      map['title_audio_url'] = titleAudioCtrl.text.trim();
    }
    if (imageUrlCtrl.text.trim().isNotEmpty) {
      map['image_url'] = imageUrlCtrl.text.trim();
    }
    map['contains_target_sound'] = containsTargetSound;
    if (highlightedTextCtrl.text.trim().isNotEmpty) {
      map['highlighted_text'] = highlightedTextCtrl.text.trim();
    }
    return map;
  }

  void dispose() {
    titleCtrl.dispose();
    titleAudioCtrl.dispose();
    imageUrlCtrl.dispose();
    highlightedTextCtrl.dispose();
  }
}

class SoundItemMatchingOptionDraft {
  final TextEditingController labelCtrl = TextEditingController();
  bool isCorrect = false;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (labelCtrl.text.trim().isNotEmpty) {
      map['label'] = labelCtrl.text.trim();
    }
    map['is_correct'] = isCorrect;
    return map;
  }

  void dispose() {
    labelCtrl.dispose();
  }
}

class SoundItemMatchingActivityDraft {
  final TextEditingController promptCtrl = TextEditingController();
  final TextEditingController promptAudioCtrl = TextEditingController();
  final TextEditingController contentAudioCtrl = TextEditingController();
  final TextEditingController tipCtrl = TextEditingController();
  final TextEditingController targetSoundCtrl = TextEditingController();
  final List<SoundItemMatchingOptionDraft> options = [];

  void addOption() => options.add(SoundItemMatchingOptionDraft());
  void removeOption(int index) {
    options[index].dispose();
    options.removeAt(index);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (promptCtrl.text.trim().isNotEmpty) {
      map['prompt'] = promptCtrl.text.trim();
    }
    if (promptAudioCtrl.text.trim().isNotEmpty) {
      map['prompt_audio_url'] = promptAudioCtrl.text.trim();
    }
    if (contentAudioCtrl.text.trim().isNotEmpty) {
      map['content_audio_url'] = contentAudioCtrl.text.trim();
    }
    if (tipCtrl.text.trim().isNotEmpty) {
      map['tip_text'] = tipCtrl.text.trim();
    }
    if (targetSoundCtrl.text.trim().isNotEmpty) {
      map['target_sound'] = targetSoundCtrl.text.trim();
    }
    final optionMaps = options.map((option) => option.toMap()).toList();
    if (optionMaps.isNotEmpty) {
      map['options'] = optionMaps;
    }
    return map;
  }

  void dispose() {
    promptCtrl.dispose();
    promptAudioCtrl.dispose();
    contentAudioCtrl.dispose();
    tipCtrl.dispose();
    targetSoundCtrl.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class GuidedReadingSegmentDraft {
  final TextEditingController phonemeLabelCtrl = TextEditingController();
  final TextEditingController graphemeCtrl = TextEditingController();
  final TextEditingController audioUrlCtrl = TextEditingController();
  bool isFocus = false;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (phonemeLabelCtrl.text.trim().isNotEmpty) {
      map['phoneme_label'] = phonemeLabelCtrl.text.trim();
    }
    if (graphemeCtrl.text.trim().isNotEmpty) {
      map['grapheme'] = graphemeCtrl.text.trim();
    }
    if (audioUrlCtrl.text.trim().isNotEmpty) {
      map['audio_url'] = audioUrlCtrl.text.trim();
    }
    map['is_focus'] = isFocus;
    return map;
  }

  void dispose() {
    phonemeLabelCtrl.dispose();
    graphemeCtrl.dispose();
    audioUrlCtrl.dispose();
  }
}

class GuidedReadingActivityDraft {
  final TextEditingController instructionTextCtrl = TextEditingController();
  final TextEditingController instructionAudioCtrl = TextEditingController();
  final TextEditingController wordTextCtrl = TextEditingController();
  final TextEditingController wordAudioCtrl = TextEditingController();
  final List<GuidedReadingSegmentDraft> segments = [];

  void addSegment() => segments.add(GuidedReadingSegmentDraft());
  void removeSegment(int index) {
    segments[index].dispose();
    segments.removeAt(index);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (instructionTextCtrl.text.trim().isNotEmpty) {
      map['instruction_text'] = instructionTextCtrl.text.trim();
    }
    if (instructionAudioCtrl.text.trim().isNotEmpty) {
      map['instruction_audio_url'] = instructionAudioCtrl.text.trim();
    }
    if (wordTextCtrl.text.trim().isNotEmpty) {
      map['word_text'] = wordTextCtrl.text.trim();
    }
    if (wordAudioCtrl.text.trim().isNotEmpty) {
      map['word_audio_url'] = wordAudioCtrl.text.trim();
    }
    final segmentMaps = segments.map((segment) => segment.toMap()).toList();
    if (segmentMaps.isNotEmpty) {
      map['segments'] = segmentMaps;
    }
    return map;
  }

  void dispose() {
    instructionTextCtrl.dispose();
    instructionAudioCtrl.dispose();
    wordTextCtrl.dispose();
    wordAudioCtrl.dispose();
    for (final segment in segments) {
      segment.dispose();
    }
  }
}

class PracticeGameOptionDraft {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController imageUrlCtrl = TextEditingController();
  final TextEditingController audioUrlCtrl = TextEditingController();
  bool isCorrect = false;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (titleCtrl.text.trim().isNotEmpty) {
      map['title'] = titleCtrl.text.trim();
    }
    if (imageUrlCtrl.text.trim().isNotEmpty) {
      map['image_url'] = imageUrlCtrl.text.trim();
    }
    if (audioUrlCtrl.text.trim().isNotEmpty) {
      map['audio_url'] = audioUrlCtrl.text.trim();
    }
    map['is_correct'] = isCorrect;
    return map;
  }

  void dispose() {
    titleCtrl.dispose();
    imageUrlCtrl.dispose();
    audioUrlCtrl.dispose();
  }
}

class SoundPresenceCheckQuestionDraft {
  final TextEditingController promptCtrl = TextEditingController();
  final TextEditingController promptAudioCtrl = TextEditingController();
  final TextEditingController wordTextCtrl = TextEditingController();
  final TextEditingController wordAudioCtrl = TextEditingController();
  final TextEditingController targetSoundCtrl = TextEditingController();
  final TextEditingController yesLabelCtrl = TextEditingController();
  final TextEditingController noLabelCtrl = TextEditingController();
  bool correctAnswer = true;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (promptCtrl.text.trim().isNotEmpty) {
      map['prompt'] = promptCtrl.text.trim();
    }
    if (promptAudioCtrl.text.trim().isNotEmpty) {
      map['prompt_audio_url'] = promptAudioCtrl.text.trim();
    }
    if (wordTextCtrl.text.trim().isNotEmpty) {
      map['word_text'] = wordTextCtrl.text.trim();
    }
    if (wordAudioCtrl.text.trim().isNotEmpty) {
      map['word_audio_url'] = wordAudioCtrl.text.trim();
    }
    if (targetSoundCtrl.text.trim().isNotEmpty) {
      map['target_sound'] = targetSoundCtrl.text.trim();
    }
    map['correct_answer'] = correctAnswer;
    if (yesLabelCtrl.text.trim().isNotEmpty) {
      map['yes_label'] = yesLabelCtrl.text.trim();
    }
    if (noLabelCtrl.text.trim().isNotEmpty) {
      map['no_label'] = noLabelCtrl.text.trim();
    }
    return map;
  }

  void dispose() {
    promptCtrl.dispose();
    promptAudioCtrl.dispose();
    wordTextCtrl.dispose();
    wordAudioCtrl.dispose();
    targetSoundCtrl.dispose();
    yesLabelCtrl.dispose();
    noLabelCtrl.dispose();
  }
}

class MissingLettersTemplateItemDraft {
  final TextEditingController valueCtrl = TextEditingController();
  String kind = 'missing';

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (valueCtrl.text.trim().isNotEmpty) {
      map['value'] = valueCtrl.text.trim();
    }
    map['kind'] = kind;
    return map;
  }

  void dispose() {
    valueCtrl.dispose();
  }
}

class MissingLettersActivityDraft {
  final TextEditingController promptTextCtrl = TextEditingController();
  final TextEditingController targetWordCtrl = TextEditingController();
  final List<MissingLettersTemplateItemDraft> answerTemplate = [];
  final List<TextEditingController> options = [];

  void addTemplateItem() =>
      answerTemplate.add(MissingLettersTemplateItemDraft());
  void removeTemplateItem(int index) {
    answerTemplate[index].dispose();
    answerTemplate.removeAt(index);
  }

  void addOption() => options.add(TextEditingController());
  void removeOption(int index) {
    options[index].dispose();
    options.removeAt(index);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (promptTextCtrl.text.trim().isNotEmpty) {
      map['prompt_text'] = promptTextCtrl.text.trim();
    }
    if (targetWordCtrl.text.trim().isNotEmpty) {
      map['target_word'] = targetWordCtrl.text.trim();
    }
    final template = answerTemplate.map((item) => item.toMap()).toList();
    if (template.isNotEmpty) {
      map['answer_template'] = template;
    }
    final optionValues = options
        .map((option) => option.text.trim())
        .where((option) => option.isNotEmpty)
        .toList();
    if (optionValues.isNotEmpty) {
      map['options'] = optionValues;
    }
    return map;
  }

  void dispose() {
    promptTextCtrl.dispose();
    targetWordCtrl.dispose();
    for (final item in answerTemplate) {
      item.dispose();
    }
    for (final option in options) {
      option.dispose();
    }
  }
}

class MatchingWordsOptionDraft {
  final TextEditingController idCtrl = TextEditingController();
  final TextEditingController labelCtrl = TextEditingController();
  final TextEditingController imageUrlCtrl = TextEditingController();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (idCtrl.text.trim().isNotEmpty) {
      map['id'] = idCtrl.text.trim();
    }
    if (labelCtrl.text.trim().isNotEmpty) {
      map['label'] = labelCtrl.text.trim();
    }
    if (imageUrlCtrl.text.trim().isNotEmpty) {
      map['image_url'] = imageUrlCtrl.text.trim();
    }
    return map;
  }

  void dispose() {
    idCtrl.dispose();
    labelCtrl.dispose();
    imageUrlCtrl.dispose();
  }
}

class MatchingWordsActivityDraft {
  String mode = 'sound_to_image';
  final TextEditingController promptTextCtrl = TextEditingController();
  final TextEditingController promptAudioCtrl = TextEditingController();
  final TextEditingController promptImageCtrl = TextEditingController();
  final TextEditingController correctOptionIdCtrl = TextEditingController();
  final List<MatchingWordsOptionDraft> options = [];

  void addOption() => options.add(MatchingWordsOptionDraft());
  void removeOption(int index) {
    options[index].dispose();
    options.removeAt(index);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['mode'] = mode;
    if (promptTextCtrl.text.trim().isNotEmpty) {
      map['prompt_text'] = promptTextCtrl.text.trim();
    }
    if (promptAudioCtrl.text.trim().isNotEmpty) {
      map['prompt_audio_url'] = promptAudioCtrl.text.trim();
    }
    if (promptImageCtrl.text.trim().isNotEmpty) {
      map['prompt_image_url'] = promptImageCtrl.text.trim();
    }
    if (correctOptionIdCtrl.text.trim().isNotEmpty) {
      map['correct_option_id'] = correctOptionIdCtrl.text.trim();
    }
    final optionMaps = options.map((option) => option.toMap()).toList();
    if (optionMaps.isNotEmpty) {
      map['options'] = optionMaps;
    }
    return map;
  }

  void dispose() {
    promptTextCtrl.dispose();
    promptAudioCtrl.dispose();
    promptImageCtrl.dispose();
    correctOptionIdCtrl.dispose();
    for (final option in options) {
      option.dispose();
    }
  }
}

class WordReadingSegmentDraft {
  final TextEditingController labelCtrl = TextEditingController();
  final TextEditingController audioUrlCtrl = TextEditingController();
  bool highlighted = false;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (labelCtrl.text.trim().isNotEmpty) {
      map['label'] = labelCtrl.text.trim();
    }
    if (audioUrlCtrl.text.trim().isNotEmpty) {
      map['audio_url'] = audioUrlCtrl.text.trim();
    }
    map['highlighted'] = highlighted;
    return map;
  }

  void dispose() {
    labelCtrl.dispose();
    audioUrlCtrl.dispose();
  }
}

class WordReadingItemDraft {
  final TextEditingController wordCtrl = TextEditingController();
  final TextEditingController imageUrlCtrl = TextEditingController();
  final TextEditingController wordAudioCtrl = TextEditingController();
  final TextEditingController modelReadingLabelCtrl = TextEditingController();
  final List<WordReadingSegmentDraft> segments = [];

  void addSegment() => segments.add(WordReadingSegmentDraft());
  void removeSegment(int index) {
    segments[index].dispose();
    segments.removeAt(index);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (wordCtrl.text.trim().isNotEmpty) {
      map['word'] = wordCtrl.text.trim();
    }
    if (imageUrlCtrl.text.trim().isNotEmpty) {
      map['image_url'] = imageUrlCtrl.text.trim();
    }
    if (wordAudioCtrl.text.trim().isNotEmpty) {
      map['word_audio_url'] = wordAudioCtrl.text.trim();
    }
    if (modelReadingLabelCtrl.text.trim().isNotEmpty) {
      map['model_reading_label'] = modelReadingLabelCtrl.text.trim();
    }
    final segmentMaps = segments.map((segment) => segment.toMap()).toList();
    if (segmentMaps.isNotEmpty) {
      map['segments'] = segmentMaps;
    }
    return map;
  }

  void dispose() {
    wordCtrl.dispose();
    imageUrlCtrl.dispose();
    wordAudioCtrl.dispose();
    modelReadingLabelCtrl.dispose();
    for (final segment in segments) {
      segment.dispose();
    }
  }
}

class SentenceReadingItemDraft {
  final TextEditingController sentenceTextCtrl = TextEditingController();
  final TextEditingController sentenceAudioCtrl = TextEditingController();
  final TextEditingController selfReadLabelCtrl = TextEditingController();
  final List<TextEditingController> displayTokens = [];

  void addDisplayToken() => displayTokens.add(TextEditingController());
  void removeDisplayToken(int index) {
    displayTokens[index].dispose();
    displayTokens.removeAt(index);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (sentenceTextCtrl.text.trim().isNotEmpty) {
      map['sentence_text'] = sentenceTextCtrl.text.trim();
    }
    final tokens = displayTokens
        .map((token) => token.text.trim())
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isNotEmpty) {
      map['display_tokens'] = tokens;
    }
    if (sentenceAudioCtrl.text.trim().isNotEmpty) {
      map['sentence_audio_url'] = sentenceAudioCtrl.text.trim();
    }
    if (selfReadLabelCtrl.text.trim().isNotEmpty) {
      map['self_read_label'] = selfReadLabelCtrl.text.trim();
    }
    return map;
  }

  void dispose() {
    sentenceTextCtrl.dispose();
    sentenceAudioCtrl.dispose();
    selfReadLabelCtrl.dispose();
    for (final token in displayTokens) {
      token.dispose();
    }
  }
}

class MiniStoryCardItemDraft {
  final TextEditingController headingCtrl = TextEditingController();
  final TextEditingController headingAudioCtrl = TextEditingController();
  final TextEditingController storyAudioCtrl = TextEditingController();
  final TextEditingController ctaLabelCtrl = TextEditingController();
  final List<TextEditingController> bodyLines = [];

  void addBodyLine() => bodyLines.add(TextEditingController());
  void removeBodyLine(int index) {
    bodyLines[index].dispose();
    bodyLines.removeAt(index);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (headingCtrl.text.trim().isNotEmpty) {
      map['heading'] = headingCtrl.text.trim();
    }
    if (headingAudioCtrl.text.trim().isNotEmpty) {
      map['heading_audio_url'] = headingAudioCtrl.text.trim();
    }
    final lines = bodyLines
        .map((line) => line.text.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isNotEmpty) {
      map['body_lines'] = lines;
    }
    if (storyAudioCtrl.text.trim().isNotEmpty) {
      map['story_audio_url'] = storyAudioCtrl.text.trim();
    }
    if (ctaLabelCtrl.text.trim().isNotEmpty) {
      map['cta_label'] = ctaLabelCtrl.text.trim();
    }
    return map;
  }

  void dispose() {
    headingCtrl.dispose();
    headingAudioCtrl.dispose();
    storyAudioCtrl.dispose();
    ctaLabelCtrl.dispose();
    for (final line in bodyLines) {
      line.dispose();
    }
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
