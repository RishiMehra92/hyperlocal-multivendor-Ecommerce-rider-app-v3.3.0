import 'dart:async';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final Completer<void>? completer;

  const LoadProfile({this.completer});

  @override
  List<Object?> get props => [completer];
}

class UpdateProfile extends ProfileEvent {
  final String? fullName;
  final String? address;
  final String? driverLicenseNumber;
  final String? vehicleType;
  final String? mobile;
  final String? email;
  final String? country;
  final List<String>? driverLicenseFiles;
  final List<String>? vehicleRegistrationFiles;
  final String? profileImageFile;

  const UpdateProfile({
    this.fullName,
    this.address,
    this.driverLicenseNumber,
    this.vehicleType,
    this.mobile,
    this.email,
    this.country,
    this.driverLicenseFiles,
    this.vehicleRegistrationFiles,
    this.profileImageFile,
  });

  @override
  List<Object?> get props => [
    fullName,
    address,
    driverLicenseNumber,
    vehicleType,
    mobile,
    email,
    country,
    driverLicenseFiles,
    vehicleRegistrationFiles,
    profileImageFile,
  ];
}

class DeleteProfileEvent extends ProfileEvent {
  const DeleteProfileEvent();

  @override
  List<Object?> get props => [];
}

class ResetUpdateStatus extends ProfileEvent {
  const ResetUpdateStatus();
}
