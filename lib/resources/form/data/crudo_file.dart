import 'dart:typed_data';

class CrudoFile {
  final Uint8List? data;
  final String? url;
  final FileSource source;
  final FileType? type;
  CrudoFile({this.data, this.url, required this.source, this.type});
}

enum FileSource { network, picker, camera }
enum FileType { image, video, audio, document }
