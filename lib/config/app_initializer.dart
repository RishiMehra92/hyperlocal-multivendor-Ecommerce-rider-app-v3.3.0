import 'package:hyper_local/repo/language_repo.dart';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/firebase_options.dart';
import 'package:hyper_local/config/injection_container.dart';

// Since `main.dart` contains initializeService inside it or other places
// we can keep the local dependencies decoupled by invoking the locator here.
class AppInitializer {
  static Future<void> initialize() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    await Hive.initFlutter();
    await Global.initializeToken();
    await Global.initializeLanguage();
    await LanguageRepo.initCache();
    await Global.initializeSettings();
    await Global.initializeLocationRequest();
    await Global.initializeOnboardingComplete();
    await Global.initializeLoggedinOnce();

    // Dependency Injection

    // Firebase
    try {
      log('🔥 Initializing Firebase...');
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      log('✅ Firebase initialized successfully');
    } catch (e) {
      log('❌ Firebase initialization error: $e');
    }
    await initDependencies();
  }
}
