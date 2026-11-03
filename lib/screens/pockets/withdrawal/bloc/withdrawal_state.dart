import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../model/withdrawal_model.dart';

class WithdrawalState extends Equatable {
  final ApiStatus fetchStatus;
  final ApiStatus singleFetchStatus;
  final ApiStatus createStatus;

  final WithdrawalResponse? response;
  final SingleWithdrawalResponse? singleResponse;
  final Map<String, dynamic>? createResponse;

  final bool isFetchingMore;
  final bool hasReachedMax;
  final int currentPage;
  final String errorMessage;

  const WithdrawalState({
    this.fetchStatus = ApiStatus.initial,
    this.singleFetchStatus = ApiStatus.initial,
    this.createStatus = ApiStatus.initial,
    this.response,
    this.singleResponse,
    this.createResponse,
    this.isFetchingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.errorMessage = '',
  });

  WithdrawalState copyWith({
    ApiStatus? fetchStatus,
    ApiStatus? singleFetchStatus,
    ApiStatus? createStatus,
    WithdrawalResponse? response,
    SingleWithdrawalResponse? singleResponse,
    Map<String, dynamic>? createResponse,
    bool? isFetchingMore,
    bool? hasReachedMax,
    int? currentPage,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return WithdrawalState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      singleFetchStatus: singleFetchStatus ?? this.singleFetchStatus,
      createStatus: createStatus ?? this.createStatus,
      response: response ?? this.response,
      singleResponse: singleResponse ?? this.singleResponse,
      createResponse: createResponse ?? this.createResponse,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      errorMessage:
          clearErrorMessage ? '' : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    fetchStatus,
    singleFetchStatus,
    createStatus,
    response,
    singleResponse,
    createResponse,
    isFetchingMore,
    hasReachedMax,
    currentPage,
    errorMessage,
  ];
}
