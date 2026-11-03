// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/dashboard/bloc/notification/notification_bloc.dart';
import 'package:hyper_local/screens/settings/bloc/profile_bloc/profile_bloc.dart';
import 'package:hyper_local/screens/settings/bloc/profile_bloc/profile_event.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/return_orders_list_bloc/return_order_list_bloc.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/loading_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/global.dart';
import '../../../utils/widgets/custom_scaffold.dart';
import '../bloc/return_order/return_orders_list_bloc/return_order_list_event.dart';
import '../widgets/tab_bar/home_tab_bar_section.dart';
import '../widgets/tab_bar/home_tab_content_section.dart';
import '../bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import '../bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import '../bloc/available_orders_bloc/available_orders_bloc.dart';
import '../bloc/available_orders_bloc/available_orders_event.dart';

// Function to open Google Maps with directions
Future<void> openGoogleMapsDirections({
  required String destinationLat,
  required String destinationLng,
  String originLat = '23.2488453',
  String originLng = '69.6696795',
}) async {
  try {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destinationLat,$destinationLng&travelmode=driving',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    // Fallback: try to open in browser if app launch fails
    try {
      final fallbackUrl = Uri.parse(
        'https://www.google.com/maps/dir/$originLat,$originLng/$destinationLat,$destinationLng',
      );
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    } catch (fallbackError) {
      throw 'Could not open Google Maps. Please install Google Maps app or try again.';
    }
  }
}

class OrdersFeedPage extends StatefulWidget {
  final int? initialTab; // 0 = Available Orders, 1 = My Orders

  const OrdersFeedPage({super.key, this.initialTab});

  @override
  State<OrdersFeedPage> createState() => _OrdersFeedPageState();
}

class _OrdersFeedPageState extends State<OrdersFeedPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  static bool _hasBeenInitialized = false;
  bool _isInitialized = _hasBeenInitialized;
  bool _shouldSkipNextRefresh = false;
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = (widget.initialTab ?? 0).clamp(0, 1);
    context.read<NotificationBloc>().add(GetUnreadCount());
    context.read<NotificationBloc>().add(FetchNotifications());
    context.read<ProfileBloc>().add(const LoadProfile());
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this, initialIndex: _currentTabIndex);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });

        // Refresh orders when switching tabs
        if (_currentTabIndex == 0) {
          context.read<AvailableOrdersBloc>().add(AllAvailableOrdersList(forceRefresh: true));
        } else if (_currentTabIndex == 1) {
          // Return/Pickup Orders tab
          context.read<ReturnOrderListBloc>().add(const FetchReturnOrders(forceRefresh: true));
        }
      }
    });

    _initializePage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Refresh data when dependencies change (e.g., when returning from order details page)
    if (_isInitialized) {
      if (_shouldSkipNextRefresh) {
        _shouldSkipNextRefresh = false;
        return;
      }
      // Also refresh when returning from other pages (like order details)
      // Small delay to ensure the widget is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _refreshDataOnPageVisible();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh orders when app becomes active
      _refreshDataOnPageVisible();
    }
  }

  /// Refreshes data when the page becomes visible
  void _refreshDataOnPageVisible() {
    if (!mounted) return;
    // Refresh based on current tab
    if (_tabController.index == 0) {
      // Available Orders tab
      context.read<AvailableOrdersBloc>().add(AllAvailableOrdersList(forceRefresh: true));
    } else if (_tabController.index == 1) {
      // Return/Pickup Orders
      context.read<ReturnOrderListBloc>().add(const FetchReturnOrders(forceRefresh: true));
    }
  }

  Future<void> _initializePage() async {
    try {
      await Global.initializeToken();
      await Global.initializeStatus();

      await Global.printFCMToken();

      final initialStatus = await Global.getDeliveryBoyStatus() ?? false;

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasBeenInitialized = true;
          _shouldSkipNextRefresh = true;
        });
      }

      // Sync the deliveryboy_status_update_bloc with the persisted status
      try {
        final bloc = context.read<DeliveryBoyStatusBloc>();
        bloc.add(SyncInitialStatus(initialStatus));
      } catch (e) {}

      // Fetch both available orders and return pickups immediately on page load
      if (mounted && initialStatus) {
        context.read<AvailableOrdersBloc>().add(AllAvailableOrdersList(forceRefresh: true));
        context.read<ReturnOrderListBloc>().add(const FetchReturnOrders(forceRefresh: true));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasBeenInitialized = true;
          _shouldSkipNextRefresh = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const CustomScaffold(body: Center(child: LoadingWidget()));
    }

    return BlocBuilder<DeliveryBoyStatusBloc, DeliveryBoyStatusState>(
      builder: (context, state) {
        final isOnline = state.isOnline;
        final isDark = context.isDarkMode;

        return CustomScaffold(
          wantSafeArea: false,
          appBar: AppBar(
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            title: HomeTabBarSection(tabController: _tabController),
            automaticallyImplyLeading: false,
            centerTitle: true,
          ),
          body: HomeTabContentSection(
            tabController: _tabController,
            isDeliveryBoyActive: isOnline, // Pass the delivery boy status
            isDarkTheme: isDark, // Pass the theme parameter
          ),
        );
      },
    );
  }
}
