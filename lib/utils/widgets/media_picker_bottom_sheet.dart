import 'dart:io';
import 'package:hyper_local/utils/extensions/translation_extension.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hyper_local/utils/widgets/custom_bottom_sheet.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';

class MediaPickerBottomSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onFile;

  const MediaPickerBottomSheet({super.key, required this.onCamera, required this.onGallery, required this.onFile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(text: context.tr('selectSource'), fontWeight: FontWeight.bold, fontSize: 18),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption(
                context,
                icon: Icons.camera_alt,
                label: context.tr('camera'),
                onTap: onCamera,
              ),
              _buildOption(
                context,
                icon: Icons.photo_library,
                label: context.tr('gallery'),
                onTap: onGallery,
              ),
              _buildOption(
                context,
                icon: Icons.insert_drive_file,
                label: context.tr('fileSource'),
                onTap: onFile,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Icon(icon, size: 30, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 8),
            CustomText(text: label, fontSize: 13, fontWeight: FontWeight.w500),
          ],
        ),
      ),
    );
  }

  static Future<File?> show(BuildContext context, {bool allowFile = true}) async {
    final ImagePicker picker = ImagePicker();
    File? selectedFile;

    await CustomBottomSheet.show(
      context: context,
      child: MediaPickerBottomSheet(
        onCamera: () async {
          final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
          if (image != null) {
            selectedFile = File(image.path);
          }
          if (context.mounted) Navigator.pop(context);
        },
        onGallery: () async {
          final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
          if (image != null) {
            selectedFile = File(image.path);
          }
          if (context.mounted) Navigator.pop(context);
        },
        onFile: () async {
          PlatformFile? file = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: ['jpg', 'jpeg', 'png'],
          );
          if (file != null && file.path != null) {
            selectedFile = File(file.path!);
          }
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );

    return selectedFile;
  }
}
