import 'package:equatable/equatable.dart';
import '../model/update_config.dart';

enum AppUpdateStatus { initial, loading, success, failure }

class AppUpdateState extends Equatable {
  final AppUpdateStatus status;
  final UpdateConfig? config;
  final bool isForced;
  final bool isUpdateAvailable;
  final String? errorMessage;

  const AppUpdateState({
    this.status = AppUpdateStatus.initial,
    this.config,
    this.isForced = false,
    this.isUpdateAvailable = false,
    this.errorMessage,
  });

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    UpdateConfig? config,
    bool? isForced,
    bool? isUpdateAvailable,
    String? errorMessage,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      config: config ?? this.config,
      isForced: isForced ?? this.isForced,
      isUpdateAvailable: isUpdateAvailable ?? this.isUpdateAvailable,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    config,
    isForced,
    isUpdateAvailable,
    errorMessage,
  ];
}
