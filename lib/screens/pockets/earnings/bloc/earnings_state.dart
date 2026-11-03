import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../model/earnings_model.dart';

class EarningsState extends Equatable {
  final EarningsResponse? response;
  final EarningsStatsResponse? statsResponse;
  final ApiStatus fetchStatus;
  final ApiStatus statsFetchStatus;
  final bool isFetchingMore;
  final bool hasReachedMax;
  final int currentPage;
  final String message;
  final bool isInactive;

  const EarningsState({
    this.response,
    this.statsResponse,
    this.fetchStatus = ApiStatus.initial,
    this.statsFetchStatus = ApiStatus.initial,
    this.isFetchingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.message = '',
    this.isInactive = false,
  });

  EarningsState copyWith({
    EarningsResponse? response,
    EarningsStatsResponse? statsResponse,
    ApiStatus? fetchStatus,
    ApiStatus? statsFetchStatus,
    bool? isFetchingMore,
    bool? hasReachedMax,
    int? currentPage,
    String? message,
    bool? isInactive,
    bool clearMessage = false,
  }) {
    return EarningsState(
      response: response ?? this.response,
      statsResponse: statsResponse ?? this.statsResponse,
      fetchStatus: fetchStatus ?? this.fetchStatus,
      statsFetchStatus: statsFetchStatus ?? this.statsFetchStatus,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      message: clearMessage ? '' : (message ?? this.message),
      isInactive: isInactive ?? this.isInactive,
    );
  }

  @override
  List<Object?> get props => [
    response,
    statsResponse,
    fetchStatus,
    statsFetchStatus,
    isFetchingMore,
    hasReachedMax,
    currentPage,
    message,
    isInactive,
  ];
}
