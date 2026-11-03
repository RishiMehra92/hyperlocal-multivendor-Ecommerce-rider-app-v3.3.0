import 'package:hyper_local/utils/services/json_parser.dart';

const String modelName = 'notification_model';

class NotificationListResponse {
  final bool success;
  final String message;
  final NotificationListData? data;

  NotificationListResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data:
          json['data'] != null
              ? NotificationListData.fromJson(
                json['data'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

class NotificationListData {
  final List<NotificationModel> notifications;
  final Pagination? pagination;

  NotificationListData({required this.notifications, this.pagination});

  factory NotificationListData.fromJson(Map<String, dynamic> json) {
    return NotificationListData(
      notifications: JsonParser.list<NotificationModel>(
        json['notifications'],
        (e) => NotificationModel.fromJson(e as Map<String, dynamic>),
      ),
      pagination:
          json['pagination'] != null
              ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
              : null,
    );
  }
}

class NotificationModel {
  final String id;
  final int userId;
  final int? storeId;
  final int? orderId;
  final String type;
  final String sentTo;
  final String title;
  final String message;
  final bool isRead;
  final NotificationContentData? data;
  final dynamic metadata;
  final String createdAt;
  final String updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.storeId,
    this.orderId,
    required this.type,
    required this.sentTo,
    required this.title,
    required this.message,
    required this.isRead,
    this.data,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: JsonParser.requireString(json['id'], model: modelName, field: 'id'),
      userId: JsonParser.requireInt(
        json['user_id'],
        model: modelName,
        field: 'user_id',
      ),
      storeId: JsonParser.intValue(json['store_id']),
      orderId: JsonParser.intValue(json['order_id']),

      type: JsonParser.requireString(
        json['type'],
        model: modelName,
        field: 'type',
      ),
      sentTo: JsonParser.requireString(
        json['sent_to'],
        model: modelName,
        field: 'sent_to',
      ),
      title: JsonParser.requireString(
        json['title'],
        model: modelName,
        field: 'title',
      ),
      message: JsonParser.requireString(
        json['message'],
        model: modelName,
        field: 'message',
      ),

      isRead: JsonParser.boolValue(json['is_read'] ?? false),

      data:
          json['data'] != null
              ? NotificationContentData.fromJson(
                json['data'] as Map<String, dynamic>,
              )
              : null,

      metadata: json['metadata'],

      createdAt: JsonParser.requireString(
        json['created_at'],
        model: modelName,
        field: 'created_at',
      ),
      updatedAt: JsonParser.requireString(
        json['updated_at'],
        model: modelName,
        field: 'updated_at',
      ),
    );
  }
}

class NotificationContentData {
  final String title;
  final String message;
  final String type;
  final String sentTo;
  final int userId;
  final int? orderId;
  final int? storeId;
  final dynamic metadata;

  NotificationContentData({
    required this.title,
    required this.message,
    required this.type,
    required this.sentTo,
    required this.userId,
    this.orderId,
    this.storeId,
    this.metadata,
  });

  factory NotificationContentData.fromJson(Map<String, dynamic> json) {
    return NotificationContentData(
      title: JsonParser.requireString(
        json['title'],
        model: modelName,
        field: 'data.title',
      ),
      message: JsonParser.requireString(
        json['message'],
        model: modelName,
        field: 'data.message',
      ),
      type: JsonParser.requireString(
        json['type'],
        model: modelName,
        field: 'data.type',
      ),
      sentTo: JsonParser.requireString(
        json['sent_to'],
        model: modelName,
        field: 'data.sent_to',
      ),
      userId: JsonParser.requireInt(
        json['user_id'],
        model: modelName,
        field: 'data.user_id',
      ),
      orderId: JsonParser.intValue(json['order_id']),
      storeId: JsonParser.intValue(json['store_id']),
      metadata: json['metadata'],
    );
  }
}

class Pagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),
    );
  }
}

class UnreadCountResponse {
  final bool success;
  final String message;
  final int unreadCount;

  UnreadCountResponse({
    required this.success,
    required this.message,
    required this.unreadCount,
  });

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      unreadCount: JsonParser.intValue(json['data']?['unread_count'] ?? 0),
    );
  }
}
