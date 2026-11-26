import '../../core/network/api_client.dart';
import '../models/auth_models.dart';
import '../models/earnings_models.dart';

class DriverRepository {
  DriverRepository(this._client);

  final ApiClient _client;

  Future<List<DriverDocumentDto>> documents() async {
    final list = await _client.getList('/drivers/me/documents');
    return list
        .whereType<Map>()
        .map((e) => DriverDocumentDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Upload a document image. Field name matches Nest `FileInterceptor('file')`.
  Future<DriverDocumentDto> uploadDocument({
    required String type,
    required String filePath,
  }) async {
    final json = await _client.multipart(
      '/drivers/me/documents/$type',
      fileField: 'file',
      filePath: filePath,
    );
    return DriverDocumentDto.fromJson(json);
  }

  Future<void> setOnlineStatus(String status) async {
    await _client.put('/drivers/me/status', body: {'status': status});
  }

  Future<DriverEarningsReport> earnings({String? from, String? to}) async {
    final json = await _client.get(
      '/drivers/me/earnings',
      query: {
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
    );
    return DriverEarningsReport.fromJson(json);
  }
}
