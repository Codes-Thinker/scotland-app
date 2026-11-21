import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../services/app_state.dart';
import '../shared/widgets/brand_logo.dart';
import '../shared/widgets/confirm_actions.dart';
import '../shared/widgets/ios_tab_bar.dart';

/// Driver nav: Jobs · Chat · History · Earnings · Profile.
class DriverShell extends StatelessWidget {
  final Widget child;
  const DriverShell({super.key, required this.child});

  int _index(String loc) {
    if (loc.startsWith('/driver/messages') || loc.startsWith('/driver/chat')) return 1;
    if (loc.startsWith('/driver/history')) return 2;
    if (loc.startsWith('/driver/earnings')) return 3;
    if (loc.startsWith('/driver/profile') ||
        loc.startsWith('/driver/documents') ||
        loc.startsWith('/driver/alerts') ||
        loc.startsWith('/driver/scheduled')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final i = _index(loc);
    final state = context.watch<AppState>();
    final chatBadge = state.unreadMessages;
    final name = state.user?.name ?? '';
    final hideNav = loc.startsWith('/driver/chat/') || loc.startsWith('/driver/tracking');

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: child,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const BrandLogo(size: 64),
              const SizedBox(height: 12),
              Text('Hi, $name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const Text('Driver · Scotland', style: TextStyle(color: PassengerPalette.muted)),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(CupertinoIcons.car_detailed),
                title: const Text('Jobs'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/driver');
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.map),
                title: const Text('Active tracking'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/driver/tracking');
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.calendar),
                title: const Text('Scheduled rides'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/driver/scheduled');
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.clock),
                title: const Text('Ride history'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/driver/history');
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.chat_bubble_2),
                title: const Text('Chat'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/driver/messages');
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.folder),
                title: const Text('Documents'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/driver/documents');
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.person_crop_circle),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/driver/profile');
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
      bottomNavigationBar: hideNav
          ? null
          : IosTabBar(
              selectedIndex: i.clamp(0, 4),
              activeColor: PassengerPalette.limeDeep,
              showLabels: true,
              onTap: (v) {
                switch (v) {
                  case 0:
                    context.go('/driver');
                  case 1:
                    context.go('/driver/messages');
                  case 2:
                    context.go('/driver/history');
                  case 3:
                    context.go('/driver/earnings');
                  case 4:
                    context.go('/driver/profile');
                }
              },
              items: [
                const IosTabItem(
                  icon: CupertinoIcons.car,
                  activeIcon: CupertinoIcons.car_detailed,
                  label: 'Jobs',
                ),
                IosTabItem(
                  icon: CupertinoIcons.chat_bubble,
                  activeIcon: CupertinoIcons.chat_bubble_fill,
                  label: 'Chat',
                  badge: chatBadge > 0 ? chatBadge : null,
                ),
                const IosTabItem(
                  icon: CupertinoIcons.clock,
                  activeIcon: CupertinoIcons.clock_fill,
                  label: 'History',
                ),
                const IosTabItem(
                  icon: CupertinoIcons.money_dollar_circle,
                  activeIcon: CupertinoIcons.money_dollar_circle_fill,
                  label: 'Earnings',
                ),
                const IosTabItem(
                  icon: CupertinoIcons.person_crop_circle,
                  activeIcon: CupertinoIcons.person_crop_circle_fill,
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
