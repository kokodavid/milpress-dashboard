import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_models.dart';

class ProfilesQuery {
  final String? search; // search across first_name, last_name, email
  final int? limit;
  final int? offset;
  final String? orderBy;
  final bool ascending;

  const ProfilesQuery({
    this.search,
    this.limit,
    this.offset,
    this.orderBy,
    this.ascending = true,
  });
}

class ProfilesRepository {
  final SupabaseClient _client;
  ProfilesRepository(this._client);

  static const String table = 'profiles';

  Future<List<Profile>> fetchProfiles({ProfilesQuery? query}) async {
    dynamic qb = _client.from(table).select();

    if (query?.search != null && query!.search!.isNotEmpty) {
      final q = query.search!;
      qb = qb.or('first_name.ilike.%$q%,last_name.ilike.%$q%,email.ilike.%$q%');
    }
    if (query?.orderBy != null) {
      qb = qb.order(query!.orderBy!, ascending: query.ascending);
    } else {
      qb = qb.order('created_at', ascending: false);
    }
    if (query?.limit != null) {
      qb = qb.limit(query!.limit!);
    }
    if (query?.offset != null) {
      final end = (query!.offset! + (query.limit ?? 50)) - 1;
      qb = qb.range(query.offset!, end);
    }

    final List data = await qb;
    return data.map((e) => Profile.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Profile?> fetchById(String id) async {
    final data = await _client.from(table).select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(Map<String, dynamic>.from(data));
  }

  Future<int> countProfiles() async {
    // Simple and compatible: fetch IDs and count client-side.
    final List data = await _client.from(table).select('id');
    return data.length;
  }
}

// Providers
final profilesRepositoryProvider = Provider<ProfilesRepository>((ref) {
  final client = Supabase.instance.client;
  return ProfilesRepository(client);
});

final profilesListProvider = FutureProvider.family<List<Profile>, ProfilesQuery?>((ref, query) async {
  final repo = ref.watch(profilesRepositoryProvider);
  return repo.fetchProfiles(query: query);
});

final profileByIdProvider = FutureProvider.family<Profile?, String>((ref, id) async {
  final repo = ref.watch(profilesRepositoryProvider);
  return repo.fetchById(id);
});

final usersCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(profilesRepositoryProvider);
  return repo.countProfiles();
});
