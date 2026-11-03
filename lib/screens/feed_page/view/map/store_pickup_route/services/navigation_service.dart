// ignore_for_file: empty_catches

import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import '../../../../model/available_orders.dart';
import '../../../../model/return_orders_list_model.dart' show Pickups;

class NavigationService {
  /// Open Google Maps with navigation to stores
  static Future<void> openGoogleMapsToStores(
    LatLng currentLocation,
    List<RouteDetails> routeDetails,
  ) async {
    try {
      final List<String> storeLocations = [];

      // Collect all store locations (using coordinates where possible, falling back to addresses)
      for (int i = 0; i < routeDetails.length; i++) {
        final store = routeDetails[i];

        // Skip if it's "Customer Location" (shipping address) or doesn't have a store ID
        if (store.storeName?.toLowerCase() != 'customer location' &&
            store.storeId != null) {
          if (store.latitude != null && store.longitude != null) {
            storeLocations.add('${store.latitude},${store.longitude}');
          } else {
            // Build store address as fallback
            final List<String> addressParts = [];
            if (store.address != null && store.address!.isNotEmpty) {
              addressParts.add(store.address!);
            }
            if (store.city != null && store.city!.isNotEmpty) {
              addressParts.add(store.city!);
            }
            if (store.state != null && store.state!.isNotEmpty) {
              addressParts.add(store.state!);
            }
            if (store.zipcode != null && store.zipcode!.isNotEmpty) {
              addressParts.add(store.zipcode!);
            }
            if (store.country != null && store.country!.isNotEmpty) {
              addressParts.add(store.country!);
            }

            if (addressParts.isNotEmpty) {
              storeLocations.add(addressParts.join(', '));
            }
          }
        }
      }

      if (storeLocations.isEmpty) {
        return;
      }

      // Build Google Maps URL
      final origin = '${currentLocation.latitude},${currentLocation.longitude}';
      final destination = storeLocations.first;
      final waypoints = storeLocations.skip(1).join('|');

      String googleMapsUrl;
      if (storeLocations.length == 1) {
        // Single destination
        googleMapsUrl =
            'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=${Uri.encodeComponent(destination)}&travelmode=driving';
      } else {
        // Multiple destinations with waypoints
        googleMapsUrl =
            'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=${Uri.encodeComponent(destination)}&waypoints=${Uri.encodeComponent(waypoints)}&travelmode=driving';
      }

      final uri = Uri.parse(googleMapsUrl);

      // Try to launch with external application mode first
      try {
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) {
            return;
          }
        }
      } catch (e) {}

