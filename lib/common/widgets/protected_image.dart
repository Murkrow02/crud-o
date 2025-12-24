import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:crud_o_core/networking/rest/rest_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:futuristic/futuristic.dart';
import 'package:path_provider/path_provider.dart';

class ProtectedImage extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  /// UI options
  final double height;
  final BoxFit fit;
  final Duration maxAge;

  const ProtectedImage({
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.height = 180,
    this.fit = BoxFit.cover,
    this.maxAge = const Duration(days: 30),
  });

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) {
      return Image.memory(imageBytes!, height: height, fit: fit);
    }

    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return const Text('No image url');
    }

    // Key by URL so Futuristic state is NOT reused across different URLs
    // when the parent grid/list reuses elements.
    return Futuristic<Uint8List?>(
      key: ValueKey<String>('protected-image:$url'),
      autoStart: true,
      futureBuilder: () async {
        return PersistentImageCache.getOrFetch(
          url: url,
          fetch: () async {
            try {
              return await RestClient().downloadFileBytesFromUri(Uri.parse(url));
            } catch (e) {
              debugPrint("Failed to download image: $url - $e");
              return null;
            }
          },
          maxAge: maxAge,
        );
      },
      busyBuilder: (context) =>
      const Center(child: CircularProgressIndicator()),
      dataBuilder: (context, Uint8List? downloadedBytes) {
        if (downloadedBytes == null) return const Text('Failed to load image');
        return Image.memory(downloadedBytes, height: height, fit: fit);
      },
    );
  }
}

class PersistentImageCache {
  /// Dedupe concurrent requests for the same URL.
  static final Map<String, Future<Uint8List?>> _inFlight = {};

  static Future<Uint8List?> getOrFetch({
    required String url,
    required Future<Uint8List?> Function() fetch,
    Duration maxAge = const Duration(days: 30),
  }) {
    // If already downloading/reading, await the same future.
    final existing = _inFlight[url];
    if (existing != null) return existing;

    final future = _getOrFetchInternal(url: url, fetch: fetch, maxAge: maxAge)
        .whenComplete(() {
      _inFlight.remove(url);
    });

    _inFlight[url] = future;
    return future;
  }

  static Future<Uint8List?> _getOrFetchInternal({
    required String url,
    required Future<Uint8List?> Function() fetch,
    required Duration maxAge,
  }) async {
    try {
      final dir = await _cacheDir();
      final key = _hashUrl(url);

      final dataFile = File('${dir.path}/$key.bin');
      final metaFile = File('${dir.path}/$key.json');

      // 1) Try cache hit
      if (await dataFile.exists() && await metaFile.exists()) {
        final meta = await _readMeta(metaFile);
        final cachedAt = meta?.cachedAt;

        if (cachedAt != null) {
          final age = DateTime.now().difference(cachedAt);
          if (age <= maxAge) {
            return await dataFile.readAsBytes();
          }
        } else {
          // Meta missing/invalid: treat as expired and refetch
        }
      }

      // 2) Fetch fresh
      final bytes = await fetch();
      if (bytes == null || bytes.isEmpty) return null;

      // 3) Persist to disk (atomic-ish write)
      await _writeAtomic(dataFile, bytes);
      await _writeAtomicString(
        metaFile,
        jsonEncode(_CacheMeta(cachedAt: DateTime.now()).toJson()),
      );

      return bytes;
    } catch (e) {
      debugPrint('PersistentImageCache error for $url: $e');
      return null;
    }
  }

  static String _hashUrl(String url) {
    final digest = sha256.convert(utf8.encode(url));
    return digest.toString();
  }

  static Future<Directory> _cacheDir() async {
    // You can switch to getApplicationSupportDirectory() if you prefer.
    final base = await getTemporaryDirectory();

    final dir = Directory('${base.path}/protected_image_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<_CacheMeta?> _readMeta(File metaFile) async {
    try {
      final raw = await metaFile.readAsString();
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        return _CacheMeta.fromJson(map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeAtomic(File file, Uint8List bytes) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    // Rename is atomic on most filesystems when same volume.
    await tmp.rename(file.path);
  }

  static Future<void> _writeAtomicString(File file, String content) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(file.path);
  }
}

class _CacheMeta {
  final DateTime cachedAt;

  _CacheMeta({required this.cachedAt});

  Map<String, dynamic> toJson() => {
    'cachedAt': cachedAt.toIso8601String(),
  };

  static _CacheMeta? fromJson(Map<String, dynamic> json) {
    final v = json['cachedAt'];
    if (v is String) {
      final dt = DateTime.tryParse(v);
      if (dt != null) return _CacheMeta(cachedAt: dt);
    }
    return null;
  }
}