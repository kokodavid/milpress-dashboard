import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class AdminActivity {
  final String id;
  final String actorId;
  final String action; // e.g., admin_created, admin_updated, course_deleted
  final String? targetType; // e.g., admin, course
  final String? targetId;
  final Map<String, dynamic>? details; // optional JSON payload
  final DateTime createdAt;

  const AdminActivity({
    required this.id,
    required this.actorId,
    required this.action,
    this.targetType,
    this.targetId,
    this.details,
    required this.createdAt,
  });

  factory AdminActivity.fromMap(Map<String, dynamic> map) {
    return AdminActivity(
      id: map['id'] as String,
      actorId: map['actor_id'] as String,
      action: map['action'] as String,
      targetType: map['target_type'] as String?,
      targetId: map['target_id'] as String?,
      details: map['details'] != null ? Map<String, dynamic>.from(map['details'] as Map) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class AdminActivityRepository {
  final SupabaseClient _client;
  AdminActivityRepository(this._client);

  static const String table = 'admin_activity_logs';

  Future<void> log({
    required String action,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    final actor = _client.auth.currentUser;
    if (actor == null) return; // not logged in
    await _client.from(table).insert({
      'actor_id': actor.id,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'details': details,
    });
  }

  Future<List<AdminActivity>> fetchRecent({int limit = 20}) async {
    final List data = await _client
        .from(table)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map((e) => AdminActivity.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }
}

// Providers
final adminActivityRepositoryProvider = Provider<AdminActivityRepository>((ref) {
  final client = Supabase.instance.client;
  return AdminActivityRepository(client);
});

final recentAdminActivityProvider = FutureProvider.family<List<AdminActivity>, int>((ref, limit) async {
  // Keep the data alive for 2 minutes after last use
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 2), link.close);
  
  final repo = ref.watch(adminActivityRepositoryProvider);
  return repo.fetchRecent(limit: limit);
});
