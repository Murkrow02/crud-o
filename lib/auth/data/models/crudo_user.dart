import 'dart:typed_data';

abstract class CrudoUser
{
   String getName();
   Future<Uint8List> getAvatar();
}