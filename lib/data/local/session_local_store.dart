import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_models.dart';

/// Local session DB (SharedPreferences) — tokens + user for auth restore.
class SessionLocalStore {
  SessionLocalStore._();
  static final SessionLocalStore instance = SessionLocalStore._();

  static const _kAccess = 'fnt_access_token';
  static const _kRefresh = 'fnt_refresh_token';
  static const _kUser = 'fnt_auth_user_json';
  static const _kRoleMode = 'fnt_role_mode'; // passenger | driver (UI mode)

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required ApiUser user,
    String? roleMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, accessToken);
    await prefs.setString(_kRefresh, refreshToken);
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
    final mode = roleMode ?? user.primaryRole;
    await prefs.setString(_kRoleMode, mode);
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, accessToken);
    await prefs.setString(_kRefresh, refreshToken);
  }

  Future<void> updateUser(ApiUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  Future<void> setRoleMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRoleMode, mode);
  }

  Future<String?> readAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccess);
  }

  Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefresh);
  }

  Future<ApiUser?> readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) return ApiUser.fromJson(map);
    } catch (_) {}
    return null;
  }

  Future<String?> readRoleMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRoleMode);
  }

  Future<bool> hasSession() async {
    final access = await readAccessToken();
    final user = await readUser();
    return access != null && access.isNotEmpty && user != null;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kUser);
    await prefs.remove(_kRoleMode);
    // Legacy mock session keys
    for (final k in [
      'fnt_logged_in',
      'fnt_session_email',
      'fnt_session_role',
      'fnt_session_name',
      'fnt_session_phone',
      'fnt_session_id',
      'fnt_session_vehicle',
      'fnt_session_licence',
      'fnt_session_docs',
    ]) {
      await prefs.remove(k);
    }
  }
}
