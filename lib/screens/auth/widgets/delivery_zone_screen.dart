import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import '../../../utils/widgets/loading_widget.dart';
import '../../../config/helper.dart';
import '../../../utils/widgets/custom_button.dart';
import '../../../utils/widgets/custom_text.dart';

import '../bloc/delivery_zone_bloc/delivery_zone_bloc.dart';
import '../bloc/delivery_zone_bloc/delivery_zone_event.dart';
import '../bloc/delivery_zone_bloc/delivery_zone_state.dart';

class DeliveryZoneScreen extends StatefulWidget {
  const DeliveryZoneScreen({super.key});

  @override
  State<DeliveryZoneScreen> createState() => _DeliveryZoneScreenState();
}

class _DeliveryZoneScreenState extends State<DeliveryZoneScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Trigger initial fetch
    context.read<DeliveryZoneBloc>().add(const FetchDeliveryZones());
    // Add scroll listener for load settings
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (isBottom(_scrollController)) {
      context.read<DeliveryZoneBloc>().add(const LoadMoreDeliveryZones());
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        title: CustomText(text: context.tr('deliveryZones')),
      ),
      body: BlocBuilder<DeliveryZoneBloc, DeliveryZoneState>(
        builder: (context, state) {
          if (state.fetchStatus == ApiStatus.initial) {
            return Center(
              child: CustomText(text: context.tr('pleaseWait')),
            );
          } else if (state.fetchStatus == ApiStatus.loading) {
            return const Center(child: LoadingWidget());
          } else if (state.fetchStatus == ApiStatus.success) {
            if (state.deliveryZones.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 24),
                      CustomText(
                        text:
                            context.tr('noDeliveryZonesAvailable', fallback: "No delivery zones available"),
                        textAlign: TextAlign.center,

                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 12),
                      CustomText(
                        text:
                            context.tr('deliveryZonesNotConfigured', fallback: "Delivery zones have not been configured yet."),
                        textAlign: TextAlign.center,

                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: context.tr('retry'),
                        onPressed: () {
                          context.read<DeliveryZoneBloc>().add(
                            const FetchDeliveryZones(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 20),
              controller: _scrollController,
              itemCount:
                  state.hasReachedMax
                      ? state.deliveryZones.length
                      : state.deliveryZones.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.deliveryZones.length) {
                  // Show loading indicator at the bottom when loading settings
                  return const Center(child: LoadingWidget());
                }
                final zone = state.deliveryZones[index];

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.location_on_rounded),
                    title: CustomText(text: zone.name ?? ""),
                    trailing:
                        state.selectedZone?.id == zone.id
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                    onTap: () {
                      context.read<DeliveryZoneBloc>().add(
                        SelectDeliveryZone(selectedZone: zone),
                      );

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        context.pop(zone);
                      });
                    },
                  ),
                );
              },
            );
          } else if (state.fetchStatus == ApiStatus.failed) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    text: context.tr('errorPrefix', positionalArgs: [state.message]),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: context.tr('retry'),
                    onPressed: () {
                      context.read<DeliveryZoneBloc>().add(
                        const FetchDeliveryZones(),
                      );
                    },
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
