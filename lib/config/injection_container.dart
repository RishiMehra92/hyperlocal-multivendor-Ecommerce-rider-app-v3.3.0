import 'package:hyper_local/bloc/language_bloc/language_bloc.dart';
import 'package:hyper_local/config/global.dart';
import 'package:get_it/get_it.dart';

import 'package:hyper_local/config/theme/theme_bloc/theme_bloc.dart';

// Repos
import 'package:hyper_local/screens/dashboard/repo/ratings_repo.dart';
import 'package:hyper_local/screens/inactive_delievryboy/bloc/inactive_page_stats/home_stats_bloc.dart';
import 'package:hyper_local/screens/inactive_delievryboy/repo/home_stats_repo.dart';
import 'package:hyper_local/screens/pockets/cash_collection/repo/cash_collection_repo.dart';
import 'package:hyper_local/screens/pockets/earnings/repo/earnings_repo.dart';
import 'package:hyper_local/screens/pockets/withdrawal/repo/withdrawal_repo.dart';
import 'package:hyper_local/screens/settings/repo/profile_repo.dart';
import 'package:hyper_local/screens/system_settings/repo/system_settings_repo.dart';
import 'package:hyper_local/screens/dashboard/repo/notification_list_repo.dart';

// Blocs
import 'package:hyper_local/screens/auth/bloc/auth_bloc/auth_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/phone_auth_bloc/phone_auth_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/delivery_zone_bloc/delivery_zone_bloc.dart';
import 'package:hyper_local/screens/delivery_zones/bloc/delivery_zone_bloc.dart'
    as zones;
import 'package:hyper_local/screens/dashboard/bloc/ratings/ratings_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/available_orders_bloc/available_orders_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/items_collected_bloc/items_collected_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/my_orders_bloc/my_orders_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/pickup_order_details_bloc/pickup_order_details_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/pickup_orders_list_bloc/pickup_order_list_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/return_orders_list_bloc/return_order_list_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/update_return_order_status_bloc/update_return_order_status_bloc.dart';
import 'package:hyper_local/screens/pockets/cash_collection/bloc/cash_collection_bloc.dart';
import 'package:hyper_local/screens/pockets/earnings/bloc/earnings_bloc.dart';
import 'package:hyper_local/screens/pockets/withdrawal/bloc/withdrawal_bloc.dart';
import 'package:hyper_local/screens/settings/bloc/profile_bloc/profile_bloc.dart';
import 'package:hyper_local/screens/settings/view/refer_and_earn/bloc/refer_and_earn/refer_and_earn_bloc.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:hyper_local/screens/dashboard/bloc/notification/notification_bloc.dart';

import '../screens/pockets/Transactions/bloc/wallet_transactions_bloc.dart';
import '../utils/app_update/bloc/app_update_bloc.dart';
import '../screens/onboarding/bloc/onboarding_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Repositories
  sl.registerLazySingleton(() => SystemSettingsRepo());
  sl.registerLazySingleton(() => ProfileRepo());
  sl.registerLazySingleton(() => WithdrawalRepo());
  sl.registerLazySingleton(() => EarningsRepo());
  sl.registerLazySingleton(() => CashCollectionRepo());
  sl.registerLazySingleton(() => RatingsRepo());
  sl.registerLazySingleton(() => NotificationListRepo());
  sl.registerLazySingleton(() => HomeStatsRepo());

  // BLoCs
  sl.registerFactory(() => HomeStatsBloc(sl()));
  sl.registerFactory(() => ThemeBloc());
  sl.registerFactory(() => SystemSettingsBloc(sl()));
  sl.registerFactory(() => AuthBloc());
  sl.registerFactory(() => PhoneAuthBloc(sl()));
  sl.registerFactory(() => DeliveryZoneBloc());
  sl.registerFactory(() => zones.DeliveryZoneBloc());
  sl.registerFactory(() => DeliveryBoyStatusBloc());
  sl.registerFactory(() => AvailableOrdersBloc());
  sl.registerFactory(() => MyOrdersBloc());
  sl.registerFactory(() => ProfileBloc(sl()));
  sl.registerFactory(() => ItemsCollectedBloc());
  sl.registerFactory(() => WithdrawalBloc(sl()));
  sl.registerFactory(() => ReturnOrderListBloc());
  sl.registerFactory(() => PickupOrderListBloc());
  sl.registerFactory(() => RatingsBloc(sl()));
  sl.registerFactory(() => PickupOrderDetailsBloc());
  sl.registerFactory(() => UpdateReturnOrderStatusBloc());
  sl.registerFactory(() => EarningsBloc(sl()));
  sl.registerFactory(() => CashCollectionBloc(sl()));
  sl.registerFactory(() => NotificationBloc(sl()));
  sl.registerFactory(() => ReferAndEarnBloc());
  sl.registerLazySingleton(
    () => LanguageBloc()..add(const LoadLanguage()),
  );
  sl.registerLazySingleton(
    () => LanguageListBloc()
      ..add(FetchLanguageList(locale: Global.currentLanguage)),
  );
  sl.registerFactory(() => WalletTransactionsBloc());
  sl.registerFactory(() => AppUpdateBloc());
  sl.registerLazySingleton(() => OnboardingCubit());
}
