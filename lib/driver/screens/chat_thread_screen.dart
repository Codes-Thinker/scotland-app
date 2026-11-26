import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../viewmodels/chat_view_model.dart';

/// Single ride conversation (API-backed).
class DriverChatThreadScreen extends StatefulWidget {
  final String threadId;
  const DriverChatThreadScreen({super.key, required this.threadId});

  @override
  State<DriverChatThreadScreen> createState() => _DriverChatThreadScreenState();
}

class _DriverChatThreadScreenState extends State<DriverChatThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  ChatViewModel? _chat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _chat = context.read<ChatViewModel>();
      _chat!.setOpenThread(widget.threadId);
      await _chat!.openThread(widget.threadId);
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _chat?.setOpenThread(null);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(ChatViewModel chat) async {
    final text = _input.text;
    if (text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    final err = await chat.send(widget.threadId, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    _input.clear();
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatViewModel>();
    final thread = chat.threadById(widget.threadId);

                if (thread == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: chat.isLoading
              ? const CircularProgressIndicator()
              : FilledButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      final loc = GoRouterState.of(context).uri.toString();
                      context.go(loc.startsWith('/passenger') ? '/passenger' : '/driver/messages');
                    }
                  },
                  child: const Text('Back'),
                ),
        ),
      );
    }

    final initial = thread.passengerName.isNotEmpty ? thread.passengerName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            chat.setOpenThread(null);
            if (context.canPop()) {
              context.pop();
            } else {
              final loc = GoRouterState.of(context).uri.toString();
              context.go(loc.startsWith('/passenger') ? '/passenger/tracking' : '/driver/messages');
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: PassengerPalette.lime.withValues(alpha: 0.4),
              child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(thread.passengerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const Text(
                    'Ride chat',
                    style: TextStyle(fontSize: 11, color: PassengerPalette.muted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: thread.messages.length,
              itemBuilder: (context, i) {
                final m = thread.messages[i];
                return Align(
                  alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                    decoration: BoxDecoration(
                      color: m.mine ? const Color(0xFFDCF8C6) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(m.mine ? 14 : 4),
                        bottomRight: Radius.circular(m.mine ? 4 : 14),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(m.body, style: const TextStyle(fontSize: 15, height: 1.3)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.time,
                          style: const TextStyle(fontSize: 10, color: PassengerPalette.muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: CupertinoTextField(
                        controller: _input,
                        placeholder: 'Message',
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(),
                        onSubmitted: (_) => _send(chat),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: PassengerPalette.limeDeep,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sending ? null : () => _send(chat),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(CupertinoIcons.paperplane_fill, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
