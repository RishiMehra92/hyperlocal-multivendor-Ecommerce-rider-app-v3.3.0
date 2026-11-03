import 'package:hyper_local/bloc/language_bloc/language_bloc.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'config/theme/theme.dart';
import 'config/theme/theme_bloc/theme_bloc.dart';
import 'config/theme/theme_bloc/theme_event.dart';
import 'config/theme/theme_bloc/theme_state.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/location_monitor_widget.dart';
import 'package:hyper_local/config/app_initializer.dart';
import 'package:hyper_local/config/injection_container.dart';
import 'package:hyper_local/utils/background_location_service.dart';
import 'package:hyper_local/config/app_bloc_observer.dart';
import 'package:hyper_local/screens/dashboard/bloc/notification/notification_bloc.dart';
import 'package:hyper_local/utils/widgets/connectivity_wrapper.dart';
import 'package:hyper_local/config/global.dart';
import 'package:flutter_http_inspector/flutter_http_inspector.dart';
import 'screens/onboarding/bloc/onboarding_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpInspector.setup();

  await AppInitializer.initialize();

  await BackgroundLocationService.initializeService();
  await BackgroundLocationService.restartServicesIfNeeded();

  Bloc.observer = AppBlocObserver();

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ThemeBloc>()..add(LoadTheme())),
        BlocProvider(create: (_) => sl<NotificationBloc>()..add(FetchNotifications())),
        BlocProvider(create: (_) => sl<SystemSettingsBloc>()),
        BlocProvider.value(value: sl<LanguageBloc>()),
        BlocProvider.value(value: sl<LanguageListBloc>()),
        BlocProvider(create: (_) => sl<OnboardingCubit>()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final isDark = context.isDarkMode;
          return BlocBuilder<LanguageBloc, LanguageState>(
            builder: (context, langState) {
              return BlocBuilder<LanguageListBloc, LanguageListState>(
                builder: (context, langListState) {
                  final activeLocale = langState is LanguageLoaded
                      ? langState.locale
                      : Locale(Global.currentLanguage);
                  final isRtl = langState is LanguageLoaded && langState.isRtl;

                  return Directionality(
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    child: SafeArea(
                      top: false,
                      bottom: Platform.isIOS ? false : true,
                      left: false,
                      right: false,
                      child: MaterialApp.router(
                        debugShowCheckedModeBanner: false,
                        theme: AppColor.getLightTheme(),
                        darkTheme: AppColor.getDarkTheme(),
                        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                        locale: activeLocale,
                        localizationsDelegates: [
                          GlobalMaterialLocalizations.delegate,
                          GlobalWidgetsLocalizations.delegate,
                          GlobalCupertinoLocalizations.delegate,
                        ],
                        supportedLocales: Global.supportedLanguages
                            .map((l) => Locale(l['code']!))
                            .toList(),
                        builder: (context, child) {
                          final content = FToastBuilder()(
                            context,
                            LocationMonitor(child: ConnectivityWrapper(child: child!)),
                          );
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              content,
                              ValueListenableBuilder<bool>(
                                valueListenable: Global.httpInspectorEnabledNotifier,
                                builder: (context, isEnabled, _) {
                                  if (!isEnabled) return const SizedBox.shrink();
                                  return const HttpInspectorOverlay(enabled: true, child: SizedBox.shrink());
                                },
                              ),
                            ],
                          );
                        },
                        routerConfig: MyAppRoute.router,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
