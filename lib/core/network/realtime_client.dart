import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../api_config.dart';
import 'api_client.dart';

/// Socket.IO client for Nest `/realtime` (JWT via handshake.auth.token).
class RealtimeClient {
  RealtimeClient(this._api);

  final ApiClient _api;
  io.Socket? _socket;
  bool _wanted = false;

  final _ready = StreamController<String>.broadcast();
  final _rideOffer = StreamController<Map<String, dynamic>>.broadcast();
  final _rideStatus = StreamController<Map<String, dynamic>>.broadcast();
  final _chatMessage = StreamController<Map<String, dynamic>>.broadcast();
  final _alertNew = StreamController<Map<String, dynamic>>.broadcast();

  Stream<String> get onReady => _ready.stream;
  Stream<Map<String, dynamic>> get onRideOffer => _rideOffer.stream;
  Stream<Map<String, dynamic>> get onRideStatus => _rideStatus.stream;
  Stream<Map<String, dynamic>> get onChatMessage => _chatMessage.stream;
  Stream<Map<String, dynamic>> get onAlertNew => _alertNew.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    _wanted = true;
    final token = _api.accessToken;
    if (token == null || token.isEmpty) {
      await _api.loadTokensFromStore();
    }
    final access = _api.accessToken;
    if (access == null || access.isEmpty) return;

    await disconnect(keepWanted: true);

    final socket = io.io(
      ApiConfig.realtimeUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .setAuth({'token': access})
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('[realtime] connected');
    });
    socket.on('ready', (data) {
      final map = _asMap(data);
      final userId = '${map['userId'] ?? ''}';
      if (userId.isNotEmpty) _ready.add(userId);
    });
    socket.on('ride.offer', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) _rideOffer.add(map);
    });
    socket.on('ride.status', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) _rideStatus.add(map);
    });
    socket.on('chat.message', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) _chatMessage.add(map);
    });
    socket.on('alert.new', (data) {
      final map = _asMap(data);
      if (map.isNotEmpty) _alertNew.add(map);
    });
    socket.onDisconnect((_) => debugPrint('[realtime] disconnected'));
    socket.onConnectError((e) => debugPrint('[realtime] connect error: $e'));
    socket.onError((e) => debugPrint('[realtime] error: $e'));

    _socket = socket;
    socket.connect();
  }

  Future<void> reconnectWithFreshToken() async {
    if (!_wanted) return;
    await connect();
  }

  Future<void> disconnect({bool keepWanted = false}) async {
    if (!keepWanted) _wanted = false;
    final s = _socket;
    _socket = null;
    if (s != null) {
      try {
        s.disconnect();
        s.dispose();
      } catch (_) {}
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  void dispose() {
    unawaited(disconnect());
    _ready.close();
    _rideOffer.close();
    _rideStatus.close();
    _chatMessage.close();
    _alertNew.close();
  }
}
