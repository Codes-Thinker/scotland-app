class ApiChatMessage {
  final String id;
  final String rideId;
  final String senderType; // passenger | driver | system
  final String? senderId;
  final String body;
  final DateTime createdAt;

  const ApiChatMessage({
    required this.id,
    required this.rideId,
    required this.senderType,
    this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory ApiChatMessage.fromJson(Map<String, dynamic> json) => ApiChatMessage(
        id: '${json['id']}',
        rideId: '${json['rideId']}',
        senderType: '${json['senderType'] ?? ''}',
        senderId: json['senderId']?.toString(),
        body: '${json['body'] ?? ''}',
        createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now().toUtc(),
      );
}

class ApiChatPage {
  final List<ApiChatMessage> data;
  final String? nextCursor;

  const ApiChatPage({required this.data, this.nextCursor});

  factory ApiChatPage.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => ApiChatMessage.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ApiChatMessage>[];
    final cursor = json['nextCursor'];
    return ApiChatPage(
      data: list,
      nextCursor: cursor == null || '$cursor' == 'null' ? null : '$cursor',
    );
  }
}
