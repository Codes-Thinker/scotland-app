import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/confirm_bottom_sheet.dart';
import '../../viewmodels/chat_view_model.dart';

/// WhatsApp-style conversation list for the driver (API ride chats).
class DriverMessagesScreen extends StatefulWidget {
  const DriverMessagesScreen({super.key});

  @override
  State<DriverMessagesScreen> createState() => _DriverMessagesScreenState();
}

class _DriverMessagesScreenState extends State<DriverMessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().refreshThreads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatViewModel>();
    final threads = chat.threads;

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chats',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                    ),
                  ),
                  if (chat.unreadCount > 0)
                    TextButton(
                      onPressed: () async {
                        final ok = await showConfirmBottomSheet(
                          context,
                          title: 'Mark all read?',
                          message: 'Clear unread badges on all chat conversations?',
                          cancelLabel: 'Keep',
                          confirmLabel: 'Mark all read',
                          isDestructive: false,
                          onConfirm: () async => chat.markAllRead(),
                        );
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All chats marked read')),
                          );
                        }
                      },
                      child: const Text('Mark all read'),
                    ),
                  IconButton(
                    onPressed: chat.isLoading ? null : () => chat.refreshThreads(),
                    icon: chat.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Messages sync with your active and recent rides',
                style: TextStyle(color: PassengerPalette.muted.withValues(alpha: 0.95), fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: threads.isEmpty
                  ? Center(
                      child: Text(
                        chat.error ?? 'No conversations yet — accept a ride to chat',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: PassengerPalette.muted, fontWeight: FontWeight.w600),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 110),
                      itemCount: threads.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
                      itemBuilder: (context, i) {
                        final t = threads[i];
                        return _ThreadTile(
                          thread: t,
                          onTap: () => context.go('/driver/chat/${t.id}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback onTap;

  const _ThreadTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = thread.passengerName.isNotEmpty ? thread.passengerName[0].toUpperCase() : '?';
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: PassengerPalette.lime.withValues(alpha: 0.35),
        child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              thread.passengerName,
              style: TextStyle(
                fontWeight: thread.unread > 0 ? FontWeight.w800 : FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            thread.time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: thread.unread > 0 ? PassengerPalette.limeDeep : PassengerPalette.muted,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              thread.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: thread.unread > 0 ? const Color(0xFF111827) : PassengerPalette.muted,
                fontWeight: thread.unread > 0 ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (thread.unread > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: PassengerPalette.limeDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${thread.unread}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}
