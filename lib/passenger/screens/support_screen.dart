import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';

enum _SupportTab { contact, messages, faq, terms }

class PassengerSupportScreen extends StatefulWidget {
  const PassengerSupportScreen({super.key});

  @override
  State<PassengerSupportScreen> createState() => _PassengerSupportScreenState();
}

class _PassengerSupportScreenState extends State<PassengerSupportScreen> {
  _SupportTab _tab = _SupportTab.contact;
  final _subject = TextEditingController();
  final _message = TextEditingController();
  final List<(String, String, String)> _inbox = [
    ('FNT Support', 'Thanks for contacting us — we usually reply within 24 hours.', 'Today'),
  ];

  static const _gold = Color(0xFFC9A227);

  static const _faqs = [
    ('How do I book a ride?', 'Use Book Now or Book Later, set pickup & destination, choose a vehicle, then Confirm.'),
    ('How do I pay?', 'Pay the taximeter fare in cash to your driver at the end of the ride.'),
    ('Can I schedule ahead?', 'Yes — tap Book Later, set date & time, then Schedule ride.'),
    ('What is SOS?', 'SOS alerts FNT dispatch immediately for emergency assistance.'),
  ];

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  void _send() {
    final s = _subject.text.trim();
    final m = _message.text.trim();
    if (s.isEmpty || m.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and message are required')),
      );
      return;
    }
    setState(() {
      _inbox.insert(0, ('You', '$s — $m', 'Just now'));
      _subject.clear();
      _message.clear();
      _tab = _SupportTab.messages;
    });
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sent — reply will appear in Messages')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AppState>().user?.name ?? 'Guest';

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Help & Support', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                  Text('Fife Nearby Taxis · Hi $name', style: const TextStyle(color: PassengerPalette.muted, fontSize: 13)),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TabChip(
                          label: 'Contact',
                          icon: CupertinoIcons.headphones,
                          active: _tab == _SupportTab.contact,
                          onTap: () => setState(() => _tab = _SupportTab.contact),
                        ),
                        const SizedBox(width: 8),
                        _TabChip(
                          label: 'Messages',
                          icon: CupertinoIcons.chat_bubble_2,
                          active: _tab == _SupportTab.messages,
                          onTap: () => setState(() => _tab = _SupportTab.messages),
                        ),
                        const SizedBox(width: 8),
                        _TabChip(
                          label: 'FAQ',
                          icon: CupertinoIcons.question_circle,
                          active: _tab == _SupportTab.faq,
                          onTap: () => setState(() => _tab = _SupportTab.faq),
                        ),
                        const SizedBox(width: 8),
                        _TabChip(
                          label: 'Terms',
                          icon: CupertinoIcons.doc_text,
                          active: _tab == _SupportTab.terms,
                          onTap: () => setState(() => _tab = _SupportTab.terms),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_tab) {
      case _SupportTab.contact:
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            const Icon(CupertinoIcons.headphones, size: 48, color: _gold),
            const SizedBox(height: 10),
            const Text(
              'Contact FNT Support',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Send us a message and our team will respond in your Messages tab, usually within 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: PassengerPalette.muted, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 18),
            const Text('Subject *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: PassengerPalette.muted)),
            const SizedBox(height: 6),
            _SoftField(
              controller: _subject,
              hint: 'e.g. Fare dispute, App issue, General enquiry…',
            ),
            const SizedBox(height: 14),
            const Text('Message *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: PassengerPalette.muted)),
            const SizedBox(height: 6),
            _SoftField(
              controller: _message,
              hint: 'Describe your issue or question in detail…',
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _send,
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Send Message to Support', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OTHER WAYS TO REACH US',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: PassengerPalette.muted),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(CupertinoIcons.mail, size: 16, color: _gold),
                      SizedBox(width: 10),
                      Expanded(child: Text('support@fifenearbytaxis.co.uk', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(CupertinoIcons.phone, size: 16, color: _gold),
                      SizedBox(width: 10),
                      Expanded(child: Text('01592 801 313 (Mon–Fri, 9am–5pm)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      case _SupportTab.messages:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          itemCount: _inbox.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final m = _inbox[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(m.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text(m.$3, style: const TextStyle(fontSize: 11, color: PassengerPalette.muted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(m.$2, style: const TextStyle(height: 1.35, color: PassengerPalette.ink)),
                ],
              ),
            );
          },
        );
      case _SupportTab.faq:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          itemCount: _faqs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final f = _faqs[i];
            return Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                backgroundColor: const Color(0xFFF7F8FA),
                collapsedBackgroundColor: const Color(0xFFF7F8FA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                children: [
                  Text(f.$2, style: const TextStyle(color: PassengerPalette.muted, height: 1.35)),
                ],
              ),
            );
          },
        );
      case _SupportTab.terms:
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: const [
            Text('Terms & Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 10),
            Text(
              'Fife Nearby Taxis provides licensed private hire bookings. Fares are charged by taximeter unless a fixed quote is agreed. Passengers must behave safely and pay the driver at trip end. Scheduled rides may be cancelled per our cancellation policy. Full terms are available on fifenearbytaxis.co.uk.',
              style: TextStyle(height: 1.45, color: PassengerPalette.muted),
            ),
            SizedBox(height: 18),
            Text('Privacy Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 10),
            Text(
              'We use your account details and trip locations only to operate bookings, safety features, and support. We do not sell your personal data. Contact support@fifenearbytaxis.co.uk for data requests.',
              style: TextStyle(height: 1.45, color: PassengerPalette.muted),
            ),
          ],
        );
    }
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFC9A227) : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 14, color: active ? Colors.black : PassengerPalette.muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: active ? Colors.black : PassengerPalette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _SoftField({required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: CupertinoTextField(
        controller: controller,
        maxLines: maxLines,
        minLines: maxLines > 1 ? 4 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        placeholder: hint,
        placeholderStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: PassengerPalette.ink),
        decoration: const BoxDecoration(),
        cursorColor: const Color(0xFFC9A227),
      ),
    );
  }
}
