import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';

import 'auth/app_router.dart';
import 'core/app_theme.dart';
import 'core/network/realtime_client.dart';
import 'services/app_state.dart';
import 'shared/models/models.dart';
import 'viewmodels/alerts_view_model.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/chat_view_model.dart';
import 'viewmodels/earnings_view_model.dart';
import 'viewmodels/ride_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    final maps = GoogleMapsFlutterPlatform.instance;
    if (maps is GoogleMapsFlutterAndroid) {
      try {
        await maps.initializeWithRenderer(AndroidMapRenderer.latest);
      } catch (_) {}
    }
  }

  final auth = AuthViewModel();
  final appState = AppState();
  await auth.restoreSession();
  if (auth.isLoggedIn && auth.user != null) {
    final u = auth.user!;
    final role = auth.sessionRole ?? UserRole.passenger;
    await appState.syncFromApiAuth(
      id: u.id,
      name: u.name,
      email: u.email,
      phone: u.phone,
      role: role,
      vehicle: u.driver?.vehicleMakeModel,
      vehiclePlate: u.driver?.vehiclePlate,
      operatingZone: u.driver?.operatingZone,
      documentsComplete: role == UserRole.passenger,
    );
  } else {
    await appState.restoreSession();
  }

  final realtime = RealtimeClient(auth.repository.client);
  auth.repository.client.onTokensRefreshed = (_) async {
    await realtime.reconnectWithFreshToken();
  };

  final chat = ChatViewModel(auth: auth, appState: appState, realtime: realtime);
  final alerts = AlertsViewModel(auth: auth, appState: appState, realtime: realtime);
  final earnings = EarningsViewModel(auth: auth, appState: appState);
  final rides = RideViewModel(
    auth: auth,
    appState: appState,
    realtime: realtime,
    chat: chat,
  );

  runApp(
    ScotlandApp(
      auth: auth,
      appState: appState,
      rides: rides,
      chat: chat,
      alerts: alerts,
      earnings: earnings,
      realtime: realtime,
    ),
  );
}

class ScotlandApp extends StatefulWidget {
  final AuthViewModel auth;
  final AppState appState;
  final RideViewModel rides;
  final ChatViewModel chat;
  final AlertsViewModel alerts;
  final EarningsViewModel earnings;
  final RealtimeClient realtime;

  const ScotlandApp({
    super.key,
    required this.auth,
    required this.appState,
    required this.rides,
    required this.chat,
    required this.alerts,
    required this.earnings,
    required this.realtime,
  });

  @override
  State<ScotlandApp> createState() => _ScotlandAppState();
}

class _ScotlandAppState extends State<ScotlandApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.appState, widget.auth);
  }

  @override
  void dispose() {
    widget.rides.dispose();
    widget.chat.dispose();
    widget.alerts.dispose();
    widget.earnings.dispose();
    widget.realtime.dispose();
    widget.appState.dispose();
    widget.auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.auth),
        ChangeNotifierProvider.value(value: widget.appState),
        ChangeNotifierProvider.value(value: widget.rides),
        ChangeNotifierProvider.value(value: widget.chat),
        ChangeNotifierProvider.value(value: widget.alerts),
        ChangeNotifierProvider.value(value: widget.earnings),
        Provider.value(value: widget.realtime),
      ],
      child: MaterialApp.router(
        title: 'Scotland',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
