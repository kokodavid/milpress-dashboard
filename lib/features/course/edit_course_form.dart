import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/widgets/app_text_form_field.dart';

import 'course_models.dart';
import 'course_repository.dart';

class EditCourseForm extends ConsumerStatefulWidget {
  final Course course;
  final VoidCallback onUpdated;
  const EditCourseForm({super.key, required this.course, required this.onUpdated});

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
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Course',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  errorMsg!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            AppTextFormField(
              label: title,
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              onSaved: (v) => title = v?.trim() ?? '',
            ),
            const SizedBox(height: 12),
            AppTextFormField(
              label: 'Description', 
              initialValue: description,
              maxLines: 6,
              validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
              onSaved: (v) => description = v?.trim() ?? '',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextFormField(
                    label: 'Type',
                    initialValue: type,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Type is required' : null,
                    onSaved: (v) => type = v?.trim() ?? '',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextFormField(
                    label: 'Level',
                    initialValue: level?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Level is required';
                      final val = int.tryParse(v);
                      if (val == null || val < 1) return 'Enter a valid level (>=1)';
                      return null;
                    },
                    onSaved: (v) => level = int.tryParse(v ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextFormField(
              label: 'Duration (min)',
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
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: locked,
                  onChanged: (v) => setState(() => locked = v ?? false),
                ),
                const Text('Locked'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
