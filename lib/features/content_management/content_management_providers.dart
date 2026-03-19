import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_content_model.dart';
import 'app_resource_model.dart';
import 'content_management_repository.dart';

final appContentProvider = FutureProvider<AppContent>((ref) async {
  final repo = ref.watch(contentManagementRepositoryProvider);
  return repo.fetchAppContent();
});

final appResourcesProvider = FutureProvider<List<AppResource>>((ref) async {
  final repo = ref.watch(contentManagementRepositoryProvider);
  return repo.fetchResources();
});
