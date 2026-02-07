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
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (title != null && title.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
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

  Widget _buildDemonstration(BuildContext context, Map<String, dynamic> config) {
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
                    DetailRow(label: 'Correct', value: isCorrect ? 'Yes' : 'No'),
                  ],
                );
              }
              return DetailRow(label: 'Option', value: option.toString());
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
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade600),
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
  const KeyValueGroup({
    super.key,
    required this.title,
    required this.rows,
  });

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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
            value:
                speed.entries.map((e) => '${e.key}: ${e.value}').join(', '),
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
