import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lesson_builder_state.dart';
import '../lesson_builder_theme.dart';
import 'learner_preview_renderer.dart';

/// Right panel of the lesson builder.
///
/// Shows a simulated mobile/tablet device frame containing a live preview
/// of the currently selected step draft. Toggles between Phone and Tablet
/// frame sizes.
class LearnerPreviewPanel extends ConsumerStatefulWidget {
  const LearnerPreviewPanel({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<LearnerPreviewPanel> createState() =>
      _LearnerPreviewPanelState();
}

class _LearnerPreviewPanelState
    extends ConsumerState<LearnerPreviewPanel> {
  _DeviceMode _mode = _DeviceMode.phone;

  @override
  Widget build(BuildContext context) {
    final drafts = ref.watch(lessonBuilderDraftsProvider(widget.lessonId));
    final activeIndex =
        ref.watch(lessonBuilderSelectedStepProvider(widget.lessonId));

    return Column(
      children: [
        _PanelHeader(
          mode: _mode,
          onModeChanged: (m) => setState(() => _mode = m),
        ),
        const Divider(height: 1, color: LessonBuilderTheme.surfaceBorder),
        Expanded(
          child: drafts.isEmpty || activeIndex >= drafts.length
              ? const _EmptyPreview()
              : _DeviceFrame(
                  mode: _mode,
                  child: LearnerPreviewRenderer(
                    draft: drafts[activeIndex],
                  ),
                ),
        ),
        const _FooterNote(),
      ],
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

enum _DeviceMode { phone, tablet }

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.mode,
    required this.onModeChanged,
  });

  final _DeviceMode mode;
  final ValueChanged<_DeviceMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'LEARNER PREVIEW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: LessonBuilderTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          _ModeToggle(mode: mode, onChanged: onModeChanged),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _DeviceMode mode;
  final ValueChanged<_DeviceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: LessonBuilderTheme.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleSegment(
            label: 'Phone',
            icon: Icons.smartphone,
            active: mode == _DeviceMode.phone,
            onTap: () => onChanged(_DeviceMode.phone),
            isFirst: true,
          ),
          _ToggleSegment(
            label: 'Tablet',
            icon: Icons.tablet_mac,
            active: mode == _DeviceMode.tablet,
            onTap: () => onChanged(_DeviceMode.tablet),
            isFirst: false,
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    required this.isFirst,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(5) : Radius.zero,
            right: !isFirst ? const Radius.circular(5) : Radius.zero,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: active
                  ? LessonBuilderTheme.textDark
                  : LessonBuilderTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? LessonBuilderTheme.textDark
                    : LessonBuilderTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A scaled device frame (black bezel + white screen) wrapping [child].
class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({required this.mode, required this.child});

  final _DeviceMode mode;
  final Widget child;

  static const _phoneAspect = 9.0 / 19.5;
  static const _tabletAspect = 3.0 / 4.0;

  @override
  Widget build(BuildContext context) {
    final aspect =
        mode == _DeviceMode.phone ? _phoneAspect : _tabletAspect;

    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 16.0;
        final maxW = constraints.maxWidth - padding * 2;
        final maxH = constraints.maxHeight - padding * 2;

        // Fit within both axes — height is usually the bottleneck in portrait.
        double frameW = maxW;
        double frameH = frameW / aspect;
        if (frameH > maxH) {
          frameH = maxH;
          frameW = frameH * aspect;
        }

        return Center(
          child: SizedBox(
            width: frameW,
            height: frameH,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(
                  mode == _DeviceMode.phone ? 36 : 20,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.all(
                mode == _DeviceMode.phone ? 10 : 12,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  mode == _DeviceMode.phone ? 28 : 10,
                ),
                child: ColoredBox(
                  color: Colors.white,
                  child: _PhoneChrome(mode: mode, child: child),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Minimal status bar + content area + home indicator inside the frame.
class _PhoneChrome extends StatelessWidget {
  const _PhoneChrome({required this.mode, required this.child});

  final _DeviceMode mode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status bar
        Container(
          height: 24,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ProgressDots(),
              const SizedBox(),
              const Icon(Icons.signal_cellular_alt,
                  size: 12, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
        // Content
        Expanded(child: child),
        // Home indicator
        if (mode == _DeviceMode.phone)
          Container(
            height: 20,
            color: Colors.white,
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Orange progress indicator dots mimicking the lesson progress bar.
class _ProgressDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(right: 3),
          width: i == 1 ? 16 : 6,
          height: 4,
          decoration: BoxDecoration(
            color: i == 1
                ? LessonBuilderTheme.primary
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Select a step to preview',
        style: TextStyle(
          fontSize: 12,
          color: LessonBuilderTheme.textMuted,
        ),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.arrow_upward, size: 10, color: LessonBuilderTheme.textMuted),
          SizedBox(width: 4),
          Text(
            'Preview updates as you edit',
            style: TextStyle(
              fontSize: 11,
              color: LessonBuilderTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
