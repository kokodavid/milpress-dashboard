import 'package:flutter/material.dart';

class LessonsListScreen extends StatelessWidget {
  const LessonsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: const Center(
        child: Text('Lessons list will appear here'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to Create Lesson screen
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Lesson'),
      ),
    );
  }
}
