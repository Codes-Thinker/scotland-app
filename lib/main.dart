import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';

import 'auth/app_router.dart';
import 'core/app_theme.dart';
import 'services/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android: latest renderer so tiles + my-location render reliably.
  if (Platform.isAndroid) {
    final maps = GoogleMapsFlutterPlatform.instance;
    if (maps is GoogleMapsFlutterAndroid) {
      try {
        await maps.initializeWithRenderer(AndroidMapRenderer.latest);
      } catch (_) {
        // Already initialized (hot restart) — ignore.
      }
    }
  }

  final state = AppState();
  await state.restoreSession();
  runApp(FifeNearbyTaxisApp(state: state));
}

class FifeNearbyTaxisApp extends StatefulWidget {
  final AppState state;
  const FifeNearbyTaxisApp({super.key, required this.state});

  @override
  State<FifeNearbyTaxisApp> createState() => _FifeNearbyTaxisAppState();
}

class _FifeNearbyTaxisAppState extends State<FifeNearbyTaxisApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.state);
  }

  @override
  void dispose() {
    widget.state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.state,
      child: MaterialApp.router(
        title: 'Fife Nearby Taxis',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
