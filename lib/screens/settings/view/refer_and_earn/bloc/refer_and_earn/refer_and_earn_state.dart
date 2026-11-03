import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../../model/refer_and_earn_model.dart';

// import 'refer_and_earn_bloc.dart';

class ReferAndEarnState extends Equatable {
  final ApiStatus status;
  final ReferAndEarnData? referAndEarnData;
  final String? error;

  const ReferAndEarnState({
    this.status = ApiStatus.loading,
    this.referAndEarnData,
    this.error,
  });

  ReferAndEarnState copyWith({
    ApiStatus? status,
    ReferAndEarnData? referAndEarnData,
    String? error,
  }) {
    return ReferAndEarnState(
      status: status ?? this.status,
      referAndEarnData: referAndEarnData ?? this.referAndEarnData,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, referAndEarnData, error];
}
