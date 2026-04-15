import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../app_resource_model.dart';
import '../content_management_providers.dart';
import '../content_management_repository.dart';
import 'resource_row_tile.dart';

class ResourcesListSection extends ConsumerWidget {
  const ResourcesListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(appResourcesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Downloadable Resources',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            SizedBox(
              width: 160,
              child: AppButton(
                label: '+ Add Resource',
                backgroundColor: AppColors.primaryColor,
                height: 36,
                onPressed: () => _showAddDialog(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Drag to reorder. The mobile app displays resources in this order.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 16),
        resourcesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading resources: $e'),
          data: (resources) {
            if (resources.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No resources yet. Add one above.'),
                ),
              );
            }
            return ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: resources.length,
              itemBuilder: (_, i) => ResourceRowTile(
                key: ValueKey(resources[i].id),
                resource: resources[i],
              ),
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                final reordered = List<AppResource>.from(resources);
                final item = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, item);
                await ref
                    .read(resourceMutationProvider.notifier)
                    .reorder(reordered);
                ref.invalidate(appResourcesProvider);
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const _AddResourceDialog(),
    ).then((_) => ref.invalidate(appResourcesProvider));
  }
}

class _AddResourceDialog extends ConsumerStatefulWidget {
  const _AddResourceDialog();

  @override
  ConsumerState<_AddResourceDialog> createState() => _AddResourceDialogState();
}

class _AddResourceDialogState extends ConsumerState<_AddResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _fileUrlCtrl = TextEditingController();
  final _audioUrlCtrl = TextEditingController();
  String _type = 'pdf';

  @override
  void dispose() {
    _labelCtrl.dispose();
    _fileUrlCtrl.dispose();
    _audioUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final resource = AppResource(
      id: '',
      label: _labelCtrl.text.trim(),
      fileUrl: _fileUrlCtrl.text.trim(),
      audioUrl: _audioUrlCtrl.text.trim(),
      type: _type,
      displayOrder: 999,
    );
    await ref.read(resourceMutationProvider.notifier).create(resource);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(resourceMutationProvider);
    return AlertDialog(
      title: const Text('Add Resource'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'e.g. Alphabets Chart',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fileUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'File URL',
                  hintText: 'https://… (PDF or video file)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _audioUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Audio URL',
                  hintText: 'https://… (MP3 or M4A)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'pdf'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saveState is AsyncLoading ? null : _save,
          child: saveState is AsyncLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
