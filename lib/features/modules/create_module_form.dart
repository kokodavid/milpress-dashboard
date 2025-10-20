import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'modules_model.dart';
import 'modules_repository.dart';

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
      final repo = ref.read(modulesRepositoryProvider);
      await repo.createModule(
        ModuleCreate(
          courseId: widget.courseId,
          position: position,
          durationMinutes: duration,
          locked: _locked,
          lockMessage: _locked && lockMessageText.isNotEmpty ? lockMessageText : null,
          description: descriptionText.isNotEmpty ? descriptionText : null,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create Module',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g. Introduction to the topic',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(labelText: 'Position'),
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
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(labelText: 'Duration (min)'),
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
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _locked,
                  onChanged: (value) {
                    setState(() {
                      _locked = value;
                    });
                  },
                  title: const Text('Locked'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_locked) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lockMessageController,
                    decoration: const InputDecoration(labelText: 'Lock message'),
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Create Module'),
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
