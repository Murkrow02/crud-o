import 'dart:typed_data';

abstract class CrudoUser
{
  final String name;
  final Uint8List avatar;
  CrudoUser({required this.name, required this.avatar});
}