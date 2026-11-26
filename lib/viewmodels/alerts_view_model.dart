import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/network/realtime_client.dart';
import '../data/models/alert_models.dart';
import '../data/repositories/alerts_repository.dart';
import '../services/app_state.dart';
import 'auth_view_model.dart';

class AlertsViewModel extends ChangeNotifier {
  AlertsViewModel({
    required AuthViewModel auth,
    required AppState appState,
    required RealtimeClient realtime,
  })  : _auth = auth,
        _app = appState,
        _realtime = realtime,
        _repo = AlertsRepository(auth.repository.client) {
    _auth.addListener(_onAuthChanged);
    _subs.add(_realtime.onAlertNew.listen(_onRealtimeAlert));
    if (_auth.isLoggedIn) unawaited(refresh());
  }

  final AuthViewModel _auth;
  final AppState _app;
  final RealtimeClient _realtime;
  final AlertsRepository _repo;
  final List<StreamSubscription<dynamic>> _subs = [];

  final List<ApiAlert> _alerts = [];
  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  List<ApiAlert> get alerts => List.unmodifiable(_alerts);
  int get unreadCount => _alerts.where((a) => a.isUnread).length;
  List<String> get displayLines => _alerts.map((a) => a.displayText).toList();

  Future<void> refresh() async {
    if (!_auth.isLoggedIn) {
      _alerts.clear();
      _syncApp();
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final page = await _repo.list(pageSize: 50);
      _alerts
        ..clear()
        ..addAll(page.data);
      _error = null;
      _syncApp();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load alerts.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repo.markRead();
      for (var i = 0; i < _alerts.length; i++) {
        final a = _alerts[i];
        if (a.readAt != null) continue;
        _alerts[i] = ApiAlert(
          id: a.id,
          type: a.type,
          title: a.title,
          body: a.body,
          createdAt: a.createdAt,
          readAt: DateTime.now().toUtc(),
        );
      }
      _syncApp();
      notifyListeners();
    } catch (_) {}
  }

  void _onRealtimeAlert(Map<String, dynamic> raw) {
    try {
      final alert = ApiAlert.fromJson(raw);
      _alerts.removeWhere((a) => a.id == alert.id);
      _alerts.insert(0, alert);
      _syncApp();
      notifyListeners();
    } catch (_) {}
  }

  void _syncApp() => _app.replaceApiAlerts(_alerts.map((a) => a.displayText).toList());

  void _onAuthChanged() {
    if (_auth.isLoggedIn) {
      unawaited(refresh());
    } else {
      _alerts.clear();
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
