import 'package:hyper_local/utils/services/json_parser.dart';

const String modelName = 'withdrawal_model';

class WithdrawalResponse {
  final bool success;
  final String message;
  final WithdrawalPaginationData? data;

  WithdrawalResponse({required this.success, required this.message, this.data});

  factory WithdrawalResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawalResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data:
          json['data'] != null
              ? WithdrawalPaginationData.fromJson(
                json['data'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

class SingleWithdrawalResponse {
  final bool success;
  final String message;
  final WithdrawalModel? data;

  SingleWithdrawalResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SingleWithdrawalResponse.fromJson(Map<String, dynamic> json) {
    return SingleWithdrawalResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data:
          json['data'] != null
              ? WithdrawalModel.fromJson(json['data'] as Map<String, dynamic>)
              : null,
    );
  }
}

class WithdrawalPaginationData {
  final int currentPage;
  final List<WithdrawalModel> data;
  final String firstPageUrl;
  final int? from;
  final int lastPage;
  final String lastPageUrl;
  final List<PaginationLink> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;
  final int total;

  WithdrawalPaginationData({
    required this.currentPage,
    required this.data,
    required this.firstPageUrl,
    this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  factory WithdrawalPaginationData.fromJson(Map<String, dynamic> json) {
    return WithdrawalPaginationData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      data: JsonParser.list<WithdrawalModel>(
        json['data'],
        (item) => WithdrawalModel.fromJson(item as Map<String, dynamic>),
      ),
      firstPageUrl: JsonParser.string(json['first_page_url'] ?? ''),
      from: JsonParser.intValue(json['from']),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      lastPageUrl: JsonParser.string(json['last_page_url'] ?? ''),
      links: JsonParser.list<PaginationLink>(
        json['links'],
        (item) => PaginationLink.fromJson(item as Map<String, dynamic>),
      ),
      nextPageUrl: JsonParser.string(json['next_page_url']),
      path: JsonParser.string(json['path'] ?? ''),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      prevPageUrl: JsonParser.string(json['prev_page_url']),
      to: JsonParser.intValue(json['to']),
      total: JsonParser.intValue(json['total'] ?? 0),
    );
  }
}

class WithdrawalModel {
  final int? id;
  final int? userId;
  final int? deliveryBoyId;
  final double? amount;
  final String? status;
  final String? requestNote;
  final String? adminRemark;
  final String? processedAt;
  final int? processedBy;
  final String? transactionId;
  final String? createdAt;
  final String? updatedAt;
  final DeliveryBoyModel? deliveryBoy;

  WithdrawalModel({
    this.id,
    this.userId,
    this.deliveryBoyId,
    this.amount,
    this.status,
    this.requestNote,
    this.adminRemark,
    this.processedAt,
    this.processedBy,
    this.transactionId,
    this.createdAt,
    this.updatedAt,
    this.deliveryBoy,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: JsonParser.intValue(json['id']),
      userId: JsonParser.intValue(json['user_id']),
      deliveryBoyId: JsonParser.intValue(json['delivery_boy_id']),
      amount: JsonParser.doubleValue(json['amount']),
      status: JsonParser.string(json['status']),
      requestNote: JsonParser.string(json['request_note']),
      adminRemark: JsonParser.string(json['admin_remark']),
      processedAt: JsonParser.string(json['processed_at']),
      processedBy: JsonParser.intValue(json['processed_by']),
      transactionId: JsonParser.string(json['transaction_id']),
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
      deliveryBoy:
          json['delivery_boy'] != null
              ? DeliveryBoyModel.fromJson(
                json['delivery_boy'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'delivery_boy_id': deliveryBoyId,
      'amount': amount,
      'status': status,
      'request_note': requestNote,
      'admin_remark': adminRemark,
      'processed_at': processedAt,
      'processed_by': processedBy,
      'transaction_id': transactionId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'delivery_boy': deliveryBoy?.toJson(),
    };
  }
}

class DeliveryBoyModel {
  final int? id;
  final int? userId;
  final int? deliveryZoneId;
  final String? fullName;
  final String? address;
  final String? driverLicense;
  final String? driverLicenseNumber;
  final String? vehicleType;
  final String? vehicleRegistration;
  final String? verificationStatus;
  final String? verificationRemark;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final UserModel? user;

  DeliveryBoyModel({
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
    this.user,
  });

  factory DeliveryBoyModel.fromJson(Map<String, dynamic> json) {
    return DeliveryBoyModel(
      id: JsonParser.intValue(json['id']),
      userId: JsonParser.intValue(json['user_id']),
      deliveryZoneId: JsonParser.intValue(json['delivery_zone_id']),
      fullName: JsonParser.string(json['full_name']),
      address: JsonParser.string(json['address']),
      driverLicense: JsonParser.string(json['driver_license']),
      driverLicenseNumber: JsonParser.string(json['driver_license_number']),
      vehicleType: JsonParser.string(json['vehicle_type']),
      vehicleRegistration: JsonParser.string(json['vehicle_registration']),
      verificationStatus: JsonParser.string(json['verification_status']),
      verificationRemark: JsonParser.string(json['verification_remark']),
      status: JsonParser.string(json['status']),
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
      deletedAt: JsonParser.string(json['deleted_at']),
      user:
          json['user'] != null
              ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'delivery_zone_id': deliveryZoneId,
      'full_name': fullName,
      'address': address,
      'driver_license': driverLicense,
      'driver_license_number': driverLicenseNumber,
      'vehicle_type': vehicleType,
      'vehicle_registration': vehicleRegistration,
      'verification_status': verificationStatus,
      'verification_remark': verificationRemark,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'user': user?.toJson(),
    };
  }
}

class UserModel {
  final int? id;
  final String? mobile;
  final String? referralCode;
  final String? friendsCode;
  final int? rewardPoints;
  final bool? status;
  final String? name;
  final String? email;
  final String? country;
  final String? iso2;
  final String? emailVerifiedAt;
  final String? accessPanel;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    this.id,
    this.mobile,
    this.referralCode,
    this.friendsCode,
    this.rewardPoints,
    this.status,
    this.name,
    this.email,
    this.country,
    this.iso2,
    this.emailVerifiedAt,
    this.accessPanel,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: JsonParser.intValue(json['id']),
      mobile: JsonParser.string(json['mobile']),
      referralCode: JsonParser.string(json['referral_code']),
      friendsCode: JsonParser.string(json['friends_code']),
      rewardPoints: JsonParser.intValue(json['reward_points']),
      status: JsonParser.boolValue(json['status']),
      name: JsonParser.string(json['name']),
      email: JsonParser.string(json['email']),
      country: JsonParser.string(json['country']),
      iso2: JsonParser.string(json['iso_2']),
      emailVerifiedAt: JsonParser.string(json['email_verified_at']),
      accessPanel: JsonParser.string(json['access_panel']),
      deletedAt: JsonParser.string(json['deleted_at']),
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobile': mobile,
      'referral_code': referralCode,
      'friends_code': friendsCode,
      'reward_points': rewardPoints,
      'status': status,
      'name': name,
      'email': email,
      'country': country,
      'iso_2': iso2,
      'email_verified_at': emailVerifiedAt,
      'access_panel': accessPanel,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class PaginationLink {
  final String? url;
  final String label;
  final bool active;

  PaginationLink({this.url, required this.label, required this.active});

  factory PaginationLink.fromJson(Map<String, dynamic> json) {
    return PaginationLink(
      url: JsonParser.string(json['url']),
      label: JsonParser.string(json['label'] ?? ''),
      active: JsonParser.boolValue(json['active'] ?? false),
    );
  }
}

class CreateWithdrawalRequest {
  final double amount;
  final String requestNote;

  CreateWithdrawalRequest({required this.amount, required this.requestNote});

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'request_note': requestNote};
  }
}
