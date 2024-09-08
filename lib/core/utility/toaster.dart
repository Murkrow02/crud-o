import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// This class is used to show toast without context for messages/errors
class Toaster {


  /*
  * Modify global config
  */
  static Alignment _alignment = Alignment.topRight;
  static void setAlignment(Alignment alignment) {
    _alignment = alignment;
  }

  static void show(String message, Color color, IconData icon) {
    toastification.show(
      title: Text(message),
      description: null,
      style: ToastificationStyle.flat,
      icon: Icon(icon),
      alignment: _alignment,
      primaryColor: color,
      showProgressBar: false,
      //applyBlurEffect: true,
      pauseOnHover: true,
      autoCloseDuration: const Duration(seconds: 5),
    );
  }

  static void success(String message) {
    show(message, Colors.green, CupertinoIcons.check_mark_circled);
  }

  static void error(String message) {
    show(message, Colors.red, CupertinoIcons.xmark_circle);
  }

  static void warning(String message) {
    show(message, Colors.orange, CupertinoIcons.exclamationmark_triangle);
  }
  
  static void info(String message) {
    show(message, Colors.blue, CupertinoIcons.info);
  }
}