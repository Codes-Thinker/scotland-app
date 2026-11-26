import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../data/models/earnings_models.dart';
import '../data/repositories/driver_repository.dart';
import '../services/app_state.dart';
import 'auth_view_model.dart';

class EarningsViewModel extends ChangeNotifier {
  EarningsViewModel({
    required AuthViewModel auth,
    required AppState appState,
  })  : _auth = auth,
        _app = appState,
        _drivers = DriverRepository(auth.repository.client) {
    _auth.addListener(_onAuthChanged);
    if (_auth.isLoggedIn && _auth.isDriverMode) unawaited(refresh());
  }

  final AuthViewModel _auth;
  final AppState _app;
  final DriverRepository _drivers;

  DriverEarningsReport? _week;
  DriverEarningsReport? _today;
  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  DriverEarningsReport? get week => _week;
  DriverEarningsReport? get today => _today;

  double get todayPounds => _today?.grossPounds ?? 0;
  double get weekPounds => _week?.grossPounds ?? 0;
  int get completedTrips => _week?.trips ?? 0;
  List<DriverEarningsDay> get days => _week?.days ?? const [];

  Future<void> refresh() async {
    if (!_auth.isLoggedIn || !_auth.isDriverMode) {
      _week = null;
      _today = null;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final now = DateTime.now();
      final todayStr = _isoDay(now);
      final weekStart = _isoDay(now.subtract(Duration(days: now.weekday - 1)));
      _today = await _drivers.earnings(from: todayStr, to: todayStr);
      _week = await _drivers.earnings(from: weekStart, to: todayStr);
      _error = null;
      _app.setApiEarnings(
        today: todayPounds,
        week: weekPounds,
        trips: completedTrips,
      );
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load earnings.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _isoDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _onAuthChanged() {
    if (_auth.isLoggedIn && _auth.isDriverMode) {
      unawaited(refresh());
    } else {
      _week = null;
      _today = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
