import 'dart:async';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';

import 'package:hyper_local/utils/location_tracker.dart';

class LocationService {
  static final Location _location = Location();

  /// Get current location with timeout
  static Future<LocationData?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      // First, try to use the cached location from LocationTracker
      final trackerLocation = LocationTracker().currentLocation;
      if (trackerLocation != null) {
        return trackerLocation;
      }

      // Check permissions
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
      }

      if (permissionGranted != PermissionStatus.granted &&
          permissionGranted != PermissionStatus.grantedLimited) {
        return null;
      }

      // Get current location with timeout
      LocationData? locationData;
      try {
        locationData = await _location.getLocation().timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('Location request timed out');
          },
        );
      } catch (e) {
        locationData = null;
      }

      return locationData;
    } catch (e) {
      return null;
    }
  }

  /// Request location permission and service explicitly
  static Future<bool> requestPermissionAndService() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return false;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
      }

      return permissionGranted == PermissionStatus.granted ||
          permissionGranted == PermissionStatus.grantedLimited;
    } catch (e) {
      return false;
    }
  }

  /// Convert LocationData to LatLng
  static LatLng? locationDataToLatLng(LocationData? locationData) {
    if (locationData?.latitude != null &&
        locationData?.longitude != null &&
        !locationData!.latitude.isNaN &&
        !locationData.latitude.isInfinite &&
        !locationData.longitude.isNaN &&
        !locationData.longitude.isInfinite) {
      return LatLng(locationData.latitude, locationData.longitude);
    }
    return null;
  }

  /// Get destination location from route details
  static LatLng? getDestinationLocation(List<dynamic>? routeDetails) {
    if (routeDetails != null && routeDetails.isNotEmpty) {
      final lastIndex = routeDetails.length - 1;
      final shippingAddress = routeDetails[lastIndex];

      if (shippingAddress.latitude != null &&
          shippingAddress.longitude != null) {
        return LatLng(shippingAddress.latitude!, shippingAddress.longitude!);
      }
    }
    return null;
  }

  /// Get location stream
  static Stream<LocationData> getLocationStream() {
    // Basic configuration for the stream
    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000, // 1 second
      distanceFilter: 0, // 0 meters for instant updates and stationary testing
    );
    return _location.onLocationChanged;
  }
}
