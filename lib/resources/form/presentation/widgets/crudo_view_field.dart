import 'package:crud_o/resources/form/data/crudo_field.dart';
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
    return Row(
      children: [
        Expanded(
          child: SizedBox(
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
            ),
          ),
        ),
        if (config.actions.isNotEmpty)
          for (var action in config.actions)
            IconButton(
              icon: Icon(action.icon),
              onPressed: () => action.execute(context),
            ),
      ],
    );
  }
}
