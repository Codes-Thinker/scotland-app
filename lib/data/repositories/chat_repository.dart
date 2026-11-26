import '../../core/network/api_client.dart';
import '../models/chat_models.dart';

class ChatRepository {
  ChatRepository(this._client);

  final ApiClient _client;

  Future<ApiChatPage> listMessages(
    String rideId, {
    String? cursor,
    int limit = 50,
  }) async {
    final json = await _client.get(
      '/rides/$rideId/messages',
      query: {
        'limit': '$limit',
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return ApiChatPage.fromJson(json);
  }

  Future<ApiChatMessage> sendMessage(String rideId, String body) async {
    final json = await _client.post(
      '/rides/$rideId/messages',
      body: {'body': body},
    );
    return ApiChatMessage.fromJson(json);
  }
}
