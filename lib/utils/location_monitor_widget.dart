import 'package:flutter/material.dart';
import 'package:hyper_local/utils/location_handler.dart';

class LocationMonitor extends StatefulWidget {
  final Widget child;

  const LocationMonitor({super.key, required this.child});

  @override
  State<LocationMonitor> createState() => _LocationMonitorState();
}

class _LocationMonitorState extends State<LocationMonitor>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Use addPostFrameCallback to ensure environment is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        LocationHandler.initialize();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LocationHandler.checkLocationAvailability();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocationHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
