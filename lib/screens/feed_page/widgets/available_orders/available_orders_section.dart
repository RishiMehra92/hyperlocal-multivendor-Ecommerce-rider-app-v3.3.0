import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/inactive_delivery_boy_widget.dart';
import 'package:hyper_local/utils/widgets/loading_widget.dart';
import '../../bloc/available_orders_bloc/available_orders_bloc.dart';
import '../../bloc/available_orders_bloc/available_orders_event.dart';
import '../../bloc/available_orders_bloc/available_orders_state.dart';
import '../../bloc/accept_order_bloc/accept_order_bloc.dart';
import 'available_order_card.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import '../view_all_feed_orders_card.dart';

class AvailableOrdersSection extends StatefulWidget {
  final bool isDeliveryBoyActive;

  const AvailableOrdersSection({super.key, required this.isDeliveryBoyActive});

  @override
  State<AvailableOrdersSection> createState() => _AvailableOrdersSectionState();
}

class _AvailableOrdersSectionState extends State<AvailableOrdersSection>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant AvailableOrdersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDeliveryBoyActive && !oldWidget.isDeliveryBoyActive) {
      context.read<AvailableOrdersBloc>().add(AllAvailableOrdersList());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (isBottom(_scrollController)) {
      final state = context.read<AvailableOrdersBloc>().state;
      if (!state.isPaginating) {
        final currentLength = state.availableOrders.length;
        context.read<AvailableOrdersBloc>().add(
          LoadMoreAvailableOrders('', currentLength: currentLength),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!widget.isDeliveryBoyActive) {
      return const InactiveDeliveryBoyWidget();
    }

    return BlocProvider(
      create: (context) => AcceptOrderBloc(),
      child: BlocConsumer<AvailableOrdersBloc, AvailableOrdersState>(
        listener: (context, state) {
          if (state.fetchStatus == ApiStatus.loading) {
            setState(() {
              _isRefreshing = true;
            });
          } else if (state.fetchStatus == ApiStatus.success ||
              state.fetchStatus == ApiStatus.failed) {
            setState(() {
              _isRefreshing = false;
            });
          }
        },
        builder: (context, state) {
          if (state.fetchStatus == ApiStatus.loading &&
              state.availableOrders.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          if (state.fetchStatus == ApiStatus.success ||
              state.isRefreshing ||
              state.fetchStatus == ApiStatus.failed) {
            final allOrders = state.availableOrders;
            final hasReachedMax = state.hasReachedMax;

            return RefreshIndicator(
              onRefresh: () async {
                final completer = Completer<void>();
                context.read<AvailableOrdersBloc>().add(
                  AllAvailableOrdersList(
                    forceRefresh: true,
                    completer: completer,
                  ),
                );
                await completer.future;
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverToBoxAdapter(
                    child: ViewAllFeedOrdersCard(
                      icon: TablerIcons.box,
                      title:
                          context.tr('myOrders', fallback: "View All Orders"),
                      subtitle:
                          context.tr('trackOrdersSubtitle', fallback: "Track all your current and past orders"),
                      onTap: () {
                        context.push(AppRoutes.myOrders);
                      },
                    ),
                  ),
                  if (allOrders.isEmpty)
                    SliverFillRemaining(
                      child: EmptyStateWidget(
                        title: context.tr('noAvailableOrders'),
                        subtitle:
                            context.tr('ordersWillAppearHere'),
                        icon: Icons.inbox_outlined,
                        isLoading: _isRefreshing,
                        onRetry: () {
                          context.read<AvailableOrdersBloc>().add(
                            AllAvailableOrdersList(forceRefresh: true),
                          );
                        },
                      ),
                    )
                  else ...[
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final order = allOrders[index];
                        return AvailableOrderCard(
                          key: ValueKey('available_${order.id}'),
                          order: order,
                        );
                      }, childCount: allOrders.length),
                    ),
                    if (!hasReachedMax)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: const Center(child: LoadingWidget()),
                        ),
                      ),
                  ],
                ],
              ),
            );
          }

          return const Center(child: LoadingWidget());
        },
      ),
    );
  }
}
