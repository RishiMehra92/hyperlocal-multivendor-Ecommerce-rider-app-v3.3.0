import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/onboarding_model.dart';
import '../repo/onboarding_repo.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final OnboardingRepository _repository;

  OnboardingCubit({OnboardingRepository? repository})
      : _repository = repository ?? OnboardingRepository(),
        super(OnboardingInitial());

  /// Helper to determine if the onboarding screen should be presented
  bool get shouldShowOnboarding {
    if (state is OnboardingDisabled) return false;
    if (state is OnboardingLoaded) {
      final loaded = state as OnboardingLoaded;
      return loaded.isEnabled && loaded.screens.isNotEmpty;
    }
    // If not loaded yet or in error, fallback onboarding is available
    return true;
  }

  /// Current active screens list, or fallback screens if none
  List<OnboardingScreenItem> get currentScreens {
    if (state is OnboardingLoaded) {
      return (state as OnboardingLoaded).screens;
    }
    if (state is OnboardingError) {
      return (state as OnboardingError).fallbackScreens;
    }
    final cached = _repository.getCachedConfig();
    if (cached != null && cached.isEnabled && cached.screens.isNotEmpty) {
      return cached.screens;
    }
    return OnboardingRepository.getDefaultScreens();
  }

  /// Preload onboarding config during splash (non-blocking with timeout)
  Future<void> preloadOnboarding() async {
    // 1. Immediately inspect cache so state is available offline
    final cachedConfig = _repository.getCachedConfig();
    if (cachedConfig != null) {
      if (!cachedConfig.isEnabled) {
        emit(const OnboardingDisabled());
      } else if (cachedConfig.screens.isNotEmpty) {
        emit(OnboardingLoaded(
          isEnabled: true,
          screens: cachedConfig.screens,
          isFallback: false,
        ));
      }
    }

    // 2. Fetch fresh config from API with timeout
    try {
      final freshConfig = await _repository.fetchFromApi().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          log('[OnboardingCubit] Preload timed out after 4s — using cache/fallback');
          throw TimeoutException('Onboarding fetch timed out');
        },
      );

      if (!freshConfig.isEnabled) {
        log('[OnboardingCubit] Onboarding disabled remotely');
        emit(const OnboardingDisabled());
        return;
      }

      if (freshConfig.screens.isEmpty) {
        log('[OnboardingCubit] Remote screens empty — falling back to defaults');
        emit(OnboardingLoaded(
          isEnabled: true,
          screens: OnboardingRepository.getDefaultScreens(),
          isFallback: true,
        ));
        return;
      }

      log('[OnboardingCubit] Loaded ${freshConfig.screens.length} screens from API');
      emit(OnboardingLoaded(
        isEnabled: true,
        screens: freshConfig.screens,
        isFallback: false,
      ));
    } catch (e) {
      log('[OnboardingCubit] Preload failed: $e');
      if (state is! OnboardingLoaded && state is! OnboardingDisabled) {
        final fallback = cachedConfig != null &&
                cachedConfig.isEnabled &&
                cachedConfig.screens.isNotEmpty
            ? cachedConfig.screens
            : OnboardingRepository.getDefaultScreens();

        emit(OnboardingError(
          message: e.toString(),
          fallbackScreens: fallback,
        ));
      }
    }
  }
}
