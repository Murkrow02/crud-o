import 'package:flutter/material.dart';

class ConfirmationDialog {

  static Future<bool> ask({
    required BuildContext context,
    required String title,
    required String message,
    String? okText,
    String? cancelText,
  }) async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [

              // Cancel button
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelText ?? 'Annulla',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),

              // Ok button
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(okText ?? 'Ok',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary))),
            ],
          );
        });
  }
}
