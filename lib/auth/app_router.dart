import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../driver/driver_shell.dart';
import '../driver/screens/alerts_screen.dart';
import '../driver/screens/chat_thread_screen.dart';
import '../driver/screens/documents_screen.dart';
import '../driver/screens/earnings_screen.dart';
import '../driver/screens/history_screen.dart';
import '../driver/screens/jobs_screen.dart';
import '../driver/screens/messages_screen.dart';
import '../driver/screens/profile_screen.dart';
import '../driver/screens/scheduled_screen.dart';
import '../driver/screens/tracking_screen.dart';
import '../passenger/passenger_shell.dart';
import '../passenger/screens/alerts_screen.dart';
import '../passenger/screens/home_screen.dart';
import '../passenger/screens/payments_screen.dart';
import '../passenger/screens/profile_screen.dart';
import '../passenger/screens/scheduled_screen.dart';
import '../passenger/screens/support_screen.dart';
import '../passenger/screens/tracking_screen.dart';
import '../passenger/screens/trips_screen.dart';
import '../services/app_state.dart';
import '../shared/models/models.dart';
import 'auth_choice_screen.dart';
import 'auth_sign_in_screen.dart';
import 'auth_signup_screen.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

GoRouter createRouter(AppState appState) {
  final authRoutes = {
    '/splash',
    '/auth/welcome',
    '/auth/choice',
    '/auth/signin',
    '/auth/login',
    '/auth/signup/passenger',
    '/auth/signup/driver',
  };

  // Always open animated splash first; SplashScreen routes after the animation.
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: appState,
    redirect: (context, state) {
      final loggedIn = appState.isLoggedIn;
      final loc = state.matchedLocation;
      final onAuth = authRoutes.contains(loc) || loc == '/' || loc.startsWith('/auth/signup');

      // Let the splash animation finish — do not redirect away from /splash.
      if (loc == '/splash') return null;

      if (!loggedIn && !onAuth) return '/auth/welcome';
      if (!loggedIn && loc == '/') return '/auth/welcome';
      if (loggedIn &&
          (loc == '/' ||
              loc == '/auth/welcome' ||
              loc == '/auth/choice' ||
              loc == '/auth/signin' ||
              loc == '/auth/login' ||
              loc.startsWith('/auth/signup'))) {
        if (appState.isPassenger) return '/passenger';
        return appState.driverDocumentsComplete ? '/driver' : '/driver/documents';
      }
      if (loggedIn && appState.isPassenger && loc.startsWith('/driver')) return '/passenger';
      if (loggedIn && appState.isDriver && loc.startsWith('/passenger')) return '/driver';
      if (loggedIn &&
          appState.isDriver &&
          !appState.driverDocumentsComplete &&
          loc.startsWith('/driver') &&
          loc != '/driver/documents' &&
          loc != '/driver/profile') {
        return '/driver/documents';
      }
      // Block stale tracking screens after cancel / completion cleanup.
      if (loggedIn && appState.isPassenger && loc == '/passenger/tracking') {
        final phase = appState.ridePhase;
        if (phase == PassengerRidePhase.idle && !appState.tracking) {
          return '/passenger';
        }
      }
      if (loggedIn && appState.isDriver && loc == '/driver/tracking') {
        if (appState.activeRide == null && appState.activeTrip == null) {
          return '/driver';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/', redirect: (context, state) => '/splash'),
      GoRoute(path: '/auth/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/auth/choice', builder: (context, state) => const AuthChoiceScreen()),
      GoRoute(path: '/auth/signin', builder: (context, state) => const AuthSignInScreen()),
      GoRoute(path: '/auth/login', redirect: (context, state) => '/auth/signin'),
      GoRoute(
        path: '/auth/signup/passenger',
        builder: (context, state) => const AuthSignupScreen(role: UserRole.passenger),
      ),
      GoRoute(
        path: '/auth/signup/driver',
        builder: (context, state) => const AuthSignupScreen(role: UserRole.driver),
      ),
      GoRoute(
        path: '/auth/signup',
        redirect: (context, state) =>
            appState.pendingRole == UserRole.driver
                ? '/auth/signup/driver'
                : '/auth/signup/passenger',
      ),
      ShellRoute(
        builder: (context, state, child) => PassengerShell(child: child),
        routes: [
          GoRoute(path: '/passenger', builder: (context, state) => const PassengerHomeScreen()),
          GoRoute(path: '/passenger/scheduled', builder: (context, state) => const PassengerScheduledScreen()),
          GoRoute(path: '/passenger/trips', builder: (context, state) => const PassengerTripsScreen()),
          GoRoute(path: '/passenger/alerts', builder: (context, state) => const PassengerAlertsScreen()),
          GoRoute(path: '/passenger/support', builder: (context, state) => const PassengerSupportScreen()),
          GoRoute(path: '/passenger/payments', builder: (context, state) => const PassengerPaymentsScreen()),
          GoRoute(path: '/passenger/profile', builder: (context, state) => const PassengerProfileScreen()),
          GoRoute(path: '/passenger/tracking', builder: (context, state) => const PassengerTrackingScreen()),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => DriverShell(child: child),
        routes: [
          GoRoute(path: '/driver', builder: (context, state) => const DriverJobsScreen()),
          GoRoute(path: '/driver/tracking', builder: (context, state) => const DriverTrackingScreen()),
          GoRoute(path: '/driver/history', builder: (context, state) => const DriverHistoryScreen()),
          GoRoute(path: '/driver/scheduled', builder: (context, state) => const DriverScheduledScreen()),
          GoRoute(path: '/driver/messages', builder: (context, state) => const DriverMessagesScreen()),
          GoRoute(
            path: '/driver/chat/:id',
            builder: (context, state) => DriverChatThreadScreen(threadId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/driver/earnings', builder: (context, state) => const DriverEarningsScreen()),
          GoRoute(path: '/driver/alerts', builder: (context, state) => const DriverAlertsScreen()),
          GoRoute(path: '/driver/documents', builder: (context, state) => const DriverDocumentsScreen()),
          GoRoute(path: '/driver/profile', builder: (context, state) => const DriverProfileScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.go(appState.isLoggedIn ? '/passenger' : '/auth/welcome'),
          child: Text(appState.isLoggedIn ? 'Go home' : 'Back to login'),
        ),
      ),
    ),
  );
}
