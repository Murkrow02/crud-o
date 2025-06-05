import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:crud_o/common/widgets/protected_image.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/crudo_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'crudo_file_picker.dart';

class CrudoImagePicker extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final int maxImagesCount;
  final ImageManipulationConfig? imageManipulationConfig;
  const CrudoImagePicker({
    super.key,
    required this.config,
    this.maxImagesCount = 1,
    this.imageManipulationConfig,
  });

  /// Compress the image using the provided compression ratio
  Future<Uint8List> _compressImage(Uint8List fileBytes) async {
    try {
      assert(imageManipulationConfig == null || (imageManipulationConfig!.compressionRatio! >= 0 && imageManipulationConfig!.compressionRatio! <= 100),
      'Compression ratio must be between 0 and 100');
      return await FlutterImageCompress.compressWithList(
        fileBytes,
        quality: imageManipulationConfig!.compressionRatio ?? 100,
      );
    } catch (e) {
      debugPrint("ERROR: Unable to compress image");
      return fileBytes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CrudoFilePicker(
      config: config,
      maxFilesCount: maxImagesCount,
      onFilePick:
          Platform.isAndroid || Platform.isIOS ? (files,updateFieldState) => _pickImage(context, files, updateFieldState) : null,
    );
  }

  void _pickImage(BuildContext context, List<CrudoFile> files, void Function() updateFieldState) async {
    final ImagePicker picker = ImagePicker();

    // Request user if they want to pick image from camera or gallery
    final bool fromGallery = await _requestFileFromCameraOrGallery(context);

    // Act based on user's choice
    XFile? file;
    if (fromGallery) {
      file = await picker.pickImage(source: ImageSource.gallery);
    } else {
      file = await picker.pickImage(source: ImageSource.camera);
    }
    if (file == null) return;

    // Get bytes, compress and add to final list
    final Uint8List fileBytes = await file.readAsBytes();
    final Uint8List compressedFileBytes = await _compressImage(fileBytes);
    files.add(CrudoFile(
      source: fromGallery ? FileSource.picker : FileSource.camera,
      data: compressedFileBytes,
      type: FileType.image,
    ));

    updateFieldState();
  }

  Future<bool> _requestFileFromCameraOrGallery(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:  Row(
            children: [
              Icon(Icons.image),
              const SizedBox(width: 10),
              Text(config.label ?? config.name)
            ],
          ),
          content: const Text('Come vuoi selezionare l\'immagine?',textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.photo_library),
              label: const Text('Galleria'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Fotocamera'),
            ),
          ],
        );
      },
    );
  }
}

class ImageManipulationConfig {
  int? compressionRatio;
  ImageManipulationConfig({this.compressionRatio});
}