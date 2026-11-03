import 'dart:async';

abstract class RatingsEvent {}

class FetchRatings extends RatingsEvent {}

class RefreshRatings extends RatingsEvent {
  final Completer<void>? completer;

  RefreshRatings({this.completer});
}

class LoadMoreRatings extends RatingsEvent {}
