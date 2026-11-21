import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/document_image_picker.dart';

class DriverDocumentsScreen extends StatelessWidget {
  const DriverDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final docs = state.driverDocuments;
    final complete = state.driverDocumentsComplete;
    final missing = state.driverDocumentsMissing;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          const Text(
            'Required documents',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
          const SizedBox(height: 6),
          Text(
            complete
                ? 'All documents verified — you can go online.'
                : 'Upload all $missing remaining document${missing == 1 ? '' : 's'} before going online.',
            style: const TextStyle(color: PassengerPalette.muted, height: 1.35),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: complete ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  complete ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.doc_text,
                  color: complete ? AppPalette.success : AppPalette.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    complete
                        ? 'Account ready for jobs'
                        : 'Driver account requires documents',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: complete ? AppPalette.success : const Color(0xFF9A3412),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.user?.vehicle != null ||
              state.user?.vehiclePlate != null ||
              state.user?.operatingZone != null) ...[
            const SizedBox(height: 14),
            Text(
              [
                if (state.user?.vehicle != null) 'Vehicle: ${state.user!.vehicle}',
                if (state.user?.vehiclePlate != null) 'Plate: ${state.user!.vehiclePlate}',
                if (state.user?.operatingZone != null) 'Zone: ${state.user!.operatingZone}',
              ].join(' · '),
              style: const TextStyle(fontSize: 13, color: PassengerPalette.muted, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 18),
          ...docs.map((d) => _DocTile(doc: d)),
          if (complete) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () => context.go('/driver'),
                style: FilledButton.styleFrom(
                  backgroundColor: PassengerPalette.limeDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Go to jobs', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final DriverDocument doc;
  const _DocTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final (color, label, icon) = switch (doc.status) {
      DriverDocStatus.verified => (AppPalette.success, 'Verified', CupertinoIcons.checkmark_circle_fill),
      DriverDocStatus.pending => (AppPalette.warning, 'Checking…', CupertinoIcons.time),
      DriverDocStatus.missing => (PassengerPalette.muted, 'Required', CupertinoIcons.cloud_upload),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(doc.hint, style: const TextStyle(fontSize: 12, color: PassengerPalette.muted)),
              ],
            ),
          ),
          if (doc.status == DriverDocStatus.verified)
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12))
          else if (doc.status == DriverDocStatus.pending)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: () async {
                final path = await pickDocumentImage(context, title: 'Upload ${doc.title}');
                if (path == null) return;
                await state.uploadDriverDocument(doc.id);
              },
              style: TextButton.styleFrom(
                foregroundColor: PassengerPalette.limeDeep,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}
