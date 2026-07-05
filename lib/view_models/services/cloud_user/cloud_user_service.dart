import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../models/user/user_model.dart';

class CloudUserService {
  final SupabaseClient _supabase;

  CloudUserService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Table used for non-auth "profile by email".
  /// You need a Supabase table `app_users` with a UNIQUE `email` column.
  static const String table = 'app_users';

  Future<User?> getUserByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final row =
        await _supabase.from(table).select().eq('email', normalized).maybeSingle();
    if (row == null) return null;

    return _fromRow(row);
  }

  Future<void> upsertUser(User user) async {
    final payload = _toRow(user);
    await _supabase.from(table).upsert(payload);
  }

  Map<String, dynamic> _toRow(User user) {
    return {
      ...user.toMap(),
      'email': user.email.trim().toLowerCase(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  User _fromRow(Map<String, dynamic> row) {
    // Stored shape matches User.toMap(), so we can parse directly.
    // Guard: email normalization.
    final map = <String, dynamic>{...row};
    if (map['email'] is String) {
      map['email'] = (map['email'] as String).trim().toLowerCase();
    }

    try {
      return User.fromMap(map);
    } catch (e) {
      debugPrint('Cloud user parse error: $e');
      rethrow;
    }
  }

  /// Merge remote into local when remote has extra info.
  /// Local always wins if it already has a non-empty value.
  User mergePreferLocal({required User local, required User remote}) {
    String pickString(String a, String b) => a.trim().isNotEmpty ? a : b;
    String? pickNullable(String? a, String? b) {
      if (a == null) return b;
      return a.trim().isNotEmpty ? a : b;
    }

    final mergedBankDetails =
        local.bankDetails.isNotEmpty ? local.bankDetails : remote.bankDetails;

    return User(
      id: local.id.isNotEmpty ? local.id : remote.id,
      ownerName: pickString(local.ownerName, remote.ownerName),
      email: pickString(local.email, remote.email),
      shopName: pickString(local.shopName, remote.shopName),
      shopTagline: pickNullable(local.shopTagline, remote.shopTagline),
      shopAddress: pickString(local.shopAddress, remote.shopAddress),
      shopLogoPath: pickNullable(local.shopLogoPath, remote.shopLogoPath),
      userImagePath: pickNullable(local.userImagePath, remote.userImagePath),
      phoneNumber: pickString(local.phoneNumber, remote.phoneNumber),
      bankDetails: mergedBankDetails,
      whatsapp: pickNullable(local.whatsapp, remote.whatsapp),
      facebook: pickNullable(local.facebook, remote.facebook),
      twitter: pickNullable(local.twitter, remote.twitter),
      instagram: pickNullable(local.instagram, remote.instagram),
    );
  }
}

