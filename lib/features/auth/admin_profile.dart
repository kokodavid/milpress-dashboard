import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class AdminProfile {
  final String id;
  final String? name;
  final String? email;
  final String? role;
  final bool? isActive;
  final DateTime? lastLogin;

  const AdminProfile({
    required this.id,
    this.name,
    this.email,
    this.role,
    this.isActive,
    this.lastLogin,
  });

  factory AdminProfile.fromMap(Map<String, dynamic> map) {
    return AdminProfile(
      id: map['id'] as String,
      name: map['name'] as String?,
      email: map['email'] as String?,
      role: map['role'] as String?,
      isActive: map['is_active'] as bool?,
      lastLogin: map['last_login'] != null ? DateTime.tryParse(map['last_login'] as String) : null,
    );
  }
}

final currentUserProvider = StreamProvider<User?>((ref) {
  final auth = Supabase.instance.client.auth;
  return auth.onAuthStateChange.map((e) => e.session?.user);
});

final adminProfileProvider = FutureProvider.family<AdminProfile?, String>((ref, userId) async {
  final client = Supabase.instance.client;
  final List<dynamic> data = await client
      .from('admin_profiles')
      .select('id, name, email, role, is_active, last_login')
      .eq('id', userId)
      .limit(1);
  if (data.isNotEmpty) {
    final row = Map<String, dynamic>.from(data.first as Map);
    return AdminProfile.fromMap(row);
  }
  return null;
});

String computeInitials(String? name, {String fallback = 'AD'}) {
  if (name == null || name.trim().isEmpty) return fallback;
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return fallback;
  String first = parts.first[0];
  String second = parts.length > 1 ? parts.last[0] : '';
  final res = (first + second).toUpperCase();
  return res.isEmpty ? fallback : res;
}
