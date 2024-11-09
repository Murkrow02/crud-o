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

  FINISCI QUA CHE NON FUNZIONA PIU NIENTE GIUSTAMENTE
  @override
  void initState() {
    // Create ProtectedImage widgets for each file URL
    var fileUrls = context.readFormContext().get(widget.config.name) as List<String?>;
    _displayedImages.addAll(fileUrls.map((file) => ProtectedImage(imageUrl: file)));
    super.initState();
  }

  /// Called when the user picks a file from the file picker
  Future<void> _pickFile() async {
    if (_selectedFiles.length >= widget.maxFilesCount) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: widget.maxFilesCount > 1,
        withData: true
    );
    if (result != null) {
      setState(() {
        var newFiles = result.files.map((file) => file.bytes!).toList();
        int remainingSpace = widget.maxFilesCount - _selectedFiles.length;
        _selectedFiles.addAll(newFiles.take(remainingSpace).map((file) => CrudoFile(data: file)));
        updateFormState();
      });
    }
  }



  void updateFormState() {
    context.readFormContext().setFiles(widget.config.name, _selectedFiles);
  }

  void _removeFile(int index) {
    setState(() {
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

