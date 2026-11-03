import 'dart:async';

abstract class SystemSettingsEvent {}

class FetchSystemSettings extends SystemSettingsEvent {
  final Completer<void>? completer;

  FetchSystemSettings({this.completer});
}

// class FetchOverAllSystemSettings extends SystemSettingsEvent {}

class RefreshSystemSettings extends SystemSettingsEvent {}

class FetchDeliveryBoySettings extends SystemSettingsEvent {}
