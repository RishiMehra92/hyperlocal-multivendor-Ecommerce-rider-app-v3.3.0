import 'package:hyper_local/utils/services/json_parser.dart';

const String modelName = 'home_stats_model';

class HomeStatsResponse {
  final bool success;
  final String message;
  final List<HomeStatsData> data;

  HomeStatsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory HomeStatsResponse.fromJson(Map<String, dynamic> json) {
    return HomeStatsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: JsonParser.list<HomeStatsData>(
        json['data'],
        (item) => HomeStatsData.fromJson(item as Map<String, dynamic>),
      ),
    );
  }
}

class HomeStatsData {
  final String key;
  final dynamic value;

  HomeStatsData({required this.key, required this.value});

  factory HomeStatsData.fromJson(Map<String, dynamic> json) {
    return HomeStatsData(
      key: JsonParser.string(json['key']),
      value: json['value'], // dynamic value - kept as is
    );
  }

  // Helper getters (unchanged logic, just cleaner)
  ProfileData? get profileData {
    if (key == 'profile' && value is Map<String, dynamic>) {
      return ProfileData.fromJson(value);
    }
    return null;
  }

  SummaryData? get summaryData {
    if (key == 'summary' && value is Map<String, dynamic>) {
      return SummaryData.fromJson(value);
    }
    return null;
  }

  PerformanceMetricsData? get performanceMetricsData {
    if (key == 'performanceMetrics' && value is Map<String, dynamic>) {
      return PerformanceMetricsData.fromJson(value);
    }
    return null;
  }

  TodayProgressData? get todayProgressData {
    if (key == 'todayProgress' && value is Map<String, dynamic>) {
      return TodayProgressData.fromJson(value);
    }
    return null;
  }

  EarningsAnalyticsData? get earningsAnalyticsData {
    if (key == 'earningsAnalytics' && value is Map<String, dynamic>) {
      return EarningsAnalyticsData.fromJson(value);
    }
    return null;
  }
}

class ProfileData {
  final DeliveryBoyData deliveryBoy;

