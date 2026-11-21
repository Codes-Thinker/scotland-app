import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists login. Uses SharedPreferences when the plugin is linked;
/// falls back to a local JSON file so MissingPluginException never crashes.
class SessionStore {
  SessionStore._();

  static const _fileName = 'fnt_session.json';
  static Map<String, dynamic>? _memory;

  static Future<Map<String, dynamic>?> read() async {
    if (_memory != null) return Map<String, dynamic>.from(_memory!);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final email = prefs.getString('fnt_session_email');
      final loggedIn = prefs.getBool('fnt_logged_in') == true || (email != null && email.isNotEmpty);
      if (!loggedIn || email == null || email.isEmpty) {
        return _readFile();
      }
      return {
        'loggedIn': true,
        'email': email,
        'role': prefs.getString('fnt_session_role') ?? 'passenger',
        'name': prefs.getString('fnt_session_name'),
        'phone': prefs.getString('fnt_session_phone'),
        'id': prefs.getString('fnt_session_id'),
        'vehicle': prefs.getString('fnt_session_vehicle'),
        'licence': prefs.getString('fnt_session_licence'),
        'docs': prefs.getBool('fnt_session_docs'),
      };
    } on MissingPluginException {
      return _readFile();
    } on PlatformException {
      return _readFile();
    } catch (_) {
      return _readFile();
    }
  }

  static Future<void> write(Map<String, dynamic>? data) async {
    if (data == null) {
      _memory = null;
      await _clearPrefs();
      await _clearFile();
      return;
    }

    _memory = Map<String, dynamic>.from(data);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fnt_logged_in', true);
      await prefs.setString('fnt_session_email', '${data['email']}'.toLowerCase());
      await prefs.setString('fnt_session_role', '${data['role'] ?? 'passenger'}');
      await prefs.setString('fnt_session_name', '${data['name'] ?? ''}');
      await prefs.setString('fnt_session_phone', '${data['phone'] ?? ''}');
      await prefs.setString('fnt_session_id', '${data['id'] ?? ''}');
      await prefs.setBool('fnt_session_docs', data['docs'] == true);
      final vehicle = data['vehicle'] as String?;
      final licence = data['licence'] as String?;
      if (vehicle != null && vehicle.isNotEmpty) {
        await prefs.setString('fnt_session_vehicle', vehicle);
      } else {
        await prefs.remove('fnt_session_vehicle');
      }
      if (licence != null && licence.isNotEmpty) {
        await prefs.setString('fnt_session_licence', licence);
      } else {
        await prefs.remove('fnt_session_licence');
      }
      await prefs.reload();
    } on MissingPluginException {
      // Plugin not linked yet (hot restart after pub add) — file fallback.
    } on PlatformException {
      // ignore
    } catch (_) {
      // ignore
    }

    await _writeFile(data);
  }

  static Future<void> _clearPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fnt_logged_in', false);
      for (final k in [
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
    } catch (_) {}
  }

  static Future<File?> _file() async {
    if (kIsWeb) return null;
    try {
      return File('${Directory.systemTemp.path}/$_fileName');
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _readFile() async {
    try {
      final f = await _file();
      if (f == null || !await f.exists()) return _memory == null ? null : Map<String, dynamic>.from(_memory!);
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return null;
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        _memory = map;
        return Map<String, dynamic>.from(map);
      }
    } catch (_) {}
    return _memory == null ? null : Map<String, dynamic>.from(_memory!);
  }

  static Future<void> _writeFile(Map<String, dynamic> data) async {
    try {
      final f = await _file();
      if (f == null) return;
      await f.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  static Future<void> _clearFile() async {
    try {
      final f = await _file();
      if (f != null && await f.exists()) await f.delete();
    } catch (_) {}
  }
}
