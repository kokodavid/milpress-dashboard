import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

import '../../widgets/app_text_form_field.dart';
import '../../widgets/app_button.dart';
import 'modules_model.dart';
import 'modules_repository.dart';

class CreateModuleForm extends ConsumerStatefulWidget {
  final String courseId;
  final VoidCallback onCreated;
  final int initialPosition;

  const CreateModuleForm({
    super.key,
    required this.courseId,
    required this.onCreated,
    this.initialPosition = 1,
  });

  @override
  ConsumerState<CreateModuleForm> createState() => _CreateModuleFormState();
}

class _CreateModuleFormState extends ConsumerState<CreateModuleForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _positionController;
  late final TextEditingController _durationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _lockMessageController;
  bool _locked = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _positionController = TextEditingController(text: widget.initialPosition.toString());
    _durationController = TextEditingController();
    _descriptionController = TextEditingController();
    _lockMessageController = TextEditingController();
  }

  @override
  void dispose() {
    _positionController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _lockMessageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final position = int.parse(_positionController.text.trim());
    final durationText = _durationController.text.trim();
    final duration = durationText.isEmpty ? null : int.parse(durationText);
    final descriptionText = _descriptionController.text.trim();
    final lockMessageText = _lockMessageController.text.trim();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(modulesRepositoryProvider);
      await repo.createModule(
        ModuleCreate(
          courseId: widget.courseId,
          position: position,
          durationMinutes: duration,
          locked: _locked,
          lockMessage: _locked && lockMessageText.isNotEmpty ? lockMessageText : null,
          description: descriptionText.isNotEmpty ? descriptionText : null,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      widget.onCreated();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 400),
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
                  'Add Module',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ),

                      // Module Title
                      AppTextFormField(
                        controller: _descriptionController,
                        label: 'Module Title*',
                        hintText: 'Enter module title',
                        maxLines: 1,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Module title is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Position and Duration (side by side)
                      Row(
                        children: [
                          Expanded(
                            child: AppTextFormField(
                              controller: _positionController,
                              label: 'Position',
                              hintText: 'Enter position',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Position is required';
                                }
                                final parsed = int.tryParse(value);
                                if (parsed == null || parsed < 1) {
                                  return 'Enter a valid position (>=1)';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextFormField(
                              controller: _durationController,
                              label: 'Duration (minutes)',
                              hintText: '00 minutes',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null;
                                }
                                final parsed = int.tryParse(value);
                                if (parsed == null || parsed < 1) {
                                  return 'Enter a valid duration (>=1)';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Lock checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _locked,
                            onChanged: (value) {
                              setState(() {
                                _locked = value ?? false;
                              });
                            },
                            activeColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Text(
                            'Lock this module',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      
                      if (_locked) ...[
                        const SizedBox(height: 16),
                        AppTextFormField(
                          controller: _lockMessageController,
                          label: 'Lock Message',
                          hintText: 'Enter lock message',
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    outlined: true,
                    backgroundColor: AppColors.primaryColor,
                    textColor: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: _isLoading ? 'Creating...' : 'Create Module',
                    onPressed: _isLoading ? null : _submit,
                    backgroundColor: AppColors.primaryColor,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
