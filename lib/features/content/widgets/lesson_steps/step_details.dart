import 'package:flutter/material.dart';

import '../../../lesson_v2/lesson_v2_models.dart';

class StepCard extends StatefulWidget {
  const StepCard({
    super.key,
    required this.step,
    required this.onEdit,
    required this.onDelete,
  });

  final LessonStep step;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<StepCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final configTitle = step.config?['title'];
    final String? title = configTitle is String ? configTitle : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: step.required
                          ? Colors.orange.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${step.position}',
                        style: TextStyle(
                          color: step.required
                              ? Colors.orange.shade700
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.stepKey,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (title != null && title.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    step.stepType.name,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Edit step',
                  ),
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Delete step',
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: StepDetails(step: step),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StepDetails extends StatelessWidget {
  const StepDetails({super.key, required this.step});

  final LessonStep step;

  @override
  Widget build(BuildContext context) {
    final config = step.config ?? const <String, dynamic>{};
    switch (step.stepType) {
      case LessonStepType.introduction:
        return _buildIntroduction(context, config);
      case LessonStepType.demonstration:
        return _buildDemonstration(context, config);
      case LessonStepType.practice:
        return _buildPractice(context, config);
      case LessonStepType.assessment:
        return _buildAssessment(context, config);
      case LessonStepType.blending:
        return _buildBlending(context, config);
      case LessonStepType.soundDiscrimination:
        return _buildSoundDiscrimination(context, config);
      case LessonStepType.soundItemMatching:
        return _buildSoundItemMatching(context, config);
      case LessonStepType.guidedReading:
        return _buildGuidedReading(context, config);
      case LessonStepType.practiceGame:
        return _buildPracticeGame(context, config);
      case LessonStepType.soundPresenceCheck:
        return _buildSoundPresenceCheck(context, config);
      case LessonStepType.missingLetters:
        return _buildMissingLetters(context, config);
      case LessonStepType.matchingWords:
        return _buildMatchingWords(context, config);
      case LessonStepType.wordReading:
        return _buildWordReading(context, config);
      case LessonStepType.sentenceReading:
        return _buildSentenceReading(context, config);
      case LessonStepType.miniStoryCard:
        return _buildMiniStoryCard(context, config);
    }
  }

  Widget _buildIntroduction(BuildContext context, Map<String, dynamic> config) {
    final displayText = config['display_text'];
    final howTo = config['how_to_svg_url'];
    final practiceTip = config['practice_tip'];
    final audio = config['audio'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayText is String && displayText.isNotEmpty)
          DetailRow(label: 'Display Text', value: displayText),
        if (howTo is String && howTo.isNotEmpty)
          DetailRow(label: 'How-to SVG', value: howTo),
        if (audio is Map) AudioDetails(audio: audio),
        if (practiceTip is Map) PracticeTipDetails(tip: practiceTip),
      ],
    );
  }

