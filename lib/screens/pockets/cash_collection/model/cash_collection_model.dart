import 'package:hyper_local/utils/services/json_parser.dart';

const String modelName = 'cash_collection_model';

class CashCollectionResponse {
  final bool? success;
  final String? message;
  final CashCollectionData? data;

  CashCollectionResponse({this.success, this.message, this.data});

  factory CashCollectionResponse.fromJson(Map<String, dynamic> json) {
    return CashCollectionResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data:
          json['data'] != null
              ? CashCollectionData.fromJson(
                json['data'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

class CashCollectionData {
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? lastPage;
  final List<CashCollectionModel>? cashCollections;

  CashCollectionData({
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
    this.cashCollections,
  });

  factory CashCollectionData.fromJson(Map<String, dynamic> json) {
    return CashCollectionData(
      total: JsonParser.intValue(json['total']),
      perPage: JsonParser.intValue(json['per_page']),
      currentPage: JsonParser.intValue(json['current_page']),
      lastPage: JsonParser.intValue(json['last_page']),
      cashCollections: JsonParser.list<CashCollectionModel>(
        json['cash_collections'],
        (x) => CashCollectionModel.fromJson(x as Map<String, dynamic>),
      ),
    );
  }
}

class CashCollectionModel {
  final int? id;
  final int? orderId;
  final String? orderDate;
  final String? cashCollected;
  final String? cashSubmitted;
  final String? remainingAmount;
  final String? submissionStatus;
  final String? createdAt;

  CashCollectionModel({
    this.id,
    this.orderId,
    this.orderDate,
    this.cashCollected,
    this.cashSubmitted,
    this.remainingAmount,
    this.submissionStatus,
    this.createdAt,
  });

  factory CashCollectionModel.fromJson(Map<String, dynamic> json) {
    return CashCollectionModel(
      id: JsonParser.intValue(json['id']),
      orderId: JsonParser.intValue(json['order_id']),
      orderDate: JsonParser.string(json['order_date']),
      cashCollected: JsonParser.string(json['cash_collected']),
      cashSubmitted: JsonParser.string(json['cash_submitted']),
      remainingAmount: JsonParser.string(json['remaining_amount']),
      submissionStatus: JsonParser.string(json['submission_status']),
      createdAt: JsonParser.string(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'order_date': orderDate,
      'cash_collected': cashCollected,
      'cash_submitted': cashSubmitted,
      'remaining_amount': remainingAmount,
      'submission_status': submissionStatus,
      'created_at': createdAt,
    };
  }
}

class CashCollectionDetailModel {
  final String? baseFee;
  final String? perStorePickupFee;
  final String? distanceBasedFee;
  final String? perOrderIncentive;
  final String? total;

  CashCollectionDetailModel({
    this.baseFee,
    this.perStorePickupFee,
    this.distanceBasedFee,
    this.perOrderIncentive,
    this.total,
  });

  factory CashCollectionDetailModel.fromJson(Map<String, dynamic> json) {
    return CashCollectionDetailModel(
      baseFee: JsonParser.string(json['base_fee']),
      perStorePickupFee: JsonParser.string(json['per_store_pickup_fee']),
      distanceBasedFee: JsonParser.string(json['distance_based_fee']),
      perOrderIncentive: JsonParser.string(json['per_order_incentive']),
      total: JsonParser.string(json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_fee': baseFee,
      'per_store_pickup_fee': perStorePickupFee,
      'distance_based_fee': distanceBasedFee,
      'per_order_incentive': perOrderIncentive,
      'total': total,
    };
  }
}
