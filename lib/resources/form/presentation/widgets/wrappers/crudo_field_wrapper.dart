import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_errorize.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_labelize.dart';
import 'package:flutter/material.dart';

class CrudoFieldWrapper extends StatelessWidget {
  final Widget child;

  const CrudoFieldWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: child),
    );

    // // Do not render
    // if (!config.shouldRenderField(context)) {
    //   return const SizedBox();
    // }
    // //

    //
    // // Render form component
    // return Padding(
    //   key: config.getFieldKey(context),
    //   padding: const EdgeInsets.symmetric(vertical: 10.0),
    //   child: Row(
    //     children: [
    //       Expanded(
    //         child: CrudoErrorize(
    //             error: errorize ? config.getValidationError(context) : null,
    //             child:
    //             CrudoLabelize(label: config.label ?? config.name, child: child)),
    //       ),
    //       if (config.actions.isNotEmpty)
    //         for (var action in config.actions)
    //           IconButton(
    //             icon: Icon(action.icon),
    //             onPressed: () => action.execute(context),
    //           ),
    //     ],
    //   ),
    // );
  }
}
