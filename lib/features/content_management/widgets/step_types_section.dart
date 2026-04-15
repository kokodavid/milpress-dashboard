import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../../lesson_v2/step_type_definition.dart';
import '../../lesson_v2/step_type_repository.dart';


class StepTypesSection extends ConsumerStatefulWidget {
  const StepTypesSection({super.key});

  @override
  ConsumerState<StepTypesSection> createState() => _StepTypesSectionState();
}

class _StepTypesSectionState extends ConsumerState<StepTypesSection> {
  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allStepTypesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        Row(
          children: [
            Text(
              'Lesson Step Types',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            SizedBox(
              width: 168,
              child: AppButton(
                label: '+ Add Step Type',
                backgroundColor: AppColors.primaryColor,
                height: 36,
                onPressed: _showAddDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'System types cannot be deleted. Custom types can be fully managed.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        allAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading step types: $e'),
          data: (types) {
            final systemTypes = types.where((t) => t.isSystem).toList();
            final customTypes = types.where((t) => !t.isSystem).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── System types ─────────────────────────────────────────────
                _SectionLabel(
                  label: 'System Types (${systemTypes.length})',
                  locked: true,
                ),
                const SizedBox(height: 8),
                if (systemTypes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No system types found.',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13),
                    ),
                  )
                else
                  for (final def in systemTypes)
                    _CustomTypeRow(
                      def: def,
                      onEdit: () => _showEditDialog(def),
                      onDelete: null, // system types cannot be deleted
                    ),

                const SizedBox(height: 20),

                // ── Custom types ─────────────────────────────────────────────
                _SectionLabel(label: 'Custom Types', locked: false),
                const SizedBox(height: 8),
                if (customTypes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No custom types yet. Use "Add Step Type" to create one.',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ),
                  )
                else
                  for (final def in customTypes)
                    _CustomTypeRow(
                      def: def,
                      onEdit: () => _showEditDialog(def),
                      onDelete: () => _confirmDelete(def),
                    ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => const _StepTypeFormDialog(),
    ).then((_) {
      if (mounted) ref.invalidate(allStepTypesProvider);
    });
  }

  void _showEditDialog(StepTypeDefinition def) {
    showDialog(
      context: context,
      builder: (_) => _StepTypeFormDialog(existing: def),
    ).then((_) {
      if (mounted) ref.invalidate(allStepTypesProvider);
    });
  }

  Future<void> _confirmDelete(StepTypeDefinition def) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Step Type'),
        content: Text(
          'Delete "${def.displayName}"? This cannot be undone. Existing lesson steps that use this type will keep their data but will display as unknown in the editor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await ref.read(stepTypeMutationProvider.notifier).delete(def);
      if (mounted) ref.invalidate(allStepTypesProvider);
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete Failed'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}


// ── Small helper widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.locked});

  final String label;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          locked ? Icons.lock_outline : Icons.tune,
          size: 14,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}


class _CustomTypeRow extends StatelessWidget {
  const _CustomTypeRow({
    required this.def,
    required this.onEdit,
    this.onDelete,
  });

  final StepTypeDefinition def;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${def.category} · ${def.key}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit',
            color: Colors.grey.shade600,
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Delete',
              color: Colors.red.shade400,
            ),
        ],
      ),
    );
  }
}

// ── Add / Edit dialog ─────────────────────────────────────────────────────────

class _StepTypeFormDialog extends ConsumerStatefulWidget {
  const _StepTypeFormDialog({this.existing});

  /// Non-null when editing an existing custom type.
  final StepTypeDefinition? existing;

  @override
  ConsumerState<_StepTypeFormDialog> createState() =>
      _StepTypeFormDialogState();
}

class _StepTypeFormDialogState extends ConsumerState<_StepTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _keyCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _previewUrlCtrl;
  late String _category;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _keyCtrl = TextEditingController(text: e?.key ?? '');
    _nameCtrl = TextEditingController(text: e?.displayName ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _previewUrlCtrl = TextEditingController(text: e?.previewUrl ?? '');
    _category = e?.category ?? kStepTypeCategories.first;
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _previewUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final def = StepTypeDefinition(
      id: widget.existing?.id ?? '',
      key: _keyCtrl.text.trim(),
      displayName: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      previewUrl:
          _previewUrlCtrl.text.trim().isEmpty ? null : _previewUrlCtrl.text.trim(),
      isSystem: false,
    );

    if (_isEdit) {
      await ref.read(stepTypeMutationProvider.notifier).update(def);
    } else {
      await ref.read(stepTypeMutationProvider.notifier).create(def);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(stepTypeMutationProvider);
    final isBusy = saveState is AsyncLoading;

    return AlertDialog(
      title: Text(_isEdit ? 'Edit Step Type' : 'Add Step Type'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Key (editable only when creating)
                TextFormField(
                  controller: _keyCtrl,
                  enabled: !_isEdit,
                  decoration: InputDecoration(
                    labelText: 'Key',
                    hintText: 'e.g. phoneme_sort',
                    border: const OutlineInputBorder(),
                    helperText: _isEdit
                        ? 'Key cannot be changed after creation'
                        : 'Lowercase letters and underscores only',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(v.trim())) {
                      return 'Use lowercase letters, digits, and underscores';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'e.g. Phoneme Sort',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'One-line description shown in the picker',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final cat in kStepTypeCategories)
                      DropdownMenuItem(value: cat, child: Text(cat)),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _previewUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Preview Image URL',
                    hintText: 'https://… (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isBusy ? null : _save,
          child: isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
