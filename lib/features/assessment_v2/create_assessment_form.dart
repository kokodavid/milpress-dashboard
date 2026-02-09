import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';
import 'package:milpress_dashboard/widgets/app_text_form_field.dart';
import 'package:milpress_dashboard/widgets/app_button.dart';

import '../course/course_repository.dart';
import 'models/course_assessment_model.dart';
import 'assessment_v2_repository.dart';

class CreateAssessmentForm extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const CreateAssessmentForm({required this.onCreated, super.key});

  @override
  ConsumerState<CreateAssessmentForm> createState() =>
      _CreateAssessmentFormState();
}

class _CreateAssessmentFormState extends ConsumerState<CreateAssessmentForm> {
  final _formKey = GlobalKey<FormState>();
  String? courseId;
  String title = '';
  String description = '';
  bool isActive = true;
  bool isLoading = false;
  String? errorMsg;

  Future<void> _submit() async {
    setState(() => errorMsg = null);
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      setState(() => isLoading = true);
      try {
        await ref.read(saveAssessmentProvider.notifier).create(
              CourseAssessmentCreate(
                courseId: courseId!,
                title: title,
                description: description.isEmpty ? null : description,
                isActive: isActive,
              ),
            );
        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onCreated();
      } catch (e) {
        setState(() => errorMsg = e.toString());
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch all courses and all assessments to exclude courses that already have one
    const query = CoursesQuery(limit: 100, orderBy: 'title', ascending: true);
    final coursesAsync = ref.watch(coursesListProvider(query));
    final assessmentsAsync = ref.watch(allAssessmentsProvider);

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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Assessment',
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

                // Course dropdown – excludes courses that already have an assessment
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Course*',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCourseDropdown(coursesAsync, assessmentsAsync),
                  ],
                ),
                const SizedBox(height: 20),

                // Title
                AppTextFormField(
                  label: 'Assessment Title*',
                  hintText: 'Enter assessment title',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Title is required' : null,
                  onSaved: (v) => title = v?.trim() ?? '',
                ),
                const SizedBox(height: 20),

                // Description
                AppTextFormField(
                  label: 'Description',
                  hintText: 'Describe this assessment',
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
                      width: 180,
                      child: AppButton(
                        label:
                            isLoading ? 'Creating...' : 'Create Assessment',
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

  Widget _buildCourseDropdown(
    AsyncValue<List<dynamic>> coursesAsync,
    AsyncValue<List<dynamic>> assessmentsAsync,
  ) {
    // Wait for both to load
    if (coursesAsync is AsyncLoading || assessmentsAsync is AsyncLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: const Row(
          children: [
            SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Loading courses…'),
          ],
        ),
      );
    }

    final courses = coursesAsync.asData?.value ?? [];
    final assessments = assessmentsAsync.asData?.value ?? [];

    // Course IDs that already have an assessment
    final usedCourseIds =
        assessments.map((a) => (a as dynamic).courseId as String).toSet();

    // Filter out courses that already have an assessment
    final availableCourses =
        courses.where((c) => !usedCourseIds.contains((c as dynamic).id)).toList();

    final items = availableCourses
        .map((c) => DropdownMenuItem<String>(
              value: (c as dynamic).id as String,
              child: Text((c as dynamic).title as String,
                  overflow: TextOverflow.ellipsis),
            ))
        .toList();

    return DropdownButtonFormField<String>(
      initialValue: courseId,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
      decoration: InputDecoration(
        hintText: 'Select a course',
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items,
      onChanged: (v) => setState(() => courseId = v),
      validator: (v) => v == null ? 'Please select a course' : null,
    );
  }
}
