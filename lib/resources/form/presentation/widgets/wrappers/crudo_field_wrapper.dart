import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_errorize.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_labelize.dart';
import 'package:flutter/material.dart';

class CrudoFieldWrapper extends StatelessWidget {
  final Widget child;

  const CrudoFieldWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
