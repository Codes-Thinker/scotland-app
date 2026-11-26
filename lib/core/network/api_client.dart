import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/local/session_local_store.dart';
import '../../data/models/auth_models.dart';
import '../api_config.dart';
import 'api_exception.dart';

typedef TokenRefreshed = Future<void> Function(AuthTokens tokens);

/// HTTP client with Bearer auth + single-flight refresh on 401.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    SessionLocalStore? store,
  })  : _http = httpClient ?? http.Client(),
        _store = store ?? SessionLocalStore.instance;

  final http.Client _http;
  final SessionLocalStore _store;

  String? _accessToken;
  String? _refreshToken;
  Future<bool>? _refreshing;
  TokenRefreshed? onTokensRefreshed;

  String? get accessToken => _accessToken;

  void setTokens({String? access, String? refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  Future<void> loadTokensFromStore() async {
    _accessToken = await _store.readAccessToken();
    _refreshToken = await _store.readRefreshToken();
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final raw = await _sendRaw('GET', path, query: query, auth: auth);
    if (raw is Map<String, dynamic>) return raw;
    if (raw is List) return {'data': raw};
    return {};
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final raw = await _sendRaw('GET', path, query: query, auth: auth);
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['documents'] ?? raw['items'];
      if (data is List) return data;
    }
    return const [];
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    final raw = await _sendRaw('POST', path, body: body, auth: auth);
    return raw is Map<String, dynamic> ? raw : {};
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    final raw = await _sendRaw('PUT', path, body: body, auth: auth);
    return raw is Map<String, dynamic> ? raw : {};
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    final raw = await _sendRaw('PATCH', path, body: body, auth: auth);
    return raw is Map<String, dynamic> ? raw : {};
  }

  Future<void> postEmpty(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    await _sendRaw('POST', path, body: body, auth: auth, expectBody: false);
  }

  Future<Map<String, dynamic>> multipart(
    String path, {
    required String fileField,
    required String filePath,
    String? filename,
    Map<String, String>? fields,
    bool auth = true,
  }) async {
    Future<http.StreamedResponse> doSend(String? token) async {
      final req = http.MultipartRequest('POST', _uri(path));
      if (auth && token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      if (fields != null) req.fields.addAll(fields);
      req.files.add(await http.MultipartFile.fromPath(
        fileField,
        filePath,
        filename: filename,
      ));
      return _http.send(req).timeout(ApiConfig.receiveTimeout);
    }

    var streamed = await doSend(_accessToken);
    var res = await http.Response.fromStream(streamed);

    if (res.statusCode == 401 && auth) {
      final ok = await _tryRefresh();
      if (ok) {
        streamed = await doSend(_accessToken);
        res = await http.Response.fromStream(streamed);
      }
    }

    return _decode(res, expectBody: true);
  }

  Future<dynamic> _sendRaw(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
    bool expectBody = true,
  }) async {
    Future<http.Response> doSend(String? token) {
      final headers = <String, String>{
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        if (auth && token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      final uri = _uri(path, query);
      final encoded = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'GET':
          return _http.get(uri, headers: headers).timeout(ApiConfig.receiveTimeout);
        case 'PUT':
          return _http.put(uri, headers: headers, body: encoded).timeout(ApiConfig.receiveTimeout);
        case 'PATCH':
          return _http.patch(uri, headers: headers, body: encoded).timeout(ApiConfig.receiveTimeout);
        case 'POST':
        default:
          return _http.post(uri, headers: headers, body: encoded).timeout(ApiConfig.receiveTimeout);
      }
    }

    var res = await doSend(_accessToken);
    if (res.statusCode == 401 && auth) {
      final ok = await _tryRefresh();
      if (ok) res = await doSend(_accessToken);
    }
    return _decodeDynamic(res, expectBody: expectBody);
  }

  Future<bool> _tryRefresh() {
    _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
    return _refreshing!;
  }

  Future<bool> _refresh() async {
    final refresh = _refreshToken ?? await _store.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _http
          .post(
            _uri('/auth/refresh'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(ApiConfig.receiveTimeout);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        await _store.clear();
        _accessToken = null;
        _refreshToken = null;
        return false;
      }
      final tokens = AuthTokens.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      _accessToken = tokens.accessToken;
      _refreshToken = tokens.refreshToken;
      await _store.saveSession(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        user: tokens.user,
      );
      if (onTokensRefreshed != null) await onTokensRefreshed!(tokens);
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decode(http.Response res, {required bool expectBody}) {
    final raw = _decodeDynamic(res, expectBody: expectBody);
    return raw is Map<String, dynamic> ? raw : {};
  }

  dynamic _decodeDynamic(http.Response res, {required bool expectBody}) {
    if (res.statusCode == 204 || res.body.isEmpty) {
      if (res.statusCode >= 200 && res.statusCode < 300) return expectBody ? <String, dynamic>{} : null;
    }
    dynamic decoded;
    if (res.body.isNotEmpty) {
      try {
        decoded = jsonDecode(res.body);
      } catch (_) {}
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return expectBody ? (decoded ?? <String, dynamic>{}) : null;
    }
    final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    final message = _messageFrom(map) ?? res.reasonPhrase ?? 'Request failed';
    throw ApiException(statusCode: res.statusCode, message: message, details: map['details']);
  }

  String? _messageFrom(Map<String, dynamic> json) {
    final m = json['message'];
    if (m is String && m.isNotEmpty) return m;
    if (m is List && m.isNotEmpty) return m.map((e) => '$e').join(' ');
    final err = json['error'];
    if (err is String && err.isNotEmpty) return err;
    return null;
  }

  void dispose() => _http.close();
}
