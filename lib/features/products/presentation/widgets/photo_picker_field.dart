import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../shared/widgets/product_photo.dart';

/// Photo capture/selection field used on the Add/Edit Product form.
///
/// Behavior on cancel (spec requirement): if the user opens the
/// camera or gallery and backs out without picking anything,
/// [ImagePicker] returns null and this widget simply keeps whatever
/// it was already showing (existing photo on edit, or the empty
/// placeholder on create) — no error, no partial state.
class PhotoPickerField extends StatefulWidget {
  const PhotoPickerField({
    super.key,
    required this.onPhotoPicked,
    this.existingPhotoPath,
  });

  /// Called with the raw picked image bytes once the user selects one.
  /// Compression/upload happens later, at Save time, not here — this
  /// widget's only job is capture + preview.
  final ValueChanged<Uint8List> onPhotoPicked;

  /// Storage path of the product's current photo, when editing.
  final String? existingPhotoPath;

  @override
  State<PhotoPickerField> createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends State<PhotoPickerField> {
  Uint8List? _newlyPickedBytes;

  Future<void> _pick(ImageSource source) async {
    Navigator.of(context).pop(); // close the bottom sheet first
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      maxWidth: 2048, // sanity ceiling only; real compression happens later
      imageQuality: 90,
    );
    if (file == null) return; // user cancelled — leave everything as-is
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _newlyPickedBytes = bytes);
    widget.onPhotoPicked(bytes);
  }

  void _openPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text(AppStrings.takePhoto),
              onTap: () => _pick(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text(AppStrings.chooseFromGallery),
              onTap: () => _pick(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNewPhoto = _newlyPickedBytes != null;
    final hasExistingPhoto = widget.existingPhotoPath != null && widget.existingPhotoPath!.isNotEmpty;

    return Center(
      child: Column(
        children: [
          InkWell(
            onTap: _openPicker,
            borderRadius: BorderRadius.circular(16),
            child: hasNewPhoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(_newlyPickedBytes!, width: 140, height: 140, fit: BoxFit.cover),
                  )
                : hasExistingPhoto
                    ? ProductPhoto(path: widget.existingPhotoPath, size: 140, borderRadius: 16)
                    : Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _openPicker,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(
              hasNewPhoto || hasExistingPhoto ? AppStrings.changePhoto : AppStrings.addPhoto,
            ),
          ),
        ],
      ),
    );
  }
}
