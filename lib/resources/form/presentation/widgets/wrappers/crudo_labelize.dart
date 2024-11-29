import 'package:flutter/material.dart';

class CrudoLabelize extends StatelessWidget {
  final String label;
  final Widget child;
  final double offset;

  const CrudoLabelize(
      {super.key, required this.label, required this.child, this.offset = 10});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      child,
      Positioned(
          top: -offset,
          left: 10,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          )),
    ]);
  }
}