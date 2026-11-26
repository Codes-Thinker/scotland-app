import 'dart:io';

/// Backend base URL for scotland-backend (`/api/v1`).
///
/// Override at build/run time:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1`
class ApiConfig {
  static const _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv.replaceAll(RegExp(r'/$'), '');
    // Android emulator → host machine. iOS simulator → localhost.
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
    return 'http://localhost:3000/api/v1';
  }

  static const connectTimeout = Duration(seconds: 20);
  static const receiveTimeout = Duration(seconds: 30);

  /// Socket.IO host (same machine as API, without `/api/v1`).
  static String get socketBaseUrl {
    final api = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return api.replaceFirst(RegExp(r'/api/v1$'), '');
  }

  static String get realtimeUrl => '$socketBaseUrl/realtime';
}
