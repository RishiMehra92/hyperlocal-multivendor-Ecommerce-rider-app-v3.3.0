import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/screens/dashboard/bloc/notification/notification_bloc.dart';
import 'package:hyper_local/screens/dashboard/model/notification_model.dart';
import 'package:hyper_local/utils/notification_manager.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/loading_widget.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import 'package:intl/intl.dart';

import '../../../config/helper.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(FetchNotifications());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (isBottom(_scrollController)) {
      final state = context.read<NotificationBloc>().state;
      if (state.fetchStatus == ApiStatus.success &&
          state.pagination != null &&
          state.pagination!.currentPage < state.pagination!.lastPage) {
        context.read<NotificationBloc>().add(
          FetchNotifications(page: state.pagination!.currentPage + 1),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBar(
        title: context.tr('notifications'),
        additionalActions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.primaryColor),
            onPressed: () {
              context.read<NotificationBloc>().add(MarkAllAsRead());
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.fetchStatus == ApiStatus.loading &&
              state.notifications.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          if (state.fetchStatus == ApiStatus.failed &&
              state.notifications.isEmpty) {
            return EmptyStateWidget(
              title: context.tr('error'),
              subtitle: state.message,
              icon: Icons.error_outline,
              onRetry: () {
                context.read<NotificationBloc>().add(FetchNotifications());
              },
            );
          }

          final notifications = state.notifications;
          final pagination = state.pagination;
          final hasMore =
              pagination != null &&
              pagination.currentPage < pagination.lastPage;

          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Notifications Yet',
              subtitle: 'Your notifications will appear here',
              icon: Icons.notifications_none_outlined,
              showRetryButton: false,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final completer = Completer<void>();
              context.read<NotificationBloc>().add(
                FetchNotifications(completer: completer),
              );
              await completer.future;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= notifications.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: LoadingWidget(),
                    ),
                  );
                }
                final notification = notifications[index];
                return _buildNotificationCard(notification, index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, int index) {
    DateTime? dateTime;
    try {
      dateTime = DateTime.parse(notification.createdAt);
    } catch (e) {}

    final timeStr =
        dateTime != null
            ? DateFormat('hh:mm a').format(dateTime.toLocal())
            : '';
    final dateStr =
        dateTime != null ? DateFormat('dd MMM').format(dateTime.toLocal()) : '';

    // ────────────────────────────────────────────────
    // We always provide background when secondaryBackground is used
    // ────────────────────────────────────────────────

    Widget? readBackground;
    Widget? unreadBackground;

    if (!notification.isRead) {
      // Action: Mark as READ (right swipe = startToEnd)
      readBackground = Container(
        color: AppColors.primaryColor,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.w),
        child: const Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 32,
        ),
      );
    }

    if (notification.isRead) {
      // Action: Mark as UNREAD (left swipe = endToStart)
      unreadBackground = Container(
        color: Colors.orange.shade700,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        child: const Icon(
          Icons.mark_email_unread_outlined,
          color: Colors.white,
          size: 32,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Dismissible(
        key: ValueKey(notification.id),

        direction: DismissDirection.horizontal,

        // Cancel actual dismissal — we just want the swipe gesture + feedback
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Right swipe → Mark read
            if (!notification.isRead) {
              context.read<NotificationBloc>().add(MarkAsRead(notification.id));

              ToastManager.show(
                context: context,
                message: 'Marked as read',
                type: ToastType.success,
              );
            }
          } else if (direction == DismissDirection.endToStart) {
            // Left swipe → Mark unread
            if (notification.isRead) {
              context.read<NotificationBloc>().add(
                MarkAsUnread(notification.id),
              );

              ToastManager.show(
                context: context,
                message: 'Marked as unread',
                type: ToastType.success,
              );
            }
          }
          return false; // ← prevent item from disappearing
        },

        // Always provide background if secondaryBackground is present
        background:
            readBackground ?? Container(), // empty container when no action

        secondaryBackground:
            unreadBackground ?? Container(), // empty when no action

        child: GestureDetector(
          onTap: () {
            //
            if (!notification.isRead) {
              context.read<NotificationBloc>().add(MarkAsRead(notification.id));
            }
            NotificationManager().handleTypeRedirection(
              notification.type,
              notification.data?.metadata,
              fromNotificationScreen: true,
            );
          },
          child: CustomCard(
            padding: EdgeInsets.zero,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 8.w,
                    decoration: BoxDecoration(
                      color:
                          notification.isRead
                              ? Colors.grey.shade300
                              : AppColors.primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8.r),
                        bottomLeft: Radius.circular(8.r),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: CustomText(
                                  text: notification.title,
                                  fontWeight:
                                      notification.isRead
                                          ? FontWeight.w500
                                          : FontWeight.bold,
                                ),
                              ),
                              CustomText(
                                text: '$dateStr $timeStr',
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          CustomText(
                            text: notification.message,
                            fontSize: 12,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            color: notification.isRead ? Colors.grey : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
