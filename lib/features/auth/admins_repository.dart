import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_profile.dart';

class AdminsRepository {
  final SupabaseClient _client;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
  AdminsRepository(this._client);

  static const table = 'admin_profiles';

  Future<CreateAdminResult> create({
    required String name,
    required String email,
    String role = 'admin',
    bool isActive = true,
  }) async {

    final resp = await _client.functions.invoke('bright-worker', body: {
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'strategy': 'temp_password',
    });

    if (resp.status >= 400) {
      throw Exception('Edge function failed (${resp.status}): ${resp.data}');
    }

    final data = resp.data as Map?;
    final dynamic idCandidate = data?['userId'] ?? data?['id'] ?? data?['user_id'];
    if (idCandidate == null || idCandidate is! String || idCandidate.isEmpty) {
      throw Exception('Failed to create admin user: invalid response');
    }
  final String userId = idCandidate;
  final dynamic tempCandidate = data != null ? data["tempPassword"] : null;
  final String? tempPassword = tempCandidate is String && tempCandidate.isNotEmpty
    ? tempCandidate
    : null;

    final List prof = await _client
        .from(table)
        .select('id, name, email, role, is_active, last_login')
        .eq('id', userId)
        .limit(1);
    if (prof.isEmpty) {
      return CreateAdminResult(
        profile: AdminProfile(
        id: userId,
        name: name,
        email: email,
        role: role,
        isActive: isActive,
        lastLogin: null,
        ),
        tempPassword: tempPassword,
      );
    }
    final row = Map<String, dynamic>.from(prof.first as Map);
    return CreateAdminResult(profile: AdminProfile.fromMap(row), tempPassword: tempPassword);
  }

  Future<void> update(
    String id, {
    String? name,
    String? email,
    String? role,
    bool? isActive,
  }) async {
    final patch = <String, dynamic>{};
    if (name != null) patch['name'] = name;
    if (email != null) patch['email'] = email;
    if (role != null) patch['role'] = role;
    if (isActive != null) patch['is_active'] = isActive;
    if (patch.isEmpty) return;
    await _client.from(table).update(patch).eq('id', id);
  }

  Future<void> delete(String id) async {
    final resp = await _client.functions.invoke('bright-worker', body: {
      'action': 'delete_admin',
      'id': id,
    });
    if (resp.status >= 400) {
      throw Exception('Delete failed (${resp.status}): ${resp.data}');
    }
  }
}

final adminsRepositoryProvider = Provider<AdminsRepository>((ref) {
  final client = Supabase.instance.client;
  return AdminsRepository(client);
});

final tempAdminPasswordsProvider = StateProvider<Map<String, String>>((ref) => {});

class CreateAdminController extends StateNotifier<AsyncValue<CreateAdminResult?>> {
  final AdminsRepository _repo;
  CreateAdminController(this._repo) : super(const AsyncData(null));

  Future<CreateAdminResult?> create({required String name, required String email, String role = 'admin', bool isActive = true}) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.create(name: name, email: email, role: role, isActive: isActive);
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createAdminProvider = StateNotifierProvider<CreateAdminController, AsyncValue<CreateAdminResult?>>((ref) {
  final repo = ref.watch(adminsRepositoryProvider);
  return CreateAdminController(repo);
});

class UpdateAdminController extends StateNotifier<AsyncValue<void>> {
  final AdminsRepository _repo;
  UpdateAdminController(this._repo) : super(const AsyncData(null));

  Future<void> update(String id, {String? name, String? email, String? role, bool? isActive}) async {
    state = const AsyncLoading();
    try {
      await _repo.update(id, name: name, email: email, role: role, isActive: isActive);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final updateAdminProvider = StateNotifierProvider<UpdateAdminController, AsyncValue<void>>((ref) {
  final repo = ref.watch(adminsRepositoryProvider);
  return UpdateAdminController(repo);
});

class DeleteAdminController extends StateNotifier<AsyncValue<void>> {
  final AdminsRepository _repo;
  DeleteAdminController(this._repo) : super(const AsyncData(null));

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.delete(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final deleteAdminProvider = StateNotifierProvider<DeleteAdminController, AsyncValue<void>>((ref) {
  final repo = ref.watch(adminsRepositoryProvider);
  return DeleteAdminController(repo);
});

class CreateAdminResult {
  final AdminProfile profile;
  final String? tempPassword;

  CreateAdminResult({required this.profile, required this.tempPassword});
}
