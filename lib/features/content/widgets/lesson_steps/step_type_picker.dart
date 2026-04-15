import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lesson_v2/lesson_v2_models.dart';
import '../../../lesson_v2/step_type_definition.dart';
import '../../../lesson_v2/step_type_repository.dart';

// ── Sealed result type ────────────────────────────────────────────────────────

/// Returned by [showStepTypePicker]. Callers pattern-match on the subtype to
/// distinguish between the 15 built-in system types and admin-created ones.
sealed class PickedStepType {}

class SystemPickedType extends PickedStepType {
  final LessonStepType type;
  SystemPickedType(this.type);
}

class CustomPickedType extends PickedStepType {
  final StepTypeDefinition def;
  CustomPickedType(this.def);
}

// ── Public entry point ────────────────────────────────────────────────────────

/// Shows the step-type picker dialog and returns a [PickedStepType], or null
/// if the user cancelled.
Future<PickedStepType?> showStepTypePicker({
  required BuildContext context,
  LessonStepType? initialSystemType,
  StepTypeDefinition? initialCustomType,
}) {
  return showDialog<PickedStepType>(
    context: context,
    builder: (_) => StepTypePickerDialog(
      initialSystemType: initialSystemType,
      initialCustomType: initialCustomType,
    ),
  );
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class StepTypePickerDialog extends ConsumerStatefulWidget {
  const StepTypePickerDialog({
    super.key,
    this.initialSystemType,
    this.initialCustomType,
  });

  final LessonStepType? initialSystemType;
  final StepTypeDefinition? initialCustomType;

  @override
  ConsumerState<StepTypePickerDialog> createState() =>
      _StepTypePickerDialogState();
}

class _StepTypePickerDialogState extends ConsumerState<StepTypePickerDialog> {
  static const List<String> _categoryOrder = [
    'Foundation',
    'Assessment',
    'Sound & Phonics',
    'Reading',
    'Story',
  ];

  LessonStepType? _selectedSystem;
  StepTypeDefinition? _selectedCustom;

  @override
  void initState() {
    super.initState();
    _selectedSystem = widget.initialSystemType;
    _selectedCustom = widget.initialCustomType;
  }

  bool get _hasSelection => _selectedSystem != null || _selectedCustom != null;

  PickedStepType? get _picked {
    if (_selectedCustom != null) return CustomPickedType(_selectedCustom!);
    if (_selectedSystem != null) return SystemPickedType(_selectedSystem!);
    return null;
  }

  String get _selectedLabel {
    if (_selectedCustom != null) return _selectedCustom!.displayName;
    if (_selectedSystem != null) return _selectedSystem!.displayName;
    return 'Select a type to continue';
  }

  void _selectSystem(LessonStepType type) {
    setState(() {
      _selectedSystem = type;
      _selectedCustom = null;
    });
  }

  void _selectCustom(StepTypeDefinition def) {
    setState(() {
      _selectedCustom = def;
      _selectedSystem = null;
    });
  }

  Map<String, List<LessonStepType>> get _groupedSystem {
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
    final grouped = _groupedSystem;
    final customAsync = ref.watch(customStepTypesProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── System types ────────────────────────────────────────────────────
          for (final category in _categoryOrder) ...[
            _buildCategoryHeader(category, _categoryAccentColor(category)),
            const SizedBox(height: 8),
            _buildSystemCategoryWrap(grouped[category]!),
            const SizedBox(height: 16),
          ],

          // ── Custom types ────────────────────────────────────────────────────
          customAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (customTypes) {
              if (customTypes.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryHeader('Custom', Colors.deepPurple.shade400),
                  const SizedBox(height: 8),
                  _buildCustomCategoryWrap(customTypes),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String category, Color accent) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: accent,
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

  Widget _buildSystemCategoryWrap(List<LessonStepType> types) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final type in types)
          SizedBox(
            width: 220,
            height: 190,
            child: _SystemTypeCard(
              type: type,
              isSelected: _selectedSystem == type,
              onTap: () => _selectSystem(type),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomCategoryWrap(List<StepTypeDefinition> types) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final def in types)
          SizedBox(
            width: 220,
            height: 190,
            child: _CustomTypeCard(
              def: def,
              isSelected: _selectedCustom?.id == def.id,
              onTap: () => _selectCustom(def),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
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
            onPressed: _hasSelection
                ? () => Navigator.of(context).pop(_picked)
                : null,
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
              _hasSelection
                  ? 'Confirm — $_selectedLabel'
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

// ── System type card ──────────────────────────────────────────────────────────

class _SystemTypeCard extends StatelessWidget {
  const _SystemTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final LessonStepType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColor(type.category);
    final bgColor = _bgColor(type.category);

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
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: _buildImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      color:
                          isSelected ? const Color(0xFFE85D04) : accentColor,
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
        errorBuilder: (_, __, ___) => _PlaceholderPreview(
          label: type.displayName,
        ),
      );
    }
    return Image.asset(
      type.assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _PlaceholderPreview(
        label: type.displayName,
      ),
    );
  }

  Color _accentColor(String category) {
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

  Color _bgColor(String category) {
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

// ── Custom type card ──────────────────────────────────────────────────────────

class _CustomTypeCard extends StatelessWidget {
  const _CustomTypeCard({
    required this.def,
    required this.isSelected,
    required this.onTap,
  });

  final StepTypeDefinition def;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.deepPurple.shade400
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: def.previewUrl != null
                    ? Image.network(
                        def.previewUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _PlaceholderPreview(
                          label: def.displayName,
                        ),
                      )
                    : _PlaceholderPreview(
                        label: def.displayName,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurple.shade100
                          : Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.extension,
                      size: 13,
                      color: isSelected
                          ? Colors.deepPurple.shade700
                          : Colors.deepPurple.shade400,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          def.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.deepPurple.shade700
                                : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          def.description.isNotEmpty
                              ? def.description
                              : 'Custom step type',
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
}

// ── Shared placeholder ────────────────────────────────────────────────────────

class _PlaceholderPreview extends StatelessWidget {
  const _PlaceholderPreview({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
