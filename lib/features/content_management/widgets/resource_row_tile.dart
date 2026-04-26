import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/media_preview_dialog.dart';
import '../app_resource_model.dart';
import '../content_management_providers.dart';
import '../content_management_repository.dart';

class ResourceRowTile extends ConsumerWidget {
  final AppResource resource;

  const ResourceRowTile({super.key, required this.resource});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileSet = resource.fileUrl.isNotEmpty;
    final audioSet = resource.audioUrl.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          resource.type == 'pdf'
              ? Icons.picture_as_pdf_outlined
              : Icons.video_file_outlined,
          color: Colors.grey.shade600,
        ),
        title: Text(resource.label,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UrlStatus(
              icon: Icons.attach_file,
              label: 'File',
              url: resource.fileUrl,
              isSet: fileSet,
            ),
            const SizedBox(height: 2),
            _UrlStatus(
              icon: Icons.volume_up_outlined,
              label: 'Audio',
              url: resource.audioUrl,
              isSet: audioSet,
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(resource.type.toUpperCase(),
                  style: const TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit',
              onPressed: () => _showEditDialog(context, ref),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: Colors.red.shade400),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, ref),
            ),
            const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _ResourceEditDialog(resource: resource),
    ).then((_) => ref.invalidate(appResourcesProvider));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete resource?'),
        content: Text('Remove "${resource.label}" from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(resourceMutationProvider.notifier).delete(resource);
      ref.invalidate(appResourcesProvider);
    }
  }
}

class _UrlStatus extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final bool isSet;

  const _UrlStatus({
    required this.icon,
    required this.label,
    required this.url,
    required this.isSet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: isSet ? Colors.grey.shade500 : Colors.red.shade300),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        Expanded(
          child: Text(
            isSet ? url : 'Not set',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isSet ? Colors.grey.shade600 : Colors.red.shade400,
            ),
          ),
        ),
        if (isSet)
          InkWell(
            onTap: () => MediaPreviewDialog.show(context, url: url, label: label),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.visibility_outlined, size: 14, color: Colors.indigo.shade400),
            ),
          ),
      ],
    );
  }
}

class _ResourceEditDialog extends ConsumerStatefulWidget {
  final AppResource resource;
  const _ResourceEditDialog({required this.resource});

  @override
  ConsumerState<_ResourceEditDialog> createState() =>
      _ResourceEditDialogState();
}

class _ResourceEditDialogState extends ConsumerState<_ResourceEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelCtrl;
  late TextEditingController _fileUrlCtrl;
  late TextEditingController _audioUrlCtrl;
  late String _type;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.resource.label);
    _fileUrlCtrl = TextEditingController(text: widget.resource.fileUrl);
    _audioUrlCtrl = TextEditingController(text: widget.resource.audioUrl);
    _type = widget.resource.type;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _fileUrlCtrl.dispose();
    _audioUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.resource.copyWith(
      label: _labelCtrl.text.trim(),
      fileUrl: _fileUrlCtrl.text.trim(),
      audioUrl: _audioUrlCtrl.text.trim(),
      type: _type,
    );
    await ref.read(resourceMutationProvider.notifier).update(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(resourceMutationProvider);
    return AlertDialog(
      title: const Text('Edit Resource'),
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
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fileUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'File URL',
                        hintText: 'https://… (PDF or video file)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ThumbnailChip(ctrl: _fileUrlCtrl, label: 'File'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _audioUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Audio URL',
                        hintText: 'https://… (MP3 or M4A)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ThumbnailChip(ctrl: _audioUrlCtrl, label: 'Audio'),
                  ),
                ],
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
              : const Text('Save'),
        ),
      ],
    );
  }
}
