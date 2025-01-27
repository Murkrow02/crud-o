import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:flutter/material.dart';

class CrudoViewField extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final Widget child;

  const CrudoViewField({
    super.key,
    required this.config,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.label ?? config.name,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
               // color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20.0,
              ),
            ),
            const SizedBox(height: 5),
            child,
          ],
        ),
      ),
    );
  }
}
