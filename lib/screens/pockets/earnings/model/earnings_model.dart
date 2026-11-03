import 'package:hyper_local/utils/services/json_parser.dart';

const String modelName = 'earnings_model';

class EarningsResponse {
  final bool? success;
  final String? message;
  final EarningsListData? data;

  EarningsResponse({this.success, this.message, this.data});

  factory EarningsResponse.fromJson(Map<String, dynamic> json) {
    return EarningsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data:
          json['data'] != null
              ? EarningsListData.fromJson(json['data'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data?.toJson()};
  }
}

class EarningsListData {
  final int? total;
  final int? perPage;
  final int? currentPage;
  final int? lastPage;
  final double? totalEarnings;
  final List<EarningsModel>? earnings;

  EarningsListData({
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
    this.totalEarnings,
    this.earnings,
  });

  factory EarningsListData.fromJson(Map<String, dynamic> json) {
    return EarningsListData(
      total: JsonParser.intValue(json['total']),
      perPage: JsonParser.intValue(json['per_page']),
      currentPage: JsonParser.intValue(json['current_page']),
      lastPage: JsonParser.intValue(json['last_page']),
      totalEarnings: JsonParser.doubleValue(json['total_earnings']),
      earnings: JsonParser.list<EarningsModel>(
        json['earnings'],
        (x) => EarningsModel.fromJson(x as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'per_page': perPage,
      'current_page': currentPage,
      'last_page': lastPage,
      'total_earnings': totalEarnings,
      'earnings': earnings?.map((x) => x.toJson()).toList(),
    };
  }
}

class EarningsModel {
  final int? id;
  final int? orderId;
  final String? orderDate;
  final EarningsDetailModel? earnings;
  final String? paymentStatus;
  final String? paidAt;
  final String? createdAt;

  EarningsModel({
    this.id,
    this.orderId,
    this.orderDate,
    this.earnings,
    this.paymentStatus,
    this.paidAt,
    this.createdAt,
  });

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      id: JsonParser.intValue(json['id']),
      orderId: JsonParser.intValue(json['order_id']),
      orderDate: JsonParser.string(json['order_date']),
      earnings:
          json['earnings'] != null
              ? EarningsDetailModel.fromJson(
                json['earnings'] as Map<String, dynamic>,
              )
              : null,
      paymentStatus: JsonParser.string(json['payment_status']),
      paidAt: JsonParser.string(json['paid_at']),
      createdAt: JsonParser.string(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'order_date': orderDate,
      'earnings': earnings?.toJson(),
      'payment_status': paymentStatus,
      'paid_at': paidAt,
      'created_at': createdAt,
    };
  }
}

class EarningsDetailModel {
  final String? baseFee;
  final String? perStorePickupFee;
  final String? distanceBasedFee;
  final String? perOrderIncentive;
  final String? total;

  EarningsDetailModel({
    this.baseFee,
    this.perStorePickupFee,
    this.distanceBasedFee,
    this.perOrderIncentive,
    this.total,
  });

  factory EarningsDetailModel.fromJson(Map<String, dynamic> json) {
    return EarningsDetailModel(
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

class EarningsStatisticsModel {
  final double? totalEarnings;
  final double? pendingEarnings;
  final double? paidEarnings;
  final int? totalOrders;
  final EarningsBreakdownModel? earningsBreakdown;
  final double? remainingCashAmount;
  final bool? isCashlimitEnabled;

  EarningsStatisticsModel({
    this.totalEarnings,
    this.pendingEarnings,
    this.paidEarnings,
    this.totalOrders,
    this.earningsBreakdown,
    this.remainingCashAmount,
    this.isCashlimitEnabled,
  });

  factory EarningsStatisticsModel.fromJson(Map<String, dynamic> json) {
    return EarningsStatisticsModel(
      totalEarnings: JsonParser.doubleValue(json['total_earnings']),
      pendingEarnings: JsonParser.doubleValue(json['pending_earnings']),
      paidEarnings: JsonParser.doubleValue(json['paid_earnings']),
      totalOrders: JsonParser.intValue(json['total_orders']),
      earningsBreakdown:
          json['earnings_breakdown'] != null
              ? EarningsBreakdownModel.fromJson(
                json['earnings_breakdown'] as Map<String, dynamic>,
              )
              : null,
      remainingCashAmount: JsonParser.doubleValue(
        json['remaining_cash_amount'],
      ),
      isCashlimitEnabled: JsonParser.boolValue(json['is_cashlimit_enabled']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_earnings': totalEarnings,
      'pending_earnings': pendingEarnings,
      'paid_earnings': paidEarnings,
      'total_orders': totalOrders,
      'earnings_breakdown': earningsBreakdown?.toJson(),
      'remaining_cash_amount': remainingCashAmount,
      'is_cashlimit_enabled': isCashlimitEnabled,
    };
  }
}

class EarningsBreakdownModel {
  final double? baseFee;
  final double? perStorePickupFee;
  final double? distanceBasedFee;
  final double? perOrderIncentive;

  EarningsBreakdownModel({
    this.baseFee,
    this.perStorePickupFee,
    this.distanceBasedFee,
    this.perOrderIncentive,
  });

  factory EarningsBreakdownModel.fromJson(Map<String, dynamic> json) {
    return EarningsBreakdownModel(
      baseFee: JsonParser.doubleValue(json['base_fee']),
      perStorePickupFee: JsonParser.doubleValue(json['per_store_pickup_fee']),
      distanceBasedFee: JsonParser.doubleValue(json['distance_based_fee']),
      perOrderIncentive: JsonParser.doubleValue(json['per_order_incentive']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_fee': baseFee,
      'per_store_pickup_fee': perStorePickupFee,
      'distance_based_fee': distanceBasedFee,
      'per_order_incentive': perOrderIncentive,
    };
  }
}

class EarningsStatsResponse {
  final bool? success;
  final String? message;
  final EarningsStatisticsModel? data;

  EarningsStatsResponse({this.success, this.message, this.data});

  factory EarningsStatsResponse.fromJson(Map<String, dynamic> json) {
    return EarningsStatsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data:
          json['data'] != null
              ? EarningsStatisticsModel.fromJson(
                json['data'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data?.toJson()};
  }
}

class EarningsDateRangeResponse {
  final bool? success;
  final String? message;
  final List<String>? data;

  EarningsDateRangeResponse({this.success, this.message, this.data});

  factory EarningsDateRangeResponse.fromJson(Map<String, dynamic> json) {
    return EarningsDateRangeResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: JsonParser.list<String>(json['data'], (v) => JsonParser.string(v)),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data};
  }
}

// Removed EarningsDateRangeModel as it was redundant with EarningsDateRangeResponse
