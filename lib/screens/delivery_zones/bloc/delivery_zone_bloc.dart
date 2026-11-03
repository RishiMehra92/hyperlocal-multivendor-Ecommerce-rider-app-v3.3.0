import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repo/delivery_zone_repo.dart';
import 'package:hyper_local/config/helper.dart';
import 'delivery_zone_event.dart';
import 'delivery_zone_state.dart';

class DeliveryZoneBloc extends Bloc<DeliveryZoneEvent, DeliveryZoneState> {
  final DeliveryZoneRepository _repository = DeliveryZoneRepository();

  DeliveryZoneBloc() : super(const DeliveryZoneState()) {
    on<FetchDeliveryZonesEvent>(_onFetchDeliveryZones);
    on<SearchDeliveryZonesEvent>(_onSearchDeliveryZones);
    on<LoadMoreDeliveryZonesEvent>(_onLoadMoreDeliveryZones);
    on<SelectDeliveryZoneEvent>(_onSelectDeliveryZone);
    on<ClearSelectedZoneEvent>(_onClearSelectedZone);
  }

  Future<void> _onFetchDeliveryZones(
    FetchDeliveryZonesEvent event,
    Emitter<DeliveryZoneState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading));

    try {
      final response = await _repository.getDeliveryZones(
        page: event.page,
        search: event.search,
      );

      emit(
        state.copyWith(
          status: ApiStatus.success,
          zones: response.data.data,
          currentPage: response.data.currentPage,
          lastPage: response.data.lastPage,
          total: response.data.total,
          hasMore: response.data.currentPage < response.data.lastPage,
          searchQuery: event.search ?? '',
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error in bloc: $e');
      }
      emit(state.copyWith(status: ApiStatus.failed, message: e.toString()));
    }
  }

  Future<void> _onSearchDeliveryZones(
    SearchDeliveryZonesEvent event,
    Emitter<DeliveryZoneState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading));

    try {
      final response = await _repository.getDeliveryZones(
        page: 1,
        search: event.query.isEmpty ? null : event.query,
      );

      emit(
        state.copyWith(
          status: ApiStatus.success,
          zones: response.data.data,
          currentPage: response.data.currentPage,
          lastPage: response.data.lastPage,
          total: response.data.total,
          hasMore: response.data.currentPage < response.data.lastPage,
          searchQuery: event.query,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Search error: $e');
      }
      emit(state.copyWith(status: ApiStatus.failed, message: e.toString()));
    }
  }

  Future<void> _onLoadMoreDeliveryZones(
    LoadMoreDeliveryZonesEvent event,
    Emitter<DeliveryZoneState> emit,
  ) async {
    if (!state.hasMore ||
        state.status != ApiStatus.success ||
        state.isLoadingMore) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repository.getDeliveryZones(
        page: nextPage,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );

      final updatedZones = [...state.zones, ...response.data.data];

      emit(
        state.copyWith(
          status: ApiStatus.success,
          zones: updatedZones,
          currentPage: response.data.currentPage,
          lastPage: response.data.lastPage,
          total: response.data.total,
          hasMore: response.data.currentPage < response.data.lastPage,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Load more error: $e');
      }
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onSelectDeliveryZone(
    SelectDeliveryZoneEvent event,
    Emitter<DeliveryZoneState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading));

    try {
      final zone = await _repository.getDeliveryZoneById(event.zoneId);
      emit(state.copyWith(status: ApiStatus.success, selectedZone: zone));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Zone details error: $e');
      }
      emit(state.copyWith(status: ApiStatus.failed, message: e.toString()));
    }
  }

  Future<void> _onClearSelectedZone(
    ClearSelectedZoneEvent event,
    Emitter<DeliveryZoneState> emit,
  ) async {
    emit(state.copyWith(clearSelectedZone: true));
  }
}
