import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/ride_view_model.dart';
import 'confirm_bottom_sheet.dart';

Future<void> confirmLogout(BuildContext context) async {
  final ok = await showConfirmBottomSheet(
    context,
    title: 'Logout?',
    message: 'Are you sure you want to log out of your account?',
    cancelLabel: 'Stay Logged In',
    confirmLabel: 'Logout',
    onConfirm: () async {
      final auth = context.read<AuthViewModel>();
      final app = context.read<AppState>();
      await auth.logout();
      await app.clearApiSession();
    },
  );
  if (ok && context.mounted) {
    context.go('/auth/welcome');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have been logged out')),
    );
  }
}

Future<void> confirmDeleteAccount(BuildContext context) async {
  final ok = await showConfirmBottomSheet(
    context,
    title: 'Delete Account?',
    message:
        'This signs you out and clears local session data. '
        'Contact support to permanently delete your account on the server.',
    cancelLabel: 'Keep Account',
    confirmLabel: 'Sign Out',
    onConfirm: () async {
      final auth = context.read<AuthViewModel>();
      final app = context.read<AppState>();
      await auth.logout();
      await app.clearApiSession();
    },
  );
  if (ok && context.mounted) {
    context.go('/auth/welcome');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out')),
    );
  }
}

Future<bool> confirmCancelRide(BuildContext context) async {
  final ok = await showConfirmBottomSheet(
    context,
    title: 'Cancel Ride?',
    message: 'Are you sure you want to cancel this ride? This action cannot be undone.',
    cancelLabel: 'Keep Ride',
    confirmLabel: 'Yes, Cancel Ride',
    onConfirm: () async {
      final rides = context.read<RideViewModel>();
      await rides.cancelActiveRide(reason: 'Cancelled by passenger');
    },
  );
  if (ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ride cancelled')),
    );
  }
  return ok;
}

Future<bool> confirmCancelScheduledRide(BuildContext context, String rideId) async {
  final ok = await showConfirmBottomSheet(
    context,
    title: 'Cancel Scheduled Ride?',
    message: 'Are you sure you want to cancel this scheduled ride? This action cannot be undone.',
    cancelLabel: 'Keep Ride',
    confirmLabel: 'Yes, Cancel',
    onConfirm: () async {
      context.read<AppState>().cancelScheduledRide(rideId);
    },
  );
  if (ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scheduled ride cancelled')),
    );
  }
  return ok;
}
