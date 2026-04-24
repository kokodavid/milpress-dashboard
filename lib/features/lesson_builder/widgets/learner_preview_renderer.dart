import 'package:flutter/material.dart';

import '../../content/widgets/lesson_steps/step_drafts.dart';
import '../../lesson_v2/lesson_v2_models.dart';

// ── App colour constants (mirrors mobile AppColors) ───────────────────────────
const Color _kPrimary   = Color(0xFFE85D04);
const Color _kCopBlue   = Color(0xFF142C44);
const Color _kText      = Color(0xFF727272);
const Color _kDark      = Color(0xFF171B22);
const Color _kBorder    = Color(0xFFF4F4F4);
const Color _kSuccess   = Color(0xFF73BE4F);
const Color _kError     = Color(0xFFF3473E);
const Color _kCardBg    = Color(0xFFF6F6F6);
const Color _kLightOrange = Color(0xFFFAEDE6);
const Color _kAccent    = Color(0x29E85D04);

/// Renders a simplified, non-pixel-perfect visual preview of a [StepDraft]
/// as a learner would see it on the mobile app.
///
/// Each step type gets its own private widget. Unimplemented types fall back
/// to [_GenericPreview].
class LearnerPreviewRenderer extends StatelessWidget {
  const LearnerPreviewRenderer({super.key, required this.draft});

  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    if (draft.customStepType != null) {
      return _GenericPreview(
        label: draft.customStepType!.displayName,
        icon: Icons.extension,
      );
    }
    return switch (draft.stepType) {
      LessonStepType.introduction     => _IntroductionPreview(draft: draft),
      LessonStepType.demonstration    => _DemonstrationPreview(draft: draft),
      LessonStepType.blending         => _BlendingPreview(draft: draft),
      LessonStepType.practice         => _PracticePreview(draft: draft),
      LessonStepType.assessment       => _AssessmentPreview(draft: draft),
      LessonStepType.soundDiscrimination => _SoundDiscriminationPreview(draft: draft),
      LessonStepType.guidedReading    => _GuidedReadingPreview(draft: draft),
      LessonStepType.missingLetters   => _MissingLettersPreview(draft: draft),
      LessonStepType.practiceGame     => _PracticeGamePreview(draft: draft),
      LessonStepType.matchingWords    => _MatchingWordsPreview(draft: draft),
      LessonStepType.soundItemMatching => _SoundItemMatchingPreview(draft: draft),
      LessonStepType.soundPresenceCheck => _SoundPresenceCheckPreview(draft: draft),
      LessonStepType.wordReading      => _WordReadingPreview(draft: draft),
      LessonStepType.sentenceReading  => _SentenceReadingPreview(draft: draft),
      LessonStepType.miniStoryCard    => _MiniStoryCardPreview(draft: draft),
    };
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Step-type preview widgets
// ══════════════════════════════════════════════════════════════════════════════

// ── Introduction ─────────────────────────────────────────────────────────────
class _IntroductionPreview extends StatelessWidget {
  const _IntroductionPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title       = draft.titleCtrl.text.trim();
    final displayText = draft.displayTextCtrl.text.trim();
    final tipText     = draft.practiceTipTextCtrl.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepTitle(title.isNotEmpty ? title : 'Introduction'),
          const SizedBox(height: 12),
          _StepCard(
            child: Column(
              children: [
                _CircularPlayStub(size: 44),
                const SizedBox(height: 10),
                if (displayText.isNotEmpty) ...[
                  Text(
                    displayText,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w800,
                      color: _kPrimary,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                // "How to make this sound" card
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF0EBE4)),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_outline, color: _kText, size: 28),
                        SizedBox(height: 6),
                        Text(
                          'How to make this sound',
                          style: TextStyle(
                            fontSize: 11,
                            color: _kText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (tipText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _TipBanner(text: tipText),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Demonstration ─────────────────────────────────────────────────────────────
class _DemonstrationPreview extends StatelessWidget {
  const _DemonstrationPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title   = draft.titleCtrl.text.trim();
    final imgUrls = draft.imageUrlCtrls.map((c) => c.text.trim()).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepTitle(title.isNotEmpty ? title : 'Demonstration'),
          const SizedBox(height: 12),
          // SVG tab row
          if (imgUrls.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < imgUrls.length && i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _SvgTabStub(label: 'Step ${i + 1}'),
                ],
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SvgTabStub(label: 'Step 1'),
                const SizedBox(width: 10),
                _SvgTabStub(label: 'Step 2'),
              ],
            ),
          const SizedBox(height: 14),
          // Drawing canvas area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _kAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Tracing canvas',
                      style: TextStyle(fontSize: 12, color: _kText),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 52,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _kCopBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_fix_high, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Blending ──────────────────────────────────────────────────────────────────
class _BlendingPreview extends StatelessWidget {
  const _BlendingPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title       = draft.titleCtrl.text.trim();
    final instruction = draft.instructionCtrl.text.trim();
    final examples    = draft.blendingExamples;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            _StepTitle(title),
            const SizedBox(height: 8),
          ],
          _StepCard(
            child: Column(
              children: [
                _ProgressBar(current: 1, total: examples.isEmpty ? 1 : examples.length),
                const SizedBox(height: 14),
                _CircularPlayStub(size: 44),
                const SizedBox(height: 8),
                if (instruction.isNotEmpty)
                  Text(
                    instruction,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _kDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 14),
                // Phoneme row
                if (examples.isNotEmpty) _PhonemeRowPreview(example: examples.first)
                else _PhonemeRowPreview(example: null),
                const SizedBox(height: 12),
                _ChevronDown(),
                const SizedBox(height: 12),
                // Blend button (outlined orange)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      backgroundColor: _kPrimary.withOpacity(0.06),
                      side: const BorderSide(color: _kPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Blend',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Practice ──────────────────────────────────────────────────────────────────
class _PracticePreview extends StatelessWidget {
  const _PracticePreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title   = draft.titleCtrl.text.trim();
    final items   = draft.practiceItems;
    final tipText = draft.tipTextCtrl.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepTitle(title.isNotEmpty ? title : 'Practice'),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _PlaceholderBox(label: 'Add practice items to preview')
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: items.take(4).map((item) {
                final label = item.labelCtrl.text.trim();
                final highlight = item.highlightedLettersCtrl.text.trim();
                return _PracticeCardStub(label: label, highlight: highlight);
              }).toList(),
            ),
          const SizedBox(height: 12),
          _TipBanner(text: tipText.isNotEmpty ? tipText : 'Say each word out loud after hearing it.'),
        ],
      ),
    );
  }
}

// ── Assessment ────────────────────────────────────────────────────────────────
class _AssessmentPreview extends StatelessWidget {
  const _AssessmentPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title   = draft.titleCtrl.text.trim();
    final prompt  = draft.promptCtrl.text.trim();
    final options = draft.assessmentOptions;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepTitle(title.isNotEmpty ? title : 'Assessment'),
          const SizedBox(height: 10),
          // Audio inline with prompt
          Row(
            children: [
              _MiniPlayButton(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  prompt.isNotEmpty ? prompt : 'Choose the correct answers',
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (options.isEmpty)
            _PlaceholderBox(label: 'Add options to preview')
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.82,
              children: options.take(6).map((opt) {
                return _AssessmentCardStub(
                  label: opt.labelCtrl.text.trim(),
                  isCorrect: opt.isCorrect,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ── Sound Discrimination ──────────────────────────────────────────────────────
class _SoundDiscriminationPreview extends StatelessWidget {
  const _SoundDiscriminationPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title       = draft.titleCtrl.text.trim();
    final targetSound = draft.targetSoundCtrl.text.trim();
    final instruction = draft.soundDiscriminationInstructionCtrl.text.trim();
    final tipText     = draft.soundDiscriminationTipCtrl.text.trim();
    final refWord     = draft.referenceWordCtrl.text.trim();
    final items       = draft.soundDiscriminationItems;
    final firstItem   = items.isNotEmpty ? items.first : null;

    final tipDisplay = tipText.isNotEmpty
        ? (refWord.isNotEmpty && !tipText.contains(refWord)
            ? '$tipText, like in "$refWord".'
            : tipText)
        : (refWord.isNotEmpty ? 'Listen for the sound, like in "$refWord".' : 'Listen carefully');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(title.isNotEmpty ? title : 'Sound Discrimination'),
          const SizedBox(height: 12),
          _StepCard(
            borderRadius: 28,
            child: Column(
              children: [
                _ProgressBar(current: 1, total: items.isEmpty ? 1 : items.length),
                const SizedBox(height: 14),
                _CircularPlayStub(size: 40),
                if (instruction.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    instruction,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _kDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                // PromptCard — 194px wide
                Center(
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFF4F1EC)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.image_outlined, color: _kText, size: 36),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          firstItem?.titleCtrl.text.trim().isNotEmpty == true
                              ? firstItem!.titleCtrl.text.trim()
                              : 'word',
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: _kDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MiniPlayButton(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ChevronDown(color: _kCopBlue),
                const SizedBox(height: 8),
                _TipBanner(text: tipDisplay),
                const SizedBox(height: 12),
                // Yes / No buttons
                Row(
                  children: [
                    Expanded(
                      child: _AnswerButton(
                        label: targetSound.isNotEmpty
                            ? 'Yes, /${targetSound}/'
                            : 'Yes',
                        color: _kSuccess,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AnswerButton(
                        label: targetSound.isNotEmpty
                            ? 'No, Not /${targetSound}/'
                            : 'No',
                        color: _kError,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Guided Reading ────────────────────────────────────────────────────────────
class _GuidedReadingPreview extends StatelessWidget {
  const _GuidedReadingPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title      = draft.titleCtrl.text.trim();
    final activities = draft.guidedReadingActivities;
    final act        = activities.isNotEmpty ? activities.first : null;
    final instruction = act?.instructionTextCtrl.text.trim() ?? '';
    final wordText    = act?.wordTextCtrl.text.trim() ?? '';
    final segments    = act?.segments ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(title.isNotEmpty ? title : 'Guided Reading',
              fontSize: 18, fontWeight: FontWeight.w700),
          const SizedBox(height: 12),
          _StepCard(
            borderRadius: 24,
            child: Column(
              children: [
                _ProgressBar(current: 1, total: activities.isEmpty ? 1 : activities.length),
                const SizedBox(height: 14),
                _CircularPlayStub(size: 44),
                const SizedBox(height: 10),
                if (instruction.isNotEmpty) ...[
                  Text(
                    instruction,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _kDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                ],
                // Segment chips row
                if (segments.isNotEmpty)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    children: segments.take(6).map((seg) {
                      final grapheme = seg.graphemeCtrl.text.trim();
                      final isFocus  = seg.isFocus;
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isFocus ? _kLightOrange : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isFocus ? _kPrimary : const Color(0xFFD9D0C7),
                            width: isFocus ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          grapheme.isNotEmpty ? grapheme : '·',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isFocus ? _kPrimary : _kDark,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    children: ['c', 'a', 't'].map((l) => Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: l == 'a' ? _kLightOrange : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: l == 'a' ? _kPrimary : const Color(0xFFD9D0C7),
                          width: l == 'a' ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(l, style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: l == 'a' ? _kPrimary : _kDark,
                      )),
                    )).toList(),
                  ),
                const SizedBox(height: 12),
                // Word text with focus grapheme highlighted in orange
                if (wordText.isNotEmpty)
                  Text(
                    wordText,
                    style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: _kDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 10),
                _ChevronDown(color: _kPrimary),
                const SizedBox(height: 10),
                _WaveformStub(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Missing Letters ───────────────────────────────────────────────────────────
class _MissingLettersPreview extends StatelessWidget {
  const _MissingLettersPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title       = draft.titleCtrl.text.trim();
    final instruction = draft.missingLettersInstructionCtrl.text.trim();
    final activities  = draft.missingLettersActivities;
    final act         = activities.isNotEmpty ? activities.first : null;
    final promptText  = act?.promptTextCtrl.text.trim() ?? '';
    final template    = act?.answerTemplate ?? [];
    final options     = act?.options ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            _StepTitle(title),
            const SizedBox(height: 8),
          ],
          _StepCard(
            borderRadius: 24,
            child: Column(
              children: [
                _ProgressBar(current: 1, total: activities.isEmpty ? 1 : activities.length),
                const SizedBox(height: 16),
                // Instruction section
                _CircularPlayStub(size: 44),
                const SizedBox(height: 8),
                if (instruction.isNotEmpty) ...[
                  Text(instruction, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _kDark,
                  ), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                ],
                Text(
                  'Make "${promptText.isNotEmpty ? promptText : 'cat'}"',
                  style: const TextStyle(fontSize: 13, color: _kText),
                ),
                const SizedBox(height: 16),
                // Slot row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: template.isNotEmpty
                      ? template.map((item) {
                          final value   = item.valueCtrl.text.trim();
                          final isGiven = item.kind == 'given';
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _SlotTileStub(value: value, isGiven: isGiven),
                          );
                        }).toList()
                      : ['c', '', 't'].map((l) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _SlotTileStub(value: l, isGiven: l.isNotEmpty),
                        )).toList(),
                ),
                const SizedBox(height: 10),
                _ChevronDown(),
                const SizedBox(height: 8),
                const Text(
                  'Selects missing letter',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kCopBlue),
                ),
                const SizedBox(height: 12),
                // Option grid — rows of 3
                if (options.isNotEmpty) ...[
                  ...() {
                    final rows = <Widget>[];
                    for (var i = 0; i < options.length; i += 3) {
                      final end = (i + 3).clamp(0, options.length);
                      rows.add(
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(end - i, (j) {
                              final opt = options[i + j].text.trim();
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _LetterOptionButton(letter: opt.isNotEmpty ? opt : '?'),
                              );
                            }),
                          ),
                        ),
                      );
                    }
                    return rows;
                  }(),
                ] else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['a', 'e', 'i'].map((l) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _LetterOptionButton(letter: l),
                    )).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Practice Game ─────────────────────────────────────────────────────────────
class _PracticeGamePreview extends StatelessWidget {
  const _PracticeGamePreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title        = draft.titleCtrl.text.trim();
    final instruction  = draft.practiceGameInstructionCtrl.text.trim();
    final targetSound  = draft.practiceGameTargetSoundCtrl.text.trim();
    final duration     = draft.practiceGameDurationCtrl.text.trim();
    final passingScore = draft.practiceGamePassingScoreCtrl.text.trim();
    final options      = draft.practiceGameOptions;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepTitle(title.isNotEmpty ? title : 'Practice Game'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _kBorder),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instruction area
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CircularPlayStub(size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            instruction.isNotEmpty ? instruction : 'Tap words with this sound',
                            style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: _kDark,
                            ),
                          ),
                          if (targetSound.isNotEmpty)
                            Text(
                              '/$targetSound/',
                              style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Stat chips
                Row(
                  children: [
                    _StatChip(icon: Icons.timer_outlined,
                        label: duration.isNotEmpty ? '${duration}s' : '60s'),
                    const SizedBox(width: 8),
                    _StatChip(icon: Icons.star_outline, label: '0'),
                  ],
                ),
                const SizedBox(height: 14),
                // 3-col option grid
                if (options.isEmpty)
                  _PlaceholderBox(label: 'Add options to preview')
                else
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.73,
                    children: options.take(6).map((opt) {
                      return _GameOptionCard(
                        label: opt.titleCtrl.text.trim(),
                        isCorrect: opt.isCorrect,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Matching Words ────────────────────────────────────────────────────────────
class _MatchingWordsPreview extends StatelessWidget {
  const _MatchingWordsPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title      = draft.titleCtrl.text.trim();
    final activities = draft.matchingWordsActivities;
    final act        = activities.isNotEmpty ? activities.first : null;
    final promptText = act?.promptTextCtrl.text.trim() ?? '';
    final options    = act?.options ?? [];
    final mode       = act?.mode ?? 'sound_to_image';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(title.isNotEmpty ? title : 'Matching Words'),
          const SizedBox(height: 12),
          _StepCard(
            borderRadius: 24,
            child: Column(
              children: [
                _ProgressBar(current: 1, total: activities.isEmpty ? 1 : activities.length),
                const SizedBox(height: 14),
                _CircularPlayStub(size: 52),
                const SizedBox(height: 10),
                if (promptText.isNotEmpty) ...[
                  Text(
                    promptText,
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _kDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                ],
                _ChevronDown(),
                const SizedBox(height: 10),
                // Word / image option pills
                if (options.isEmpty)
                  _PlaceholderBox(label: 'Add options to preview')
                else
                  ...options.take(4).map((opt) {
                    final label = opt.labelCtrl.text.trim();
                    final hasImage = opt.imageUrlCtrl.text.trim().isNotEmpty;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _kBorder),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasImage) ...[
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F7F7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.image_outlined, size: 16, color: _kText),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              label.isNotEmpty ? label : 'Option',
                              style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600, color: _kDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sound Item Matching ───────────────────────────────────────────────────────
class _SoundItemMatchingPreview extends StatelessWidget {
  const _SoundItemMatchingPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title      = draft.titleCtrl.text.trim();
    final activities = draft.soundItemMatchingActivities;
    final act        = activities.isNotEmpty ? activities.first : null;
    final prompt     = act?.promptCtrl.text.trim() ?? '';
    final tipText    = act?.tipCtrl.text.trim() ?? '';
    final targetSound = act?.targetSoundCtrl.text.trim() ?? '';
    final options    = act?.options ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(title.isNotEmpty ? title : 'Sound Item Matching'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _kBorder),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress + score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 / ${activities.isEmpty ? 1 : activities.length}',
                        style: const TextStyle(fontSize: 12, color: _kText)),
                    _StatChip(icon: Icons.star_outline, label: '0'),
                  ],
                ),
                const SizedBox(height: 12),
                // Prompt block
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _kCopBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        prompt.isNotEmpty ? prompt : 'Find words with this sound',
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: _kDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Double chevron
                const Column(
                  children: [
                    Icon(Icons.expand_more, size: 18, color: _kCopBlue),
                    Icon(Icons.expand_more, size: 18, color: _kCopBlue),
                  ],
                ),
                const SizedBox(height: 6),
                // Tip banner
                _TipBanner(
                  text: tipText.isNotEmpty ? tipText : 'Tap all words that match',
                  bgColor: Colors.white,
                ),
                const SizedBox(height: 12),
                // Word option buttons
                if (options.isEmpty)
                  _PlaceholderBox(label: 'Add options to preview')
                else
                  ...options.take(4).map((opt) {
                    final label = opt.labelCtrl.text.trim();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label.isNotEmpty ? label : 'word',
                          style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: _kDark,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sound Presence Check ──────────────────────────────────────────────────────
class _SoundPresenceCheckPreview extends StatelessWidget {
  const _SoundPresenceCheckPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title     = draft.titleCtrl.text.trim();
    final questions = draft.soundPresenceCheckQuestions;
    final q         = questions.isNotEmpty ? questions.first : null;
    final prompt    = q?.promptCtrl.text.trim() ?? '';
    final wordText  = q?.wordTextCtrl.text.trim() ?? '';
    final yesLabel  = q?.yesLabelCtrl.text.trim() ?? 'Yes';
    final noLabel   = q?.noLabelCtrl.text.trim() ?? 'No';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title.isNotEmpty) ...[
            _StepTitle(title),
            const SizedBox(height: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _kBorder),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProgressBar(current: 1, total: questions.isEmpty ? 1 : questions.length),
                const SizedBox(height: 14),
                Text(
                  prompt.isNotEmpty ? prompt : 'Does this word have the sound?',
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _kDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                if (wordText.isNotEmpty)
                  Text(
                    wordText,
                    style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: _kDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 14),
                // CopBlue circular audio
                Center(
                  child: Container(
                    width: 52, height: 52,
                    decoration: const BoxDecoration(color: _kCopBlue, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(height: 12),
                _ChevronDown(color: const Color(0xFF8A8A8A)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _RoundedAnswerButton(label: yesLabel, color: _kSuccess)),
                    const SizedBox(width: 10),
                    Expanded(child: _RoundedAnswerButton(label: noLabel, color: _kError)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Word Reading ──────────────────────────────────────────────────────────────
class _WordReadingPreview extends StatelessWidget {
  const _WordReadingPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title      = draft.titleCtrl.text.trim();
    final items      = draft.wordReadingItems;
    final firstItem  = items.isNotEmpty ? items.first : null;
    final word       = firstItem?.wordCtrl.text.trim() ?? '';
    final modelLabel = firstItem?.modelReadingLabelCtrl.text.trim() ?? '';
    final segments   = firstItem?.segments ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(title.isNotEmpty ? title : 'Word Reading'),
          const SizedBox(height: 12),
          _StepCard(
            borderRadius: 24,
            child: Column(
              children: [
                _ProgressBar(current: 1, total: items.isEmpty ? 1 : items.length),
                const SizedBox(height: 14),
                _CircularPlayStub(size: 44),
                const SizedBox(height: 14),
                // Word card — 196px wide
                Center(
                  child: Container(
                    width: 184,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF0EBE4)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.image_outlined, color: _kText, size: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          word.isNotEmpty ? word : 'cat',
                          style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700, color: _kDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _MiniPlayButton(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ChevronDown(),
                const SizedBox(height: 10),
                // Model reading accordion stub
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          modelLabel.isNotEmpty ? modelLabel : 'Model reading',
                          style: const TextStyle(fontSize: 13, color: _kText),
                        ),
                      ),
                      const Icon(Icons.expand_more, size: 18, color: _kText),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _NextButton(label: 'Next Word'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sentence Reading ──────────────────────────────────────────────────────────
class _SentenceReadingPreview extends StatelessWidget {
  const _SentenceReadingPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title     = draft.titleCtrl.text.trim();
    final items     = draft.sentenceReadingItems;
    final firstItem = items.isNotEmpty ? items.first : null;
    final tokens    = firstItem?.displayTokens
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList() ?? [];
    final selfReadLabel = firstItem?.selfReadLabelCtrl.text.trim() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(title.isNotEmpty ? title : 'Sentence Reading'),
          const SizedBox(height: 12),
          _StepCard(
            borderRadius: 24,
            child: Column(
              children: [
                _ProgressBar(current: 1, total: items.isEmpty ? 1 : items.length),
                const SizedBox(height: 14),
                _CircularPlayStub(size: 44),
                const SizedBox(height: 14),
                // Token row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF0EBE4)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: tokens.isNotEmpty
                        ? tokens.map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _kCardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _kBorder),
                            ),
                            child: Text(t, style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: _kDark,
                            )),
                          )).toList()
                        : ['The', 'cat', 'sat', 'on', 'the', 'mat.'].map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _kCardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _kBorder),
                            ),
                            child: Text(t, style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: _kDark,
                            )),
                          )).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                _WaveformStub(),
                const SizedBox(height: 10),
                // Self-read toggle pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Text(
                      selfReadLabel.isNotEmpty ? selfReadLabel : 'Now you read it',
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _kDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ChevronDown(color: const Color(0xFF8A8A8A)),
                const SizedBox(height: 10),
                _NextButton(label: 'Next Sentence'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Story Card ───────────────────────────────────────────────────────────
class _MiniStoryCardPreview extends StatelessWidget {
  const _MiniStoryCardPreview({required this.draft});
  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final title     = draft.titleCtrl.text.trim();
    final items     = draft.miniStoryCardItems;
    final firstItem = items.isNotEmpty ? items.first : null;
    final heading   = firstItem?.headingCtrl.text.trim() ?? '';
    final bodyLines = firstItem?.bodyLines
        .map((c) => c.text.trim())
        .where((l) => l.isNotEmpty)
        .toList() ?? [];
    final ctaLabel  = firstItem?.ctaLabelCtrl.text.trim() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(title.isNotEmpty ? title : 'Mini Story Card'),
          const SizedBox(height: 12),
          _StepCard(
            borderRadius: 24,
            child: Column(
              children: [
                _ProgressBar(current: 1, total: items.isEmpty ? 1 : items.length),
                const SizedBox(height: 14),
                _CircularPlayStub(size: 44),
                const SizedBox(height: 10),
                Text(
                  heading.isNotEmpty ? heading : 'The story heading',
                  style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: _kDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                // Story card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBorder),
                  ),
                  child: bodyLines.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: bodyLines.take(4).map((line) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(line, style: const TextStyle(
                              fontSize: 14, color: _kDark, height: 1.5,
                            )),
                          )).toList(),
                        )
                      : const Text(
                          'Story text will appear here.',
                          style: TextStyle(fontSize: 14, color: _kText, height: 1.5),
                        ),
                ),
                const SizedBox(height: 12),
                _WaveformStub(),
                const SizedBox(height: 12),
                // CTA / listen button (outlined, borderRadius 22)
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kCopBlue,
                      side: const BorderSide(color: _kCopBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Text(
                      ctaLabel.isNotEmpty ? ctaLabel : 'Listen to the sentence',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _NextButton(label: 'Next', borderRadius: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic fallback ──────────────────────────────────────────────────────────
class _GenericPreview extends StatelessWidget {
  const _GenericPreview({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: _kText),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: _kDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Preview not available',
            style: TextStyle(fontSize: 12, color: _kText),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _StepTitle extends StatelessWidget {
  const _StepTitle(
    this.text, {
    this.fontSize = 20,
    this.fontWeight = FontWeight.w600,
  });
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: _kDark),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.child, this.borderRadius = 24});
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: child,
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total, this.label = 'Word'});
  final int current;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? current / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label $current of $total',
          style: const TextStyle(fontSize: 11, color: _kText),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFDDD8D1),
            color: _kCopBlue,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _CircularPlayStub extends StatelessWidget {
  const _CircularPlayStub({this.size = 44, this.color = _kPrimary});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(Icons.play_arrow, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}

class _MiniPlayButton extends StatelessWidget {
  const _MiniPlayButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        shape: BoxShape.circle,
        border: Border.all(color: _kBorder),
      ),
      child: const Icon(Icons.play_arrow, size: 16, color: _kText),
    );
  }
}

class _WaveformStub extends StatelessWidget {
  const _WaveformStub();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.graphic_eq, size: 20, color: _kCopBlue),
          const SizedBox(width: 6),
          const Text('waveform', style: TextStyle(fontSize: 11, color: _kText)),
        ],
      ),
    );
  }
}

class _ChevronDown extends StatelessWidget {
  const _ChevronDown({this.color = const Color(0xFF8A8A8A)});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(Icons.expand_more, size: 24, color: color));
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.text, this.bgColor});
  final String text;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor ?? _kLightOrange,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPrimary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: _kDark),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: color.withOpacity(0.06),
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _RoundedAnswerButton extends StatelessWidget {
  const _RoundedAnswerButton({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: color.withOpacity(0.06),
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, this.borderRadius = 16});
  final String label;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          disabledBackgroundColor: _kPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PhonemeRowPreview extends StatelessWidget {
  const _PhonemeRowPreview({required this.example});
  final BlendingExampleDraft? example;

  @override
  Widget build(BuildContext context) {
    final phonemes = example?.phonemes ?? [];
    final items = phonemes.isNotEmpty
        ? phonemes
        : <PhonemeDraft>[];

    if (items.isEmpty) {
      // placeholder
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0EBE4)),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: ['c', 'a', 't'].map((l) =>
            _PhonemeTileStub(label: l, highlighted: l == 'a'),
          ).toList(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0EBE4)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: items.map((ph) => _PhonemeTileStub(
          label: ph.labelCtrl.text.trim(),
          highlighted: ph.highlighted,
        )).toList(),
      ),
    );
  }
}

class _PhonemeTileStub extends StatelessWidget {
  const _PhonemeTileStub({required this.label, required this.highlighted});
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 52,
      height: 38,
      decoration: BoxDecoration(
        color: highlighted ? _kPrimary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? _kPrimary : const Color(0xFFD9D0C7),
          width: highlighted ? 1.5 : 1.0,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label.isNotEmpty ? label : '?',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: highlighted ? _kPrimary : _kDark,
        ),
      ),
    );
  }
}

class _PracticeCardStub extends StatelessWidget {
  const _PracticeCardStub({required this.label, required this.highlight});
  final String label;
  final String highlight;

  @override
  Widget build(BuildContext context) {
    final idx = highlight.isNotEmpty
        ? label.toLowerCase().indexOf(highlight.toLowerCase())
        : -1;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: _kCardBg,
                child: const Center(child: Icon(Icons.image_outlined, color: _kText, size: 28)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          idx >= 0 && highlight.isNotEmpty
              ? Text.rich(TextSpan(children: [
                  if (idx > 0)
                    TextSpan(text: label.substring(0, idx),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kText)),
                  TextSpan(
                    text: label.substring(idx, idx + highlight.length),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                  if (idx + highlight.length < label.length)
                    TextSpan(
                      text: label.substring(idx + highlight.length),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kText),
                    ),
                ]))
              : Text(
                  label.isNotEmpty ? label : '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kText),
                  textAlign: TextAlign.center,
                ),
          const SizedBox(height: 4),
          SizedBox(height: 24, child: _MiniPlayButton()),
        ],
      ),
    );
  }
}

class _AssessmentCardStub extends StatelessWidget {
  const _AssessmentCardStub({required this.label, required this.isCorrect});
  final String label;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder, width: 2),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.image_outlined, color: _kText, size: 22)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.isNotEmpty ? label : '—',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kText),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SvgTabStub extends StatelessWidget {
  const _SvgTabStub({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_outlined, color: _kText, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: _kText)),
        ],
      ),
    );
  }
}

class _SlotTileStub extends StatelessWidget {
  const _SlotTileStub({required this.value, required this.isGiven});
  final String value;
  final bool isGiven;

  @override
  Widget build(BuildContext context) {
    if (isGiven) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: Text(
          value.isNotEmpty ? value : '?',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _kPrimary.withOpacity(0.5), width: 2),
      ),
      alignment: Alignment.center,
      child: Container(width: 16, height: 3,
        decoration: BoxDecoration(color: _kPrimary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

class _LetterOptionButton extends StatelessWidget {
  const _LetterOptionButton({required this.letter});
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kText),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kCopBlue),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kCopBlue)),
        ],
      ),
    );
  }
}

class _GameOptionCard extends StatelessWidget {
  const _GameOptionCard({required this.label, required this.isCorrect});
  final String label;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect ? _kSuccess.withOpacity(0.5) : _kBorder,
          width: isCorrect ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.image_outlined, color: _kText, size: 22)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.isNotEmpty ? label : '—',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kText),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          _MiniPlayButton(),
        ],
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  const _PlaceholderBox({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_outlined, size: 28, color: Colors.grey.shade300),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: _kText),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
