
import 'package:crud_o/resources/form/data/crudo_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_errorize.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_labelize.dart';
import 'package:flutter/material.dart';

class CrudoFieldWrapper extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final Widget child;
  final bool errorize;

  const CrudoFieldWrapper(
      {super.key,
        required this.config,
        required this.child,
        this.errorize = true});

  @override
  Widget build(BuildContext context) {

    // Do not render
    if (!config.shouldRenderField(context)) {
      return const SizedBox();
    }

    // Render form component
    return Padding(
      key: config.getFieldKey(context),
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: CrudoErrorize(
                error: errorize ? config.getValidationError(context) : null,
                child:
                CrudoLabelize(label: config.label ?? config.name, child: child)),
          ),
          if (config.actions.isNotEmpty)
            for (var action in config.actions)
              IconButton(
                icon: Icon(action.icon),
                onPressed: () => action.execute(context),
              ),
        ],
      ),
    );
  }
}
