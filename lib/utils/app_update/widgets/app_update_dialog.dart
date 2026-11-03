import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';

import 'package:upgrader/upgrader.dart';
import '../model/update_config.dart';

class AppUpdateDialog extends StatefulWidget {
  final UpdateConfig config;
  final bool isForced;
  final VoidCallback onLater;

  const AppUpdateDialog({
    super.key,
    required this.config,
    required this.isForced,
    required this.onLater,
  });

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  late final Upgrader upgrader;

  @override
  void initState() {
    super.initState();
    upgrader = Upgrader(debugLogging: false);
  }

  Future<bool> _isUpdateAvailable() async {
    await upgrader.initialize();
    return upgrader.isUpdateAvailable();
  }

  Future<void> _launchStore() async {
    // Fallback: If URL is empty or invalid, let upgrader handle routing to the App Store/Play Store natively.
    upgrader.sendUserToAppStore();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isForced,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: FutureBuilder<bool>(
            future: _isUpdateAvailable(),
            builder: (context, snapshot) {
              final bool isLoading =
                  snapshot.connectionState == ConnectionState.waiting;
              final bool updateAvailable = snapshot.data ?? false;
              // final bool updateAvailable = true;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    updateAvailable || isLoading
                        ? Icons.system_update
                        : Icons.hourglass_empty,
                    size: 72,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    updateAvailable
                        ? (widget.config.title.isNotEmpty
                            ? widget.config.title
                            : context.tr('updateAvailable'))
                        : context.tr('comingSoonTitle'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    isLoading
                        ? 'Checking for latest version...'
                        : (updateAvailable
                            ? (widget.config.message.isNotEmpty
                                ? widget.config.message
                                : context.tr('forceUpdateDialogMessage'))
                            : context.tr('comingSoonMessage')),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  if (isLoading)
                    const CircularProgressIndicator()
                  else if (updateAvailable)
                    Row(
                      children: [
                        if (!widget.isForced) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onLater,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                context.tr('doItLater'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],

                        Expanded(
                          child: CustomButton(
                            text: context.tr('updateNow'),
                            onPressed: _launchStore,
                          ),
                        ),
                      ],
                    )
                  else
                    // Coming Soon → Only Close button
                    const SizedBox.shrink(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
