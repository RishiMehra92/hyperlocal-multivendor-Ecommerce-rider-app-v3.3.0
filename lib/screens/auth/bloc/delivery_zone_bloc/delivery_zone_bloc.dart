import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/helper.dart';

import '../../model/delivery_zone_model.dart';
import '../../repo/delivery_zone_repo.dart';
import 'delivery_zone_event.dart';
import 'delivery_zone_state.dart';

class DeliveryZoneBloc extends Bloc<DeliveryZoneEvent, DeliveryZoneState> {
  int _offset = 0;
  final int _limit = 15;
  bool _hasReachedMax = false;
  final DeliveryZoneRepo _deliveryZoneRepo = DeliveryZoneRepo();

  DeliveryZoneBloc() : super(const DeliveryZoneState()) {
    on<FetchDeliveryZones>(_onFetchDeliveryZones);
    on<LoadMoreDeliveryZones>(_onLoadMoreDeliveryZones);
    on<SelectDeliveryZone>(_onSelectDeliveryZone);
  }

  Future<void> _onFetchDeliveryZones(
    FetchDeliveryZones event,
    Emitter<DeliveryZoneState> emit,
  ) async {
    try {
      emit(state.copyWith(fetchStatus: ApiStatus.loading, clearMessage: true));
      _offset = 0;
      _hasReachedMax = false;
      late List<DeliveryZoneModel> deliveryZones;

      final response = await _deliveryZoneRepo.getDeliveryZone(
        offset: _offset,
        limit: _limit,
      );

      try {
        deliveryZones =
            (response['data']['data'] as List<dynamic>?)
                ?.map(
                  (item) =>
                      DeliveryZoneModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];
      } catch (e, s) {
        debugPrint(s.toString());
      }

      final int currentPage = response['data']['current_page'] as int;
      final int lastPage = response['data']['last_page'] as int;
      _hasReachedMax = currentPage >= lastPage;
      emit(
        state.copyWith(
          fetchStatus: ApiStatus.success,
          deliveryZones: deliveryZones,
          hasReachedMax: _hasReachedMax,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(fetchStatus: ApiStatus.failed, message: e.toString()),
      );
    }
  }

  Future<void> _onLoadMoreDeliveryZones(
    LoadMoreDeliveryZones event,
    Emitter<DeliveryZoneState> emit,
  ) async {
    if (_hasReachedMax) return;

    try {
      final currentState = state;
      if (currentState.fetchStatus == ApiStatus.success) {
        _offset += _limit;

        final response = await _deliveryZoneRepo.getDeliveryZone(
          offset: _offset,
          limit: _limit,
        );

        final List<DeliveryZoneModel> moreDeliveryZones =
            (response['data']['data'] as List<dynamic>?)
                ?.map(
                  (item) =>
                      DeliveryZoneModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];
        final int currentPage = response['data']['current_page'] as int;
        final int lastPage = response['data']['last_page'] as int;

        _hasReachedMax = currentPage >= lastPage;

        emit(
          currentState.copyWith(
            deliveryZones: [
              ...currentState.deliveryZones,
              ...moreDeliveryZones,
            ],
            hasReachedMax: _hasReachedMax,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(fetchStatus: ApiStatus.failed, message: e.toString()),
      );
    }
  }

  void _onSelectDeliveryZone(
    SelectDeliveryZone event,
    Emitter<DeliveryZoneState> emit,
  ) {
    if (state.fetchStatus == ApiStatus.success) {
      emit(state.copyWith(selectedZone: event.selectedZone));
    }
  }
}
