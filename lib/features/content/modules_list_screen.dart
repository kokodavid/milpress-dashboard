import 'package:flutter/material.dart';

class ModulesListScreen extends StatelessWidget {
  const ModulesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modules')),
      body: const Center(
        child: Text('Modules list will appear here'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to Create Module screen
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Module'),
      ),
    );
  }
}
