import 'dart:math' show sin, cos, atan2, sqrt;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../../../model/available_orders.dart';

class MapService {
  static const double _earthRadius = 6371; // Earth's radius in kilometers

  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * pi / 180;

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = _earthRadius * c;

    return distance;
  }

  /// Generate pickup route from current location to stores (excluding customer location)
  static List<LatLng> generatePickupRoutePoints(
    LocationData? currentLocation,
    List<RouteDetails>? routeDetails,
  ) {
    final List<LatLng> routePoints = [];

    final startingPoint = _locationDataToLatLng(currentLocation);
    if (startingPoint != null) {
      routePoints.add(startingPoint);
    }

    if (routeDetails != null && routeDetails.isNotEmpty) {
      // Get all route details except the last one (which is usually the customer)
      // or filter based on storeId
      final stores = getFilteredStores(routeDetails);
      for (final store in stores) {
        final storePoint = _routeDetailToLatLng(store);
        if (storePoint != null) {
          _addPointIfNew(routePoints, storePoint);
        }
      }
    }

    return routePoints;
  }

  /// Generate delivery route from current location/store to customer location
  static List<LatLng> generateDeliveryRoutePoints(
    LocationData? currentLocation,
    List<RouteDetails>? routeDetails, {
    LatLng? storePoint,
  }) {
    final List<LatLng> routePoints = [];

    // If we have a specific starting store point, use it, otherwise use current location
    final startPoint = storePoint ?? _locationDataToLatLng(currentLocation);
    if (startPoint != null) {
      routePoints.add(startPoint);
    }

    if (routeDetails != null && routeDetails.isNotEmpty) {
      // The last item is the customer location
      final customer = routeDetails.last;
      final customerPoint = _routeDetailToLatLng(customer);
      if (customerPoint != null) {
        _addPointIfNew(routePoints, customerPoint);
      }
    }

    return routePoints;
  }

  static LatLng? _locationDataToLatLng(LocationData? locationData) {
    if (!isValidLatLng(locationData?.latitude, locationData?.longitude)) {
      return null;
    }
    return LatLng(locationData!.latitude, locationData.longitude);
  }

  static LatLng? _routeDetailToLatLng(RouteDetails detail) {
    if (!isValidLatLng(detail.latitude, detail.longitude)) return null;
    return LatLng(detail.latitude!, detail.longitude!);
  }

  static bool isValidLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) {
      return false;
    }
    if (lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0) return false;
    return true;
  }

  static void _addPointIfNew(List<LatLng> points, LatLng point) {
    if (points.isEmpty) {
      points.add(point);
      return;
    }

    final last = points.last;
    if (!_arePointsEqual(last, point)) {
      points.add(point);
    }
  }

  static bool _arePointsEqual(
    LatLng a,
    LatLng b, {
    double tolerance = 0.000001,
  }) {
    return (a.latitude - b.latitude).abs() < tolerance &&
        (a.longitude - b.longitude).abs() < tolerance;
  }

  /// Generate curved path between points
  static List<LatLng> generateCurvedPath(
    List<LatLng> routePoints, {
    double curveIntensity = 0.12,
  }) {
    if (routePoints.length < 2) return routePoints;

    final List<LatLng> curvedPoints = [];

    for (int i = 0; i < routePoints.length - 1; i++) {
      final start = routePoints[i];
      final end = routePoints[i + 1];

      // Add start point
      curvedPoints.add(start);

      // Calculate midpoint
      final midLat = (start.latitude + end.latitude) / 2;
      final midLng = (start.longitude + end.longitude) / 2;

      // Calculate perpendicular offset for curve
      final latDiff = end.latitude - start.latitude;
      final lngDiff = end.longitude - start.longitude;

      // Perpendicular vector (swap and negate)
      final perpLat = -lngDiff;
      final perpLng = latDiff;

      // Normalize perpendicular vector
      final perpMagnitude = sqrt(perpLat * perpLat + perpLng * perpLng);
      if (perpMagnitude > 0) {
        final normalizedPerpLat = perpLat / perpMagnitude;
        final normalizedPerpLng = perpLng / perpMagnitude;

        // Apply curve with intensity
        final curveLat = midLat + normalizedPerpLat * curveIntensity;
        final curveLng = midLng + normalizedPerpLng * curveIntensity;

        // Add curved midpoint
        curvedPoints.add(LatLng(curveLat, curveLng));
      }

      // Add end point (will be start of next segment)
      if (i == routePoints.length - 2) {
        curvedPoints.add(end);
      }
    }

    return curvedPoints;
  }

  /// Generate dashed route polylines
  static List<Polyline> generateDashedRoute(List<LatLng> routePoints) {
    final List<Polyline> dashedPolylines = [];

    if (routePoints.length < 2) {
      if (routePoints.isNotEmpty) {
        return [
          Polyline(
            points: routePoints,
            strokeWidth: 1.5, // Very thin lines for elegant appearance
            color: const Color(0xFF059669),
          ),
        ];
      }
      return [];
    }

    // Use straight lines directly (no curves)

    // Create proper dashed lines by breaking the route into segments
    for (int i = 0; i < routePoints.length - 1; i++) {
      final start = routePoints[i];
      final end = routePoints[i + 1];

      // Create multiple small dashes for each segment
      const int numDashes = 8;
      for (int dash = 0; dash < numDashes; dash++) {
        final dashStartFraction = dash / numDashes.toDouble();
        final dashEndFraction =
            (dash + 0.6) / numDashes.toDouble(); // 60% dash, 40% gap

        if (dashEndFraction <= 1.0) {
          final dashStart = _interpolatePoint(start, end, dashStartFraction);
          final dashEnd = _interpolatePoint(start, end, dashEndFraction);

          dashedPolylines.add(
            Polyline(
              points: [dashStart, dashEnd],
              strokeWidth: 3, // Very thin lines for elegant appearance
              color: const Color(0xFF059669),
              strokeCap: StrokeCap.round,
            ),
          );
        }
      }
    }
    return dashedPolylines;
  }

  /// Helper method to interpolate between two points
  static LatLng _interpolatePoint(LatLng start, LatLng end, double fraction) {
    final lat = start.latitude + (end.latitude - start.latitude) * fraction;
    final lng = start.longitude + (end.longitude - start.longitude) * fraction;
    return LatLng(lat, lng);
  }

  /// Build all markers for the map
  static List<Marker> buildPickupMarkers(
    LocationData? currentLocation,
    List<RouteDetails>? routeDetails, {
    double rotation = 0,
    required Function(List<RouteDetails> stores) onStoreTap,
  }) {
    final List<Marker> markers = [];

    // Current location marker (Rider - Blue vehicle)
    if (isValidLatLng(currentLocation?.latitude, currentLocation?.longitude)) {
      markers.add(
        Marker(
          point: LatLng(currentLocation!.latitude, currentLocation.longitude),
          width: 45,
          height: 45,
          child: Transform.rotate(
            angle: rotation * pi / 180,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bike,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    // Group store markers by coordinate (to handle overlapping stores)
    final stores = getFilteredStores(routeDetails);
    final Map<String, List<RouteDetails>> groupedStores = {};
    for (final store in stores) {
      if (isValidLatLng(store.latitude, store.longitude)) {
        final key =
            '${store.latitude!.toStringAsFixed(5)},${store.longitude!.toStringAsFixed(5)}';
        groupedStores.putIfAbsent(key, () => []).add(store);
      }
    }

    // Build one marker per unique coordinate
    groupedStores.forEach((key, storesAtPoint) {
      final firstStore = storesAtPoint.first;
      markers.add(
        Marker(
          point: LatLng(firstStore.latitude!, firstStore.longitude!),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => onStoreTap(storesAtPoint),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.store, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    });

    return markers;
  }

  /// Build delivery markers
  static List<Marker> buildDeliveryMarkers(
    LocationData? currentLocation,
    List<RouteDetails>? routeDetails, {
    double rotation = 0,
  }) {
    final List<Marker> markers = [];

    // Current location marker (Rider - Blue vehicle)
    if (isValidLatLng(currentLocation?.latitude, currentLocation?.longitude)) {
      markers.add(
        Marker(
          point: LatLng(currentLocation!.latitude, currentLocation.longitude),
          width: 45,
          height: 45,
          child: Transform.rotate(
            angle: rotation * pi / 180,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bike,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    // Delivery location marker (Red)
    if (routeDetails != null && routeDetails.isNotEmpty) {
      final customer = routeDetails.last;
      if (customer.latitude != null && customer.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(customer.latitude!, customer.longitude!),
            width: 45,
            height: 45,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  /// Calculate total route distance (current location → store 1 → store 2 → delivery address)
  static double calculateDistanceToStores(
    LocationData? currentLocation,
    List<RouteDetails>? routeDetails,
  ) {
    if (currentLocation == null || routeDetails == null) {
      return 0.0;
    }

    if (routeDetails.isEmpty) {
      return 0.0;
    }

    double totalDistance = 0.0;
    LatLng? previousPoint = LatLng(
      currentLocation.latitude,
      currentLocation.longitude,
    );

    // Calculate distance following the actual route path
    for (int i = 0; i < routeDetails.length; i++) {
      final routePoint = routeDetails[i];

      // Skip if it's "Customer Location" or doesn't have coordinates
      if (routePoint.storeName != null &&
          routePoint.storeName!.toLowerCase() != 'customer location' &&
          routePoint.latitude != null &&
          routePoint.longitude != null) {
        final currentPoint = LatLng(
          routePoint.latitude!,
          routePoint.longitude!,
        );

        // Calculate distance from previous point to current point
        final segmentDistance = calculateDistance(previousPoint!, currentPoint);
        totalDistance += segmentDistance;

        // Update previous point for next iteration
        previousPoint = currentPoint;
      } else {
        //
      }
    }

    // Add distance to delivery address (last item in route details)
    if (routeDetails.isNotEmpty) {
      final deliveryAddress = routeDetails.last;

      if (deliveryAddress.latitude != null &&
          deliveryAddress.longitude != null) {
        final deliveryLatLng = LatLng(
          deliveryAddress.latitude!,
          deliveryAddress.longitude!,
        );
        final deliveryDistance = calculateDistance(
          previousPoint!,
          deliveryLatLng,
        );
        totalDistance += deliveryDistance;
      } else {}
    }

    return totalDistance;
  }

  /// Get filtered stores (excluding Customer Location)
  static List<RouteDetails> getFilteredStores(
    List<RouteDetails>? routeDetails,
  ) {
    if (routeDetails == null) return [];

    return routeDetails
        .where(
          (store) =>
              store.storeName?.toLowerCase() != 'customer location' &&
              store.storeId != null,
        )
        .toList();
  }

  /// Fetch accurate route from OSRM
  static Future<List<LatLng>> fetchAccurateRoute(List<LatLng> points) async {
    // Filter out identical or extremely close consecutive points
    // OSRM fails with HTTP 400 if consecutive waypoints are effectively the same location
    final List<LatLng> validPoints = [];
    for (final p in points) {
      if (validPoints.isEmpty) {
        validPoints.add(p);
      } else {
        // Only add if it's more than 5 meters away from the previous point
        if (calculateDistance(validPoints.last, p) * 1000 > 5.0) {
          validPoints.add(p);
        }
      }
    }

    if (validPoints.length < 2) {
      debugPrint(
        '[OSRM Router] Cannot fetch route: less than 2 distinct points provided after deduplication',
      );
      return validPoints.isNotEmpty ? validPoints : points;
    }

    final String coordinates = validPoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');
    final String url =
        'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=polyline';

    debugPrint('[OSRM Router] Requesting road path route...');
    debugPrint('[OSRM Router] URL: $url');

    try {
      final response = await Dio().get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'HyperlocalRiderApp/1.0',
            'Accept':
                'application/json, application/geo+json, application/gpx+xml, img/basemap, */*; q=0.8',
          },
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['routes'] != null &&
            (data['routes'] as List).isNotEmpty &&
            data['routes'][0]['geometry'] != null) {
          final geometry = data['routes'][0]['geometry'];
          final decodedRoute = _decodeGeometry(geometry);
          if (decodedRoute.isNotEmpty) {
            debugPrint(
              '[OSRM Router] Success: Successfully fetched and decoded road route with ${decodedRoute.length} points',
            );
            return decodedRoute;
          } else {
            debugPrint(
              '[OSRM Router] Warning: OSRM returned success but geometry decoding yielded 0 points',
            );
          }
        } else {
          debugPrint(
            '[OSRM Router] Error: OSRM response body does not contain valid route geometry',
          );
        }
      } else {
        debugPrint(
          '[OSRM Router] Error: OSRM server returned HTTP status code ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint(
        '[OSRM Router] Exception: Failed to fetch road route from OSRM. Error: $e',
      );
    }

    debugPrint(
      '[OSRM Router] Fallback: Falling back to straight-line route coordinates',
    );
    return points;
  }

  static List<LatLng> _decodeGeometry(dynamic geometry) {
    if (geometry is String) {
      return _decodePolyline(geometry);
    }

    if (geometry is Map<String, dynamic>) {
      final coords = geometry['coordinates'];
      if (coords is List && coords.isNotEmpty) {
        return coords
            .where((c) => c is List && c.length >= 2)
            .map((c) {
              final lat = (c[1] as num).toDouble();
              final lng = (c[0] as num).toDouble();
              if (lat.isNaN || lat.isInfinite || lng.isNaN || lng.isInfinite) {
                return null;
              }
              return LatLng(lat, lng);
            })
            .whereType<LatLng>()
            .toList();
      }
    }

    if (geometry is List && geometry.isNotEmpty) {
      return geometry
          .where((c) => c is List && c.length >= 2)
          .map((c) {
            final lat = (c[1] as num).toDouble();
            final lng = (c[0] as num).toDouble();
            if (lat.isNaN || lat.isInfinite || lng.isNaN || lng.isInfinite) {
              return null;
            }
            return LatLng(lat, lng);
          })
          .whereType<LatLng>()
          .toList();
    }

    return [];
  }

  static List<LatLng> _decodePolyline(String encoded) {
    try {
      List<PointLatLng> result = PolylinePoints.decodePolyline(encoded);
      return result
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Calculate the shortest distance from a point to a polyline (set of segments)
  /// Returns distance in meters
  static double minDistanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;
    if (polyline.length == 1) return _distanceInMeters(point, polyline.first);

    double minDistance = double.infinity;

    for (int i = 0; i < polyline.length - 1; i++) {
      final double distance = _distanceToSegment(
        point,
        polyline[i],
        polyline[i + 1],
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// Distance from point P to segment AB in meters
  static double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final double l2 = _sqrDistance(a, b);
    if (l2 == 0.0) return _distanceInMeters(p, a);

    final double t =
        ((p.latitude - a.latitude) * (b.latitude - a.latitude) +
            (p.longitude - a.longitude) * (b.longitude - a.longitude)) /
        l2;

    if (t < 0.0) return _distanceInMeters(p, a);
    if (t > 1.0) return _distanceInMeters(p, b);

    final LatLng projection = LatLng(
      a.latitude + t * (b.latitude - a.latitude),
      a.longitude + t * (b.longitude - a.longitude),
    );

    return _distanceInMeters(p, projection);
  }

  static double _sqrDistance(LatLng a, LatLng b) {
    return (a.latitude - b.latitude) * (a.latitude - b.latitude) +
        (a.longitude - b.longitude) * (a.longitude - b.longitude);
  }

  static double _distanceInMeters(LatLng p1, LatLng p2) {
    return calculateDistance(p1, p2) * 1000; // Convert km to meters
  }

  /// Check if the user is off-route (e.g., > 40 meters away)
  static bool isPointOffRoute(
    LatLng point,
    List<LatLng> route, {
    double thresholdMeters = 40.0,
  }) {
    if (route.isEmpty) return false;
    final double distance = minDistanceToPolyline(point, route);
    return distance > thresholdMeters;
  }

  /// Trims a polyline to start from the current location, discarding passed segments
  static List<LatLng> trimRouteToCurrentLocation(
    LatLng currentLatLng,
    List<LatLng> routePoints,
  ) {
    if (routePoints.length < 2) return routePoints;

    int closestSegmentIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final double distance = _distanceToSegment(
        currentLatLng,
        routePoints[i],
        routePoints[i + 1],
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestSegmentIndex = i;
      }
    }

    // Return current location followed by the remaining points of the route
    final List<LatLng> remaining = [currentLatLng];
    remaining.addAll(routePoints.sublist(closestSegmentIndex + 1));
    return remaining;
  }
}
