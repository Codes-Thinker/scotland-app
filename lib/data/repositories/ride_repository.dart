import '../../core/network/api_client.dart';
import '../models/ride_models.dart';

class RideRepository {
  RideRepository(this._client);

  final ApiClient _client;

  Future<RideEstimate> estimate({
    required ApiPlace pickup,
    required ApiPlace drop,
    required String rideType,
    required String bookingMode,
    required String vehicleCategory,
    String? scheduledAt,
  }) async {
    final json = await _client.post('/rides/estimate', body: {
      'pickup': pickup.toJson(),
      'drop': drop.toJson(),
      'rideType': rideType,
      'bookingMode': bookingMode,
      'vehicleCategory': vehicleCategory,
      'scheduledAt': ?scheduledAt,
    });
    return RideEstimate.fromJson(json);
  }

  Future<ApiRide> create({
    required ApiPlace pickup,
    required ApiPlace drop,
    required String rideType,
    required String bookingMode,
    required String vehicleCategory,
    String? scheduledAt,
  }) async {
    final json = await _client.post('/rides', body: {
      'pickup': pickup.toJson(),
      'drop': drop.toJson(),
      'rideType': rideType,
      'bookingMode': bookingMode,
      'vehicleCategory': vehicleCategory,
      'scheduledAt': ?scheduledAt,
    });
    return ApiRide.fromJson(json);
  }

  Future<ApiRide> getById(String id) async {
    final json = await _client.get('/rides/$id');
    return ApiRide.fromJson(json);
  }

  Future<List<ApiRide>> list({
    required String role,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = await _client.get(
      '/rides',
      query: {
        'role': role,
        'page': '$page',
        'pageSize': '$pageSize',
        'status': ?status,
      },
    );
    final data = json['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => ApiRide.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ApiRide> cancel(String id, {String? reason}) async {
    final json = await _client.post(
      '/rides/$id/cancel',
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
    return ApiRide.fromJson(json);
  }

  Future<ApiRide> rate(String id, {required int score, String? comment}) async {
    final json = await _client.post(
      '/rides/$id/rating',
      body: {
        'score': score,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    return ApiRide.fromJson(json);
  }

  Future<List<ApiRideOffer>> offers() async {
    final list = await _client.getList('/drivers/me/offers');
    return list
        .whereType<Map>()
        .map((e) => ApiRideOffer.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ApiRide> accept(String rideId) async {
    final json = await _client.post('/rides/$rideId/accept');
    return ApiRide.fromJson(json);
  }

  Future<void> reject(String rideId) async {
    await _client.postEmpty('/rides/$rideId/reject');
  }

  Future<ApiRide> arrive(String rideId) async {
    final json = await _client.post('/rides/$rideId/arrive');
    return ApiRide.fromJson(json);
  }

  Future<ApiRide> start(String rideId) async {
    final json = await _client.post('/rides/$rideId/start');
    return ApiRide.fromJson(json);
  }

  Future<ApiRide> complete(String rideId, {int? distanceM}) async {
    final json = await _client.post(
      '/rides/$rideId/complete',
      body: {'distanceM': ?distanceM},
    );
    return ApiRide.fromJson(json);
  }

  Future<void> setOnlineStatus(String status) async {
    await _client.put('/drivers/me/status', body: {'status': status});
  }

  Future<void> postLocation({
    required double lat,
    required double lng,
    double? heading,
  }) async {
    await _client.postEmpty(
      '/drivers/me/location',
      body: {
        'lat': lat,
        'lng': lng,
        'heading': ?heading,
      },
    );
  }
}