  ProfileData({required this.deliveryBoy});

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      deliveryBoy: DeliveryBoyData.fromJson(
        json['deliveryBoy'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class DeliveryBoyData {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? profileImage;
  final String status;
  final double rating;
  final int totalDeliveries;
  final DeliveryZone? deliveryZone;
  final List<StoreData> stores;

  DeliveryBoyData({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.profileImage,
    required this.status,
    required this.rating,
    required this.totalDeliveries,
    this.deliveryZone,
    required this.stores,
  });

  factory DeliveryBoyData.fromJson(Map<String, dynamic> json) {
    return DeliveryBoyData(
      id: JsonParser.intValue(json['id'] ?? 0),
      fullName: JsonParser.string(json['fullName'] ?? ''),
      email: JsonParser.string(json['email'] ?? ''),
      phone: JsonParser.string(json['phone']),
      profileImage: JsonParser.string(json['profileImage']),
      status: JsonParser.string(json['status'] ?? ''),
      rating: JsonParser.doubleValue(json['rating'] ?? 0.0),
      totalDeliveries: JsonParser.intValue(json['totalDeliveries'] ?? 0),
      deliveryZone:
          json['deliveryZone'] != null
              ? DeliveryZone.fromJson(
                json['deliveryZone'] as Map<String, dynamic>,
              )
              : null,
      stores: JsonParser.list<StoreData>(
        json['stores'],
        (item) => StoreData.fromJson(item as Map<String, dynamic>),
      ),
    );
  }
}

class DeliveryZone {
  final int id;
  final String name;
  final String centerLatitude;
  final String centerLongitude;
  final List<BoundaryPoint> boundaryJson;

  DeliveryZone({
    required this.id,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.boundaryJson,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: JsonParser.intValue(json['id'] ?? 0),
      name: JsonParser.string(json['name'] ?? ''),
      centerLatitude: JsonParser.string(json['centerLatitude'] ?? ''),
      centerLongitude: JsonParser.string(json['centerLongitude'] ?? ''),
      boundaryJson: JsonParser.list<BoundaryPoint>(
        json['boundaryJson'],
        (item) => BoundaryPoint.fromJson(item as Map<String, dynamic>),
      ),
    );
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
}

class SummaryData {
  final PeriodData today;
  final PeriodData thisWeek;
  final PeriodData thisMonth;
  final PeriodData total;

  SummaryData({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.total,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    return SummaryData(
      today: PeriodData.fromJson(json['today'] as Map<String, dynamic>? ?? {}),
      thisWeek: PeriodData.fromJson(
        json['thisWeek'] as Map<String, dynamic>? ?? {},
      ),
      thisMonth: PeriodData.fromJson(
        json['thisMonth'] as Map<String, dynamic>? ?? {},
      ),
      total: PeriodData.fromJson(json['total'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class PeriodData {
  final double earnings;
  final int orders;
  final double rating;

  PeriodData({
    required this.earnings,
    required this.orders,
    required this.rating,
  });

  factory PeriodData.fromJson(Map<String, dynamic> json) {
    return PeriodData(
      earnings: JsonParser.doubleValue(json['earnings'] ?? 0.0),
      orders: JsonParser.intValue(json['orders'] ?? 0),
      rating: JsonParser.doubleValue(json['rating'] ?? 0.0),
    );
  }
}

class PerformanceMetricsData {
  final int ordersDelivered;
  final double averageRating;

  PerformanceMetricsData({
    required this.ordersDelivered,
    required this.averageRating,
  });

  factory PerformanceMetricsData.fromJson(Map<String, dynamic> json) {
    return PerformanceMetricsData(
      ordersDelivered: JsonParser.intValue(json['ordersDelivered'] ?? 0),
      averageRating: JsonParser.doubleValue(json['averageRating'] ?? 0.0),
    );
  }
}

class TodayProgressData {
  final double earnings;
  final int trips;
  final String sessions;
  final int gigs;

  TodayProgressData({
    required this.earnings,
    required this.trips,
    required this.sessions,
    required this.gigs,
  });

  factory TodayProgressData.fromJson(Map<String, dynamic> json) {
    return TodayProgressData(
      earnings: JsonParser.doubleValue(json['earnings'] ?? 0.0),
      trips: JsonParser.intValue(json['trips'] ?? 0),
      sessions: JsonParser.string(json['sessions'] ?? ''),
      gigs: JsonParser.intValue(json['gigs'] ?? 0),
    );
  }
}

class EarningsAnalyticsData {
  final AnalyticsSummary summary;
  final AnalyticsCharts charts;

  EarningsAnalyticsData({required this.summary, required this.charts});

  factory EarningsAnalyticsData.fromJson(Map<String, dynamic> json) {
    return EarningsAnalyticsData(
      summary: AnalyticsSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
      charts: AnalyticsCharts.fromJson(
        json['charts'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class AnalyticsSummary {
  final double totalEarnings;
  final double averageEarnings;
  final int totalOrders;
  final double averageRating;

  AnalyticsSummary({
    required this.totalEarnings,
    required this.averageEarnings,
    required this.totalOrders,
    required this.averageRating,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalEarnings: JsonParser.doubleValue(json['totalEarnings'] ?? 0.0),
      averageEarnings: JsonParser.doubleValue(json['averageEarnings'] ?? 0.0),
      totalOrders: JsonParser.intValue(json['totalOrders'] ?? 0),
      averageRating: JsonParser.doubleValue(json['averageRating'] ?? 0.0),
    );
  }
}

class AnalyticsCharts {
  final ChartData weekly;
  final ChartData monthly;
  final ChartData yearly;

  AnalyticsCharts({
    required this.weekly,
    required this.monthly,
    required this.yearly,
  });

  factory AnalyticsCharts.fromJson(Map<String, dynamic> json) {
    return AnalyticsCharts(
      weekly: ChartData.fromJson(json['weekly'] as Map<String, dynamic>? ?? {}),
      monthly: ChartData.fromJson(
        json['monthly'] as Map<String, dynamic>? ?? {},
      ),
      yearly: ChartData.fromJson(json['yearly'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class ChartData {
  final String period;
  final List<ChartPoint> data;

  ChartData({required this.period, required this.data});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      period: JsonParser.string(json['period'] ?? ''),
      data: JsonParser.list<ChartPoint>(
        json['data'],
        (item) => ChartPoint.fromJson(item as Map<String, dynamic>),
      ),
    );
  }
}

class ChartPoint {
  final String label;
  final double earnings;
  final int orders;
  final double? percentage;

  ChartPoint({
    required this.label,
    required this.earnings,
    required this.orders,
    this.percentage,
  });

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      label: JsonParser.string(
        json['day'] ?? json['week'] ?? json['month'] ?? '',
      ),
      earnings: JsonParser.doubleValue(json['earnings'] ?? 0.0),
      orders: JsonParser.intValue(json['orders'] ?? 0),
      percentage:
          json['percentage'] != null
              ? JsonParser.doubleValue(json['percentage'])
              : null,
    );
  }
}

class StoreData {
  final int id;
  final String name;
  final String? slug;
  final String? address;
  final String latitude;
  final String longitude;
  final String? logo;
  final String? banner;

  StoreData({
    required this.id,
    required this.name,
    this.slug,
    this.address,
    required this.latitude,
    required this.longitude,
    this.logo,
    this.banner,
  });

  factory StoreData.fromJson(Map<String, dynamic> json) {
    return StoreData(
      id: JsonParser.intValue(json['id'] ?? 0),
      name: JsonParser.string(json['name'] ?? ''),
      slug: JsonParser.string(json['slug']),
      address: JsonParser.string(json['address']),
      latitude: JsonParser.string(json['latitude'] ?? '0.0'),
      longitude: JsonParser.string(json['longitude'] ?? '0.0'),
      logo: JsonParser.string(json['logo']),
      banner: JsonParser.string(json['banner']),
    );
  }
}
