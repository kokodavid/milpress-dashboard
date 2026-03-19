import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:milpress_dashboard/features/auth/admin_activity_repository.dart';
import 'package:milpress_dashboard/features/auth/activity_actions.dart';

import 'app_content_model.dart';
import 'app_resource_model.dart';

final contentManagementRepositoryProvider =
    Provider<ContentManagementRepository>((ref) {
  final client = Supabase.instance.client;
  return ContentManagementRepository(client);
});

class ContentManagementRepository {
  final SupabaseClient _client;
  ContentManagementRepository(this._client);

  static const String _contentTable = 'app_content';
  static const String _resourcesTable = 'app_resources';

  // ── app_content (single row) ──────────────────────────────────────────────

  Future<AppContent> fetchAppContent() async {
    final data = await _client
        .from(_contentTable)
        .select()
        .eq('id', 1)
        .maybeSingle();
    if (data == null) return const AppContent();
    return AppContent.fromMap(data);
  }

  Future<void> updateAppContent(AppContent content) async {
    await _client
        .from(_contentTable)
        .upsert({'id': 1, ...content.toUpdateMap()});
  }

  // ── app_resources (ordered list) ──────────────────────────────────────────

  Future<List<AppResource>> fetchResources() async {
    final List data = await _client
        .from(_resourcesTable)
        .select()
        .order('display_order', ascending: true);
    return data
        .map((e) => AppResource.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppResource> createResource(AppResource resource) async {
    final List data = await _client
        .from(_resourcesTable)
        .insert(resource.toInsertMap())
        .select();
    return AppResource.fromMap(data.first as Map<String, dynamic>);
  }

  Future<void> updateResource(AppResource resource) async {
    await _client
        .from(_resourcesTable)
        .update(resource.toUpdateMap())
        .eq('id', resource.id);
  }

  Future<void> deleteResource(String id) async {
    await _client.from(_resourcesTable).delete().eq('id', id);
  }

  /// Batch-update display_order for a reordered list.
  Future<void> reorderResources(List<AppResource> resources) async {
    for (int i = 0; i < resources.length; i++) {
      await _client
          .from(_resourcesTable)
          .update({'display_order': i + 1})
          .eq('id', resources[i].id);
    }
  }
}

// ── Mutation controllers ───────────────────────────────────────────────────

class UpdateAppContentController extends StateNotifier<AsyncValue<void>> {
  final ContentManagementRepository _repo;
  final Ref _ref;
  UpdateAppContentController(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> save(AppContent content) async {
    state = const AsyncLoading();
    try {
      await _repo.updateAppContent(content);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.appContentUpdated,
        targetType: 'app_content',
        targetId: '1',
        details: content.toUpdateMap(),
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final updateAppContentProvider =
    StateNotifierProvider<UpdateAppContentController, AsyncValue<void>>((ref) {
  final repo = ref.watch(contentManagementRepositoryProvider);
  return UpdateAppContentController(repo, ref);
});

class ResourceMutationController extends StateNotifier<AsyncValue<void>> {
  final ContentManagementRepository _repo;
  final Ref _ref;
  ResourceMutationController(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> create(AppResource resource) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createResource(resource);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.appResourceCreated,
        targetType: 'app_resource',
        targetId: created.id,
        details: {'label': created.label, 'type': created.type},
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> update(AppResource resource) async {
    state = const AsyncLoading();
    try {
      await _repo.updateResource(resource);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.appResourceUpdated,
        targetType: 'app_resource',
        targetId: resource.id,
        details: {'label': resource.label, 'type': resource.type},
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> delete(AppResource resource) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteResource(resource.id);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.appResourceDeleted,
        targetType: 'app_resource',
        targetId: resource.id,
        details: {'label': resource.label},
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> reorder(List<AppResource> resources) async {
    state = const AsyncLoading();
    try {
      await _repo.reorderResources(resources);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final resourceMutationProvider =
    StateNotifierProvider<ResourceMutationController, AsyncValue<void>>((ref) {
  final repo = ref.watch(contentManagementRepositoryProvider);
  return ResourceMutationController(repo, ref);
});
