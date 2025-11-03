import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'modules_model.dart';
import 'modules_repository.dart';
import '../../widgets/app_button.dart';

Future<void> showEditModuleDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Module module,
  required VoidCallback onUpdated,
}) {
  return showDialog(
    context: context,
    builder: (context) => _EditModuleDialog(
      module: module,
      ref: ref,
      onUpdated: onUpdated,
    ),
  );
}

class _EditModuleDialog extends StatefulWidget {
  final Module module;
  final WidgetRef ref;
  final VoidCallback onUpdated;

  const _EditModuleDialog({
    required this.module,
    required this.ref,
    required this.onUpdated,
  });

  @override
  State<_EditModuleDialog> createState() => _EditModuleDialogState();
}

class _EditModuleDialogState extends State<_EditModuleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _positionController;
  late final TextEditingController _durationController;
  late final TextEditingController _lockMessageController;
  late bool _locked;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.module.description ?? '');
    _positionController = TextEditingController(text: widget.module.position.toString());
    _durationController = TextEditingController(
      text: widget.module.durationMinutes?.toString() ?? '',
    );
    _lockMessageController = TextEditingController(text: widget.module.lockMessage ?? '');
    _locked = widget.module.locked;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _positionController.dispose();
    _durationController.dispose();
    _lockMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Module',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Module Title
                  const Text(
                    'Module Title*',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Enter module title',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE85D04)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Module title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Position
                  const Text(
                    'Position',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _positionController,
                    decoration: InputDecoration(
                      hintText: 'Course type i.e word',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE85D04)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Position is required';
                      }
                      final position = int.tryParse(value.trim());
                      if (position == null || position < 1) {
                        return 'Position must be a positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Duration
                  const Text(
                    'Duration (in minutes)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      hintText: '00 minutes',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE85D04)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final duration = int.tryParse(value.trim());
                        if (duration == null || duration < 0) {
                          return 'Duration must be a positive number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Lock checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _locked,
                        onChanged: _isUpdating ? null : (value) {
                          setState(() {
                            _locked = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFFE85D04),
                      ),
                      const Text(
                        'Lock this course',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Cancel',
                          outlined: true,
                          backgroundColor: const Color(0xFFE85D04),
                          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          label: _isUpdating ? 'Updating...' : 'Update Module',
                          backgroundColor: const Color(0xFFE85D04),
                          onPressed: _isUpdating ? null : _handleUpdate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    final update = ModuleUpdate(
      description: _descriptionController.text.trim(),
      position: int.parse(_positionController.text.trim()),
      durationMinutes: _durationController.text.trim().isEmpty
          ? null
          : int.parse(_durationController.text.trim()),
      locked: _locked,
      lockMessage: _locked && _lockMessageController.text.trim().isNotEmpty
          ? _lockMessageController.text.trim()
          : null,
    );

    try {
      await widget.ref.read(updateModuleProvider.notifier).update(widget.module.id, update);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Module updated successfully')),
        );
        Navigator.of(context).pop();
        widget.onUpdated();
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update module: $e')),
        );
      }
    }
  }
}