import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';

class AuthState extends Equatable {
  final ApiStatus status;
  final String message;
  final MobileANdEmailStatus mobileANdEmailStatus;
  final MobileANdEmailStatus emailStatus;

  const AuthState({
    this.status = ApiStatus.initial,
    this.message = '',
    this.mobileANdEmailStatus = MobileANdEmailStatus.initial,
    this.emailStatus = MobileANdEmailStatus.initial,
  });

  AuthState copyWith({
    ApiStatus? status,
    String? message,
    bool clearMessage = false,
    MobileANdEmailStatus? mobileANdEmailStatus,
    MobileANdEmailStatus? emailStatus,
  }) {
    return AuthState(
      status: status ?? this.status,
      message: clearMessage ? '' : (message ?? this.message),
      mobileANdEmailStatus: mobileANdEmailStatus ?? this.mobileANdEmailStatus,
      emailStatus: emailStatus ?? this.emailStatus,
    );
  }

  @override
  List<Object?> get props => [
    status,
    message,
    mobileANdEmailStatus,
    emailStatus,
  ];
}
