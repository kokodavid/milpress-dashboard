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
                if (!def.isSystem && def.fields.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${def.fields.length} field${def.fields.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade600,
                      ),
                    ),
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

  /// Mutable list of field definitions being built.
  late List<StepFieldDefinition> _fields;

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
    _fields = List<StepFieldDefinition>.from(e?.fields ?? const []);
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
      fields: _fields,
    );

    if (_isEdit) {
      await ref.read(stepTypeMutationProvider.notifier).update(def);
    } else {
      await ref.read(stepTypeMutationProvider.notifier).create(def);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showAddFieldDialog() async {
    final result = await showDialog<StepFieldDefinition>(
      context: context,
      builder: (ctx) => const _AddFieldDialog(),
    );
    if (result != null) {
      setState(() => _fields.add(result));
    }
  }

  void _removeField(int index) {
    setState(() => _fields.removeAt(index));
  }

  void _moveFieldUp(int index) {
    if (index <= 0) return;
    setState(() {
      final item = _fields.removeAt(index);
      _fields.insert(index - 1, item);
    });
  }

  void _moveFieldDown(int index) {
    if (index >= _fields.length - 1) return;
    setState(() {
      final item = _fields.removeAt(index);
      _fields.insert(index + 1, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(stepTypeMutationProvider);
    final isBusy = saveState is AsyncLoading;

    return AlertDialog(
      title: Text(_isEdit ? 'Edit Step Type' : 'Add Step Type'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Metadata ─────────────────────────────────────────────────
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

                // ── Fields section ────────────────────────────────────────────
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.view_list_outlined,
                        size: 16, color: Colors.black87),
                    const SizedBox(width: 6),
                    Text(
                      'Form Fields',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showAddFieldDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Field'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Define the inputs admins will fill when creating a step with this type.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),

                if (_fields.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.grey.shade200,
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: Text(
                      'No fields yet. Click "Add Field" to define what admins will fill in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  )
                else
                  for (int i = 0; i < _fields.length; i++)
                    _FieldRow(
                      field: _fields[i],
                      index: i,
                      total: _fields.length,
                      onRemove: () => _removeField(i),
                      onMoveUp: i > 0 ? () => _moveFieldUp(i) : null,
                      onMoveDown:
                          i < _fields.length - 1 ? () => _moveFieldDown(i) : null,
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

// ── Field row (in the list inside the dialog) ─────────────────────────────────

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.index,
    required this.total,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  final StepFieldDefinition field;
  final int index;
  final int total;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  Color get _typeColor {
    switch (field.fieldType) {
      case StepFieldType.imageUrl:
        return Colors.purple.shade100;
      case StepFieldType.audioUrl:
        return Colors.green.shade100;
      case StepFieldType.text:
        return Colors.blue.shade100;
      case StepFieldType.repeatingGroup:
        return Colors.orange.shade100;
    }
  }

  Color get _typeTextColor {
    switch (field.fieldType) {
      case StepFieldType.imageUrl:
        return Colors.purple.shade700;
      case StepFieldType.audioUrl:
        return Colors.green.shade700;
      case StepFieldType.text:
        return Colors.blue.shade700;
      case StepFieldType.repeatingGroup:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Reorder arrows
          Column(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: onMoveUp != null
                    ? InkWell(
                        onTap: onMoveUp,
                        borderRadius: BorderRadius.circular(4),
                        child: Icon(Icons.arrow_drop_up,
                            size: 18, color: Colors.grey.shade500),
                      )
                    : const SizedBox(),
              ),
              SizedBox(
                width: 20,
                height: 20,
                child: onMoveDown != null
                    ? InkWell(
                        onTap: onMoveDown,
                        borderRadius: BorderRadius.circular(4),
                        child: Icon(Icons.arrow_drop_down,
                            size: 18, color: Colors.grey.shade500),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Field type badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _typeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              field.fieldType.displayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _typeTextColor,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Label and key
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  field.fieldType == StepFieldType.repeatingGroup
                      ? '${field.name}  ·  ${field.subFields.length} sub-field${field.subFields.length == 1 ? '' : 's'}'
                      : field.name,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // Required badge
          if (field.isRequired)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                'Required',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Delete
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Remove field',
          ),
        ],
      ),
    );
  }
}

// ── Add Field dialog ──────────────────────────────────────────────────────────

class _AddFieldDialog extends StatefulWidget {
  const _AddFieldDialog();

  @override
  State<_AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<_AddFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  StepFieldType _fieldType = StepFieldType.text;
  bool _isRequired = false;

  /// Sub-fields for repeating-group type.
  final List<StepFieldDefinition> _subFields = [];

  /// Auto-derived key, updated as the label changes.
  String _derivedKey = '';

  @override
  void initState() {
    super.initState();
    _labelCtrl.addListener(_onLabelChanged);
  }

  void _onLabelChanged() {
    setState(() {
      _derivedKey =
          StepFieldDefinition.deriveNameFromLabel(_labelCtrl.text);
    });
  }

  @override
  void dispose() {
    _labelCtrl.removeListener(_onLabelChanged);
    _labelCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_fieldType == StepFieldType.repeatingGroup && _subFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least one sub-field to the activity')),
      );
      return;
    }
    final field = StepFieldDefinition(
      name: _derivedKey,
      label: _labelCtrl.text.trim(),
      fieldType: _fieldType,
      isRequired: _isRequired,
      subFields:
          _fieldType == StepFieldType.repeatingGroup ? List.of(_subFields) : [],
    );
    Navigator.of(context).pop(field);
  }

  Future<void> _addSubField() async {
    final sub = await showDialog<StepFieldDefinition>(
      context: context,
      builder: (_) => const _AddSubFieldDialog(),
    );
    if (sub != null) setState(() => _subFields.add(sub));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Field'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                TextFormField(
                  controller: _labelCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'e.g. Activities',
                    border: OutlineInputBorder(),
                    helperText: 'Shown to admins above the input',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 6),
                if (_derivedKey.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 8),
                    child: Text('Key: $_derivedKey',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ),
                const SizedBox(height: 8),

                // Field type selector
                Text('Field type',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final type in StepFieldType.values)
                      _TypeChip(
                        label: type.displayName,
                        icon: _iconForType(type),
                        selected: _fieldType == type,
                        onTap: () => setState(() => _fieldType = type),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Sub-field editor (only for repeatingGroup) ────────────
                if (_fieldType == StepFieldType.repeatingGroup) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sub-fields per activity',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addSubField,
                        icon: const Icon(Icons.add, size: 15),
                        label: const Text('Add sub-field'),
                        style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFE85D04),
                            textStyle: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_subFields.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.orange.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.orange.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Define the fields each activity row will contain '
                              '(e.g. Word, Audio URL).',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (var i = 0; i < _subFields.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _subFields[i].fieldType.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepPurple.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _subFields[i].label,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (_subFields[i].isRequired)
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 6),
                                child: Text('Required',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            Colors.orange.shade700)),
                              ),
                            IconButton(
                              icon: Icon(Icons.close,
                                  size: 15,
                                  color: Colors.grey.shade400),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 24, minHeight: 24),
                              onPressed: () =>
                                  setState(() => _subFields.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 8),
                  const Divider(),
                ],

                const SizedBox(height: 8),

                // Required toggle
                Row(
                  children: [
                    Switch(
                      value: _isRequired,
                      onChanged: (v) =>
                          setState(() => _isRequired = v),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    const Text('Required',
                        style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      _fieldType == StepFieldType.repeatingGroup
                          ? '(must have ≥1 activity)'
                          : '(must be filled before saving)',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  IconData _iconForType(StepFieldType type) {
    switch (type) {
      case StepFieldType.text:
        return Icons.text_fields;
      case StepFieldType.imageUrl:
        return Icons.image_outlined;
      case StepFieldType.audioUrl:
        return Icons.volume_up_outlined;
      case StepFieldType.repeatingGroup:
        return Icons.view_list_outlined;
    }
  }
}

// ── Add Sub-Field dialog (for repeating groups) ───────────────────────────────

class _AddSubFieldDialog extends StatefulWidget {
  const _AddSubFieldDialog();
  @override
  State<_AddSubFieldDialog> createState() => _AddSubFieldDialogState();
}

class _AddSubFieldDialogState extends State<_AddSubFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  StepFieldType _type = StepFieldType.text;
  bool _isRequired = false;
  String _derivedKey = '';

  @override
  void initState() {
    super.initState();
    _labelCtrl.addListener(() {
      setState(() {
        _derivedKey =
            StepFieldDefinition.deriveNameFromLabel(_labelCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Sub-field'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _labelCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'e.g. Word, Audio URL',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              if (_derivedKey.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 4, left: 2, bottom: 8),
                  child: Text('Key: $_derivedKey',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ),
              const SizedBox(height: 12),
              Text('Type',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              // Only flat types are valid as sub-fields
              Wrap(
                spacing: 6,
                children: [
                  for (final t in [
                    StepFieldType.text,
                    StepFieldType.imageUrl,
                    StepFieldType.audioUrl,
                  ])
                    _TypeChip(
                      label: t.displayName,
                      icon: _iconFor(t),
                      selected: _type == t,
                      onTap: () => setState(() => _type = t),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Switch(
                    value: _isRequired,
                    onChanged: (v) => setState(() => _isRequired = v),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  const Text('Required', style: TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(StepFieldDefinition(
              name: _derivedKey,
              label: _labelCtrl.text.trim(),
              fieldType: _type,
              isRequired: _isRequired,
            ));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  IconData _iconFor(StepFieldType t) {
    switch (t) {
      case StepFieldType.text:
        return Icons.text_fields;
      case StepFieldType.imageUrl:
        return Icons.image_outlined;
      case StepFieldType.audioUrl:
        return Icons.volume_up_outlined;
      case StepFieldType.repeatingGroup:
        return Icons.view_list_outlined;
    }
  }
}

// ── Field type chip ───────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryColor.withOpacity(0.1)
                : Colors.grey.shade100,
            border: Border.all(
              color: selected
                  ? AppColors.primaryColor
                  : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? AppColors.primaryColor
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: selected
                      ? AppColors.primaryColor
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
