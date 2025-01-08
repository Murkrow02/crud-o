import 'package:flutter/widgets.dart';

class CrudoAppWrapper extends StatelessWidget {
  
  final Widget child;
  const CrudoAppWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
