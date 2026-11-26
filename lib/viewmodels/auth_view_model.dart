import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/utils/validators.dart';
import '../data/models/auth_models.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/driver_repository.dart';
import '../shared/models/models.dart';

/// MVVM ViewModel for authentication + session (Provider ChangeNotifier).
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthRepository? repository})
      : _auth = repository ?? AuthRepository() {
    _drivers = DriverRepository(_auth.client);
  }

  final AuthRepository _auth;
  late final DriverRepository _drivers;

  ApiUser? _user;
  String _roleMode = 'passenger'; // UI mode from welcome selection
  bool _ready = false;
  bool _loading = false;
  String? _error;

  AuthRepository get repository => _auth;
  DriverRepository get drivers => _drivers;

  ApiUser? get user => _user;
  bool get isReady => _ready;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String get roleMode => _roleMode;

  bool get isDriverMode => _roleMode == 'driver' && (_user?.isDriver ?? false);
  bool get isPassengerMode {
    if (_user == null) return _roleMode == 'passenger';
    if (_user!.isDriver && _roleMode == 'driver') return false;
    return true;
  }

  UserRole get pendingRole =>
      _roleMode == 'driver' ? UserRole.driver : UserRole.passenger;

  UserRole? get sessionRole {
    if (_user == null) return null;
    return isDriverMode ? UserRole.driver : UserRole.passenger;
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void selectRole(UserRole role) {
    _roleMode = role == UserRole.driver ? 'driver' : 'passenger';
    _auth.setRoleMode(_roleMode);
    notifyListeners();
  }

  Future<void> restoreSession() async {
    _loading = true;
    notifyListeners();
    try {
      await _auth.bootstrap();
      final has = await _auth.hasLocalSession();
      if (!has) {
        _user = null;
        _roleMode = (await _auth.roleMode()) ?? 'passenger';
        return;
      }
      _roleMode = (await _auth.roleMode()) ?? 'passenger';
      // Prefer fresh /me; fall back to cached user offline.
      try {
        _user = await _auth.me();
      } catch (_) {
        _user = await _auth.restoreUser();
      }
      if (_user != null) {
        // Keep role mode valid for this account.
        if (_roleMode == 'driver' && !_user!.isDriver) {
          _roleMode = 'passenger';
          await _auth.setRoleMode(_roleMode);
        }
        if (_roleMode == 'passenger' && !_user!.isPassenger && _user!.isDriver) {
          _roleMode = 'driver';
          await _auth.setRoleMode(_roleMode);
        }
      }
    } finally {
      _ready = true;
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final e = Validators.email(email);
    if (e != null) return e;
    final p = Validators.password(password, min: 1);
    if (password.trim().isEmpty) return 'Enter your password.';
    if (p != null && password.length < 6) return 'Password must be at least 6 characters.';

    return _run(() async {
      final wanted = _roleMode;
      final tokens = await _auth.login(email: email, password: password);
      _user = tokens.user;
      if (wanted == 'driver' && !_user!.isDriver) {
        await _auth.logout();
        _user = null;
        throw const ApiException(
          statusCode: 403,
          message: 'This account is not a driver. Select Passenger to sign in.',
        );
      }
      if (wanted == 'passenger' && _user!.isDriver && !_user!.roles.contains('passenger')) {
        _roleMode = 'driver';
      } else if (!_user!.isDriver) {
        _roleMode = 'passenger';
      } else if (wanted == 'driver') {
        _roleMode = 'driver';
      } else {
        _roleMode = 'passenger';
      }
      await _auth.setRoleMode(_roleMode);
    });
  }

  /// Register then require Sign In (tokens not kept locally).
  Future<String?> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final err = _validateCommon(
      name: name,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (err != null) return err;

    return _run(() async {
      await _auth.registerPassenger(
        RegisterPassengerRequest(
          name: name,
          email: email,
          phone: phone,
          password: password,
          acceptedTerms: true,
        ),
      );
      // Do not auto-login — user signs in next (existing product flow).
    });
  }

  Future<String?> registerDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String vehicleMakeModel,
    required String vehiclePlate,
    required String operatingZone,
    String? licenceNumber,
  }) async {
    final err = _validateCommon(
      name: name,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (err != null) return err;
    final v = Validators.vehicleMakeModel(vehicleMakeModel);
    if (v != null) return v;
    final plate = Validators.vehiclePlate(vehiclePlate);
    if (plate != null) return plate;
    final zone = Validators.operatingZone(operatingZone);
    if (zone != null) return zone;

    return _run(() async {
      await _auth.registerDriver(
        RegisterDriverRequest(
          name: name,
          email: email,
          phone: phone,
          password: password,
          acceptedTerms: true,
          vehicleMakeModel: vehicleMakeModel,
          vehiclePlate: vehiclePlate,
          operatingZone: operatingZone,
          licenceNumber: licenceNumber,
        ),
      );
    });
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    try {
      await _auth.logout();
    } finally {
      _user = null;
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<DriverDocumentDto>> fetchDocuments() => _drivers.documents();

  Future<String?> uploadDocument({
    required String type,
    required String filePath,
  }) async {
    return _run(() async {
      await _drivers.uploadDocument(type: type, filePath: filePath);
    });
  }

  String? _validateCommon({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) {
    return Validators.fullName(name) ??
        Validators.email(email) ??
        Validators.phone(phone) ??
        Validators.password(password, min: 8) ??
        Validators.confirmPassword(confirmPassword, password);
  }

  Future<String?> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return null;
    } on ApiException catch (e) {
      _error = e.message;
      return e.message;
    } catch (e) {
      final msg = e.toString().contains('SocketException') ||
              e.toString().contains('Failed host lookup') ||
              e.toString().contains('Connection refused')
          ? 'Cannot reach server. Check API URL and that the backend is running.'
          : 'Something went wrong. Please try again.';
      _error = msg;
      return msg;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
