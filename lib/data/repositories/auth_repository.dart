import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../local/session_local_store.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository({
    ApiClient? client,
    SessionLocalStore? store,
  })  : _client = client ?? ApiClient(),
        _store = store ?? SessionLocalStore.instance {
    _client.onTokensRefreshed = (tokens) async {
      // Already saved inside ApiClient.refresh; keep in-memory user sync via callback if needed.
    };
  }

  final ApiClient _client;
  final SessionLocalStore _store;

  ApiClient get client => _client;

  Future<void> bootstrap() async {
    await _client.loadTokensFromStore();
  }

  Future<AuthTokens> login({required String email, required String password}) async {
    final json = await _client.post(
      '/auth/login',
      auth: false,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
    final tokens = AuthTokens.fromJson(json);
    await _persist(tokens);
    return tokens;
  }

  Future<AuthTokens> registerPassenger(RegisterPassengerRequest req) async {
    final json = await _client.post(
      '/auth/register/passenger',
      auth: false,
      body: req.toJson(),
    );
    return AuthTokens.fromJson(json);
  }

  Future<AuthTokens> registerDriver(RegisterDriverRequest req) async {
    final json = await _client.post(
      '/auth/register/driver',
      auth: false,
      body: req.toJson(),
    );
    return AuthTokens.fromJson(json);
  }

  /// Persist session after register when you want auto-login.
  Future<void> persistTokens(AuthTokens tokens, {String? roleMode}) =>
      _persist(tokens, roleMode: roleMode);

  Future<ApiUser> me() async {
    final json = await _client.get('/auth/me');
    final user = ApiUser.fromJson(json);
    await _store.updateUser(user);
    return user;
  }

  Future<void> logout() async {
    final refresh = await _store.readRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _client.postEmpty(
          '/auth/logout',
          auth: false,
          body: {'refreshToken': refresh},
        );
      }
    } on ApiException {
      // Always clear local session even if revoke fails.
    } catch (_) {}
    _client.setTokens(access: null, refresh: null);
    await _store.clear();
  }

  Future<ApiUser?> restoreUser() => _store.readUser();

  Future<String?> roleMode() => _store.readRoleMode();

  Future<void> setRoleMode(String mode) => _store.setRoleMode(mode);

  Future<bool> hasLocalSession() => _store.hasSession();

  Future<void> _persist(AuthTokens tokens, {String? roleMode}) async {
    _client.setTokens(access: tokens.accessToken, refresh: tokens.refreshToken);
    await _store.saveSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: tokens.user,
      roleMode: roleMode ?? tokens.user.primaryRole,
    );
  }
}
