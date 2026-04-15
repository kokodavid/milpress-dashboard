import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/admin_activity_repository.dart';
import '../auth/activity_actions.dart';
import 'step_type_definition.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class StepTypeRepository {
  final SupabaseClient _client;
  static const String _table = 'lesson_step_types';

  const StepTypeRepository(this._client);

  Future<List<StepTypeDefinition>> fetchAllTypes() async {
    final List data = await _client
        .from(_table)
        .select()
        .order('is_system', ascending: false)
        .order('created_at', ascending: true);
    return data
        .map((e) => StepTypeDefinition.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StepTypeDefinition>> fetchCustomTypes() async {
    final List data = await _client
        .from(_table)
        .select()
        .eq('is_system', false)
        .order('created_at', ascending: true);
    return data
        .map((e) => StepTypeDefinition.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<StepTypeDefinition> create(StepTypeDefinition input) async {
    final List data = await _client
        .from(_table)
        .insert(input.toInsertMap())
        .select();
    return StepTypeDefinition.fromMap(data.first as Map<String, dynamic>);
  }

  Future<void> update(StepTypeDefinition updated) async {
    await _client
        .from(_table)
        .update(updated.toUpdateMap())
        .eq('id', updated.id);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final stepTypeRepositoryProvider = Provider<StepTypeRepository>((ref) {
  return StepTypeRepository(Supabase.instance.client);
});

final allStepTypesProvider =
    FutureProvider<List<StepTypeDefinition>>((ref) async {
  final repo = ref.watch(stepTypeRepositoryProvider);
  return repo.fetchAllTypes();
});

final customStepTypesProvider =
    FutureProvider<List<StepTypeDefinition>>((ref) async {
  final repo = ref.watch(stepTypeRepositoryProvider);
  return repo.fetchCustomTypes();
});

// ── Mutation controller ───────────────────────────────────────────────────────

class StepTypeMutationController
    extends StateNotifier<AsyncValue<void>> {
  final StepTypeRepository _repo;
  final Ref _ref;

  StepTypeMutationController(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> create(StepTypeDefinition input) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.create(input);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.stepTypeCreated,
        targetType: 'lesson_step_type',
        targetId: created.id,
        details: {'key': created.key, 'display_name': created.displayName},
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> update(StepTypeDefinition updated) async {
    state = const AsyncLoading();
    try {
      await _repo.update(updated);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.stepTypeUpdated,
        targetType: 'lesson_step_type',
        targetId: updated.id,
        details: {'key': updated.key, 'display_name': updated.displayName},
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> delete(StepTypeDefinition def) async {
    state = const AsyncLoading();
    try {
      await _repo.delete(def.id);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.stepTypeDeleted,
        targetType: 'lesson_step_type',
        targetId: def.id,
        details: {'key': def.key, 'display_name': def.displayName},
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final stepTypeMutationProvider =
    StateNotifierProvider<StepTypeMutationController, AsyncValue<void>>((ref) {
  final repo = ref.watch(stepTypeRepositoryProvider);
  return StepTypeMutationController(repo, ref);
});
