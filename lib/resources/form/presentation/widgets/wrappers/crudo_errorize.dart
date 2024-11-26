import 'package:flutter/material.dart';

class CrudoErrorize extends StatelessWidget {
  final String? error;
  final Widget child;

  const CrudoErrorize({super.key, required this.error, required this.child});

  @override
  Widget build(BuildContext context) {
    if (error == null || error!.isEmpty) {
      return child;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
          child: Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
