import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/network/realtime_client.dart';
import '../data/models/chat_models.dart';
import '../data/models/ride_models.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/ride_repository.dart';
import '../services/app_state.dart';
import '../shared/models/models.dart';
import 'auth_view_model.dart';

/// Ride chat over `GET/POST /rides/:id/messages` + realtime `chat.message`.
class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    required AuthViewModel auth,
    required AppState appState,
    required RealtimeClient realtime,
  })  : _auth = auth,
        _app = appState,
        _realtime = realtime,
        _chat = ChatRepository(auth.repository.client),
        _rides = RideRepository(auth.repository.client) {
    _auth.addListener(_onAuthChanged);
    _subs.add(_realtime.onChatMessage.listen(_onRealtimeMessage));
    if (_auth.isLoggedIn) {
      unawaited(refreshThreads());
    }
  }

  final AuthViewModel _auth;
  final AppState _app;
  final RealtimeClient _realtime;
  final ChatRepository _chat;
  final RideRepository _rides;
  final List<StreamSubscription<dynamic>> _subs = [];

  final List<ChatThread> _threads = [];
  bool _loading = false;
  String? _error;
  String? _openThreadId;

  bool get isLoading => _loading;
  String? get error => _error;
  List<ChatThread> get threads => List.unmodifiable(_threads);
  int get unreadCount => _threads.fold(0, (s, t) => s + t.unread);

  ChatThread? threadById(String id) {
    for (final t in _threads) {
      if (t.id == id || t.rideId == id) return t;
    }
    return null;
  }

  void setOpenThread(String? id) {
    _openThreadId = id;
    if (id != null) markRead(id);
  }

  Future<void> refreshThreads() async {
    if (!_auth.isLoggedIn) {
      _threads.clear();
      _syncApp();
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final role = _auth.isDriverMode ? 'driver' : 'passenger';
      final rides = await _rides.list(role: role, pageSize: 40);
      final chatable = rides.where((r) => r.driverId != null && r.driverId!.isNotEmpty).toList();

      final next = <ChatThread>[];
      for (final ride in chatable) {
        final existing = threadById(ride.id);
        final messages = existing?.messages ?? const <ChatMessage>[];
        final peer = _auth.isDriverMode
            ? (ride.passengerName.isEmpty ? 'Passenger' : ride.passengerName)
            : (ride.driverName ?? 'Driver');
        final last = messages.isNotEmpty
            ? messages.last
            : ChatMessage(
                from: 'System',
                body: '${ride.pickup.address} → ${ride.drop.address}',
                time: _fmt(ride.requestedAt.toLocal()),
              );
        next.add(
          ChatThread(
            id: ride.id,
            passengerName: peer,
            rideId: ride.id,
            lastMessage: last.body,
            time: last.time,
            unread: existing?.unread ?? 0,
            messages: messages,
          ),
        );
      }

      // Preserve order: most recently messaged first, else API order.
      next.sort((a, b) {
        final au = a.unread;
        final bu = b.unread;
        if (au != bu) return bu.compareTo(au);
        return 0;
      });

      _threads
        ..clear()
        ..addAll(next);
      _error = null;
      _syncApp();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load chats.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> openThread(String rideId) async {
    _openThreadId = rideId;
    ensureThreadShell(rideId);
    return loadMessages(rideId);
  }

  void ensureThreadShell(String rideId, {String? peerName}) {
    final i = _threads.indexWhere((t) => t.id == rideId || t.rideId == rideId);
    if (i >= 0) return;
    final name = peerName ??
        (_auth.isDriverMode
            ? (_app.activeTrip?.passengerName ?? 'Passenger')
            : (_app.activeRide?.driverName ?? 'Driver'));
    _threads.insert(
      0,
      ChatThread(
        id: rideId,
        passengerName: name,
        rideId: rideId,
        lastMessage: 'Chat open',
        time: _fmt(DateTime.now()),
        unread: 0,
        messages: const [],
      ),
    );
    _syncApp();
    notifyListeners();
  }

  Future<String?> loadMessages(String rideId) async {
    try {
      final page = await _chat.listMessages(rideId);
      // API returns newest first — reverse for chronological UI.
      final chronological = page.data.reversed.toList();
      final ui = chronological.map((m) => _toUi(m)).toList();
      final i = _threads.indexWhere((t) => t.id == rideId || t.rideId == rideId);
      if (i < 0) {
        ensureThreadShell(rideId);
      }
      final idx = _threads.indexWhere((t) => t.id == rideId || t.rideId == rideId);
      if (idx < 0) return null;
      final t = _threads[idx];
      final last = ui.isNotEmpty ? ui.last : null;
      _threads[idx] = t.copyWith(
        messages: ui,
        lastMessage: last?.body ?? t.lastMessage,
        time: last?.time ?? t.time,
        unread: 0,
      );
      _syncApp();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not load messages.';
    }
  }

  Future<String?> send(String rideId, String body) async {
    final text = body.trim();
    if (text.isEmpty) return null;
    try {
      final msg = await _chat.sendMessage(rideId, text);
      _upsertMessage(msg, bumpUnread: false);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not send message.';
    }
  }

  void markRead(String threadId) {
    final i = _threads.indexWhere((t) => t.id == threadId || t.rideId == threadId);
    if (i < 0) return;
    if (_threads[i].unread == 0) return;
    _threads[i] = _threads[i].copyWith(unread: 0);
    _syncApp();
    notifyListeners();
  }

  void markAllRead() {
    var changed = false;
    for (var i = 0; i < _threads.length; i++) {
      if (_threads[i].unread == 0) continue;
      _threads[i] = _threads[i].copyWith(unread: 0);
      changed = true;
    }
    if (!changed) return;
    _syncApp();
    notifyListeners();
  }

  void onRideAssigned(ApiRide ride) {
    ensureThreadShell(
      ride.id,
      peerName: _auth.isDriverMode ? ride.passengerName : (ride.driverName ?? 'Driver'),
    );
  }

  void _onRealtimeMessage(Map<String, dynamic> raw) {
    try {
      final msg = ApiChatMessage.fromJson(raw);
      final mine = msg.senderId != null && msg.senderId == _auth.user?.id;
      _upsertMessage(msg, bumpUnread: !mine && _openThreadId != msg.rideId);
    } catch (_) {}
  }

  void _upsertMessage(ApiChatMessage msg, {required bool bumpUnread}) {
    ensureThreadShell(msg.rideId);
    final i = _threads.indexWhere((t) => t.id == msg.rideId || t.rideId == msg.rideId);
    if (i < 0) return;
    final t = _threads[i];
    if (t.messages.any((m) => m.body == msg.body && m.time == _fmt(msg.createdAt.toLocal()) && m.mine == (msg.senderId == _auth.user?.id))) {
      // Soft dedupe by content+time; also check id via body uniqueness for rapid WS+REST.
    }
    final ui = _toUi(msg);
    final already = t.messages.any(
      (m) => m.body == ui.body && m.time == ui.time && m.mine == ui.mine && m.from == ui.from,
    );
    final messages = already ? t.messages : [...t.messages, ui];
    final updated = t.copyWith(
      messages: messages,
      lastMessage: ui.body,
      time: ui.time,
      unread: bumpUnread ? t.unread + (already ? 0 : 1) : 0,
    );
    _threads.removeAt(i);
    _threads.insert(0, updated);
    _syncApp();
    notifyListeners();
  }

  ChatMessage _toUi(ApiChatMessage m) {
    final mine = m.senderId != null && m.senderId == _auth.user?.id;
    final from = mine
        ? 'You'
        : (m.senderType == 'driver'
            ? 'Driver'
            : m.senderType == 'passenger'
                ? 'Passenger'
                : 'System');
    return ChatMessage(
      from: from,
      body: m.body,
      time: _fmt(m.createdAt.toLocal()),
      mine: mine,
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _syncApp() => _app.replaceChatThreads(_threads);

  void _onAuthChanged() {
    if (_auth.isLoggedIn) {
      unawaited(refreshThreads());
    } else {
      _threads.clear();
      _syncApp();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
