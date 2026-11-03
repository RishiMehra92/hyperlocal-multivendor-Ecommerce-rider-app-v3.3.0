import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../model/settings_repo.dart';

class SystemSettingsState extends Equatable {
  final SettingsModel? settings;
  final ApiStatus fetchStatus;
  final String message;

  const SystemSettingsState({
    this.settings,
    this.fetchStatus = ApiStatus.initial,
    this.message = '',
  });

  SystemSettingsState copyWith({
    SettingsModel? settings,
    ApiStatus? fetchStatus,
    String? message,
    bool clearMessage = false,
  }) {
    return SystemSettingsState(
      settings: settings ?? this.settings,
      fetchStatus: fetchStatus ?? this.fetchStatus,
      message: clearMessage ? '' : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [settings, fetchStatus, message];
}
