import 'dart:typed_data';
import 'package:crud_o/common/widgets/protected_image.dart';
import 'package:crud_o/core/networking/rest/rest_client.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/crudo_file.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_field_wrapper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CrudoFilePicker extends StatefulWidget {
  final CrudoFieldConfiguration config;
  final int maxFilesCount;
  final FilePickCallback? onFilePick;
  final FileRemovedCallback? onFileRemoved;
  const CrudoFilePicker({
    super.key,
    required this.config,
    this.maxFilesCount = 1,
    this.onFilePick,
    this.onFileRemoved,
  });

  @override
  _CrudoFilePickerState createState() => _CrudoFilePickerState();
}

typedef FilePickCallback = void Function(List<CrudoFile> files, void Function() updateFormState);
typedef FileRemovedCallback = void Function(CrudoFile file, int index);

class _CrudoFilePickerState extends State<CrudoFilePicker> {
  final List<CrudoFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadExistingFilesFromFormContext();
  }

  void _loadExistingFilesFromFormContext() {
    var fileUrls =
    context.readFormContext().get(widget.config.name) as List<String?>?;
    if (fileUrls == null) return;

    for (var url in fileUrls) {
      var file = CrudoFile(url: url, source: FileSource.network);
      _selectedFiles.add(file);
    }
  }

  Future<void> _pickFile() async {
    if (_selectedFiles.length >= widget.maxFilesCount) return;

    // Custom callback to pick files
    if(widget.onFilePick != null) {
      widget.onFilePick!(_selectedFiles, _updateFormState);
      return;
    }

    // File picker
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: widget.maxFilesCount > 1,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    // Process files
    for (var file in result.files) {
      if (file.bytes == null) continue;

      Uint8List fileBytes = file.bytes!;
      var newFile = CrudoFile(data: fileBytes, source: FileSource.picker);
      _selectedFiles.add(newFile);
    }

    _updateFormState();
  }

  void _removeFile(int index) {
    var removedFile = _selectedFiles.removeAt(index);
    widget.onFileRemoved?.call(removedFile, index);
    _updateFormState();
  }

  void _updateFormState() {
    context.readFormContext().setFiles(
      widget.config.name,
      _selectedFiles.where((file) => file.source != FileSource.network).toList(),
    );
    setState(() {});
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
            ..._selectedFiles.asMap().entries.map((entry) {
              int index = entry.key;
              var file = entry.value;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    ProtectedImage(
                      imageBytes: file.data,
                      imageUrl: file.url,
                    ),
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
