import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../core/auth_theme.dart';

/// Shows Camera / Gallery sheet and returns the picked image path, or null if cancelled.
Future<String?> pickDocumentImage(BuildContext context, {String title = 'Upload document'}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PassengerPalette.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose Camera or Gallery',
                style: TextStyle(color: PassengerPalette.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: PassengerPalette.surface,
                leading: const Icon(CupertinoIcons.camera_fill, color: AuthTheme.gold),
                title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Take a new photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: PassengerPalette.surface,
                leading: const Icon(CupertinoIcons.photo_fill_on_rectangle_fill, color: AuthTheme.gold),
                title: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Choose from photos'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: PassengerPalette.muted)),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (source == null) return null;

  final picker = ImagePicker();
  try {
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
    );
    return file?.path;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open camera or gallery. Check permissions.')),
      );
    }
    return null;
  }
}
