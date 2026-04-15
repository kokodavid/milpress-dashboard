import 'package:flutter/material.dart';

import '../../../lesson_v2/lesson_v2_models.dart';

// ── Public entry point ────────────────────────────────────────────────────────

/// Shows the step-type picker dialog and returns the chosen [LessonStepType],
/// or null if the user cancelled.
Future<LessonStepType?> showStepTypePicker({
  required BuildContext context,
  LessonStepType? initialType,
}) {
  return showDialog<LessonStepType>(
    context: context,
    builder: (_) => StepTypePickerDialog(initialType: initialType),
  );
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class StepTypePickerDialog extends StatefulWidget {
  const StepTypePickerDialog({super.key, this.initialType});

  final LessonStepType? initialType;

  @override
  State<StepTypePickerDialog> createState() => _StepTypePickerDialogState();
}

class _StepTypePickerDialogState extends State<StepTypePickerDialog> {
  static const List<String> _categoryOrder = [
    'Foundation',
    'Assessment',
    'Sound & Phonics',
    'Reading',
    'Story',
  ];

  late LessonStepType? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialType;
  }

  Map<String, List<LessonStepType>> get _grouped {
    final map = <String, List<LessonStepType>>{
      for (final c in _categoryOrder) c: [],
    };
    for (final type in LessonStepType.values) {
      map[type.category]?.add(type);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 760,
        constraints: const BoxConstraints(maxHeight: 760),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(child: _buildScrollableGrid()),
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Step Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Select what kind of activity this step contains',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildScrollableGrid() {
    final grouped = _grouped;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final category in _categoryOrder) ...[
            _buildCategoryHeader(category),
            const SizedBox(height: 8),
            _buildCategoryWrap(grouped[category]!),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String category) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _categoryAccentColor(category),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          category,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryWrap(List<LessonStepType> types) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final type in types)
          SizedBox(
            width: 220,
            height: 190,
            child: _TypeCard(
              type: type,
              isSelected: _selected == type,
              onTap: () => setState(() => _selected = type),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    final hasSelection = _selected != null;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFFE85D04)),
              foregroundColor: const Color(0xFFE85D04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed:
                hasSelection ? () => Navigator.of(context).pop(_selected) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE85D04),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              hasSelection
                  ? 'Confirm — ${_selected!.displayName}'
                  : 'Select a type to continue',
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Color _categoryAccentColor(String category) {
    switch (category) {
      case 'Foundation':
        return Colors.blue.shade600;
      case 'Assessment':
        return Colors.purple.shade600;
      case 'Sound & Phonics':
        return Colors.teal.shade600;
      case 'Reading':
        return Colors.green.shade600;
      case 'Story':
        return Colors.amber.shade700;
      default:
        return Colors.grey.shade600;
    }
  }
}

// ── Type card ─────────────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final LessonStepType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = _categoryAccentColor(type.category);
    final bgColor = _categoryBgColor(type.category);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFE85D04) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Illustration image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: _buildImage(),
              ),
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category-coloured icon bubble
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange.shade100 : bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      type.icon,
                      size: 13,
                      color: isSelected ? const Color(0xFFE85D04) : accentColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFFE85D04)
                                : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          type.description,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = type.previewUrl;
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _PlaceholderPreview(type: type),
      );
    }
    return Image.asset(
      type.assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _PlaceholderPreview(type: type),
    );
  }

  Color _categoryAccentColor(String category) {
    switch (category) {
      case 'Foundation':
        return Colors.blue.shade600;
      case 'Assessment':
        return Colors.purple.shade600;
      case 'Sound & Phonics':
        return Colors.teal.shade600;
      case 'Reading':
        return Colors.green.shade600;
      case 'Story':
        return Colors.amber.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _categoryBgColor(String category) {
    switch (category) {
      case 'Foundation':
        return Colors.blue.shade50;
      case 'Assessment':
        return Colors.purple.shade50;
      case 'Sound & Phonics':
        return Colors.teal.shade50;
      case 'Reading':
        return Colors.green.shade50;
      case 'Story':
        return Colors.amber.shade50;
      default:
        return Colors.grey.shade100;
    }
  }
}

// ── Placeholder shown when the PNG asset hasn't been added yet ────────────────

class _PlaceholderPreview extends StatelessWidget {
  const _PlaceholderPreview({required this.type});

  final LessonStepType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type.icon, size: 22, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