  Widget _buildDemonstration(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final images = config['image_urls'];
    final feedbackTitle = config['feedbackTitle'];
    final feedbackBody = config['feedbackBody'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images is List && images.isNotEmpty)
          DetailRow(
            label: 'Images',
            value: images.map((e) => e.toString()).join(', '),
          ),
        if (feedbackTitle is String && feedbackTitle.isNotEmpty)
          DetailRow(label: 'Feedback Title', value: feedbackTitle),
        if (feedbackBody is String && feedbackBody.isNotEmpty)
          DetailRow(label: 'Feedback Body', value: feedbackBody),
      ],
    );
  }

  Widget _buildPractice(BuildContext context, Map<String, dynamic> config) {
    final items = config['items'];
    final tip = config['tip'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items is List && items.isNotEmpty)
          ItemsList(
            label: 'Items',
            items: items,
            itemBuilder: (item) {
              if (item is Map) {
                final label = item['label']?.toString() ?? '';
                final imageUrl = item['image_url']?.toString() ?? '';
                final soundUrl = item['sound_url']?.toString() ?? '';
                return KeyValueGroup(
                  title: label.isNotEmpty ? label : 'Item',
                  rows: [
                    if (imageUrl.isNotEmpty)
                      DetailRow(label: 'Image', value: imageUrl),
                    if (soundUrl.isNotEmpty)
                      DetailRow(label: 'Sound', value: soundUrl),
                  ],
                );
              }
              return DetailRow(label: 'Item', value: item.toString());
            },
          ),
        if (tip is Map) TipDetails(tip: tip),
      ],
    );
  }

  Widget _buildAssessment(BuildContext context, Map<String, dynamic> config) {
    final prompt = config['prompt'];
    final soundInstruction = config['sound_instruction_url'];
    final options = config['options'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prompt is String && prompt.isNotEmpty)
          DetailRow(label: 'Prompt', value: prompt),
        if (soundInstruction is String && soundInstruction.isNotEmpty)
          DetailRow(label: 'Sound Instruction', value: soundInstruction),
        if (options is List && options.isNotEmpty)
          ItemsList(
            label: 'Options',
            items: options,
            itemBuilder: (option) {
              if (option is Map) {
                final label = option['label']?.toString() ?? '';
                final imageUrl = option['image_url']?.toString() ?? '';
                final isCorrect = option['is_correct'] == true;
                return KeyValueGroup(
                  title: label.isNotEmpty ? label : 'Option',
                  rows: [
                    if (imageUrl.isNotEmpty)
                      DetailRow(label: 'Image', value: imageUrl),
                    DetailRow(
                      label: 'Correct',
                      value: isCorrect ? 'Yes' : 'No',
                    ),
                  ],
                );
              }
              return DetailRow(label: 'Option', value: option.toString());
            },
          ),
      ],
    );
  }

  Widget _buildBlending(BuildContext context, Map<String, dynamic> config) {
    final instruction = config['instruction'];
    final instrAudio = config['instruction_audio_url'];
    final examples = config['examples'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (instruction is String && instruction.isNotEmpty)
          DetailRow(label: 'Instruction', value: instruction),
        if (instrAudio is String && instrAudio.isNotEmpty)
          DetailRow(label: 'Instruction Audio', value: instrAudio),
        if (examples is List && examples.isNotEmpty)
          ItemsList(
            label: 'Examples',
            items: examples,
            itemBuilder: (ex) {
              if (ex is! Map) {
                return DetailRow(label: 'Example', value: ex.toString());
              }
              final word = ex['word']?.toString() ?? '';
              final wordAudioUrl =
                  ex['word_audio_url']?.toString() ??
                  ex['audio_url']?.toString() ??
                  '';
              final phonemes = ex['phonemes'];
              return KeyValueGroup(
                title: word.isNotEmpty ? word : 'Example',
                rows: [
                  if (wordAudioUrl.isNotEmpty)
                    DetailRow(label: 'Word Audio', value: wordAudioUrl),
                  if (phonemes is List && phonemes.isNotEmpty)
                    DetailRow(
                      label: 'Phonemes',
                      value: phonemes
                          .whereType<Map>()
                          .map(
                            (p) =>
                                '${p['label']}${p['highlighted'] == true ? '*' : ''}',
                          )
                          .join(' '),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildSoundDiscrimination(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final titleAudio = config['title_audio_url'];
    final targetSound = config['target_sound'];
    final referenceWord = config['reference_word'];
    final tipText = config['tip_text'];
    final items = config['items'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titleAudio is String && titleAudio.isNotEmpty)
          DetailRow(label: 'Title Audio', value: titleAudio),
        if (targetSound is String && targetSound.isNotEmpty)
          DetailRow(label: 'Target Sound', value: targetSound),
        if (referenceWord is String && referenceWord.isNotEmpty)
          DetailRow(label: 'Reference Word', value: referenceWord),
        if (tipText is String && tipText.isNotEmpty)
          DetailRow(label: 'Tip', value: tipText),
        if (items is List && items.isNotEmpty)
          ItemsList(
            label: 'Items',
            items: items,
            itemBuilder: (item) {
              if (item is! Map) {
                return DetailRow(label: 'Item', value: item.toString());
              }
              final title = item['title']?.toString() ?? '';
              final itemAudio = item['title_audio_url']?.toString() ?? '';
              final imageUrl = item['image_url']?.toString() ?? '';
              final containsTargetSound = item['contains_target_sound'] == true;
              final highlightedText =
                  item['highlighted_text']?.toString() ?? '';
              return KeyValueGroup(
                title: title.isNotEmpty ? title : 'Item',
                rows: [
                  if (itemAudio.isNotEmpty)
                    DetailRow(label: 'Audio', value: itemAudio),
                  if (imageUrl.isNotEmpty)
                    DetailRow(label: 'Image', value: imageUrl),
                  DetailRow(
                    label: 'Contains Target Sound',
                    value: containsTargetSound ? 'Yes' : 'No',
                  ),
                  if (highlightedText.isNotEmpty)
                    DetailRow(
                      label: 'Highlighted Text',
                      value: highlightedText,
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildSoundItemMatching(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final activities = config['activities'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activities is List && activities.isNotEmpty)
          ItemsList(
            label: 'Activities',
            items: activities,
            itemBuilder: (activity) {
              if (activity is! Map) {
                return DetailRow(label: 'Activity', value: activity.toString());
              }
              final prompt = activity['prompt']?.toString() ?? '';
              final promptAudio =
                  activity['prompt_audio_url']?.toString() ?? '';
              final contentAudio =
                  activity['content_audio_url']?.toString() ?? '';
              final tipText = activity['tip_text']?.toString() ?? '';
              final targetSound = activity['target_sound']?.toString() ?? '';
              final options = activity['options'];
              return KeyValueGroup(
                title: prompt.isNotEmpty ? prompt : 'Activity',
                rows: [
                  if (promptAudio.isNotEmpty)
                    DetailRow(label: 'Prompt Audio', value: promptAudio),
                  if (contentAudio.isNotEmpty)
                    DetailRow(label: 'Content Audio', value: contentAudio),
                  if (tipText.isNotEmpty)
                    DetailRow(label: 'Tip', value: tipText),
                  if (targetSound.isNotEmpty)
                    DetailRow(label: 'Target Sound', value: targetSound),
                  if (options is List && options.isNotEmpty)
                    DetailRow(
                      label: 'Options',
                      value: options
                          .whereType<Map>()
                          .map(
                            (option) =>
                                '${option['label']}${option['is_correct'] == true ? ' *' : ''}',
                          )
                          .join(', '),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildGuidedReading(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final activities = config['activities'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activities is List && activities.isNotEmpty)
          ItemsList(
            label: 'Activities',
            items: activities,
            itemBuilder: (activity) {
              if (activity is! Map) {
                return DetailRow(label: 'Activity', value: activity.toString());
              }
              final instructionText =
                  activity['instruction_text']?.toString() ?? '';
              final instructionAudio =
                  activity['instruction_audio_url']?.toString() ?? '';
              final wordText = activity['word_text']?.toString() ?? '';
              final wordAudio = activity['word_audio_url']?.toString() ?? '';
              final segments = activity['segments'];
              return KeyValueGroup(
                title: wordText.isNotEmpty ? wordText : 'Activity',
                rows: [
                  if (instructionText.isNotEmpty)
                    DetailRow(label: 'Instruction', value: instructionText),
                  if (instructionAudio.isNotEmpty)
                    DetailRow(
                      label: 'Instruction Audio',
                      value: instructionAudio,
                    ),
                  if (wordAudio.isNotEmpty)
                    DetailRow(label: 'Word Audio', value: wordAudio),
                  if (segments is List && segments.isNotEmpty)
                    DetailRow(
                      label: 'Segments',
                      value: segments
                          .whereType<Map>()
                          .map(
                            (segment) =>
                                '${segment['phoneme_label']} -> ${segment['grapheme']}${segment['is_focus'] == true ? ' *' : ''}',
                          )
                          .join(', '),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildPracticeGame(BuildContext context, Map<String, dynamic> config) {
    final instructionText = config['instruction_text'];
    final instructionAudio = config['instruction_audio_url'];
    final targetSound = config['target_sound'];
    final durationSeconds = config['duration_seconds'];
    final passingScore = config['passing_score'];
    final options = config['options'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (instructionText is String && instructionText.isNotEmpty)
          DetailRow(label: 'Instruction', value: instructionText),
        if (instructionAudio is String && instructionAudio.isNotEmpty)
          DetailRow(label: 'Instruction Audio', value: instructionAudio),
        if (targetSound is String && targetSound.isNotEmpty)
          DetailRow(label: 'Target Sound', value: targetSound),
        if (durationSeconds != null)
          DetailRow(label: 'Duration', value: '$durationSeconds seconds'),
        if (passingScore != null)
          DetailRow(label: 'Passing Score', value: passingScore.toString()),
        if (options is List && options.isNotEmpty)
          ItemsList(
            label: 'Options',
            items: options,
            itemBuilder: (option) {
              if (option is! Map) {
                return DetailRow(label: 'Option', value: option.toString());
              }
              final title = option['title']?.toString() ?? '';
              final imageUrl = option['image_url']?.toString() ?? '';
              final audioUrl = option['audio_url']?.toString() ?? '';
              final isCorrect = option['is_correct'] == true;
              return KeyValueGroup(
                title: title.isNotEmpty ? title : 'Option',
                rows: [
                  if (imageUrl.isNotEmpty)
                    DetailRow(label: 'Image', value: imageUrl),
                  if (audioUrl.isNotEmpty)
                    DetailRow(label: 'Audio', value: audioUrl),
                  DetailRow(label: 'Correct', value: isCorrect ? 'Yes' : 'No'),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildSoundPresenceCheck(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final questions = config['questions'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (questions is List && questions.isNotEmpty)
          ItemsList(
            label: 'Questions',
            items: questions,
            itemBuilder: (question) {
              if (question is! Map) {
                return DetailRow(label: 'Question', value: question.toString());
              }
              final prompt = question['prompt']?.toString() ?? '';
              final promptAudio =
                  question['prompt_audio_url']?.toString() ?? '';
              final wordText = question['word_text']?.toString() ?? '';
              final wordAudio = question['word_audio_url']?.toString() ?? '';
              final targetSound = question['target_sound']?.toString() ?? '';
              final correctAnswer = question['correct_answer'] == true;
              final yesLabel = question['yes_label']?.toString() ?? '';
              final noLabel = question['no_label']?.toString() ?? '';
              return KeyValueGroup(
                title: prompt.isNotEmpty ? prompt : 'Question',
                rows: [
                  if (promptAudio.isNotEmpty)
                    DetailRow(label: 'Prompt Audio', value: promptAudio),
                  if (wordText.isNotEmpty)
                    DetailRow(label: 'Word Text', value: wordText),
                  if (wordAudio.isNotEmpty)
                    DetailRow(label: 'Word Audio', value: wordAudio),
                  if (targetSound.isNotEmpty)
                    DetailRow(label: 'Target Sound', value: targetSound),
                  if (yesLabel.isNotEmpty)
                    DetailRow(label: 'Yes Label', value: yesLabel),
                  if (noLabel.isNotEmpty)
                    DetailRow(label: 'No Label', value: noLabel),
                  DetailRow(
                    label: 'Correct Answer',
                    value: correctAnswer ? 'Yes' : 'No',
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildMissingLetters(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final instructionText = config['instruction_text'];
    final instructionAudio = config['instruction_audio_url'];
    final activities = config['activities'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (instructionText is String && instructionText.isNotEmpty)
          DetailRow(label: 'Instruction', value: instructionText),
        if (instructionAudio is String && instructionAudio.isNotEmpty)
          DetailRow(label: 'Instruction Audio', value: instructionAudio),
        if (activities is List && activities.isNotEmpty)
          ItemsList(
            label: 'Activities',
            items: activities,
            itemBuilder: (activity) {
              if (activity is! Map) {
                return DetailRow(label: 'Activity', value: activity.toString());
              }
              final promptText = activity['prompt_text']?.toString() ?? '';
              final targetWord = activity['target_word']?.toString() ?? '';
              final answerTemplate = activity['answer_template'];
              final options = activity['options'];
              return KeyValueGroup(
                title: promptText.isNotEmpty ? promptText : 'Activity',
                rows: [
                  if (targetWord.isNotEmpty)
                    DetailRow(label: 'Target Word', value: targetWord),
                  if (answerTemplate is List && answerTemplate.isNotEmpty)
                    DetailRow(
                      label: 'Answer Template',
                      value: answerTemplate
                          .whereType<Map>()
                          .map((item) => '${item['value']} (${item['kind']})')
                          .join(', '),
                    ),
                  if (options is List && options.isNotEmpty)
                    DetailRow(
                      label: 'Options',
                      value: options
                          .map((option) => option.toString())
                          .join(', '),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildMatchingWords(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final instructionAudio = config['instruction_audio_url'];
    final activities = config['activities'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (instructionAudio is String && instructionAudio.isNotEmpty)
          DetailRow(label: 'Instruction Audio', value: instructionAudio),
        if (activities is List && activities.isNotEmpty)
          ItemsList(
            label: 'Activities',
            items: activities,
            itemBuilder: (activity) {
              if (activity is! Map) {
                return DetailRow(label: 'Activity', value: activity.toString());
              }
              final mode = activity['mode']?.toString() ?? '';
              final promptText = activity['prompt_text']?.toString() ?? '';
              final promptAudio =
                  activity['prompt_audio_url']?.toString() ?? '';
              final promptImage =
                  activity['prompt_image_url']?.toString() ?? '';
              final correctOptionId =
                  activity['correct_option_id']?.toString() ?? '';
              final options = activity['options'];
              return KeyValueGroup(
                title: promptText.isNotEmpty ? promptText : 'Activity',
                rows: [
                  if (mode.isNotEmpty) DetailRow(label: 'Mode', value: mode),
                  if (promptAudio.isNotEmpty)
                    DetailRow(label: 'Prompt Audio', value: promptAudio),
                  if (promptImage.isNotEmpty)
                    DetailRow(label: 'Prompt Image', value: promptImage),
                  if (correctOptionId.isNotEmpty)
                    DetailRow(
                      label: 'Correct Option ID',
                      value: correctOptionId,
                    ),
                  if (options is List && options.isNotEmpty)
                    DetailRow(
                      label: 'Options',
                      value: options
                          .whereType<Map>()
                          .map((option) {
                            final id = option['id']?.toString() ?? '';
                            final label = option['label']?.toString() ?? '';
                            final imageUrl =
                                option['image_url']?.toString() ?? '';
                            final base = label.isNotEmpty ? '$id: $label' : id;
                            return imageUrl.isNotEmpty ? '$base [image]' : base;
                          })
                          .join(', '),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildWordReading(BuildContext context, Map<String, dynamic> config) {
    final instructionAudio = config['instruction_audio_url'];
    final items = config['items'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (instructionAudio is String && instructionAudio.isNotEmpty)
          DetailRow(label: 'Instruction Audio', value: instructionAudio),
        if (items is List && items.isNotEmpty)
          ItemsList(
            label: 'Items',
            items: items,
            itemBuilder: (item) {
              if (item is! Map) {
                return DetailRow(label: 'Item', value: item.toString());
              }
              final word = item['word']?.toString() ?? '';
              final imageUrl = item['image_url']?.toString() ?? '';
              final wordAudio = item['word_audio_url']?.toString() ?? '';
              final modelReadingLabel =
                  item['model_reading_label']?.toString() ?? '';
              final segments = item['segments'];
              return KeyValueGroup(
                title: word.isNotEmpty ? word : 'Item',
                rows: [
                  if (imageUrl.isNotEmpty)
                    DetailRow(label: 'Image', value: imageUrl),
                  if (wordAudio.isNotEmpty)
                    DetailRow(label: 'Word Audio', value: wordAudio),
                  if (modelReadingLabel.isNotEmpty)
                    DetailRow(
                      label: 'Model Reading Label',
                      value: modelReadingLabel,
                    ),
                  if (segments is List && segments.isNotEmpty)
                    DetailRow(
                      label: 'Segments',
                      value: segments
                          .whereType<Map>()
                          .map(
                            (segment) =>
                                '${segment['label']}${segment['highlighted'] == true ? ' *' : ''}',
                          )
                          .join(', '),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildSentenceReading(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final instructionAudio = config['instruction_audio_url'];
    final items = config['items'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (instructionAudio is String && instructionAudio.isNotEmpty)
          DetailRow(label: 'Instruction Audio', value: instructionAudio),
        if (items is List && items.isNotEmpty)
          ItemsList(
            label: 'Items',
            items: items,
            itemBuilder: (item) {
              if (item is! Map) {
                return DetailRow(label: 'Item', value: item.toString());
              }
              final sentenceText = item['sentence_text']?.toString() ?? '';
              final displayTokens = item['display_tokens'];
              final sentenceAudio =
                  item['sentence_audio_url']?.toString() ?? '';
              final selfReadLabel = item['self_read_label']?.toString() ?? '';
              return KeyValueGroup(
                title: sentenceText.isNotEmpty ? sentenceText : 'Item',
                rows: [
                  if (displayTokens is List && displayTokens.isNotEmpty)
                    DetailRow(
                      label: 'Display Tokens',
                      value: displayTokens
                          .map((token) => token.toString())
                          .join(', '),
                    ),
                  if (sentenceAudio.isNotEmpty)
                    DetailRow(label: 'Sentence Audio', value: sentenceAudio),
                  if (selfReadLabel.isNotEmpty)
                    DetailRow(label: 'Self Read Label', value: selfReadLabel),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildMiniStoryCard(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
    final instructionAudio = config['instruction_audio_url'];
    final items = config['items'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (instructionAudio is String && instructionAudio.isNotEmpty)
          DetailRow(label: 'Instruction Audio', value: instructionAudio),
        if (items is List && items.isNotEmpty)
          ItemsList(
            label: 'Items',
            items: items,
            itemBuilder: (item) {
              if (item is! Map) {
                return DetailRow(label: 'Item', value: item.toString());
              }
              final heading = item['heading']?.toString() ?? '';
              final headingAudio = item['heading_audio_url']?.toString() ?? '';
              final bodyLines = item['body_lines'];
              final storyAudio = item['story_audio_url']?.toString() ?? '';
              final ctaLabel = item['cta_label']?.toString() ?? '';
              return KeyValueGroup(
                title: heading.isNotEmpty ? heading : 'Item',
                rows: [
                  if (headingAudio.isNotEmpty)
                    DetailRow(label: 'Heading Audio', value: headingAudio),
                  if (bodyLines is List && bodyLines.isNotEmpty)
                    DetailRow(
                      label: 'Body Lines',
                      value: bodyLines
                          .map((line) => line.toString())
                          .join(' | '),
                    ),
                  if (storyAudio.isNotEmpty)
                    DetailRow(label: 'Story Audio', value: storyAudio),
                  if (ctaLabel.isNotEmpty)
                    DetailRow(label: 'CTA Label', value: ctaLabel),
                ],
              );
            },
          ),
      ],
    );
  }
}

class ItemsList extends StatelessWidget {
  const ItemsList({
    super.key,
    required this.label,
    required this.items,
    required this.itemBuilder,
  });

  final String label;
  final List items;
  final Widget Function(dynamic item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 6),
        Column(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: itemBuilder(item),
              ),
          ],
        ),
      ],
    );
  }
}

class KeyValueGroup extends StatelessWidget {
  const KeyValueGroup({super.key, required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class AudioDetails extends StatelessWidget {
  const AudioDetails({super.key, required this.audio});

  final Map audio;

  @override
  Widget build(BuildContext context) {
    final baseUrl = audio['base_url'];
    final speed = audio['speed_variants'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (baseUrl is String && baseUrl.isNotEmpty)
          DetailRow(label: 'Audio Base', value: baseUrl),
        if (speed is Map && speed.isNotEmpty)
          DetailRow(
            label: 'Audio Speeds',
            value: speed.entries.map((e) => '${e.key}: ${e.value}').join(', '),
          ),
      ],
    );
  }
}

class PracticeTipDetails extends StatelessWidget {
  const PracticeTipDetails({super.key, required this.tip});

  final Map tip;

  @override
  Widget build(BuildContext context) {
    final text = tip['text'];
    final audioUrl = tip['audio_url'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text is String && text.isNotEmpty)
          DetailRow(label: 'Practice Tip', value: text),
        if (audioUrl is String && audioUrl.isNotEmpty)
          DetailRow(label: 'Tip Audio', value: audioUrl),
      ],
    );
  }
}

class TipDetails extends StatelessWidget {
  const TipDetails({super.key, required this.tip});

  final Map tip;

  @override
  Widget build(BuildContext context) {
    final text = tip['text'];
    final soundUrl = tip['sound_url'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text is String && text.isNotEmpty)
          DetailRow(label: 'Tip Text', value: text),
        if (soundUrl is String && soundUrl.isNotEmpty)
          DetailRow(label: 'Tip Sound', value: soundUrl),
      ],
    );
  }
}
