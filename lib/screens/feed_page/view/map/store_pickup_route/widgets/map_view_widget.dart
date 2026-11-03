import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hyper_local/config/constant.dart';

class MapViewWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng initialCenter;
  final List<Polyline> polylines;
  final List<Marker> markers;
  final VoidCallback onMapReady;
  final bool showMapContent;

  const MapViewWidget({
    super.key,
    required this.mapController,
    required this.initialCenter,
    required this.polylines,
    required this.markers,
    required this.onMapReady,
    required this.showMapContent,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15.0, // Increased default zoom for better visibility
        onMapReady: onMapReady,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/'
              'World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: AppConstant.packageName,
        ),
        if (polylines.any((p) => p.points.isNotEmpty))
          PolylineLayer(
            polylines: polylines.where((p) => p.points.isNotEmpty).toList(),
          ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
