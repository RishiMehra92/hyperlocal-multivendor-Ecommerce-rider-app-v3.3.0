import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequest extends AuthEvent {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequest extends AuthEvent {
  final String name;
  final String email;
  final String mobile;
  final String password;
  final String country;
  final String iso2;
  final String countryCode;
  final String completePhoneNumber;
  final String confirmPassword;
  final List<File>? driverLicenseFiles;
  final List<File>? vehicleRegistrationFiles;
  final String address;
  final String vehicleType;
  final String driverLicenseNumber;

  final int deliveryZoneId;
  final String referCode;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.mobile,
    required this.password,
    required this.country,
    required this.iso2,
    required this.countryCode,
    required this.completePhoneNumber,
    required this.confirmPassword,
    this.driverLicenseFiles,
    required this.deliveryZoneId,
    this.vehicleRegistrationFiles,
    required this.address,
    required this.vehicleType,
    required this.driverLicenseNumber,
    required this.referCode,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    mobile,
    password,
    country,
    iso2,
    countryCode,
    completePhoneNumber,
    confirmPassword,
    driverLicenseFiles,
    vehicleRegistrationFiles,
    address,
    vehicleType,
    driverLicenseNumber,
  ];
}

class EmailOrMobileNumber extends AuthEvent {
  final String type;

  final String value;

  EmailOrMobileNumber({required this.type, required this.value});

  @override
  List<Object?> get props => [type, value];
}
