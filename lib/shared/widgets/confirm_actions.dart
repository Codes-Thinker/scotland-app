import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import 'confirm_bottom_sheet.dart';

Future<void> confirmLogout(BuildContext context) async {
  final ok = await showConfirmBottomSheet(
    context,
    title: 'Logout?',
    message: 'Are you sure you want to log out of your account?',
    cancelLabel: 'Stay Logged In',
    confirmLabel: 'Logout',
    onConfirm: () => context.read<AppState>().logout(),
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
        'This permanently removes your local account data and signs you out. '
        'You will need to create a new account to use the app again. This cannot be undone.',
    cancelLabel: 'Keep Account',
    confirmLabel: 'Delete Account',
    onConfirm: () => context.read<AppState>().deleteAccount(),
  );
  if (ok && context.mounted) {
    context.go('/auth/welcome');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deleted')),
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
      context.read<AppState>().cancelBooking();
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