      // Fallback: Try to launch with in-app mode
      try {
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
          if (launched) {
            return;
          }
        }
      } catch (e) {}

      // Fallback: Try to launch with platform default
      try {
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(uri);
          if (launched) {
            return;
          }
        }
      } catch (e) {}

      // Final fallback: Try to open in web browser
      try {
        final webUri = Uri.parse('https://www.google.com/maps');
        if (await canLaunchUrl(webUri)) {
          final launched = await launchUrl(
            webUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) {
            return;
          }
        }
      } catch (e) {}

      // Try to open the actual navigation URL in browser
      try {
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) {
            return;
          }
        }
      } catch (e) {}

      // Try to open with device's default maps app using geo: scheme
      try {
        final geoUri = Uri.parse(
          'geo:${currentLocation.latitude},${currentLocation.longitude}?q=${Uri.encodeComponent(storeLocations.first)}',
        );
        if (await canLaunchUrl(geoUri)) {
          final launched = await launchUrl(geoUri);
          if (launched) {
            return;
          }
        }
      } catch (e) {}

      // Try to open with device's default maps app using coordinates only
      try {
        final coordUri = Uri.parse(
          'geo:${currentLocation.latitude},${currentLocation.longitude}',
        );
        if (await canLaunchUrl(coordUri)) {
          final launched = await launchUrl(coordUri);
          if (launched) {
            return;
          }
        }
      } catch (e) {}
    } catch (e) {}
  }

  /// Open Google Maps with navigation to shipping address
  static Future<void> openGoogleMapsToShippingAddress(
    LatLng currentLocation,
    String? shippingAddress1,
    String? shippingAddress2,
  ) async {
    try {
      // Build shipping address
      final List<String> addressParts = [];
      if (shippingAddress1 != null && shippingAddress1.isNotEmpty) {
        addressParts.add(shippingAddress1);
      }
      if (shippingAddress2 != null && shippingAddress2.isNotEmpty) {
        addressParts.add(shippingAddress2);
      }

      if (addressParts.isEmpty) {
        return;
      }

      final destination = addressParts.join(', ');
      final origin = '${currentLocation.latitude},${currentLocation.longitude}';

      final googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=${Uri.encodeComponent(destination)}&travelmode=driving';

      final uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {}
    } catch (e) {}
  }

  /// Open Google Maps navigation to a specific destination coordinates
  static Future<void> openDirectionsInGoogleMaps(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  /// Open Google Maps navigation to the shipping address
  static Future<void> navigateToShippingAddress(
    String? address1,
    String? address2,
  ) async {
    final List<String> addressParts = [];
    if (address1 != null && address1.isNotEmpty) {
      addressParts.add(address1);
    }
    if (address2 != null && address2.isNotEmpty) {
      addressParts.add(address2);
    }
    if (addressParts.isEmpty) return;

    final destination = addressParts.join(', ');
    final googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}&travelmode=driving';
    final uri = Uri.parse(googleMapsUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  /// Open Google Maps navigation to the order stores
  static Future<void> navigateToStores(List<RouteDetails> routeDetails) async {
    final List<String> storeLocations = [];
    for (final store in routeDetails) {
      if (store.storeName?.toLowerCase() != 'customer location' &&
          store.storeId != null) {
        if (store.latitude != null && store.longitude != null) {
          storeLocations.add('${store.latitude},${store.longitude}');
        } else {
          final List<String> addressParts = [];
          if (store.address != null && store.address!.isNotEmpty) {
            addressParts.add(store.address!);
          }
          if (store.city != null && store.city!.isNotEmpty) {
            addressParts.add(store.city!);
          }
          if (addressParts.isNotEmpty) {
            storeLocations.add(addressParts.join(', '));
          }
        }
      }
    }
    if (storeLocations.isEmpty) return;

    final destination = storeLocations.first;
    final waypoints = storeLocations.skip(1).join('|');
    String googleMapsUrl;
    if (storeLocations.length == 1) {
      googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}&travelmode=driving';
    } else {
      googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}&waypoints=${Uri.encodeComponent(waypoints)}&travelmode=driving';
    }
    final uri = Uri.parse(googleMapsUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  /// Navigate for the entire order depending on status (Stores vs Shipping Address)
  static Future<void> navigateForOrder(Orders order) async {
    final status = order.status?.toLowerCase() ?? 'assigned';
    final bool isPostPickup =
        status == 'out_for_delivery' ||
        status == 'collected' ||
        status == 'delivered';

    if (!isPostPickup) {
      await navigateToStores(order.deliveryRoute?.routeDetails ?? []);
    } else {
      await navigateToShippingAddress(
        order.shippingAddress1,
        order.shippingAddress2,
      );
    }
  }

  /// Navigate for the entire pickup depending on status (Store vs Shipping Address)
  static Future<void> navigateForPickup(Pickups pickup) async {
    final status = pickup.pickupStatus?.toLowerCase() ?? 'pending';
    final bool isPickedUp =
        status == 'picked_up' || status == 'delivered_to_seller';

    if (isPickedUp) {
      final store = pickup.store;
      if (store != null) {
        final double? lat =
            store.latitude != null
                ? double.tryParse(store.latitude.toString())
                : null;
        final double? lng =
            store.longitude != null
                ? double.tryParse(store.longitude.toString())
                : null;
        if (lat != null && lng != null) {
          await openDirectionsInGoogleMaps(lat, lng);
        } else {
          await navigateToShippingAddress(store.address, null);
        }
      }
    } else {
      final order = pickup.order;
      if (order != null) {
        final double? lat =
            order.shippingLatitude != null
                ? double.tryParse(order.shippingLatitude.toString())
                : null;
        final double? lng =
            order.shippingLongitude != null
                ? double.tryParse(order.shippingLongitude.toString())
                : null;
        if (lat != null && lng != null) {
          await openDirectionsInGoogleMaps(lat, lng);
        } else {
          await navigateToShippingAddress(
            order.shippingAddress1,
            order.shippingAddress2,
          );
        }
      }
    }
  }
}
