import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repo/app_version_repository.dart';
import 'app_update_event.dart';
import 'app_update_state.dart';
import '../model/update_config.dart';

class AppUpdateBloc extends Bloc<AppUpdateEvent, AppUpdateState> {
  final AppVersionRepository _repository;

  AppUpdateBloc({AppVersionRepository? repository})
    : _repository = repository ?? AppVersionRepository(),
      super(const AppUpdateState()) {
    on<CheckAppUpdate>(_onCheckAppUpdate);
  }

  Future<void> _onCheckAppUpdate(
    CheckAppUpdate event,
    Emitter<AppUpdateState> emit,
  ) async {
    emit(state.copyWith(status: AppUpdateStatus.loading));
    try {
      final config = await _repository.fetchUpdateConfig();
      log('[AppUpdateBloc] config status: ${config.status}');

      bool isForced = config.status == UpdateStatus.forceUpdate;
      bool isUpdateAvailable = config.status != UpdateStatus.upToDate;

      emit(
        state.copyWith(
          status: AppUpdateStatus.success,
          config: config,
          isForced: isForced,
          isUpdateAvailable: isUpdateAvailable,
        ),
      );
    } catch (e) {
      log('[AppUpdateBloc] Error: $e');
      emit(
        state.copyWith(
          status: AppUpdateStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
