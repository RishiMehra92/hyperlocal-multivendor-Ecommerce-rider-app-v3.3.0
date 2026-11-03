part of 'notification_bloc.dart';

abstract class NotificationEvent {}

class FetchNotifications extends NotificationEvent {
  final int page;
  final int perPage;
  final Completer<void>? completer;

  FetchNotifications({this.page = 1, this.perPage = 15, this.completer});
}

class MarkAsRead extends NotificationEvent {
  final String id;
  MarkAsRead(this.id);
}

class MarkAsUnread extends NotificationEvent {
  final String id;
  MarkAsUnread(this.id);
}

class MarkAllAsRead extends NotificationEvent {}

class GetUnreadCount extends NotificationEvent {}
