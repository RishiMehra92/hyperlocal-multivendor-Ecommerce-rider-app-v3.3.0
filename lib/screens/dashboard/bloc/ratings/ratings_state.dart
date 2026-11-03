import 'package:equatable/equatable.dart';
import 'package:hyper_local/config/helper.dart';
import '../../model/ratings_model.dart';

class RatingsState extends Equatable {
  final ApiStatus fetchStatus;
  final RatingsResponse? overallRatings;
  final DeliveryFeedbackResponse? feedback;
  final bool hasReachedMax;
  final bool isFetchingMore;
  final int currentPage;
  final String message;

  const RatingsState({
    this.fetchStatus = ApiStatus.initial,
    this.overallRatings,
    this.feedback,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
    this.currentPage = 1,
    this.message = '',
  });

  RatingsState copyWith({
    ApiStatus? fetchStatus,
    RatingsResponse? overallRatings,
    DeliveryFeedbackResponse? feedback,
    bool? hasReachedMax,
    bool? isFetchingMore,
    int? currentPage,
    String? message,
    bool clearMessage = false,
  }) {
    return RatingsState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      overallRatings: overallRatings ?? this.overallRatings,
      feedback: feedback ?? this.feedback,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      currentPage: currentPage ?? this.currentPage,
      message: clearMessage ? '' : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    fetchStatus,
    overallRatings,
    feedback,
    hasReachedMax,
    isFetchingMore,
    currentPage,
    message,
  ];
}
