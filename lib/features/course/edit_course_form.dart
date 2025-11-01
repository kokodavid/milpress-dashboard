import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';
import 'package:milpress_dashboard/widgets/app_text_form_field.dart';
import 'package:milpress_dashboard/widgets/app_button.dart';

import 'course_models.dart';
import 'course_repository.dart';

class EditCourseForm extends ConsumerStatefulWidget {
  final Course course;
  final VoidCallback onUpdated;
  const EditCourseForm({
    super.key,
    required this.course,
    required this.onUpdated,
  });

  @override
  ConsumerState<EditCourseForm> createState() => _EditCourseFormState();
}

class _EditCourseFormState extends ConsumerState<EditCourseForm> {
  final _formKey = GlobalKey<FormState>();

  late String title = widget.course.title;
  late String description = widget.course.description ?? '';
  late String type = widget.course.type ?? '';
  late int? level = widget.course.level;
  late int? duration = widget.course.durationInMinutes;
  late bool locked = widget.course.locked;
  bool isLoading = false;
  String? errorMsg;

  Future<void> _submit() async {
    setState(() {
      errorMsg = null;
    });
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      setState(() {
        isLoading = true;
      });
      try {
        final repo = ref.read(courseRepositoryProvider);
        await repo.updateCourse(
          widget.course.id,
          CourseUpdate(
            title: title,
            description: description,
            type: type,
            level: level,
            durationInMinutes: duration,
            locked: locked,
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onUpdated();
      } catch (e) {
        setState(() {
          errorMsg = e.toString();
        });
      } finally {
        setState(() {
          isLoading = false;
        });
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
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Course',
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

              // Course Title
              AppTextFormField(
                label: 'Course Title',
                initialValue: title,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
                onSaved: (v) => title = v?.trim() ?? '',
              ),
              const SizedBox(height: 10),
              // Course Description
              AppTextFormField(
                label: 'Course Description',
                initialValue: description,
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Description is required'
                    : null,
                onSaved: (v) => description = v?.trim() ?? '',
              ),

              const SizedBox(height: 10),
              // Type and Level row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextFormField(
                          label: 'Type',
                          initialValue: type,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Type is required'
                              : null,
                          onSaved: (v) => type = v?.trim() ?? '',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextFormField(
                          label: 'Level',
                          initialValue: level?.toString() ?? '',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Level is required';
                            final val = int.tryParse(v);
                            if (val == null || val < 1)
                              return 'Enter a valid level (>=1)';
                            return null;
                          },
                          onSaved: (v) => level = int.tryParse(v ?? ''),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppTextFormField(
                label: 'Duration in (minutes)',
                initialValue: duration?.toString() ?? '',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Duration is required';
                  }
                  final val = int.tryParse(v);
                  if (val == null || val < 1) {
                    return 'Enter a valid duration (>=1)';
                  }
                  return null;
                },
                onSaved: (v) => duration = int.tryParse(v ?? ''),
              ),
              const SizedBox(height: 20),

              // Lock checkbox
              Row(
                children: [
                  Checkbox(
                    value: locked,
                    onChanged: (v) => setState(() => locked = v ?? false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text(
                    'Lock this course',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100,
                    child: AppButton(
                      label: 'Cancel',
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
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
