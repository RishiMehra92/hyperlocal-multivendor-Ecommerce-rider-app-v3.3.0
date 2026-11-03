import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:hyper_local/config/helper.dart';
import 'system_settings_event.dart';
import 'system_settings_state.dart';
import '../repo/system_settings_repo.dart';
import '../model/settings_repo.dart';
import 'package:hyper_local/config/global.dart';

class SystemSettingsBloc
    extends Bloc<SystemSettingsEvent, SystemSettingsState> {
  final SystemSettingsRepo _repo;
  SettingsModel? _cachedSettings;

  SystemSettingsBloc(this._repo) : super(const SystemSettingsState()) {
    on<FetchSystemSettings>(_onFetchSystemSettings);
    on<RefreshSystemSettings>(_onRefreshSystemSettings);
    on<FetchDeliveryBoySettings>(_onFetchDeliveryBoySettings);
  }

  Future<void> _onFetchSystemSettings(
    FetchSystemSettings event,
    Emitter<SystemSettingsState> emit,
  ) async {
    try {
      // If we have cached system_settings, emit them immediately
      if (_cachedSettings != null) {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.success,
            settings: _cachedSettings!,
          ),
        );
        if (event.completer != null && !event.completer!.isCompleted) {
          event.completer!.complete();
        }
        return;
      }

      emit(state.copyWith(fetchStatus: ApiStatus.loading, clearMessage: true));

      SettingsModel? settings = await _repo.getSystemSettings();
      if (settings != null) {
        _cachedSettings = settings;
        await Global.saveSettings(customSms: settings.isCustomSmsEnabled);
        emit(
          state.copyWith(fetchStatus: ApiStatus.success, settings: settings),
        );
      } else {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            message: 'Failed to fetch system_settings',
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {}

      // If we have cached system_settings, use them even on error
      if (_cachedSettings != null) {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.success,
            settings: _cachedSettings!,
          ),
        );
      } else {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            message: 'Failed to fetch system_settings',
          ),
        );
      }
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onRefreshSystemSettings(
    RefreshSystemSettings event,
    Emitter<SystemSettingsState> emit,
  ) async {
    try {
      emit(state.copyWith(fetchStatus: ApiStatus.loading, clearMessage: true));

      final settings = await _repo.getSystemSettings();
      if (settings != null) {
        _cachedSettings = settings;
        await Global.saveSettings(customSms: settings.isCustomSmsEnabled);
        emit(
          state.copyWith(fetchStatus: ApiStatus.success, settings: settings),
        );
      } else {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            message: 'Failed to refresh system_settings',
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {}

      if (_cachedSettings != null) {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.success,
            settings: _cachedSettings!,
          ),
        );
      } else {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            message: 'Failed to refresh system_settings',
          ),
        );
      }
    }
  }

  Future<void> _onFetchDeliveryBoySettings(
    FetchDeliveryBoySettings event,
    Emitter<SystemSettingsState> emit,
  ) async {
    try {
      emit(state.copyWith(fetchStatus: ApiStatus.loading, clearMessage: true));

      final settings = await _repo.getDeliveryBoySettings();
      if (settings != null) {
        _cachedSettings = settings;
        await Global.saveSettings(customSms: settings.isCustomSmsEnabled);
        emit(
          state.copyWith(fetchStatus: ApiStatus.success, settings: settings),
        );
      } else {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.failed,
            message: 'Failed to fetch delivery boy system_settings',
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {}
      emit(
        state.copyWith(
          fetchStatus: ApiStatus.failed,
          message: 'Failed to fetch delivery boy system_settings',
        ),
      );
    }
  }

  // Getter for current system_settings
  SettingsModel? get currentSettings => _cachedSettings;

  // Getter for currency symbol
  String get currencySymbol {
    final symbol = _cachedSettings?.systemSettings?.value?.currencySymbol;
    if (symbol == null || symbol.isEmpty) {
      return '₹';
    }

    return symbol;
  }

  bool get isDemo => _cachedSettings?.systemSettings?.value?.demoMode ?? false;

  String get demoMessage =>
      _cachedSettings?.systemSettings?.value?.deliveryBoyDemoModeMessage ??
      "Some operations may not be allowed in the DEMO MODE.";

  // Getter for currency code
  String get currencyCode =>
      _cachedSettings?.systemSettings?.value?.currency ?? 'INR';
}
