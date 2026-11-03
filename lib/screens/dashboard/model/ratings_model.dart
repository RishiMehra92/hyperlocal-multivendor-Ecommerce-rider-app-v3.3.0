import 'package:hyper_local/utils/services/json_parser.dart';

const String modelName = 'ratings_model';

/// Overall Ratings Response
class RatingsResponse {
  final bool success;
  final String message;
  final RatingsData data;

  RatingsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RatingsResponse.fromJson(Map<String, dynamic> json) {
    return RatingsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: RatingsData.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class RatingsData {
  final int totalReviews;
  final double averageRating;
  final RatingsBreakdown ratingsBreakdown;

  RatingsData({
    required this.totalReviews,
    required this.averageRating,
    required this.ratingsBreakdown,
  });

  factory RatingsData.fromJson(Map<String, dynamic> json) {
    return RatingsData(
      totalReviews: JsonParser.intValue(json['total_reviews'] ?? 0),
      averageRating: JsonParser.doubleValue(json['average_rating'] ?? 0.0),
      ratingsBreakdown: RatingsBreakdown.fromJson(
        json['ratings_breakdown'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class RatingsBreakdown {
  final int oneStar;
  final int twoStar;
  final int threeStar;
  final int fourStar;
  final int fiveStar;

  RatingsBreakdown({
    required this.oneStar,
    required this.twoStar,
    required this.threeStar,
    required this.fourStar,
    required this.fiveStar,
  });

  factory RatingsBreakdown.fromJson(Map<String, dynamic> json) {
    return RatingsBreakdown(
      oneStar: JsonParser.intValue(json['1_star'] ?? 0),
      twoStar: JsonParser.intValue(json['2_star'] ?? 0),
      threeStar: JsonParser.intValue(json['3_star'] ?? 0),
      fourStar: JsonParser.intValue(json['4_star'] ?? 0),
      fiveStar: JsonParser.intValue(json['5_star'] ?? 0),
    );
  }
}

/// Delivery Feedback Response
class DeliveryFeedbackResponse {
  final bool success;
  final String message;
  final FeedbackPaginationData data;

  DeliveryFeedbackResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory DeliveryFeedbackResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryFeedbackResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: FeedbackPaginationData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class FeedbackPaginationData {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<DeliveryFeedback> feedbackItems;

  FeedbackPaginationData({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.feedbackItems,
  });

  factory FeedbackPaginationData.fromJson(Map<String, dynamic> json) {
    return FeedbackPaginationData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),
      feedbackItems: JsonParser.list<DeliveryFeedback>(
        json['data'],
        (item) => DeliveryFeedback.fromJson(item as Map<String, dynamic>),
      ),
    );
  }
}

class DeliveryFeedback {
  final int id;
  final User user;
  final DeliveryBoy deliveryBoy;
  final dynamic order; // Can be null
  final String title;
  final String slug;
  final String description;
  final int rating;
  final DateTime createdAt;

  DeliveryFeedback({
    required this.id,
    required this.user,
    required this.deliveryBoy,
    this.order,
    required this.title,
    required this.slug,
    required this.description,
    required this.rating,
    required this.createdAt,
  });

  factory DeliveryFeedback.fromJson(Map<String, dynamic> json) {
    return DeliveryFeedback(
      id: JsonParser.intValue(json['id'] ?? 0),
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      deliveryBoy: DeliveryBoy.fromJson(
        json['delivery_boy'] as Map<String, dynamic>? ?? {},
      ),
      order: json['order'],
      title: JsonParser.string(json['title'] ?? ''),
      slug: JsonParser.string(json['slug'] ?? ''),
      description: JsonParser.string(json['description'] ?? ''),
      rating: JsonParser.intValue(json['rating'] ?? 0),
      createdAt: JsonParser.dateTimeValue(json['created_at']) ?? DateTime.now(),
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String mobile;
  final String? referralCode;
  final String? friendsCode;
  final int rewardPoints;
  final String profileImage;
  final bool status;
  final String country;
  final String iso2;
  final String accessPanel;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    this.referralCode,
    this.friendsCode,
    required this.rewardPoints,
    required this.profileImage,
    required this.status,
    required this.country,
    required this.iso2,
    required this.accessPanel,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: JsonParser.intValue(json['id'] ?? 0),
      name: JsonParser.string(json['name'] ?? ''),
      email: JsonParser.string(json['email'] ?? ''),
      mobile: JsonParser.string(json['mobile'] ?? ''),
      referralCode: JsonParser.string(json['referral_code']),
      friendsCode: JsonParser.string(json['friends_code']),
      rewardPoints: JsonParser.intValue(json['reward_points'] ?? 0),
      profileImage: JsonParser.string(json['profile_image'] ?? ''),
      status: JsonParser.boolValue(json['status'] ?? false),
      country: JsonParser.string(json['country'] ?? ''),
      iso2: JsonParser.string(json['iso_2'] ?? ''),
      accessPanel: JsonParser.string(json['access_panel'] ?? ''),
      createdAt: JsonParser.dateTimeValue(json['created_at']) ?? DateTime.now(),
    );
  }
}

class DeliveryBoy {
  final int id;
  final int userId;
  final int deliveryZoneId;
  final String status;
  final String fullName;
  final String address;
  final List<String> driverLicense;
  final String driverLicenseNumber;
  final String vehicleType;
  final List<String> vehicleRegistration;
  final String verificationStatus;
  final String? verificationRemark;
  final DateTime createdAt;

  DeliveryBoy({
    required this.id,
    required this.userId,
    required this.deliveryZoneId,
    required this.status,
    required this.fullName,
    required this.address,
    required this.driverLicense,
    required this.driverLicenseNumber,
    required this.vehicleType,
    required this.vehicleRegistration,
    required this.verificationStatus,
    this.verificationRemark,
    required this.createdAt,
  });

  factory DeliveryBoy.fromJson(Map<String, dynamic> json) {
    return DeliveryBoy(
      id: JsonParser.intValue(json['id'] ?? 0),
      userId: JsonParser.intValue(json['user_id'] ?? 0),
      deliveryZoneId: JsonParser.intValue(json['delivery_zone_id'] ?? 0),
      status: JsonParser.string(json['status'] ?? ''),
      fullName: JsonParser.string(json['full_name'] ?? ''),
      address: JsonParser.string(json['address'] ?? ''),
      driverLicense: JsonParser.list<String>(
        json['driver_license'],
        (v) => JsonParser.string(v),
      ),
      driverLicenseNumber: JsonParser.string(
        json['driver_license_number'] ?? '',
      ),
      vehicleType: JsonParser.string(json['vehicle_type'] ?? ''),
      vehicleRegistration: JsonParser.list<String>(
        json['vehicle_registration'],
        (v) => JsonParser.string(v),
      ),
      verificationStatus: JsonParser.string(json['verification_status'] ?? ''),
      verificationRemark: JsonParser.string(json['verification_remark']),
      createdAt: JsonParser.dateTimeValue(json['created_at']) ?? DateTime.now(),
    );
  }
}

/// Helper class for calculating ratings statistics
class RatingsStatistics {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingBreakdown;

  RatingsStatistics({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingBreakdown,
  });

  factory RatingsStatistics.fromFeedbackList(
    List<DeliveryFeedback> feedbackList,
  ) {
    if (feedbackList.isEmpty) {
      return RatingsStatistics(
        averageRating: 0.0,
        totalReviews: 0,
        ratingBreakdown: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );
    }

    final totalReviews = feedbackList.length;
    final totalRating = feedbackList.fold<int>(
      0,
      (sum, feedback) => sum + feedback.rating,
    );
    final averageRating = totalRating / totalReviews;

    final ratingBreakdown = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final feedback in feedbackList) {
      ratingBreakdown[feedback.rating] =
          (ratingBreakdown[feedback.rating] ?? 0) + 1;
    }

    return RatingsStatistics(
      averageRating: averageRating,
      totalReviews: totalReviews,
      ratingBreakdown: ratingBreakdown,
    );
  }
}
