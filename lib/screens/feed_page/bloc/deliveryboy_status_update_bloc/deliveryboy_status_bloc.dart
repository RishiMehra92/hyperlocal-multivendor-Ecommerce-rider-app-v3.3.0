import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../config/api_base_helper.dart';
import '../../../../config/api_routes.dart';
import '../../../../config/global.dart';
import '../../../../config/helper.dart';
import '../../../../utils/location_tracker.dart';
import '../../repo/deliveryboy_status.dart';
import 'deliveryboy_status_event.dart';
import 'deliveryboy_status_state.dart';

class DeliveryBoyStatusBloc
    extends Bloc<DeliveryBoyStatusEvent, DeliveryBoyStatusState> {
  final LocationTracker _locationTracker = LocationTracker();
  final DeliveryBoyStatusRepo _deliveryBoyStatusRepo = DeliveryBoyStatusRepo();
  bool _isProcessing = false;
  bool _isCheckingApi = false;

  DeliveryBoyStatusBloc() : super(const DeliveryBoyStatusState()) {
    on<SyncInitialStatus>(_onSyncInitialStatus);
    on<CheckApiStatus>(_onCheckApiStatus);
    on<ToggleStatus>(_onToggleStatus);
  }

  @override
  Future<void> close() {
    _locationTracker.stopTracking();
    return super.close();
  }

  Future<void> _onSyncInitialStatus(
    SyncInitialStatus event,
    Emitter<DeliveryBoyStatusState> emit,
  ) async {
    try {
      // Emit the local status immediately
      emit(state.copyWith(status: ApiStatus.success, isOnline: event.isOnline));

      // Start location services if online
      if (event.isOnline) {
        _locationTracker.startTracking();
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: 'Failed to sync initial status: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onCheckApiStatus(
    CheckApiStatus event,
    Emitter<DeliveryBoyStatusState> emit,
  ) async {
    if (_isCheckingApi) {
      return;
    }

    _isCheckingApi = true;

    try {
      await Global.refreshCachedToken();

      Map<String, dynamic> response;

      // First try the profile endpoint
      try {
        response = await ApiBaseHelper.getApi(
          url: ApiRoutes.deliveryBoyProfileApi,
          useAuthToken: true,
          params: {},
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
              'Profile endpoint timed out after 10 seconds',
            );
          },
        );
      } catch (e) {
        // Fallback to status endpoint if profile fails
        response = await ApiBaseHelper.post(
          url: ApiRoutes.deliveryBoyStatusApi,
          useAuthToken: true,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException(
              'Status endpoint also timed out after 5 seconds',
            );
          },
        );
      }

      if (response['success'] == true) {
        bool isOnline = false;
        bool isVerified = true;

        if (response['data'] != null) {
          // Try to get status from different possible locations
          isOnline =
              response['data']?['is_online'] ??
              response['data']?['delivery_boy']?['status'] == 'active' ??
              response['data']?['delivery_boy']?['is_online'] ??
              false;
        }

        emit(
          state.copyWith(
            status: ApiStatus.success,
            isOnline: isOnline,
            isVerified: isVerified,
          ),
        );

        // Update local storage
        await Global.setDeliveryBoyStatus(isOnline);

        // Start/stop location services based on API status
        if (isOnline) {
          _locationTracker.startTracking();
        } else {
          _locationTracker.stopTracking();
        }
      } else {
        // Explicitly check for verification error
        final String? message = response['message'];
        final bool isUnverified =
            message != null &&
            message.toLowerCase().contains('not been verified yet');

        if (isUnverified) {
          emit(
            state.copyWith(
              status: ApiStatus.success,
              isOnline: false,
              isVerified: false,
              message: message,
            ),
          );
          // Also force local status to offline for unverified accounts
          await Global.setDeliveryBoyStatus(false);
          return;
        }

        emit(
          state.copyWith(
            status: ApiStatus.failed,
            message: response['message'] ?? 'Failed to check status',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: 'Failed to check API status: ${e.toString()}',
        ),
      );
    } finally {
      _isCheckingApi = false;
    }
  }

  Future<void> _onToggleStatus(
    ToggleStatus event,
    Emitter<DeliveryBoyStatusState> emit,
  ) async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;

    // Prevent toggling to online if not verified
    if (event.isOnline && !state.isVerified) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          isOnline: false,
          isVerified: false,
          message: 'Your account has not been verified yet.',
        ),
      );
      _isProcessing = false;
      return;
    }

    // Emit loading state immediately for better UX
    emit(state.copyWith(status: ApiStatus.loading));

    try {
      if (event.isOnline) {
        // Going online - simplified process

        double? latitude;
        double? longitude;

        // Try to get location with multiple fallbacks
        try {
          // 1. Check LocationTracker first (if it's already running somehow)
          if (_locationTracker.currentLocation != null) {
            latitude = _locationTracker.currentLocation!.latitude;
            longitude = _locationTracker.currentLocation!.longitude;
          }

          // 2. Request fresh location from Geolocator
          if (latitude == null || longitude == null) {
            // Check if service is enabled
            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (!serviceEnabled) {
              // Service is not enabled, we can't get fresh location here
            } else {
              // Check location permissions
              LocationPermission permissionStatus =
                  await Geolocator.checkPermission();
              if (permissionStatus == LocationPermission.denied) {
                permissionStatus = await Geolocator.requestPermission();
              }

              if (permissionStatus == LocationPermission.whileInUse ||
                  permissionStatus == LocationPermission.always) {
                // Request a FRESH position, not a last known one
                Position position = await Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.high,
                    timeLimit: Duration(seconds: 8),
                  ),
                );
                latitude = position.latitude;
                longitude = position.longitude;
              }
            }
          }
        } catch (e) {
          // Ignored - move to next fallback
        }

        // 3. Fallback: Try to get coordinates from profile/delivery zone center
        if (latitude == null || longitude == null) {
          try {
            await Global.refreshCachedToken();
            final profileResponse = await ApiBaseHelper.getApi(
              url: ApiRoutes.deliveryBoyProfileApi,
              useAuthToken: true,
              params: {},
            ).timeout(const Duration(seconds: 5));

            if (profileResponse['success'] == true &&
                profileResponse['data'] != null) {
              final data = profileResponse['data'];
              final deliveryBoy = data['delivery_boy'];

              if (deliveryBoy != null) {
                // Try direct boy coords first
                latitude = double.tryParse(
                  deliveryBoy['latitude']?.toString() ?? '',
                );
                longitude = double.tryParse(
                  deliveryBoy['longitude']?.toString() ?? '',
                );

                // Fallback to zone center if boy doesn't have fixed coords
                if (latitude == null && deliveryBoy['delivery_zone'] != null) {
                  final zone = deliveryBoy['delivery_zone'];
                  latitude = double.tryParse(
                    zone['center_latitude']?.toString() ?? '',
                  );
                  longitude = double.tryParse(
                    zone['center_longitude']?.toString() ?? '',
                  );
                }
              }
            }
          } catch (profileError) {
            // Last resort: If we still have no coordinates but are going online,
            // we'll try to let the backend handle it or fail there.
          }
        }

        // Final validation before sending to API
        if (latitude == null || longitude == null) {
          emit(
            state.copyWith(
              status: ApiStatus.failed,
              isOnline: false,
              message:
                  'Unable to get your current location. Please check your GPS and try again.',
            ),
          );
          _isProcessing = false;
          return;
        }

        await Global.refreshCachedToken();

        if (Global.userToken == null || Global.userToken!.isEmpty) {
          emit(
            state.copyWith(
              status: ApiStatus.failed,
              message: 'Authentication token is missing. Please login again.',
            ),
          );
          _isProcessing = false;
          return;
        }

        final response = await _deliveryBoyStatusRepo.updateDeliveryBoyStatus(
          isOnline: true,
          latitude: latitude,
          longitude: longitude,
        );

        if (response['success'] == true) {
          // Start location services in background (don't wait for it)
          _startLocationServicesInBackground();

          emit(
            state.copyWith(
              status: ApiStatus.success,
              isOnline: true,
              message: response['message'] ?? 'Status updated successfully',
            ),
          );
          await Global.setDeliveryBoyStatus(true);
        } else {
          emit(
            state.copyWith(
              status: ApiStatus.failed,
              message: response['message'] ?? 'Failed to update status',
            ),
          );
        }
      } else {
        await Global.refreshCachedToken();

        if (Global.userToken == null || Global.userToken!.isEmpty) {
          emit(
            state.copyWith(
              status: ApiStatus.failed,
              message: 'Authentication token is missing. Please login again.',
            ),
          );
          _isProcessing = false;
          return;
        }

        final response = await _deliveryBoyStatusRepo.updateDeliveryBoyStatus(
          isOnline: false,
        );

        if (response['success'] == true) {
          // Stop location services in background (don't wait for it)
          _stopLocationServicesInBackground();

          emit(
            state.copyWith(
              status: ApiStatus.success,
              isOnline: false,
              message: response['message'] ?? 'Status updated successfully',
            ),
          );
          await Global.setDeliveryBoyStatus(false);
        } else {
          emit(
            state.copyWith(
              status: ApiStatus.failed,
              message: response['message'] ?? 'Failed to update status',
            ),
          );
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ApiStatus.failed,
          message: 'Failed to update status: ${e.toString()}',
        ),
      );
    } finally {
      _isProcessing = false;
    }
  }

  // Helper method to start location services in background
  void _startLocationServicesInBackground() {
    Future.microtask(() async {
      try {
        _locationTracker.startTracking();
      } catch (e) {
        //
      }
    });
  }

  // Helper method to stop location services in background
  void _stopLocationServicesInBackground() {
    Future.microtask(() async {
      try {
        _locationTracker.stopTracking();
      } catch (e) {
        //
      }
    });
  }
}
