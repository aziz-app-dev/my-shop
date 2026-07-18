import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../models/user/user_model.dart';
import '../firebase/firebase_service.dart';

/// Shop profile stored in Firestore at `users/{uid}` (the same doc the data
/// subcollections hang off). The stored shape matches `User.toMap()` so it
/// round-trips through Hive, Firestore, and backup unchanged.
class CloudUserService {
  final FirebaseService _fb;

  CloudUserService({FirebaseService? firebase})
    : _fb = firebase ?? FirebaseService.instance;

  /// Fetch the signed-in user's shop profile, or null if none / signed out.
  Future<User?> getProfile() async {
    if (!_fb.isSignedIn) return null;
    final snap = await _fb.userDoc.get();
    final data = snap.data();
    if (data == null || data['ownerName'] == null) return null;
    return _fromRow(data);
  }

  /// Back-compat alias used by the splash first-open flow.
  Future<User?> getFirstUser() => getProfile();

  /// Save/overwrite the signed-in user's shop profile.
  Future<void> upsertUser(User user) async {
    if (!_fb.isSignedIn) return;
    await _fb.userDoc.set({
      ...user.toMap(),
      'email': user.email.trim().toLowerCase(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  User _fromRow(Map<String, dynamic> row) {
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
      // Setup is complete if either copy says so.
      shopSetupComplete: local.shopSetupComplete || remote.shopSetupComplete,
    );
  }
}
