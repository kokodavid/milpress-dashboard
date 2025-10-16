import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'modules_model.dart';

// Repository provider
final modulesRepositoryProvider = Provider<ModulesRepository>((ref) {
  final client = Supabase.instance.client;
  return ModulesRepository(client);
});

// Queries
class ModulesQuery {
  final String? courseId;
  final bool? locked;
  final String? search; // searches description and lock_message
  final int? limit;
  final int? offset;
  final String? orderBy; // defaults to position when null
  final bool ascending;

  const ModulesQuery({
    this.courseId,
    this.locked,
    this.search,
    this.limit,
    this.offset,
    this.orderBy,
    this.ascending = true,
  });
}

// Read providers
final modulesListProvider = FutureProvider.family<List<Module>, ModulesQuery?>((ref, query) async {
  final repo = ref.watch(modulesRepositoryProvider);
  return repo.fetchModules(query: query);
});

final modulesForCourseProvider = FutureProvider.family<List<Module>, String>((ref, courseId) async {
  final repo = ref.watch(modulesRepositoryProvider);
  return repo.fetchModulesByCourseId(courseId);
});

final moduleByIdProvider = FutureProvider.family<Module?, String>((ref, id) async {
  final repo = ref.watch(modulesRepositoryProvider);
  return repo.fetchModuleById(id);
});

// Mutation controllers
class CreateModuleController extends StateNotifier<AsyncValue<Module?>> {
  final ModulesRepository _repo;
  CreateModuleController(this._repo) : super(const AsyncData<Module?>(null));

  Future<Module?> create(ModuleCreate data) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createModule(data);
      state = AsyncData(created);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createModuleProvider = StateNotifierProvider<CreateModuleController, AsyncValue<Module?>>((ref) {
  final repo = ref.watch(modulesRepositoryProvider);
  return CreateModuleController(repo);
});

class UpdateModuleController extends StateNotifier<AsyncValue<void>> {
  final ModulesRepository _repo;
  UpdateModuleController(this._repo) : super(const AsyncData(null));

  Future<void> update(String id, ModuleUpdate data) async {
    state = const AsyncLoading();
    try {
      await _repo.updateModule(id, data);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final updateModuleProvider = StateNotifierProvider<UpdateModuleController, AsyncValue<void>>((ref) {
  final repo = ref.watch(modulesRepositoryProvider);
  return UpdateModuleController(repo);
});

class DeleteModuleController extends StateNotifier<AsyncValue<void>> {
  final ModulesRepository _repo;
  DeleteModuleController(this._repo) : super(const AsyncData(null));

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteModule(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final deleteModuleProvider = StateNotifierProvider<DeleteModuleController, AsyncValue<void>>((ref) {
  final repo = ref.watch(modulesRepositoryProvider);
  return DeleteModuleController(repo);
});

// Repository
class ModulesRepository {
  final SupabaseClient _client;
  ModulesRepository(this._client);

  static const String table = 'modules';

  Future<List<Module>> fetchModules({ModulesQuery? query}) async {
    dynamic qb = _client.from(table).select();

    if (query?.courseId != null) {
      qb = qb.eq('course_id', query!.courseId!);
    }
    if (query?.locked != null) {
      qb = qb.eq('locked', query!.locked!);
    }
    if (query?.search != null && query!.search!.isNotEmpty) {
      qb = qb.or('description.ilike.%${query.search!}%,lock_message.ilike.%${query.search!}%');
    }

    if (query?.orderBy != null) {
      qb = qb.order(query!.orderBy!, ascending: query.ascending);
    } else {
      qb = qb.order('position', ascending: true);
    }

    if (query?.limit != null) {
      qb = qb.limit(query!.limit!);
    }
    if (query?.offset != null) {
      final end = (query!.offset! + (query.limit ?? 50)) - 1;
      qb = qb.range(query.offset!, end);
    }

    final List data = await qb;
    return data.map((e) => Module.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<Module>> fetchModulesByCourseId(String courseId,
      {int? limit, int? offset, String orderBy = 'position', bool ascending = true}) async {
    dynamic qb = _client.from(table).select().eq('course_id', courseId).order(orderBy, ascending: ascending);
    if (limit != null) qb = qb.limit(limit);
    if (offset != null) qb = qb.range(offset, (offset + (limit ?? 50)) - 1);
    final List data = await qb;
    return data.map((e) => Module.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<Module?> fetchModuleById(String id) async {
    final data = await _client.from(table).select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return Module.fromMap(data);
  }

  Future<Module> createModule(ModuleCreate input) async {
    final List data = await _client.from(table).insert(input.toInsertMap()).select();
    return Module.fromMap(data.first as Map<String, dynamic>);
  }

  Future<void> updateModule(String id, ModuleUpdate update) async {
    await _client.from(table).update(update.toUpdateMap()).eq('id', id);
  }

  Future<void> deleteModule(String id) async {
    await _client.from(table).delete().eq('id', id);
  }
}
