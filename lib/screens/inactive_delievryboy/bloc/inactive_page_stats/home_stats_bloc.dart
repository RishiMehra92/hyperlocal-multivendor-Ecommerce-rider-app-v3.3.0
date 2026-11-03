import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/helper.dart';
import '../../repo/home_stats_repo.dart';
import 'home_stats_event.dart';
import 'home_stats_state.dart';

class HomeStatsBloc extends Bloc<HomeStatsEvent, HomeStatsState> {
  final HomeStatsRepo _homeStatsRepo;

  HomeStatsBloc(this._homeStatsRepo) : super(const HomeStatsState()) {
    on<FetchHomeStats>(_onFetchHomeStats);
    on<RefreshHomeStats>(_onRefreshHomeStats);
  }

  Future<void> _onFetchHomeStats(
    FetchHomeStats event,
    Emitter<HomeStatsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ApiStatus.loading));

      final response = await _homeStatsRepo.getHomeStats();

      if (response.success) {
        emit(state.copyWith(status: ApiStatus.success, response: response));
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            errorMessage: response.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: ApiStatus.failed, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onRefreshHomeStats(
    RefreshHomeStats event,
    Emitter<HomeStatsState> emit,
  ) async {
    try {
      final response = await _homeStatsRepo.getHomeStats();

      if (response.success) {
        emit(state.copyWith(status: ApiStatus.success, response: response));
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            errorMessage: response.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: ApiStatus.failed, errorMessage: e.toString()),
      );
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }
}
