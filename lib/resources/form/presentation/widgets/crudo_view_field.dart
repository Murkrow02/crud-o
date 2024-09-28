import 'package:flutter/material.dart';

class CrudoViewField extends StatelessWidget {
  final String name;
  final String value;

  const CrudoViewField({
    super.key,
    required this.name,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      width: double.infinity,
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                 // color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20.0,
                ),
              ),
              Text(
                value,
                style:  const TextStyle(
                  fontSize: 16.0,
                 // color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ),
      ),
    );
  }
}