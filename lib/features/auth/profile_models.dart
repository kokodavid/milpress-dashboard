import 'package:flutter/foundation.dart';

@immutable
class Profile {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Profile({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName {
    final parts = [firstName, lastName].where((e) => (e ?? '').trim().isNotEmpty).toList();
    return parts.isEmpty ? '' : parts.join(' ');
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      email: map['email'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) : null,
    );
  }
}
