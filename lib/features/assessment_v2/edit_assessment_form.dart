import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';
import 'package:milpress_dashboard/widgets/app_text_form_field.dart';
import 'package:milpress_dashboard/widgets/app_button.dart';

import 'models/course_assessment_model.dart';
import 'assessment_v2_repository.dart';

class EditAssessmentForm extends ConsumerStatefulWidget {
  final CourseAssessment assessment;
  final VoidCallback onUpdated;
  const EditAssessmentForm({
    super.key,
    required this.assessment,
    required this.onUpdated,
  });

  @override
  ConsumerState<EditAssessmentForm> createState() => _EditAssessmentFormState();
}

class _EditAssessmentFormState extends ConsumerState<EditAssessmentForm> {
  final _formKey = GlobalKey<FormState>();

  late String title = widget.assessment.title;
  late String description = widget.assessment.description ?? '';
  late bool isActive = widget.assessment.isActive;
  bool isLoading = false;
  String? errorMsg;

  Future<void> _submit() async {
    setState(() => errorMsg = null);
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      setState(() => isLoading = true);
      try {
        await ref.read(saveAssessmentProvider.notifier).update(
              widget.assessment.id,
              CourseAssessmentUpdate(
                title: title,
                description: description.isEmpty ? null : description,
                isActive: isActive,
              ),
            );
        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onUpdated();
      } catch (e) {
        setState(() => errorMsg = e.toString());
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Assessment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
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
              const SizedBox(height: 10),

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

              // Title
              AppTextFormField(
                label: 'Assessment Title',
                initialValue: title,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
                onSaved: (v) => title = v?.trim() ?? '',
              ),
              const SizedBox(height: 10),

              // Description
              AppTextFormField(
                label: 'Description',
                initialValue: description,
                maxLines: 4,
                onSaved: (v) => description = v?.trim() ?? '',
              ),
              const SizedBox(height: 20),

              // Active toggle
              Row(
                children: [
                  Checkbox(
                    value: isActive,
                    onChanged: (v) => setState(() => isActive = v ?? true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text(
                    'Active',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Buttons
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
                      label: isLoading ? 'Saving...' : 'Save Changes',
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
    );
  }
}
