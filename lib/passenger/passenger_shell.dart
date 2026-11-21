import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../services/app_state.dart';
import '../shared/widgets/brand_logo.dart';
import '../shared/widgets/confirm_actions.dart';
import '../shared/widgets/ios_tab_bar.dart';

class PassengerShell extends StatelessWidget {
  final Widget child;
  const PassengerShell({super.key, required this.child});

  int _index(String loc) {
    if (loc.contains('/scheduled')) return 1;
    if (loc.contains('/trips') || loc.contains('/history')) return 2;
    if (loc.contains('/alerts')) return 3;
    if (loc.contains('/support')) return 4;
    if (loc.contains('/profile')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final i = _index(loc);
    final hideNav = loc.contains('/tracking');
    final state = context.watch<AppState>();
    final name = state.user?.name ?? '';
    final alertCount = state.passengerAlerts.length;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: child,
      bottomNavigationBar: hideNav
          ? null
          : IosTabBar(
              selectedIndex: i.clamp(0, 5),
              activeColor: const Color(0xFFC9A227),
              onTap: (v) {
                switch (v) {
                  case 0:
                    context.go('/passenger');
                  case 1:
                    context.go('/passenger/scheduled');
                  case 2:
                    context.go('/passenger/trips');
                  case 3:
                    context.go('/passenger/alerts');
                  case 4:
                    context.go('/passenger/support');
                  case 5:
                    context.go('/passenger/profile');
                }
              },
              items: [
                const IosTabItem(
                  icon: CupertinoIcons.car,
                  activeIcon: CupertinoIcons.car_detailed,
                  label: 'Book',
                ),
                const IosTabItem(
                  icon: CupertinoIcons.calendar,
                  activeIcon: CupertinoIcons.calendar_today,
                  label: 'Scheduled',
                ),
                const IosTabItem(
                  icon: CupertinoIcons.clock,
                  activeIcon: CupertinoIcons.clock_fill,
                  label: 'History',
                ),
                IosTabItem(
                  icon: CupertinoIcons.bell,
                  activeIcon: CupertinoIcons.bell_fill,
                  label: 'Alerts',
                  badge: alertCount > 0 ? alertCount : null,
                ),
                const IosTabItem(
                  icon: CupertinoIcons.question_circle,
                  activeIcon: CupertinoIcons.question_circle_fill,
                  label: 'Support',
                ),
                const IosTabItem(
                  icon: CupertinoIcons.person,
                  activeIcon: CupertinoIcons.person_fill,
                  label: 'Profile',
                ),
              ],
            ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const BrandLogo(size: 64),
              const SizedBox(height: 12),
              Text('Hi, $name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const Text('Passenger · Scotland', style: TextStyle(color: PassengerPalette.muted)),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(CupertinoIcons.car_detailed),
                title: const Text('Book'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/passenger');
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.calendar),
                title: const Text('Scheduled'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/passenger/scheduled');
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.clock),
                title: const Text('History'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/passenger/trips');
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.exclamationmark_shield, color: AppPalette.danger),
                title: const Text('Emergency SOS'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SOS sent to dispatch (mock)')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.square_arrow_right, color: AppPalette.danger),
                title: const Text('Sign out'),
                onTap: () async {
                  Navigator.pop(context);
                  await confirmLogout(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
