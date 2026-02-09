import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

import '../../widgets/app_text_form_field.dart';
import '../../widgets/app_button.dart';
import 'modules_model.dart';
import 'modules_repository.dart';
import '../assessment_v2/assessment_v2_repository.dart';

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
  String _moduleType = 'lesson';

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
      // For assessment modules, look up the course assessment
      String? assessmentId;
      if (_moduleType == 'assessment') {
        final assessment = await ref.read(assessmentByCourseIdProvider(widget.courseId).future);
        if (assessment == null) {
          setState(() {
            _error = 'No assessment found for this course. Create one first.';
            _isLoading = false;
          });
          return;
        }
        assessmentId = assessment.id;
      }

      // Use notifier so activity logging runs
      await ref.read(createModuleProvider.notifier).create(
        ModuleCreate(
          courseId: widget.courseId,
          position: position,
          durationMinutes: _moduleType == 'lesson' ? duration : null,
          locked: _locked,
          lockMessage: _locked && lockMessageText.isNotEmpty ? lockMessageText : null,
          description: descriptionText.isNotEmpty ? descriptionText : null,
          moduleType: _moduleType,
          assessmentId: assessmentId,
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
        constraints: const BoxConstraints(maxHeight: 550),
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

                      // Module Type Toggle
                      const Text(
                        'Module Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _moduleType = 'lesson'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _moduleType == 'lesson' ? AppColors.primaryColor : Colors.white,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                  border: Border.all(
                                    color: _moduleType == 'lesson' ? AppColors.primaryColor : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.menu_book,
                                      size: 18,
                                      color: _moduleType == 'lesson' ? Colors.white : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lesson Module',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _moduleType == 'lesson' ? Colors.white : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _moduleType = 'assessment'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _moduleType == 'assessment' ? AppColors.primaryColor : Colors.white,
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                  border: Border.all(
                                    color: _moduleType == 'assessment' ? AppColors.primaryColor : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.quiz,
                                      size: 18,
                                      color: _moduleType == 'assessment' ? Colors.white : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Assessment Module',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _moduleType == 'assessment' ? Colors.white : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Assessment info (shown only for assessment modules)
                      if (_moduleType == 'assessment') ...[
                        Builder(
                          builder: (context) {
                            final assessmentAsync = ref.watch(assessmentByCourseIdProvider(widget.courseId));
                            return assessmentAsync.when(
                              data: (assessment) {
                                if (assessment == null) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'No assessment found for this course. Create one first.',
                                            style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Linked Assessment',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              assessment.title,
                                              style: TextStyle(
                                                color: Colors.green.shade800,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              error: (e, _) => Text('Error loading assessment: $e'),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

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
                          if (_moduleType == 'lesson') ...[
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
