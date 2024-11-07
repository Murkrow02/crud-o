import 'dart:typed_data';
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
  final RestClient restClient = RestClient();
  final List<CrudoFile> _selectedFiles = [];

  Future<void> _pickFile() async {
    if (_selectedFiles.length >= widget.maxFilesCount) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: widget.maxFilesCount > 1, withData: true);
    if (result != null) {
      setState(() {
        var newFiles = result.files.map((file) => file.bytes!).toList();
        int remainingSpace = widget.maxFilesCount - _selectedFiles.length;
        _selectedFiles.addAll(newFiles.take(remainingSpace).map((file) => CrudoFile(data: file, newFile: true)));
        updateFormState();
      });
    }
  }

  void updateFormState()
  {
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
        child: Futuristic(
          autoStart: true,
          futureBuilder: () async {
            var imageUrls = context.readFormContext().get(widget.config.name);
            for (var imageUrl in imageUrls) {
              try {
                var imageBytes = imageUrl != null
                    ? await restClient.downloadFileBytes(imageUrl)
                    : null;
                if (imageBytes != null && !_selectedFiles.contains(imageBytes)) {
                  _selectedFiles.insert(0, CrudoFile(data: imageBytes, newFile: false));
                  updateFormState();
                }
              } catch (e) {
                // Handle the error (e.g., log it if necessary)
                print("Failed to download image: $imageUrl");
              }
            }
          },
          busyBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
          dataBuilder: (context, _) {
            updateFormState();
            return Row(
              children: [
                ..._selectedFiles.asMap().entries.map((entry) {
                  int index = entry.key;
                  Uint8List? file = entry.value.data;
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        Image.memory(file!, height: 180),
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
            );
          },
        ),
      ),
    );
  }
}


