import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/utils/widgets/toast_message.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/screens/Location_Disclosure/location_disclosure.dart';
import 'package:hyper_local/screens/dashboard/view/notification_list_page.dart';
import 'package:hyper_local/screens/feed_page/view/pickup_order/pickup_order_details_page.dart';
import 'package:hyper_local/screens/auth/view/login_page.dart';
import 'package:hyper_local/screens/auth/view/phone_login_page.dart';
import 'package:hyper_local/screens/auth/view/phone_otp_verification_page.dart';
import 'package:hyper_local/screens/auth/view/forgot_password_page.dart';
import 'package:hyper_local/screens/auth/view/register_page.dart';
import 'package:hyper_local/screens/feed_page/view/orders_feed_page.dart';
import 'package:hyper_local/screens/inactive_delievryboy/bloc/inactive_page_stats/home_stats_bloc.dart';
import 'package:hyper_local/screens/settings/view/refer_and_earn/bloc/refer_and_earn/refer_and_earn_bloc.dart';
import 'package:hyper_local/screens/splash_screen/splash_screen.dart';
import 'package:hyper_local/screens/onboarding/onboarding_screen.dart';
import 'package:hyper_local/config/global.dart';

import 'package:hyper_local/screens/pockets/view/pockets_page.dart';
import 'package:hyper_local/utils/app_update/bloc/app_update_bloc.dart';
import 'package:hyper_local/utils/widgets/bottombar.dart';
import 'package:hyper_local/screens/feed_page/view/map/delivery_map/pickup_order_map_page.dart';
import 'package:hyper_local/screens/feed_page/model/available_orders.dart';
import 'package:hyper_local/screens/feed_page/model/return_orders_list_model.dart';
import 'package:hyper_local/screens/feed_page/view/order_detail/order_details_page.dart';
import 'package:hyper_local/screens/feed_page/view/map/store_pickup_route/map_delivery_page.dart';
import 'package:hyper_local/utils/widgets/location_permission_wrapper.dart';

import '../config/injection_container.dart';
import '../screens/dashboard/bloc/ratings/ratings_bloc.dart';
import '../screens/inactive_delievryboy/view/home_Screen.dart';
import '../screens/pockets/Transactions/bloc/wallet_transactions_bloc.dart';
import '../screens/pockets/cash_collection/view/all_cash_collection_page.dart';
import '../screens/pockets/earnings/view/all_earnings_page.dart';
import '../screens/pockets/earnings/view/earnings_list_page.dart';
import '../screens/pockets/Transactions/view/view_transactions_page.dart';
import '../screens/pockets/withdrawal/view/withdrawal_history_page.dart';
import '../screens/inactive_delievryboy/view/view_history_of_orders.dart';

import '../screens/auth/widgets/delivery_zone_screen.dart';
import '../screens/feed_page/bloc/order_details_bloc/order_details_bloc.dart';
import '../screens/feed_page/repo/order_details.dart';
import '../screens/inactive_delievryboy/bloc/delivered_orders/delivered_orders_bloc.dart';

import '../screens/settings/view/refer_and_earn/view/refer_and_earn_page.dart';
import '../screens/settings/view/settings.dart';
import '../screens/settings/view/profile_page.dart';
import '../screens/settings/view/profile_widgets/delivery_zone_page.dart';
import '../screens/settings/view/profile_widgets/personal_info_page.dart';
import '../screens/settings/view/profile_widgets/vehicle_info_page.dart';
import '../screens/settings/view/terms_privacy_page.dart';
import '../screens/settings/view/support_page.dart';
import '../screens/dashboard/view/ratings_page.dart';
import '../screens/settings/view/my_orders.dart';
import '../screens/settings/view/my_pickups_page.dart';
import '../screens/delivery_zones/view/delivery_zone_list_page.dart';
import '../screens/delivery_zones/view/delivery_zone_details_page.dart';
import '../screens/delivery_zones/model/delivery_zone_model.dart';

import 'package:hyper_local/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/available_orders_bloc/available_orders_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/items_collected_bloc/items_collected_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/my_orders_bloc/my_orders_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/pickup_order_details_bloc/pickup_order_details_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/pickup_orders_list_bloc/pickup_order_list_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/return_orders_list_bloc/return_order_list_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/update_return_order_status_bloc/update_return_order_status_bloc.dart';
import 'package:hyper_local/screens/pockets/earnings/bloc/earnings_bloc.dart';
import 'package:hyper_local/screens/pockets/cash_collection/bloc/cash_collection_bloc.dart';
import 'package:hyper_local/screens/pockets/withdrawal/bloc/withdrawal_bloc.dart';
import 'package:hyper_local/screens/settings/bloc/profile_bloc/profile_bloc.dart';
import 'package:hyper_local/screens/settings/bloc/profile_bloc/profile_event.dart';
import 'package:hyper_local/screens/pockets/cash_collection/bloc/cash_collection_event.dart';

