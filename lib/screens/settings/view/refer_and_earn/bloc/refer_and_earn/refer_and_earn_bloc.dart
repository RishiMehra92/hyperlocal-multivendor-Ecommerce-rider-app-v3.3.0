import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/settings/view/refer_and_earn/bloc/refer_and_earn/refer_and_earn_event.dart';
import '../../../../../../config/helper.dart';
import '../../repo/refer_and_earn_repo.dart';
import 'refer_and_earn_state.dart';

class ReferAndEarnBloc extends Bloc<ReferAndEarnEvent, ReferAndEarnState> {
  final ReferAndEarnRepository _referAndEarnRepository =
      ReferAndEarnRepository();

  ReferAndEarnBloc() : super(const ReferAndEarnState()) {
    on<FetchReferInfo>(_onFetchReferInfo);
  }

  Future<void> _onFetchReferInfo(
    FetchReferInfo event,
    Emitter<ReferAndEarnState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading));
    try {
      final response = await _referAndEarnRepository.fetchReferAndEarn();

      if (response.success == true) {
        emit(
          state.copyWith(
            status: ApiStatus.success,
            referAndEarnData: response.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failed,
            error: response.message ?? 'Something went wrong',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: ApiStatus.failed, error: e.toString()));
    }
  }
}
