import 'dart:io';
import 'package:hyper_local/utils/services/json_parser.dart';

const String modelName = 'update_deliveryboy_status_model';

class UpdateDeliveryBoyStatusResponse {
  bool? success;
  String? message;
  DeliveryBoyStatusModel? data;

  UpdateDeliveryBoyStatusResponse({this.success, this.message, this.data});

  factory UpdateDeliveryBoyStatusResponse.fromJson(Map<String, dynamic> json) {
    return UpdateDeliveryBoyStatusResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data:
          json['data'] != null
              ? DeliveryBoyStatusModel.fromJson(
                json['data'] as Map<String, dynamic>,
              )
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

class DeliveryBoyStatusModel {
  DeliveryBoy? deliveryBoy;

  DeliveryBoyStatusModel({this.deliveryBoy});

  factory DeliveryBoyStatusModel.fromJson(Map<String, dynamic> json) {
    return DeliveryBoyStatusModel(
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
    if (deliveryBoy != null) {
      data['delivery_boy'] = deliveryBoy!.toJson();
    }
    return data;
  }
}

class DeliveryBoy {
  int? id;
  int? userId;
  int? deliveryZoneId;
  String? fullName;
  String? address;
  File? driverLicense; // File object (not from JSON)
  String? driverLicenseNumber;
  String? vehicleType;
  File? vehicleRegistration; // File object (not from JSON)
  String? verificationStatus;
  String? verificationRemark;
  String? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  DeliveryZone? deliveryZone;

  DeliveryBoy({
    this.id,
    this.userId,
    this.deliveryZoneId,
    this.fullName,
    this.address,
    this.driverLicense,
    this.driverLicenseNumber,
    this.vehicleType,
    this.vehicleRegistration,
    this.verificationStatus,
    this.verificationRemark,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.deliveryZone,
  });

  factory DeliveryBoy.fromJson(Map<String, dynamic> json) {
    return DeliveryBoy(
      id: JsonParser.intValue(json['id']),
      userId: JsonParser.intValue(json['user_id']),
      deliveryZoneId: JsonParser.intValue(json['delivery_zone_id']),
      fullName: JsonParser.string(json['full_name']),
      address: JsonParser.string(json['address']),
      driverLicenseNumber: JsonParser.string(json['driver_license_number']),
      vehicleType: JsonParser.string(json['vehicle_type']),
      verificationStatus: JsonParser.string(json['verification_status']),
      verificationRemark: JsonParser.string(json['verification_remark']),
      status: JsonParser.string(json['status']),
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
      deletedAt: JsonParser.string(json['deleted_at']),
      deliveryZone:
          json['delivery_zone'] != null
              ? DeliveryZone.fromJson(
                json['delivery_zone'] as Map<String, dynamic>,
              )
              : null,
      // Note: driverLicense and vehicleRegistration are File objects
      // They are not parsed from JSON here (usually handled separately in API calls)
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['delivery_zone_id'] = deliveryZoneId;
    data['full_name'] = fullName;
    data['address'] = address;
    data['driver_license'] = driverLicense;
    data['driver_license_number'] = driverLicenseNumber;
    data['vehicle_type'] = vehicleType;
    data['vehicle_registration'] = vehicleRegistration;
    data['verification_status'] = verificationStatus;
    data['verification_remark'] = verificationRemark;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    if (deliveryZone != null) {
      data['delivery_zone'] = deliveryZone!.toJson();
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
  double? rushDeliveryTimePerKm;
  double? rushDeliveryCharges;
  int? deliveryTimePerKm;
  int? regularDeliveryCharges;
  double? freeDeliveryAmount;
  double? distanceBasedDeliveryCharges;
  double? perStoreDropOffFee;
  double? handlingCharges;
  double? deliveryBoyBaseFee;
  double? deliveryBoyPerStorePickupFee;
  double? deliveryBoyDistanceBasedFee;
  double? deliveryBoyPerOrderIncentive;
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
      rushDeliveryTimePerKm: JsonParser.doubleValue(
        json['rush_delivery_time_per_km'],
      ),
      rushDeliveryCharges: JsonParser.doubleValue(
        json['rush_delivery_charges'],
      ),
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
      deliveryBoyBaseFee: JsonParser.doubleValue(json['delivery_boy_base_fee']),
      deliveryBoyPerStorePickupFee: JsonParser.doubleValue(
        json['delivery_boy_per_store_pickup_fee'],
      ),
      deliveryBoyDistanceBasedFee: JsonParser.doubleValue(
        json['delivery_boy_distance_based_fee'],
      ),
      deliveryBoyPerOrderIncentive: JsonParser.doubleValue(
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
