import '../../core/network/api_client.dart';
import '../models/alert_models.dart';

class AlertsRepository {
  AlertsRepository(this._client);

  final ApiClient _client;

  Future<ApiAlertPage> list({int page = 1, int pageSize = 50}) async {
    final json = await _client.get(
      '/me/alerts',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
      },
    );
    return ApiAlertPage.fromJson(json);
  }

  Future<int> markRead({List<String>? ids}) async {
    final json = await _client.post(
      '/me/alerts/read',
      body: {
        'ids': ?ids,
      },
    );
    return (json['updated'] as num?)?.toInt() ?? 0;
  }
}
