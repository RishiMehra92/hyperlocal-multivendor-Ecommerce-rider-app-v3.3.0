import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../../model/delivery_zone_model.dart';

class DeliveryZoneState extends Equatable {
  final ApiStatus fetchStatus;
  final List<DeliveryZoneModel> deliveryZones;
  final bool hasReachedMax;
  final DeliveryZoneModel? selectedZone;
  final String message;

  const DeliveryZoneState({
    this.fetchStatus = ApiStatus.initial,
    this.deliveryZones = const [],
    this.hasReachedMax = false,
    this.selectedZone,
    this.message = '',
  });

  DeliveryZoneState copyWith({
    ApiStatus? fetchStatus,
    List<DeliveryZoneModel>? deliveryZones,
    bool? hasReachedMax,
    DeliveryZoneModel? selectedZone,
    String? message,
    bool clearMessage = false,
  }) {
    return DeliveryZoneState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      deliveryZones: deliveryZones ?? this.deliveryZones,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      selectedZone: selectedZone ?? this.selectedZone,
      message: clearMessage ? '' : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    fetchStatus,
    deliveryZones,
    hasReachedMax,
    selectedZone,
    message,
  ];
}
