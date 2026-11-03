// delivery_boy_status_state.dart

import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';

class DeliveryBoyStatusState extends Equatable {
  final ApiStatus status;
  final bool isOnline;
  final bool isVerified;
  final double? latitude;
  final double? longitude;
  final String message;

  const DeliveryBoyStatusState({
    this.status = ApiStatus.initial,
    this.isOnline = false,
    this.isVerified = true,
    this.latitude,
    this.longitude,
    this.message = '',
  });

  DeliveryBoyStatusState copyWith({
    ApiStatus? status,
    bool? isOnline,
    bool? isVerified,
    double? latitude,
    double? longitude,
    String? message,
    bool clearMessage = false,
  }) {
    return DeliveryBoyStatusState(
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      message: clearMessage ? '' : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    status,
    isOnline,
    isVerified,
    latitude,
    longitude,
    message,
  ];
}
