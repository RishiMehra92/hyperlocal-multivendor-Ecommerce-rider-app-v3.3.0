part of 'notification_bloc.dart';

class NotificationState extends Equatable {
  final ApiStatus fetchStatus;
  final List<NotificationModel> notifications;
  final Pagination? pagination;
  final int unreadCount;
  final String message;

  const NotificationState({
    this.fetchStatus = ApiStatus.initial,
    this.notifications = const [],
    this.pagination,
    this.unreadCount = 0,
    this.message = '',
  });

  NotificationState copyWith({
    ApiStatus? fetchStatus,
    List<NotificationModel>? notifications,
    Pagination? pagination,
    int? unreadCount,
    String? message,
    bool clearMessage = false,
  }) {
    return NotificationState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      notifications: notifications ?? this.notifications,
      pagination: pagination ?? this.pagination,
      unreadCount: unreadCount ?? this.unreadCount,
      message: clearMessage ? '' : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    fetchStatus,
    notifications,
    pagination,
    unreadCount,
    message,
  ];
}