import 'package:hyper_local/screens/auth/bloc/auth_bloc/auth_bloc.dart';
import 'package:hyper_local/screens/feed_page/view/order_detail/payment_method_selection_page.dart';
import 'package:hyper_local/screens/auth/bloc/phone_auth_bloc/phone_auth_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/delivery_zone_bloc/delivery_zone_bloc.dart';
import 'package:hyper_local/screens/delivery_zones/bloc/delivery_zone_bloc.dart'
    as zones;

Page platformPage(Widget child) {
  if (Platform.isIOS) {
    return CupertinoPage(child: child);
  } else {
    return MaterialPage(child: child);
  }
}

class AppRoutes {
  static const String splashScreen = '/';
  static const String onBoarding = '/onboarding';
  static const String login = '/login';
  static const String phoneOtpVerification = '/phone-otp-verification';
  static const String phoneLogin = '/phone-login';
  static const String forgotPassword = '/forgot-password';
  static const String register = '/register';
  static const String home = '/home';
  static const String deliveryZone = '/deliveryZone';
  static const String locaitonDisclosure = '/location-disclosure';
  static const String feed = '/feed';
  static const String gigs = '/gigs';
  static const String pockets = '/pockets';
  static const String more = '/settings';
  static const String pickupOrderMap = '/pickup-order-map';
  static const String orderDetails = '/order-details';
  static const String mapDelivery = '/map-delivery';
  static const String fullScreenMap = '/full-screen-map';
  static const String profile = '/profile';
  static const String personalInfo = '/personal-info';
  static const String vehicleInfo = '/vehicle-info';
  static const String deliveryZonePage = '/delivery-zone';
  static const String earnings = '/earnings';
  static const String allEarnings = '/all-earnings';
  static const String cashCollection = '/cash-collection';
  static const String allCashCollection = '/all-cash-collection';
  static const String withdrawalHistory = '/withdrawal-history';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String support = '/support';
  static const String viewHistory = '/view-history';
  static const String notificationTest = '/notification-test';
  static const String ratings = '/ratings';
  static const String myOrders = '/my-orders';
  static const String myPickups = '/my-pickups';
  static const String notifications = '/notifications';
  static const String pickupOrderDetails = '/pickup-order-details';
  static const String deliveryZoneList = '/delivery-zone-list';
  static const String authDeliveryZoneList = '/auth-delivery-zone-list';
  static const String deliveryZoneDetails = '/delivery-zone-details';
  static const String authDeliveryZoneDetails = '/auth-delivery-zone-details';
  static const String referAndEarn = '/refer-and-earn';
  static const String viewTransactions = "/view-transactions";
  static const String paymentMethodSelection = "/payment-method-selection";
}

