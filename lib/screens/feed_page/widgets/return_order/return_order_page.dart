import 'dart:async';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/return_orders_list_bloc/return_order_list_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/return_orders_list_bloc/return_order_list_state.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/inactive_delivery_boy_widget.dart';
import 'package:hyper_local/utils/widgets/loading_widget.dart';
import '../../bloc/return_order/return_orders_list_bloc/return_order_list_event.dart';
import '../return_order/return_order_card.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import '../view_all_feed_orders_card.dart';

class ReturnOrdersSection extends StatefulWidget {
  final bool isDeliveryBoyActive;

  const ReturnOrdersSection({super.key, required this.isDeliveryBoyActive});

  @override
  State<ReturnOrdersSection> createState() => _ReturnOrdersSectionState();
}

class _ReturnOrdersSectionState extends State<ReturnOrdersSection>
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
  void didUpdateWidget(covariant ReturnOrdersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDeliveryBoyActive && !oldWidget.isDeliveryBoyActive) {
      context.read<ReturnOrderListBloc>().add(const FetchReturnOrders());
    }
  }

  void _onScroll() {
    if (isBottom(_scrollController)) {
      context.read<ReturnOrderListBloc>().add(const LoadMoreReturnOrders());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child:
          widget.isDeliveryBoyActive
              ? _buildActiveContent()
              : InactiveDeliveryBoyWidget(
                message:
                    context.tr('activateAccountToViewPickupOrders'),
                buttonText: context.tr('goOnline'),
              ),
    );
  }

  Widget _buildActiveContent() {
    return BlocConsumer<ReturnOrderListBloc, ReturnOrderListState>(
      listener: (context, state) {
        if (state.status == ApiStatus.loading) {
          setState(() {
            _isRefreshing = true;
          });
        } else if (state.status == ApiStatus.success ||
            state.status == ApiStatus.failed) {
          setState(() {
            _isRefreshing = false;
          });
        }
      },
      builder: (context, state) {
        if (state.status == ApiStatus.loading && state.orders.isEmpty) {
          return const Center(child: LoadingWidget());
        }

        if (state.status == ApiStatus.success ||
            state.isRefreshing ||
            state.status == ApiStatus.failed) {
          final orders = state.orders;
          final hasReachedMax = state.hasReachedMax;

          return RefreshIndicator(
            onRefresh: () async {
              final completer = Completer<void>();
              context.read<ReturnOrderListBloc>().add(
                FetchReturnOrders(forceRefresh: true, completer: completer),
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
                    icon: TablerIcons.truck_return,
                    title:
                        context.tr('pickupOrders', fallback: "Pickup Orders"),
                    subtitle:
                        context.tr('trackPickupsSubtitle', fallback: "Track all your current and past pickups"),
                    onTap: () {
                      context.push(AppRoutes.myPickups);
                    },
                  ),
                ),
                if (orders.isEmpty)
                  SliverFillRemaining(
                    child: EmptyStateWidget(
                      title:
                          context.tr('noReturnOrdersAvailable'),
                      subtitle:
                          context.tr('ordersWillAppearHere'),
                      icon: Icons.inbox_outlined,
                      isLoading: _isRefreshing,
                      onRetry: () {
                        context.read<ReturnOrderListBloc>().add(
                          const FetchReturnOrders(forceRefresh: true),
                        );
                      },
                    ),
                  )
                else ...[
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final pickup = orders[index];
                      return ReturnOrderCard(
                        key: ValueKey('return_pickup_${pickup.id}'),
                        pickup: pickup,
                      );
                    }, childCount: orders.length),
                  ),
                  if (!hasReachedMax)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: LoadingWidget()),
                      ),
                    ),
                ],
              ],
            ),
          );
        }

        return const Center(child: LoadingWidget());
      },
    );
  }
}
