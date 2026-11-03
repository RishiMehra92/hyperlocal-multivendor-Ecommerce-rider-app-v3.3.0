import 'package:hyper_local/utils/services/json_parser.dart';

const String modelName = 'delivery_zone_model';

class DeliveryZoneListResponse {
  final bool success;
  final String message;
  final DeliveryZoneData data;

  DeliveryZoneListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DeliveryZoneListResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryZoneListResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: DeliveryZoneData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class DeliveryZoneData {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<DeliveryZoneModel> data;

  DeliveryZoneData({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.data,
  });

  factory DeliveryZoneData.fromJson(Map<String, dynamic> json) {
    return DeliveryZoneData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),
      data: JsonParser.list<DeliveryZoneModel>(
        json['data'],
        (e) => DeliveryZoneModel.fromJson(e as Map<String, dynamic>),
      ),
    );
  }
}

class DeliveryZoneModel {
  final int id;
  final String name;
  final String slug;
  final String centerLatitude;
  final String centerLongitude;
  final double radiusKm;
  final List<BoundaryPoint> boundaryJson;
  final bool rushDeliveryEnabled;
  final int deliveryTimePerKm;
  final int? rushDeliveryTimePerKm;
  final int? rushDeliveryCharges;
  final int regularDeliveryCharges;
  final int? freeDeliveryAmount;
  final int? distanceBasedDeliveryCharges;
  final int? perStoreDropOffFee;
  final int? handlingCharges;
  final int bufferTime;
  final String status;
  final String? deliveryBoyBaseFee;
  final String? deliveryBoyPerStorePickupFee;
  final String? deliveryBoyDistanceBasedFee;
  final String? deliveryBoyPerOrderIncentive;
  final String createdAt;
  final String updatedAt;

  DeliveryZoneModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusKm,
    required this.boundaryJson,
    required this.rushDeliveryEnabled,
    required this.deliveryTimePerKm,
    this.rushDeliveryTimePerKm,
    this.rushDeliveryCharges,
    required this.regularDeliveryCharges,
    this.freeDeliveryAmount,
    this.distanceBasedDeliveryCharges,
    this.perStoreDropOffFee,
    this.handlingCharges,
    required this.bufferTime,
    required this.status,
    this.deliveryBoyBaseFee,
    this.deliveryBoyPerStorePickupFee,
    this.deliveryBoyDistanceBasedFee,
    this.deliveryBoyPerOrderIncentive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryZoneModel.fromJson(Map<String, dynamic> json) {
    return DeliveryZoneModel(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
      name: JsonParser.requireString(
        json['name'],
        model: modelName,
        field: 'name',
      ),
      slug: JsonParser.requireString(
        json['slug'],
        model: modelName,
        field: 'slug',
      ),
      centerLatitude: JsonParser.string(json['center_latitude'] ?? '0'),
      centerLongitude: JsonParser.string(json['center_longitude'] ?? '0'),
      radiusKm: JsonParser.doubleValue(json['radius_km'] ?? 0.0),

      boundaryJson: JsonParser.list<BoundaryPoint>(
        json['boundary_json'],
        (e) => BoundaryPoint.fromJson(e as Map<String, dynamic>),
      ),

      rushDeliveryEnabled: JsonParser.boolValue(
        json['rush_delivery_enabled'] ?? false,
      ),
      deliveryTimePerKm: JsonParser.intValue(json['delivery_time_per_km'] ?? 0),
      rushDeliveryTimePerKm: JsonParser.intValue(
        json['rush_delivery_time_per_km'],
      ),
      rushDeliveryCharges: JsonParser.intValue(json['rush_delivery_charges']),
      regularDeliveryCharges: JsonParser.intValue(
        json['regular_delivery_charges'] ?? 0,
      ),
      freeDeliveryAmount: JsonParser.intValue(json['free_delivery_amount']),
      distanceBasedDeliveryCharges: JsonParser.intValue(
        json['distance_based_delivery_charges'],
      ),
      perStoreDropOffFee: JsonParser.intValue(json['per_store_drop_off_fee']),
      handlingCharges: JsonParser.intValue(json['handling_charges']),
      bufferTime: JsonParser.intValue(json['buffer_time'] ?? 0),

      status: JsonParser.string(json['status'] ?? 'inactive'),

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

      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'radius_km': radiusKm,
      'boundary_json': boundaryJson.map((e) => e.toJson()).toList(),
      'rush_delivery_enabled': rushDeliveryEnabled,
      'delivery_time_per_km': deliveryTimePerKm,
      'rush_delivery_time_per_km': rushDeliveryTimePerKm,
      'rush_delivery_charges': rushDeliveryCharges,
      'regular_delivery_charges': regularDeliveryCharges,
      'free_delivery_amount': freeDeliveryAmount,
      'distance_based_delivery_charges': distanceBasedDeliveryCharges,
      'per_store_drop_off_fee': perStoreDropOffFee,
      'handling_charges': handlingCharges,
      'buffer_time': bufferTime,
      'status': status,
      'delivery_boy_base_fee': deliveryBoyBaseFee,
      'delivery_boy_per_store_pickup_fee': deliveryBoyPerStorePickupFee,
      'delivery_boy_distance_based_fee': deliveryBoyDistanceBasedFee,
      'delivery_boy_per_order_incentive': deliveryBoyPerOrderIncentive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class BoundaryPoint {
  final double lat;
  final double lng;

  BoundaryPoint({required this.lat, required this.lng});

  factory BoundaryPoint.fromJson(Map<String, dynamic> json) {
    return BoundaryPoint(
      lat: JsonParser.doubleValue(json['lat'] ?? 0.0),
      lng: JsonParser.doubleValue(json['lng'] ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng};
  }
}
