import 'dart:typed_data';

class CrudoFile {
  final Uint8List? data;
  final String? url;
  final FileSource source;

  CrudoFile({this.data, this.url, required this.source});
}

enum FileSource { network, picker }