class MyAppRoute {
  static GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splashScreen,
    onException: (context, state, router) {
      // Ignore Firebase Auth redirects (reCAPTCHA flow) so we stay on the current page
      if (state.uri.toString().contains('firebaseauth/link')) {
        return;
      }
      // For any other routing errors, go to home or show a simple error
      debugPrint('Routing error: ${state.error}');
      router.go(AppRoutes.splashScreen);
    },
    redirect: (context, state) {
      if (!AppConstant.hasValidBaseUrl) {
        final loc = state.matchedLocation;
        if (loc != AppRoutes.splashScreen) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = navigatorKey.currentContext;
            if (ctx != null) {
              ToastManager.show(
                context: ctx,
                message: 'user not found',
                type: ToastType.error,
              );
            }
          });
          return AppRoutes.splashScreen;
        }
      }
      return null;
    },

    routes: [
      GoRoute(
        name: 'splashScreen',
        path: AppRoutes.splashScreen,
        pageBuilder:
            (context, state) => platformPage(
              BlocProvider(
                create: (context) => sl<AppUpdateBloc>(),
                child: const SplashScreen(),
              ),
            ),
      ),
      GoRoute(
        name: 'onboarding',
        path: AppRoutes.onBoarding,
        pageBuilder: (context, state) => platformPage(const OnboardingScreen()),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<AuthBloc>()),
              BlocProvider(create: (_) => sl<PhoneAuthBloc>()),
              BlocProvider(create: (_) => sl<DeliveryZoneBloc>()),
            ],
            child: child,
          );
        },
        routes: [
          GoRoute(
            name: 'login',
            path: AppRoutes.login,
            pageBuilder: (context, state) => platformPage(const LoginPage()),
          ),

          GoRoute(
            name: 'phoneLogin',
            path: AppRoutes.phoneLogin,
            pageBuilder:
                (context, state) => platformPage(const PhoneLoginPage()),
          ),

          GoRoute(
            name: 'phoneOtpVerification',
            path: AppRoutes.phoneOtpVerification,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return platformPage(
                PhoneOTPVerificationPage(
                  verificationId: extra['verificationId'] as String,
                  phoneNumber: extra['phoneNumber'] as String,
                  isRegistration: extra['isRegistration'] as bool? ?? false,
                  registrationData:
                      extra['registrationData'] as Map<String, dynamic>?,
                ),
              );
            },
          ),

          GoRoute(
            name: 'forgotPassword',
            path: AppRoutes.forgotPassword,
            pageBuilder:
                (context, state) => platformPage(const ForgotPasswordPage()),
          ),

          GoRoute(
            name: 'register',
            path: AppRoutes.register,
            pageBuilder: (context, state) => platformPage(const RegisterPage()),
          ),

          GoRoute(
            name: 'deliveryZone',
            path: AppRoutes.deliveryZone,
            pageBuilder:
                (context, state) => platformPage(const DeliveryZoneScreen()),
          ),

          GoRoute(
            name: 'authDeliveryZoneList',
            path: AppRoutes.authDeliveryZoneList,
            pageBuilder: (context, state) {
              final isSelectionMode =
                  (state.extra as Map<String, dynamic>?)?['isSelectionMode']
                      as bool? ??
                  false;
              return platformPage(
                BlocProvider(
                  create: (_) => sl<zones.DeliveryZoneBloc>(),
                  child: DeliveryZoneListPage(
                    isSelectionMode: isSelectionMode,
                    isFromAuth: true,
                  ),
                ),
              );
            },
          ),

          GoRoute(
            name: 'authDeliveryZoneDetails',
            path: '${AppRoutes.authDeliveryZoneDetails}/:zoneId',
            pageBuilder: (context, state) {
              final zoneId = int.parse(state.pathParameters['zoneId']!);
              final zone = state.extra as DeliveryZoneModel?;
              return platformPage(
                DeliveryZoneDetailsPage(zoneId: zoneId, zone: zone),
              );
            },
          ),

          GoRoute(
            name: 'locaitonDisclosure',
            path: AppRoutes.locaitonDisclosure,
            pageBuilder:
                (context, state) => platformPage(const LocationDisclosure()),
          ),
        ],
      ),

      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<HomeStatsBloc>()),
              BlocProvider(create: (_) => sl<DeliveryBoyStatusBloc>()),
              BlocProvider(create: (_) => sl<AvailableOrdersBloc>()),
              BlocProvider(create: (_) => sl<MyOrdersBloc>()),
              BlocProvider(
                create: (_) => sl<ProfileBloc>()..add(const LoadProfile()),
              ),
              BlocProvider(create: (_) => sl<ItemsCollectedBloc>()),
              BlocProvider(create: (_) => sl<WithdrawalBloc>()),
              BlocProvider(create: (_) => sl<ReturnOrderListBloc>()),
              BlocProvider(create: (_) => sl<PickupOrderListBloc>()),
              BlocProvider(create: (_) => sl<PickupOrderDetailsBloc>()),
              BlocProvider(create: (_) => sl<UpdateReturnOrderStatusBloc>()),
              BlocProvider(create: (_) => sl<EarningsBloc>()),
              BlocProvider(
                create:
                    (_) => sl<CashCollectionBloc>()..add(FetchCashCollection()),
              ),
              BlocProvider(create: (_) => sl<zones.DeliveryZoneBloc>()),
              BlocProvider(create: (_) => sl<WalletTransactionsBloc>()),
            ],
            child: LocationPermissionWrapper(child: child),
          );
        },
        routes: [
          ShellRoute(
            builder: (context, state, child) {
              return BlocProvider(
                create: (context) => OrderDetailsBloc(OrderDetailsRepo()),
                child: child,
              );
            },
            routes: [
              GoRoute(
                name: 'orderDetails',
                path: AppRoutes.orderDetails,
                pageBuilder: (context, state) {
                  final extras = state.extra as Map<String, dynamic>;
                  return platformPage(
                    OrderDetailsPage(
                      orderId: int.parse(extras['orderId'].toString()),
                      from: extras['from'] ?? false,
                      sourceTab: extras['sourceTab'],
                      arrivalConfirmed: extras['arrivalConfirmed'],
                    ),
                  );
                },
              ),
              GoRoute(
                name: 'paymentMethodSelection',
                path: AppRoutes.paymentMethodSelection,
                pageBuilder: (context, state) {
                  final extras = state.extra as Map<String, dynamic>;
                  return platformPage(
                    PaymentMethodSelectionPage(
                      orderId: extras['orderId'] as int,
                      paymentUrl: extras['paymentUrl'] as String?,
                      canPayOnline: extras['canPayOnline'] as bool,
                      codAmount: extras['codAmount'] as String,
                    ),
                  );
                },
              ),
            ],
          ),

          GoRoute(
            name: 'pickup-order-details',
            path: AppRoutes.pickupOrderDetails,

            pageBuilder: (context, state) {
              final params = state.extra as Map<String, dynamic>;
              final returnId = params['returnId'];

              return platformPage(PickupOrderDetailsPage(returnId: returnId));
            },
          ),

          GoRoute(
            name: 'pickupOrderMap',
            path: AppRoutes.pickupOrderMap,
            pageBuilder: (context, state) {
              final params = state.extra as Map<String, dynamic>;
              final pickup = params['pickup'] as Pickups;
              final locationType =
                  params['locationType'] as String? ?? 'customer';

              return platformPage(
                PickupOrderMapPage(pickup: pickup, locationType: locationType),
              );
            },
          ),

          GoRoute(
            name: 'mapDelivery',
            path: AppRoutes.mapDelivery,
            pageBuilder: (context, state) {
              final params = state.extra as Map<String, dynamic>;
              final order = params['order'] as Orders;
              final sourceTab = params['sourceTab'] as int?;

              final status = order.status?.toLowerCase() ?? 'assigned';
              final bool isPostPickup =
                  status == 'out_for_delivery' ||
                  status == 'collected' ||
                  status == 'delivered';

              return platformPage(
                BlocProvider(
                  create: (context) => OrderDetailsBloc(OrderDetailsRepo()),
                  child: OrderDetailsPage(
                    orderId: order.id!,
                    from: isPostPickup,
                    sourceTab: sourceTab,
                  ),
                ),
              );
            },
          ),

          GoRoute(
            name: 'fullScreenMap',
            path: AppRoutes.fullScreenMap,
            pageBuilder: (context, state) {
              final params = state.extra as Map<String, dynamic>;
              final order = params['order'] as Orders;
              final sourceTab = params['sourceTab'] as int?;
              return platformPage(
                BlocProvider(
                  create: (context) => OrderDetailsBloc(OrderDetailsRepo()),
                  child: MapDeliveryPage(
                    order: order,
                    currentLat: '0',
                    currentLng: '0',
                    autoOpenBottomSheet: false,
                    sourceTab: sourceTab,
                  ),
                ),
              );
            },
          ),

          GoRoute(
            name: 'profile',
            path: AppRoutes.profile,
            pageBuilder: (context, state) => platformPage(const ProfilePage()),
          ),

          GoRoute(
            name: 'personalInfo',
            path: AppRoutes.personalInfo,
            pageBuilder:
                (context, state) => platformPage(const PersonalInfoPage()),
          ),

          GoRoute(
            name: 'vehicleInfo',
            path: AppRoutes.vehicleInfo,
            pageBuilder:
                (context, state) => platformPage(const VehicleInfoPage()),
          ),

          GoRoute(
            name: 'deliveryZonePage',
            path: AppRoutes.deliveryZonePage,
            pageBuilder:
                (context, state) => platformPage(const DeliveryZonePage()),
          ),

          GoRoute(
            name: 'earnings',
            path: AppRoutes.earnings,
            pageBuilder:
                (context, state) => platformPage(const EarningsListPage()),
          ),

          GoRoute(
            name: 'allEarnings',
            path: AppRoutes.allEarnings,
            pageBuilder:
                (context, state) => platformPage(const AllEarningsPage()),
          ),

          GoRoute(
            name: 'cashCollection',
            path: AppRoutes.cashCollection,
            pageBuilder:
                (context, state) => platformPage(const AllCashCollectionPage()),
          ),

          GoRoute(
            name: 'allCashCollection',
            path: AppRoutes.allCashCollection,
            pageBuilder:
                (context, state) => platformPage(const AllCashCollectionPage()),
          ),

          GoRoute(
            name: 'withdrawalHistory',
            path: AppRoutes.withdrawalHistory,
            pageBuilder:
                (context, state) => platformPage(const WithdrawalHistoryPage()),
          ),

          GoRoute(
            name: 'viewHistory',
            path: AppRoutes.viewHistory,
            pageBuilder:
                (context, state) => platformPage(
                  BlocProvider(
                    create: (context) => DeliveredOrdersBloc(),
                    child: const ViewHistoryOfOrders(),
                  ),
                ),
          ),

          GoRoute(
            name: 'ratings',
            path: AppRoutes.ratings,
            pageBuilder:
                (context, state) => platformPage(
                  BlocProvider(
                    create: (context) => sl<RatingsBloc>(),
                    child: const RatingsPage(),
                  ),
                ),
          ),

          //RatingsBloc
          GoRoute(
            name: 'myOrders',
            path: AppRoutes.myOrders,
            pageBuilder:
                (context, state) => platformPage(
                  MyOrdersPage(initialTabStatus: state.extra as String?),
                ),
          ),

          GoRoute(
            name: 'myPickups',
            path: AppRoutes.myPickups,
            pageBuilder:
                (context, state) => platformPage(const MyPickupsPage()),
          ),

          ShellRoute(
            builder: (context, state, child) {
              return BottomNavBar(child: child);
            },
            routes: [
              GoRoute(
                name: 'home',
                path: AppRoutes.home,
                pageBuilder: (context, state) {
                  return platformPage(const HomeScreen());
                },
              ),

              GoRoute(
                name: 'feed',
                path: AppRoutes.feed,
                pageBuilder: (context, state) {
                  final tabIndex = int.tryParse(
                    state.uri.queryParameters['tab'] ?? '0',
                  );
                  return platformPage(OrdersFeedPage(initialTab: tabIndex));
                },
              ),

              GoRoute(
                name: 'pockets',
                path: AppRoutes.pockets,
                pageBuilder:
                    (context, state) => platformPage(const PocketsPage()),
              ),

              GoRoute(
                name: 'settings',
                path: AppRoutes.more,
                pageBuilder: (context, state) => platformPage(const MorePage()),
              ),
            ],
          ),

          GoRoute(
            name: 'terms',
            path: AppRoutes.terms,
            pageBuilder:
                (context, state) =>
                    platformPage(const TermsPrivacyPage(isTerms: true)),
          ),

          GoRoute(
            name: 'privacy',
            path: AppRoutes.privacy,
            pageBuilder:
                (context, state) =>
                    platformPage(const TermsPrivacyPage(isTerms: false)),
          ),

          GoRoute(
            name: 'support',
            path: AppRoutes.support,
            pageBuilder: (context, state) => platformPage(const SupportPage()),
          ),

          GoRoute(
            name: 'notifications',
            path: AppRoutes.notifications,
            pageBuilder:
                (context, state) => platformPage(const NotificationListPage()),
          ),

          GoRoute(
            name: 'deliveryZoneList',
            path: AppRoutes.deliveryZoneList,
            pageBuilder: (context, state) {
              final isSelectionMode =
                  (state.extra as Map<String, dynamic>?)?['isSelectionMode']
                      as bool? ??
                  false;
              return platformPage(
                DeliveryZoneListPage(isSelectionMode: isSelectionMode),
              );
            },
          ),

          GoRoute(
            name: 'deliveryZoneDetails',
            path: '${AppRoutes.deliveryZoneDetails}/:zoneId',
            pageBuilder: (context, state) {
              final zoneId = int.parse(state.pathParameters['zoneId']!);
              final zone = state.extra as DeliveryZoneModel?;
              return platformPage(
                DeliveryZoneDetailsPage(zoneId: zoneId, zone: zone),
              );
            },
          ),

          GoRoute(
            name: 'referAndEarn',
            path: AppRoutes.referAndEarn,
            pageBuilder:
                (context, state) => platformPage(
                  BlocProvider(
                    create: (context) => sl<ReferAndEarnBloc>(),
                    child: const ReferAndEarnPage(),
                  ),
                ),
          ),

          GoRoute(
            name: 'viewTransactions',
            path: AppRoutes.viewTransactions,
            pageBuilder:
                (context, state) => platformPage(const ViewTransactionsPage()),
          ),
        ],
      ),
    ],
  );
  static void pushUnique(String location, {Object? extra}) {
    // routerDelegate.currentConfiguration.last.matchedLocation provides the top-most route location
    final String currentPath =
        router.routerDelegate.currentConfiguration.last.matchedLocation;

    if (currentPath != location) {
      router.push(location, extra: extra);
    }
  }

  static void goUnique(String location, {Object? extra}) {
    final String currentPath =
        router.routerDelegate.currentConfiguration.last.matchedLocation;

    if (currentPath != location) {
      router.go(location, extra: extra);
    }
  }
}
