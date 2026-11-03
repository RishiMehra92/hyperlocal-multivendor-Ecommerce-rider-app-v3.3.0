import 'package:hyper_local/utils/services/json_parser.dart';

const String modelName = 'delivery_zone_model';

class DeliveryZoneResponse {
  bool? success;
  String? message;
  DeliveryZone? data;

  DeliveryZoneResponse({this.success, this.message, this.data});

  factory DeliveryZoneResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryZoneResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data:
          json['data'] != null
              ? DeliveryZone.fromJson(json['data'] as Map<String, dynamic>)
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

class DeliveryZone {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<DeliveryZoneModel>? data;

  DeliveryZone({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.data,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),
      data: JsonParser.list<DeliveryZoneModel>(
        json['data'],
        (v) => DeliveryZoneModel.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DeliveryZoneModel {
  int? id;
  String? name;
  String? slug;
  String? centerLatitude;
  String? centerLongitude;
  double? radiusKm;
  List<BoundaryJson>? boundaryJson;
  bool? rushDeliveryEnabled;
  int? deliveryTimePerKm;
  int? rushDeliveryTimePerKm;
  int? rushDeliveryCharges;
  int? regularDeliveryCharges;
  int? freeDeliveryAmount;
  int? distanceBasedDeliveryCharges;
  int? perStoreDropOffFee;
  int? handlingCharges;
  int? bufferTime;
  String? status;
  String? deliveryBoyBaseFee;
  String? deliveryBoyPerStorePickupFee;
  String? deliveryBoyDistanceBasedFee;
  String? deliveryBoyPerOrderIncentive;
  String? createdAt;
  String? updatedAt;

  DeliveryZoneModel({
    this.id,
    this.name,
    this.slug,
    this.centerLatitude,
    this.centerLongitude,
    this.radiusKm,
    this.boundaryJson,
    this.rushDeliveryEnabled,
    this.deliveryTimePerKm,
    this.rushDeliveryTimePerKm,
    this.rushDeliveryCharges,
    this.regularDeliveryCharges,
    this.freeDeliveryAmount,
    this.distanceBasedDeliveryCharges,
    this.perStoreDropOffFee,
    this.handlingCharges,
    this.bufferTime,
    this.status,
    this.deliveryBoyBaseFee,
    this.deliveryBoyPerStorePickupFee,
    this.deliveryBoyDistanceBasedFee,
    this.deliveryBoyPerOrderIncentive,
    this.createdAt,
    this.updatedAt,
  });

  factory DeliveryZoneModel.fromJson(Map<String, dynamic> json) {
    return DeliveryZoneModel(
      id: JsonParser.intValue(json['id']),
      name: JsonParser.string(json['name']),
      slug: JsonParser.string(json['slug']),

      centerLatitude: JsonParser.string(json['center_latitude']),
      centerLongitude: JsonParser.string(json['center_longitude']),
      radiusKm: JsonParser.doubleValue(json['radius_km']),

      boundaryJson: JsonParser.list<BoundaryJson>(
        json['boundary_json'],
        (v) => BoundaryJson.fromJson(v as Map<String, dynamic>),
      ),

      rushDeliveryEnabled: JsonParser.boolValue(
        json['rush_delivery_enabled'] ?? false,
      ),

      deliveryTimePerKm: JsonParser.intValue(json['delivery_time_per_km']),
      rushDeliveryTimePerKm: JsonParser.intValue(
        json['rush_delivery_time_per_km'],
      ),
      rushDeliveryCharges: JsonParser.intValue(json['rush_delivery_charges']),
      regularDeliveryCharges: JsonParser.intValue(
        json['regular_delivery_charges'],
      ),
      freeDeliveryAmount: JsonParser.intValue(json['free_delivery_amount']),
      distanceBasedDeliveryCharges: JsonParser.intValue(
        json['distance_based_delivery_charges'],
      ),
      perStoreDropOffFee: JsonParser.intValue(json['per_store_drop_off_fee']),
      handlingCharges: JsonParser.intValue(json['handling_charges']),
      bufferTime: JsonParser.intValue(json['buffer_time']),

      status: JsonParser.string(json['status'] ?? ''),

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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['center_latitude'] = centerLatitude;
    data['center_longitude'] = centerLongitude;
    data['radius_km'] = radiusKm;
    if (boundaryJson != null) {
      data['boundary_json'] = boundaryJson!.map((v) => v.toJson()).toList();
    }
    data['rush_delivery_enabled'] = rushDeliveryEnabled;
    data['delivery_time_per_km'] = deliveryTimePerKm;
    data['rush_delivery_time_per_km'] = rushDeliveryTimePerKm;
    data['rush_delivery_charges'] = rushDeliveryCharges;
    data['regular_delivery_charges'] = regularDeliveryCharges;
    data['free_delivery_amount'] = freeDeliveryAmount;
    data['distance_based_delivery_charges'] = distanceBasedDeliveryCharges;
    data['per_store_drop_off_fee'] = perStoreDropOffFee;
    data['handling_charges'] = handlingCharges;
    data['buffer_time'] = bufferTime;
    data['status'] = status;
    data['delivery_boy_base_fee'] = deliveryBoyBaseFee;
    data['delivery_boy_per_store_pickup_fee'] = deliveryBoyPerStorePickupFee;
    data['delivery_boy_distance_based_fee'] = deliveryBoyDistanceBasedFee;
    data['delivery_boy_per_order_incentive'] = deliveryBoyPerOrderIncentive;
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
