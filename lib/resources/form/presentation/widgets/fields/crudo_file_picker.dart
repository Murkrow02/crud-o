import 'dart:typed_data';
import 'package:crud_o/common/widgets/protected_image.dart';
import 'package:crud_o/core/networking/rest/rest_client.dart';
import 'package:crud_o/resources/form/data/crudo_file.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:futuristic/futuristic.dart';
import 'crudo_field.dart';


class CrudoFilePicker extends StatefulWidget {
  final CrudoFieldConfiguration config;
  final int maxFilesCount;

  const CrudoFilePicker({
    super.key,
    required this.config,
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
    var fileUrls = context.readFormContext().get(widget.config.name) as List<String?>?;
    if (fileUrls == null) return;
    for (var url in fileUrls) {
      _displayedImages.add(ProtectedImage(imageUrl: url));
      _selectedFiles.add(CrudoFile(url: url, source: FileSource.network));
    }
  }

  Future<void> _pickFile() async {
    if (_displayedImages.length >= widget.maxFilesCount) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: widget.maxFilesCount > 1,
      withData: true,
    );

    if (result != null) {
      setState(() {
        List<Uint8List> newFiles = result.files.map((file) => file.bytes!).toList();
        for (var file in newFiles) {
          _displayedImages.add(ProtectedImage(imageBytes: file));
          _selectedFiles.add(CrudoFile(data: file, source: FileSource.picker));
        }
        updateFormState();
      });
    }
  }

  void updateFormState() {
    context.readFormContext().setFiles(
      widget.config.name,
      _selectedFiles.where((file) => file.source == FileSource.picker).toList(),
    );
  }

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
                          child: const Icon(Icons.close, size: 16, color: Colors.red),
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
