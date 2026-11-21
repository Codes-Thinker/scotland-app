import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../shared/widgets/confirm_bottom_sheet.dart';

class DriverClientsScreen extends StatelessWidget {
  const DriverClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My Clients', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  Text(
                    '${state.retainedClients} retained · 60s priority window',
                    style: const TextStyle(color: AppPalette.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.groups, color: AppPalette.primary),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.border),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.star, color: Color(0xFFF1C40F)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your clients get you first for 60 seconds when they book. If unavailable, job goes to pool but you keep the client.',
                  style: TextStyle(height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.block, color: AppPalette.danger),
                  SizedBox(width: 8),
                  Text('Blocked Passengers', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage passengers you do not want ride requests from.',
                style: TextStyle(color: AppPalette.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              ...state.clients.map((c) {
                final blocked = state.blocked.contains(c);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      if (blocked) {
                        state.unblockClient(c);
                        return;
                      }
                      final ok = await showConfirmBottomSheet(
                        context,
                        title: 'Block passenger?',
                        message: 'You will not receive ride requests from $c.',
                        cancelLabel: 'Keep',
                        confirmLabel: 'Block',
                        onConfirm: () async => state.blockClient(c),
                      );
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$c blocked')),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.danger,
                      side: const BorderSide(color: AppPalette.danger),
                    ),
                    child: Text(blocked ? 'Unblock' : 'Block'),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
