import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../data/models/auth_models.dart';
import '../../services/app_state.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/document_image_picker.dart';
import '../../viewmodels/auth_view_model.dart';

class DriverDocumentsScreen extends StatefulWidget {
  const DriverDocumentsScreen({super.key});

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  List<DriverDocumentDto>? _remote;
  bool _loading = true;
  String? _error;
  String? _uploading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await context.read<AuthViewModel>().fetchDocuments();
      if (!mounted) return;
      setState(() {
        _remote = docs;
        _loading = false;
      });
      final allVerified = docs.isNotEmpty && docs.every((d) => d.status == 'verified');
      if (allVerified) {
        for (final d in docs) {
          // ignore: unawaited_futures
          context.read<AppState>().uploadDriverDocument(d.type);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
        _remote = null;
      });
    }
  }

  Future<void> _upload(DriverDocumentDto doc) async {
    final path = await pickDocumentImage(context, title: 'Upload ${_title(doc.type)}');
    if (!mounted || path == null) return;
    setState(() => _uploading = doc.type);
    final err = await context.read<AuthViewModel>().uploadDocument(
          type: doc.type,
          filePath: path,
        );
    if (!mounted) return;
    setState(() => _uploading = null);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await context.read<AppState>().uploadDriverDocument(doc.type);
    await _load();
  }

  String _title(String type) {
    switch (type) {
      case 'licence':
        return "Driver's Licence";
      case 'council_licence':
        return 'Council License';
      case 'council_plate':
        return 'Council Vehicle Plate Number';
      case 'insurance':
        return 'Car Insurance Document';
      case 'v5c':
        return 'Vehicle Registration Document';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final complete = state.driverDocumentsComplete;
    final docs = _remote;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
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
                  : 'Upload documents now. Admin verification is required before going online.',
              style: const TextStyle(color: PassengerPalette.muted, height: 1.35),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppPalette.danger)),
              TextButton(onPressed: _load, child: const Text('Retry')),
              const SizedBox(height: 12),
              // Offline / API down fallback to local list
              ...state.driverDocuments.map((d) => _LocalDocTile(doc: d)),
            ] else if (docs != null)
              ...docs.map(
                (d) => _ApiDocTile(
                  doc: d,
                  title: _title(d.type),
                  uploading: _uploading == d.type,
                  onUpload: () => _upload(d),
                ),
              ),
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
      ),
    );
  }
}

class _ApiDocTile extends StatelessWidget {
  final DriverDocumentDto doc;
  final String title;
  final bool uploading;
  final VoidCallback onUpload;

  const _ApiDocTile({
    required this.doc,
    required this.title,
    required this.uploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (doc.status) {
      'verified' => (AppPalette.success, 'Verified', CupertinoIcons.checkmark_circle_fill),
      'pending' => (AppPalette.warning, 'Pending review', CupertinoIcons.time),
      'expired' => (AppPalette.danger, 'Expired', CupertinoIcons.exclamationmark_circle),
      _ => (PassengerPalette.muted, 'Required', CupertinoIcons.cloud_upload),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (doc.status == 'verified')
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12))
          else if (uploading || doc.status == 'pending')
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: onUpload,
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

class _LocalDocTile extends StatelessWidget {
  final DriverDocument doc;
  const _LocalDocTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
