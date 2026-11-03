import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../../model/home_stats_model.dart';

class HomeStatsState extends Equatable {
  final ApiStatus status;
  final HomeStatsResponse? response;
  final String errorMessage;

  const HomeStatsState({
    this.status = ApiStatus.initial,
    this.response,
    this.errorMessage = "",
  });

  HomeStatsState copyWith({
    ApiStatus? status,
    HomeStatsResponse? response,
    String? errorMessage,
  }) {
    return HomeStatsState(
      status: status ?? this.status,
      response: response ?? this.response,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, response, errorMessage];
}
