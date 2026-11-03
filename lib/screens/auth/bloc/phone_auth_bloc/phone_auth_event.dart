import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class PhoneAuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event to send OTP to phone number
class SendOTPEvent extends PhoneAuthEvent {
  final String phoneNumber;
  final bool isCustomSms;

  SendOTPEvent({required this.phoneNumber, this.isCustomSms = false});

  @override
  List<Object?> get props => [phoneNumber, isCustomSms];
}

/// Event to verify OTP
class VerifyOTPEvent extends PhoneAuthEvent {
  final String verificationId;
  final String otp;
  final bool isCustomSms;

  VerifyOTPEvent({
    required this.verificationId,
    required this.otp,
    this.isCustomSms = false,
  });

  @override
  List<Object?> get props => [verificationId, otp, isCustomSms];
}

/// Event when verification is completed automatically
class AutoVerificationCompletedEvent extends PhoneAuthEvent {
  final PhoneAuthCredential credential;
  final Map<String, dynamic>? registrationData;

  AutoVerificationCompletedEvent({
    required this.credential,
    this.registrationData,
  });

  @override
  List<Object?> get props => [credential, registrationData];
}

/// Event to resend OTP
class ResendOTPEvent extends PhoneAuthEvent {
  final String phoneNumber;
  final Map<String, dynamic>? registrationData;
  final bool isCustomSms;

  ResendOTPEvent({
    required this.phoneNumber,
    this.registrationData,
    this.isCustomSms = false,
  });

  @override
  List<Object?> get props => [phoneNumber, registrationData, isCustomSms];
}

/// Event to send OTP for registration
class SendOTPForRegistrationEvent extends PhoneAuthEvent {
  final String phoneNumber;
  final Map<String, dynamic> registrationData;
  final bool isCustomSms;

  SendOTPForRegistrationEvent({
    required this.phoneNumber,
    required this.registrationData,
    this.isCustomSms = false,
  });

  @override
  List<Object?> get props => [phoneNumber, registrationData, isCustomSms];
}

/// Event to verify OTP and complete registration
class VerifyOTPAndRegisterEvent extends PhoneAuthEvent {
  final String verificationId;
  final String otp;
  final Map<String, dynamic> registrationData;
  final bool isCustomSms;

  VerifyOTPAndRegisterEvent({
    required this.verificationId,
    required this.otp,
    required this.registrationData,
    this.isCustomSms = false,
  });

  @override
  List<Object?> get props => [
    verificationId,
    otp,
    registrationData,
    isCustomSms,
  ];
}

/// Event to reset phone auth state
class ResetPhoneAuthEvent extends PhoneAuthEvent {}

/// Event to verify if a user exists by phone number
class VerifyUserExistsEvent extends PhoneAuthEvent {
  final String phoneNumber;
  final bool isVerify;

  VerifyUserExistsEvent({required this.phoneNumber, required this.isVerify});

  @override
  List<Object?> get props => [phoneNumber, isVerify];
}
