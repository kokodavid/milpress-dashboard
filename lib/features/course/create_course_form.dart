import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/app_text_form_field.dart';
import 'course_models.dart';
import 'course_repository.dart';

class CreateCourseForm extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const CreateCourseForm({required this.onCreated, super.key});

  @override
  ConsumerState<CreateCourseForm> createState() => _CreateCourseFormState();
}

class _CreateCourseFormState extends ConsumerState<CreateCourseForm> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  String type = '';
  int? level;
  int? duration;
  bool locked = false;
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
        await repo.createCourse(
          CourseCreate(
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
        widget.onCreated();
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
        child: Center(
          child: SizedBox(
            width: 650,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Course',
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
                  label: 'Title',
                  validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                  onSaved: (v) => title = v?.trim() ?? '',
                ),
                const SizedBox(height: 8),
                AppTextFormField(
                  label: 'Description',
                  maxLines: 6,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
                  onSaved: (v) => description = v?.trim() ?? '',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppTextFormField(
                        label: 'Type',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Type is required' : null,
                        onSaved: (v) => type = v?.trim() ?? '',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextFormField(
                        label: 'Level',
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
                const SizedBox(height: 8),
                AppTextFormField(
                  label: 'Duration (min)',
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
                const SizedBox(height: 8),
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
                          : const Text('Create'),
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
