import 'package:hyper_local/utils/services/json_parser.dart';

const String modelName = 'profile_model';

class ProfileResponse {
  bool? success;
  String? message;
  ProfileModel? data;

  ProfileResponse({this.success, this.message, this.data});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data:
          json['data'] != null
              ? ProfileModel.fromJson(json['data'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class ProfileModel {
  User? user;
  DeliveryBoy? deliveryBoy;

  ProfileModel({this.user, this.deliveryBoy});

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      user:
          json['user'] != null
              ? User.fromJson(json['user'] as Map<String, dynamic>)
              : null,
      deliveryBoy:
          json['delivery_boy'] != null
              ? DeliveryBoy.fromJson(
                json['delivery_boy'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (deliveryBoy != null) {
      data['delivery_boy'] = deliveryBoy!.toJson();
    }
    return data;
  }
}

class User {
  int? id;
  String? name;
  String? email;
  String? mobile;
  String? country;
  String? iso2;
  double? walletBalance;
  double? blockedBalance;
  double? availableBalance;
  String? referralCode;
  String? friendsCode;
  int? rewardPoints;
  String? profileImage;
  String? emailVerifiedAt;
  String? createdAt;
  String? updatedAt;
  String? status;

  User({
    this.id,
    this.name,
    this.email,
    this.mobile,
    this.country,
    this.iso2,
    this.walletBalance,
    this.blockedBalance,
    this.availableBalance,
    this.referralCode,
    this.friendsCode,
    this.rewardPoints,
    this.profileImage,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: JsonParser.intValue(json['id']),
      name: JsonParser.string(json['name']),
      email: JsonParser.string(json['email']),
      mobile: JsonParser.string(json['mobile']),
      country: JsonParser.string(json['country']),
      iso2: JsonParser.string(json['iso_2']),
      walletBalance: JsonParser.doubleValue(json['wallet_balance']),
      blockedBalance: JsonParser.doubleValue(json['blocked_balance']),
      availableBalance: JsonParser.doubleValue(json['available_balance']),
      referralCode: JsonParser.string(json['referral_code']),
      friendsCode: JsonParser.string(json['friends_code']),
      rewardPoints: JsonParser.intValue(json['reward_points']),
      profileImage: JsonParser.string(json['profile_image']),
      emailVerifiedAt: JsonParser.string(json['email_verified_at']),
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
      status: JsonParser.string(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['mobile'] = mobile;
    data['country'] = country;
    data['iso_2'] = iso2;
    data['wallet_balance'] = walletBalance;
    data['blocked_balance'] = blockedBalance;
    data['available_balance'] = availableBalance;
    data['referral_code'] = referralCode;
    data['friends_code'] = friendsCode;
    data['reward_points'] = rewardPoints;
    data['profile_image'] = profileImage;
    data['email_verified_at'] = emailVerifiedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['status'] = status;
    return data;
  }
}

class DeliveryBoy {
  int? id;
  int? userId;
  int? deliveryZoneId;
  String? status;
  String? fullName;
  String? address;
  List<String>? driverLicense;
  String? driverLicenseNumber;
  String? vehicleType;
  List<String>? vehicleRegistration;
  String? verificationStatus;
  String? verificationRemark;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  DeliveryZone? deliveryZone;
  List<Media>? media;

  DeliveryBoy({
    this.id,
    this.userId,
    this.deliveryZoneId,
    this.status,
    this.fullName,
    this.address,
    this.driverLicense,
    this.driverLicenseNumber,
    this.vehicleType,
    this.vehicleRegistration,
    this.verificationStatus,
    this.verificationRemark,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deliveryZone,
    this.media,
  });

  factory DeliveryBoy.fromJson(Map<String, dynamic> json) {
    return DeliveryBoy(
      id: JsonParser.intValue(json['id']),
      userId: JsonParser.intValue(json['user_id']),
      deliveryZoneId: JsonParser.intValue(json['delivery_zone_id']),
      status: JsonParser.string(json['status']),
      fullName: JsonParser.string(json['full_name']),
      address: JsonParser.string(json['address']),
      driverLicense: JsonParser.list<String>(
        json['driver_license'],
        (v) => JsonParser.string(v),
      ),
      driverLicenseNumber: JsonParser.string(json['driver_license_number']),
      vehicleType: JsonParser.string(json['vehicle_type']),
      vehicleRegistration: JsonParser.list<String>(
        json['vehicle_registration'],
        (v) => JsonParser.string(v),
      ),
      verificationStatus: JsonParser.string(json['verification_status']),
      verificationRemark: JsonParser.string(json['verification_remark']),
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
      deletedAt: JsonParser.string(json['deleted_at']),
      deliveryZone:
          json['delivery_zone'] != null
              ? DeliveryZone.fromJson(
                json['delivery_zone'] as Map<String, dynamic>,
              )
              : null,
      media: JsonParser.list<Media>(
        json['media'],
        (v) => Media.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['delivery_zone_id'] = deliveryZoneId;
    data['status'] = status;
    data['full_name'] = fullName;
    data['address'] = address;
    data['driver_license'] = driverLicense;
    data['driver_license_number'] = driverLicenseNumber;
    data['vehicle_type'] = vehicleType;
    data['vehicle_registration'] = vehicleRegistration;
    data['verification_status'] = verificationStatus;
    data['verification_remark'] = verificationRemark;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    if (deliveryZone != null) {
      data['delivery_zone'] = deliveryZone!.toJson();
    }
    if (media != null) {
      data['media'] = media!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DeliveryZone {
  int? id;
  String? name;
  String? slug;
  String? centerLatitude;
  String? centerLongitude;
  double? radiusKm;
  int? rushDeliveryTimePerKm;
  int? rushDeliveryCharges;
  int? deliveryTimePerKm;
  int? regularDeliveryCharges;
  double? freeDeliveryAmount;
  double? distanceBasedDeliveryCharges;
  double? perStoreDropOffFee;
  double? handlingCharges;
  String? deliveryBoyBaseFee;
  String? deliveryBoyPerStorePickupFee;
  String? deliveryBoyDistanceBasedFee;
  String? deliveryBoyPerOrderIncentive;
  int? bufferTime;
  List<BoundaryJson>? boundaryJson;
  bool? rushDeliveryEnabled;
  String? status;
  String? createdAt;
  String? updatedAt;

  DeliveryZone({
    this.id,
    this.name,
    this.slug,
    this.centerLatitude,
    this.centerLongitude,
    this.radiusKm,
    this.rushDeliveryTimePerKm,
    this.rushDeliveryCharges,
    this.deliveryTimePerKm,
    this.regularDeliveryCharges,
    this.freeDeliveryAmount,
    this.distanceBasedDeliveryCharges,
    this.perStoreDropOffFee,
    this.handlingCharges,
    this.deliveryBoyBaseFee,
    this.deliveryBoyPerStorePickupFee,
    this.deliveryBoyDistanceBasedFee,
    this.deliveryBoyPerOrderIncentive,
    this.bufferTime,
    this.boundaryJson,
    this.rushDeliveryEnabled,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: JsonParser.intValue(json['id']),
      name: JsonParser.string(json['name']),
      slug: JsonParser.string(json['slug']),
      centerLatitude: JsonParser.string(json['center_latitude']),
      centerLongitude: JsonParser.string(json['center_longitude']),
      radiusKm: JsonParser.doubleValue(json['radius_km']),
      rushDeliveryTimePerKm: JsonParser.intValue(
        json['rush_delivery_time_per_km'],
      ),
      rushDeliveryCharges: JsonParser.intValue(json['rush_delivery_charges']),
      deliveryTimePerKm: JsonParser.intValue(json['delivery_time_per_km']),
      regularDeliveryCharges: JsonParser.intValue(
        json['regular_delivery_charges'],
      ),
      freeDeliveryAmount: JsonParser.doubleValue(json['free_delivery_amount']),
      distanceBasedDeliveryCharges: JsonParser.doubleValue(
        json['distance_based_delivery_charges'],
      ),
      perStoreDropOffFee: JsonParser.doubleValue(
        json['per_store_drop_off_fee'],
      ),
      handlingCharges: JsonParser.doubleValue(json['handling_charges']),
      deliveryBoyBaseFee: JsonParser.string(json['delivery_boy_base_fee']),
      deliveryBoyPerStorePickupFee: JsonParser.string(
        json['delivery_boy_per_store_pickup_fee'],
      ),
      deliveryBoyDistanceBasedFee: JsonParser.string(
        json['delivery_boy_distance_based_fee'],
      ),
      deliveryBoyPerOrderIncentive: JsonParser.string(
        json['delivery_boy_per_order_incentive'],
      ),
      bufferTime: JsonParser.intValue(json['buffer_time']),
      boundaryJson: JsonParser.list<BoundaryJson>(
        json['boundary_json'],
        (v) => BoundaryJson.fromJson(v as Map<String, dynamic>),
      ),
      rushDeliveryEnabled: JsonParser.boolValue(
        json['rush_delivery_enabled'] ?? false,
      ),
      status: JsonParser.string(json['status']),
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['center_latitude'] = centerLatitude;
    data['center_longitude'] = centerLongitude;
    data['radius_km'] = radiusKm;
    data['rush_delivery_time_per_km'] = rushDeliveryTimePerKm;
    data['rush_delivery_charges'] = rushDeliveryCharges;
    data['delivery_time_per_km'] = deliveryTimePerKm;
    data['regular_delivery_charges'] = regularDeliveryCharges;
    data['free_delivery_amount'] = freeDeliveryAmount;
    data['distance_based_delivery_charges'] = distanceBasedDeliveryCharges;
    data['per_store_drop_off_fee'] = perStoreDropOffFee;
    data['handling_charges'] = handlingCharges;
    data['delivery_boy_base_fee'] = deliveryBoyBaseFee;
    data['delivery_boy_per_store_pickup_fee'] = deliveryBoyPerStorePickupFee;
    data['delivery_boy_distance_based_fee'] = deliveryBoyDistanceBasedFee;
    data['delivery_boy_per_order_incentive'] = deliveryBoyPerOrderIncentive;
    data['buffer_time'] = bufferTime;
    if (boundaryJson != null) {
      data['boundary_json'] = boundaryJson!.map((v) => v.toJson()).toList();
    }
    data['rush_delivery_enabled'] = rushDeliveryEnabled;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class BoundaryJson {
  double? lat;
  double? lng;

  BoundaryJson({this.lat, this.lng});

  factory BoundaryJson.fromJson(Map<String, dynamic> json) {
    return BoundaryJson(
      lat: JsonParser.doubleValue(json['lat']),
      lng: JsonParser.doubleValue(json['lng']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lat'] = lat;
    data['lng'] = lng;
    return data;
  }
}

class Media {
  int? id;
  String? modelType;
  int? modelId;
  String? uuid;
  String? collectionName;
  String? name;
  String? fileName;
  String? mimeType;
  String? disk;
  String? conversionsDisk;
  int? size;
  List<dynamic>? manipulations;
  List<dynamic>? customProperties;
  List<dynamic>? generatedConversions;
  List<dynamic>? responsiveImages;
  int? orderColumn;
  String? createdAt;
  String? updatedAt;
  String? originalUrl;
  String? previewUrl;

  Media({
    this.id,
    this.modelType,
    this.modelId,
    this.uuid,
    this.collectionName,
    this.name,
    this.fileName,
    this.mimeType,
    this.disk,
    this.conversionsDisk,
    this.size,
    this.manipulations,
    this.customProperties,
    this.generatedConversions,
    this.responsiveImages,
    this.orderColumn,
    this.createdAt,
    this.updatedAt,
    this.originalUrl,
    this.previewUrl,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: JsonParser.intValue(json['id']),
      modelType: JsonParser.string(json['model_type']),
      modelId: JsonParser.intValue(json['model_id']),
      uuid: JsonParser.string(json['uuid']),
      collectionName: JsonParser.string(json['collection_name']),
      name: JsonParser.string(json['name']),
      fileName: JsonParser.string(json['file_name']),
      mimeType: JsonParser.string(json['mime_type']),
      disk: JsonParser.string(json['disk']),
      conversionsDisk: JsonParser.string(json['conversions_disk']),
      size: JsonParser.intValue(json['size']),
      manipulations: json['manipulations']?.cast<dynamic>(),
      customProperties: json['custom_properties']?.cast<dynamic>(),
      generatedConversions: json['generated_conversions']?.cast<dynamic>(),
      responsiveImages: json['responsive_images']?.cast<dynamic>(),
      orderColumn: JsonParser.intValue(json['order_column']),
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
      originalUrl: JsonParser.string(json['original_url']),
      previewUrl: JsonParser.string(json['preview_url']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['model_type'] = modelType;
    data['model_id'] = modelId;
    data['uuid'] = uuid;
    data['collection_name'] = collectionName;
    data['name'] = name;
    data['file_name'] = fileName;
    data['mime_type'] = mimeType;
    data['disk'] = disk;
    data['conversions_disk'] = conversionsDisk;
    data['size'] = size;
    data['manipulations'] = manipulations;
    data['custom_properties'] = customProperties;
    data['generated_conversions'] = generatedConversions;
    data['responsive_images'] = responsiveImages;
    data['order_column'] = orderColumn;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['original_url'] = originalUrl;
    data['preview_url'] = previewUrl;
    return data;
  }
}
