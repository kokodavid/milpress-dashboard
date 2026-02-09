import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';
import 'package:milpress_dashboard/widgets/app_button.dart';
import 'package:milpress_dashboard/widgets/app_text_form_field.dart';

import 'assessment_v2_repository.dart';
import 'models/assessment_level_model.dart';

class CreateLevelForm extends ConsumerStatefulWidget {
  final String assessmentId;
  final int initialDisplayOrder;
  final ValueChanged<AssessmentLevel> onCreated;

  const CreateLevelForm({
    super.key,
    required this.assessmentId,
    required this.onCreated,
    this.initialDisplayOrder = 1,
  });

  @override
  ConsumerState<CreateLevelForm> createState() => _CreateLevelFormState();
}

class _CreateLevelFormState extends ConsumerState<CreateLevelForm> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  late int displayOrder = widget.initialDisplayOrder;
  bool isLoading = false;
  String? errorMsg;

  Future<void> _submit() async {
    setState(() => errorMsg = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    setState(() => isLoading = true);
    try {
      final created = await ref.read(saveLevelProvider.notifier).create(
            AssessmentLevelCreate(
              assessmentId: widget.assessmentId,
              title: title,
              description: description.isEmpty ? null : description,
              displayOrder: displayOrder,
            ),
          );
      if (!mounted) return;
      if (created == null) {
        throw StateError('Unable to create level');
      }
      Navigator.of(context).pop();
      widget.onCreated(created);
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMsg = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: 650,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Level',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          isLoading ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (errorMsg != null)
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
                        errorMsg!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ),
                AppTextFormField(
                  label: 'Level Title*',
                  hintText: 'Enter level title',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Level title is required'
                      : null,
                  onSaved: (v) => title = v?.trim() ?? '',
                ),
                const SizedBox(height: 20),
                AppTextFormField(
                  label: 'Display Order*',
                  hintText: 'Enter display order',
                  initialValue: widget.initialDisplayOrder.toString(),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Display order is required';
                    }
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null || parsed < 1) {
                      return 'Enter a valid number (>= 1)';
                    }
                    return null;
                  },
                  onSaved: (v) =>
                      displayOrder = int.tryParse(v?.trim() ?? '') ?? 1,
                ),
                const SizedBox(height: 20),
                AppTextFormField(
                  label: 'Description',
                  hintText: 'Describe this level',
                  maxLines: 4,
                  onSaved: (v) => description = v?.trim() ?? '',
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: AppButton(
                        label: 'Cancel',
                        onPressed:
                            isLoading ? null : () => Navigator.of(context).pop(),
                        outlined: true,
                        backgroundColor: Colors.grey,
                        textColor: Colors.grey,
                        height: 44,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: AppButton(
                        label: isLoading ? 'Creating...' : 'Create Level',
                        onPressed: isLoading ? null : _submit,
                        backgroundColor: AppColors.primaryColor,
                        textColor: Colors.white,
                        height: 44,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
