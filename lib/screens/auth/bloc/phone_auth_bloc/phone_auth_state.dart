import 'package:equatable/equatable.dart';

enum PhoneAuthStatus {
  initial,
  sendingOTP,
  otpSent,
  verifyingOTP,
  otpVerified,
  authenticating,
  success,
  failed,
  registering,
  registrationSuccess,
  userNotFound,
  otpResent,
  userChecking,
  userExists,
}

class PhoneAuthState extends Equatable {
  final PhoneAuthStatus status;
  final String verificationId;
  final String idToken;
  final String accessToken;
  final String message;

  const PhoneAuthState({
    this.status = PhoneAuthStatus.initial,
    this.verificationId = '',
    this.idToken = '',
    this.accessToken = '',
    this.message = '',
  });

  PhoneAuthState copyWith({
    PhoneAuthStatus? status,
    String? verificationId,
    String? idToken,
    String? accessToken,
    String? message,
    bool clearMessage = false,
  }) {
    return PhoneAuthState(
      status: status ?? this.status,
      verificationId: verificationId ?? this.verificationId,
      idToken: idToken ?? this.idToken,
      accessToken: accessToken ?? this.accessToken,
      message: clearMessage ? '' : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    status,
    verificationId,
    idToken,
    accessToken,
    message,
  ];
}
