import 'dart:async';

abstract class CashCollectionEvent {}

class FetchCashCollection extends CashCollectionEvent {
  final String? dateRange;
  final Completer<void>? completer;

  FetchCashCollection({this.dateRange, this.completer});
}

class FetchCashCollectionStats extends CashCollectionEvent {}

class FetchCashCollectionByDateRange extends CashCollectionEvent {
  final String dateRange;
  final String? submissionStatus;
  final Completer<void>? completer;

  FetchCashCollectionByDateRange(
    this.dateRange, {
    this.submissionStatus,
    this.completer,
  });
}

class FetchLast30Minutes extends CashCollectionEvent {}

class FetchLast1Hour extends CashCollectionEvent {}

class FetchLast5Hours extends CashCollectionEvent {}

class FetchLast1Day extends CashCollectionEvent {}

class FetchLast7Days extends CashCollectionEvent {}

class FetchLast30Days extends CashCollectionEvent {}

class FetchLast365Days extends CashCollectionEvent {}

class LoadMoreCashCollection extends CashCollectionEvent {}

class SettleOnlineEvent extends CashCollectionEvent {
  final List<int> collectionIds;
  SettleOnlineEvent(this.collectionIds);
}

class ResetSettleStatusEvent extends CashCollectionEvent {}
