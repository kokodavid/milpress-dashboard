import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'modules_model.dart';
import 'modules_repository.dart';
import '../../widgets/app_button.dart';

Future<void> showDeleteModuleDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Module module,
  required VoidCallback onDeleted,
}) {
  return showDialog(
    context: context,
    builder: (context) => _DeleteModuleDialog(
      module: module,
      ref: ref,
      onDeleted: onDeleted,
    ),
  );
}

class _DeleteModuleDialog extends StatefulWidget {
  final Module module;
  final WidgetRef ref;
  final VoidCallback onDeleted;

  const _DeleteModuleDialog({
    required this.module,
    required this.ref,
    required this.onDeleted,
  });

  @override
  State<_DeleteModuleDialog> createState() => _DeleteModuleDialogState();
}

class _DeleteModuleDialogState extends State<_DeleteModuleDialog> {
  bool _isDeleting = false;

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
                  'Delete Module',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Content
            Text(
              'Are you sure you want to delete this module?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            
            // Module preview card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE85D04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.module.position}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Module ${widget.module.position}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            if (widget.module.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.module.description!,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Warning card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This action cannot be undone',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.module.moduleType == 'assessment'
                              ? 'The assessment link will be removed. The assessment itself will not be deleted.'
                              : 'All lessons in this module will also be permanently deleted.',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                    onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: _isDeleting ? 'Deleting...' : 'Delete Module',
                    backgroundColor: Colors.red.shade600,
                    onPressed: _isDeleting ? null : _handleDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await widget.ref.read(deleteModuleProvider.notifier).delete(
        widget.module.id,
        details: {
          'description': widget.module.description,
          'position': widget.module.position,
          'course_id': widget.module.courseId,
          'module_type': widget.module.moduleType,
          if (widget.module.assessmentId != null) 'assessment_id': widget.module.assessmentId,
        },
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Module deleted successfully')),
        );
        widget.onDeleted();
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete module: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}