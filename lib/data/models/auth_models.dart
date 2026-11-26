class ApiDriverInfo {
  final String? operatingZone;
  final String onlineStatus;
  final double ratingAvg;
  final int ridesCount;
  final String? vehicleMakeModel;
  final String? vehiclePlate;
  final String? vehicleCategory;

  const ApiDriverInfo({
    this.operatingZone,
    this.onlineStatus = 'offline',
    this.ratingAvg = 0,
    this.ridesCount = 0,
    this.vehicleMakeModel,
    this.vehiclePlate,
    this.vehicleCategory,
  });

  factory ApiDriverInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ApiDriverInfo();
    }
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    return ApiDriverInfo(
      operatingZone: json['operatingZone'] as String?,
      onlineStatus: '${json['onlineStatus'] ?? 'offline'}',
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
      ridesCount: (json['ridesCount'] as num?)?.toInt() ?? 0,
      vehicleMakeModel: vehicle?['makeModel'] as String?,
      vehiclePlate: vehicle?['plate'] as String?,
      vehicleCategory: vehicle?['category'] as String?,
    );
  }
}

class ApiUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> roles;
  final String status;
  final ApiDriverInfo? driver;

  const ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.roles,
    required this.status,
    this.driver,
  });

  bool get isDriver => roles.contains('driver');
  bool get isPassenger => roles.contains('passenger') || !isDriver;
  bool get isPending => status == 'pending';
  bool get isSuspended => status == 'suspended';
  bool get isActive => status == 'active';

  /// Active app mode: driver if role includes driver and mode prefers it.
  String get primaryRole => isDriver ? 'driver' : 'passenger';

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    final roles = rolesRaw is List
        ? rolesRaw.map((e) => '$e').toList()
        : <String>[];
    return ApiUser(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}'.toLowerCase(),
      phone: '${json['phone'] ?? ''}',
      roles: roles,
      status: '${json['status'] ?? 'active'}',
      driver: json['driver'] is Map<String, dynamic>
          ? ApiDriverInfo.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'roles': roles,
        'status': status,
        if (driver != null)
          'driver': {
            'operatingZone': driver!.operatingZone,
            'onlineStatus': driver!.onlineStatus,
            'ratingAvg': driver!.ratingAvg,
            'ridesCount': driver!.ridesCount,
            'vehicle': driver!.vehicleMakeModel == null
                ? null
                : {
                    'makeModel': driver!.vehicleMakeModel,
                    'plate': driver!.vehiclePlate,
                    'category': driver!.vehicleCategory,
                  },
          },
      };
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final ApiUser user;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: '${json['accessToken']}',
      refreshToken: '${json['refreshToken']}',
      tokenType: '${json['tokenType'] ?? 'Bearer'}',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
      user: ApiUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class RegisterPassengerRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
  final bool acceptedTerms;

  const RegisterPassengerRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.acceptedTerms,
  });

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
        'acceptedTerms': acceptedTerms,
      };
}

class RegisterDriverRequest extends RegisterPassengerRequest {
  final String vehicleMakeModel;
  final String vehiclePlate;
  final String operatingZone;
  final String? licenceNumber;

  const RegisterDriverRequest({
    required super.name,
    required super.email,
    required super.phone,
    required super.password,
    required super.acceptedTerms,
    required this.vehicleMakeModel,
    required this.vehiclePlate,
    required this.operatingZone,
    this.licenceNumber,
  });

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'vehicleMakeModel': vehicleMakeModel.trim(),
        'vehiclePlate': vehiclePlate.trim().toUpperCase(),
        'operatingZone': operatingZone.trim(),
        if (licenceNumber != null && licenceNumber!.trim().isNotEmpty)
          'licenceNumber': licenceNumber!.trim(),
      };
}

class DriverDocumentDto {
  final String type;
  final String status;
  final String? fileKey;
  final String? expiresAt;

  const DriverDocumentDto({
    required this.type,
    required this.status,
    this.fileKey,
    this.expiresAt,
  });

  factory DriverDocumentDto.fromJson(Map<String, dynamic> json) {
    return DriverDocumentDto(
      type: '${json['type'] ?? json['id'] ?? ''}',
      status: '${json['status'] ?? 'missing'}',
      fileKey: json['fileKey'] as String?,
      expiresAt: json['expiresAt'] as String?,
    );
  }
}
