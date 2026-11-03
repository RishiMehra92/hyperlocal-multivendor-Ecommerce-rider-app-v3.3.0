import 'package:flutter/material.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../router/app_routes.dart';

class BottomNavBar extends StatefulWidget {
  final Widget child;

  const BottomNavBar({super.key, required this.child});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  static const List<String> _routes = [
    AppRoutes.home,
    AppRoutes.feed,
    AppRoutes.pockets,
    AppRoutes.more,
  ];

  void _onItemTapped(int index) {
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    int selectedIndex = _routes.indexOf(currentRoute);
    if (selectedIndex == -1) selectedIndex = 0;

    return CustomScaffold(
      wantSafeArea: false,
      bottomNavigationBar: myBottomBarWIdget(
        routes: _routes,
        selectedIndex: selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: widget.child,
    );
  }
}

class myBottomBarWIdget extends StatelessWidget {
  final List<String> routes;
  final int selectedIndex;
  final Function(int) onItemTapped; // Passed from parent

  const myBottomBarWIdget({
    super.key,
    required this.routes,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(routes.length, (index) {
            final isSelected = index == selectedIndex;
            final route = routes[index];

            IconData icon;
            String label;

            switch (route) {
              case AppRoutes.home:
                icon = isSelected ? Icons.home : Icons.home_outlined;
                label = context.tr('home');
                break;
              case AppRoutes.feed:
                icon = isSelected ? TablerIcons.bike_filled : TablerIcons.bike;
                label = context.tr('feed');
                break;
              case AppRoutes.pockets:
                icon =
                    isSelected
                        ? TablerIcons.credit_card_filled
                        : TablerIcons.credit_card;
                label = context.tr('pockets');
                break;
              case AppRoutes.more:
                icon =
                    isSelected
                        ? TablerIcons.settings_filled
                        : TablerIcons.settings;
                label = context.tr('settings');
                break;
              default:
                icon = TablerIcons.home;
                label = context.tr('home');
            }

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onItemTapped(index), // Uses the parent's function
                child: Container(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: (isTablet(context: context) ? 14 : 24).sp,
                      ),
                      CustomText(
                        text: label,
                        fontSize: sz(12, seprateTabletSize: 7),
                        fontWeight: FontWeight.w700,
                        color:
                            isSelected
                                ? context.isDarkMode
                                    ? null
                                    : Colors.black
                                : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
