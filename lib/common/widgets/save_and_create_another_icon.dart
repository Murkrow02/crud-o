import 'package:flutter/material.dart';

class SaveAndCreateAnotherIcon extends StatelessWidget {
  const SaveAndCreateAnotherIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      width: 24 * 1.7,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.save,
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                size: 16,
                Icons.add,
              )
            ),
          ),
        ],
      ),
    );
  }
}
