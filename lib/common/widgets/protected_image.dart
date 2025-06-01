import 'dart:typed_data';

import 'package:crud_o/core/configuration/rest_client_configuration.dart';
import 'package:crud_o/core/networking/rest/rest_client.dart';
import 'package:flutter/material.dart';
import 'package:futuristic/futuristic.dart';

class ProtectedImage extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  ProtectedImage({
    super.key,
    this.imageUrl,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) {
      // If imageBytes are provided, display directly
      return Image.memory(imageBytes!, height: 180);
    }

    // Otherwise, fetch image using imageUrl
    return Futuristic<Uint8List?>(
      autoStart: true,
      futureBuilder: () async {
        try {
          return await RestClient().downloadFileBytesFromUri(Uri.parse(imageUrl!));
        } catch (e) {
          print("Failed to download image: $imageUrl");
          return null;
        }
      },
      busyBuilder: (context) => const Center(child: CircularProgressIndicator()),
      dataBuilder: (context, Uint8List? downloadedBytes) {
        if (downloadedBytes == null) return const Text('Failed to load image');
        return Image.memory(downloadedBytes, height: 180);
      },
    );
  }
}
