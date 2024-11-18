import 'dart:typed_data';
import 'package:crud_o/common/widgets/protected_image.dart';
import 'package:crud_o/core/networking/rest/rest_client.dart';
import 'package:crud_o/resources/form/data/crudo_file.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:futuristic/futuristic.dart';
import 'crudo_field.dart';

class CrudoFilePicker extends StatefulWidget {
  final CrudoFieldConfiguration config;
  final int maxFilesCount;
  final ImageManipulationConfig? imageManipulationConfig;

  const CrudoFilePicker({
    super.key,
    required this.config,
    this.imageManipulationConfig,
    this.maxFilesCount = 1,
  });

  @override
  _CrudoFilePickerState createState() => _CrudoFilePickerState();
}

class _CrudoFilePickerState extends State<CrudoFilePicker> {
  final List<CrudoFile> _selectedFiles = [];
  final List<ProtectedImage> _displayedImages = [];

  @override
  void initState() {
    super.initState();
    // Load images from network URLs and mark as network files
    var fileUrls =
        context.readFormContext().get(widget.config.name) as List<String?>?;
    if (fileUrls == null) return;
    for (var url in fileUrls) {
      _displayedImages.add(ProtectedImage(imageUrl: url));
      _selectedFiles.add(CrudoFile(url: url, source: FileSource.network));
    }
  }

  /// Called whenever a new file is going to be picked
  Future<void> _pickFile() async {
    if (_displayedImages.length >= widget.maxFilesCount) return;

    // Show file picker
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: widget.maxFilesCount > 1,
      withData: true,
    );

    // No file picked
    if (result == null || result.files.isEmpty) return;

    // Process picked files
    var pickedFiles = result.files;
    for (var file in pickedFiles) {
      if (file.bytes == null) continue;

      // Check if need manipulation
      var fileBytes = file.bytes!;
      if(widget.imageManipulationConfig != null) {
        fileBytes = await _manipulateImage(fileBytes, widget.imageManipulationConfig!);
      }

      // Add to preview UI
      _displayedImages.add(ProtectedImage(imageBytes: fileBytes));

      // Add to selected files
      _selectedFiles.add(CrudoFile(data: fileBytes, source: FileSource.picker));
    }

    // Update form state
    setState(() {
      updateFormState();
    });
  }
  
  /// Apply image manipulation to the original image bytes
  Future<Uint8List> _manipulateImage(Uint8List originalImage, ImageManipulationConfig config) async {
    try {
      assert(config.compressionRatio != null && config.compressionRatio! >= 0 &&
          config.compressionRatio! <= 100, 'Ratio must be between 0 and 100');
      return await FlutterImageCompress.compressWithList(
        originalImage,
        //minHeight: 1920,
        //minWidth: 1080,
        quality: config.compressionRatio ?? 100,
        //rotate: 135,
      );
    }
    catch(e){
      print("ERROR: unable to manipulate image");
      return originalImage;
    }
  }

  /// Update the form state with only the actual files selected by the user
  void updateFormState() {
    context.readFormContext().setFiles(
          widget.config.name,
          _selectedFiles
              .where((file) => file.source == FileSource.picker)
              .toList(),
        );
  }

  /// Remove file from the list
  void _removeFile(int index) {
    setState(() {
      // Remove from both lists in sync
      _displayedImages.removeAt(index);
      _selectedFiles.removeAt(index);
      updateFormState();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.config.reactive) {
      throw Exception('CrudoFilePicker does not yet support reactive fields');
    }

    return CrudoFieldWrapper(
      config: widget.config,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ..._displayedImages.asMap().entries.map((entry) {
              int index = entry.key;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    entry.value,
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _removeFile(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 16, color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (_selectedFiles.length < widget.maxFilesCount)
              Expanded(
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _pickFile,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ImageManipulationConfig {
  int? compressionRatio;

  ImageManipulationConfig({this.compressionRatio});
}
