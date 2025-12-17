import 'dart:typed_data';
import 'package:crud_o_core/networking/rest/rest_client.dart';
import 'package:flutter/material.dart';
import 'package:futuristic/futuristic.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class ProtectedImage extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  const ProtectedImage({
    super.key,
    this.imageUrl,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) {
      return Image.memory(imageBytes!, height: 180);
    }

    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return const Text('No image url');
    }

    return Futuristic<Uint8List?>(
      autoStart: true,
      futureBuilder: () async {
        return PersistentImageCache.getOrFetch(
          url: url,
          fetch: () async {
            try {
              return await RestClient()
                  .downloadFileBytesFromUri(Uri.parse(url));
            } catch (_) {
              debugPrint("Failed to download image: $url");
              return null;
            }
          },
          maxAge: const Duration(days: 30), // tweak as you like
        );
      },
      busyBuilder: (context) =>
      const Center(child: CircularProgressIndicator()),
      dataBuilder: (context, Uint8List? downloadedBytes) {
        if (downloadedBytes == null) return const Text('Failed to load image');
        return Image.memory(downloadedBytes, height: 180);
      },
    );
  }
}

class PersistentImageCache {
  static final Map<String, Future<Uint8List?>> _inFlight = {};

  static String _keyToFileName(String url) {
    final hash = sha1.convert(utf8.encode(url)).toString();
    return '$hash.img';
  }

  static Future<File> _fileForUrl(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/protected_image_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/${_keyToFileName(url)}');
  }

  static Future<Uint8List?> getOrFetch({
    required String url,
    required Future<Uint8List?> Function() fetch,
    Duration maxAge = const Duration(days: 7),
  }) {
    // Deduplicate concurrent calls for same url
    return _inFlight.putIfAbsent(url, () async {
      try {
        final file = await _fileForUrl(url);

        if (await file.exists()) {
          final stat = await file.stat();
          final isFresh = DateTime.now().difference(stat.modified) <= maxAge;
          if (isFresh) {
            return await file.readAsBytes();
          }
        }

        final bytes = await fetch();
        if (bytes != null && bytes.isNotEmpty) {
          // Atomic-ish write
          final tmp = File('${file.path}.tmp');
          await tmp.writeAsBytes(bytes, flush: true);
          await tmp.rename(file.path);
        }
        return bytes;
      } finally {
        _inFlight.remove(url);
      }
    });
  }

  static Future<void> invalidate(String url) async {
    final file = await _fileForUrl(url);
    if (await file.exists()) await file.delete();
  }

  static Future<void> clearAll() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/protected_image_cache');
    if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
  }
}
