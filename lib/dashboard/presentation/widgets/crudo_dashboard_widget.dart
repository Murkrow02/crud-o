import 'package:flutter/material.dart';
import 'package:smooth_counter/smooth_counter.dart';

class CrudoDashboardWidget extends StatelessWidget {

  final CrudoDashboardWidgetSize size;
  final Widget child;
  const CrudoDashboardWidget({super.key, required this.size, required this.child});
  const CrudoDashboardWidget.half({super.key, required this.child}) : size = CrudoDashboardWidgetSize.half;
  const CrudoDashboardWidget.full({super.key, required this.child}) : size = CrudoDashboardWidgetSize.full;
  const CrudoDashboardWidget.third({super.key, required this.child}) : size = CrudoDashboardWidgetSize.third;


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      width: _getWidth(context),
      height: 150,
      child:   Card(
        child: child
      ),
    );
  }

  double _getWidth(BuildContext context) {
    switch (size) {
      case CrudoDashboardWidgetSize.half:
        return MediaQuery.of(context).size.width / 2;
      case CrudoDashboardWidgetSize.full:
        return MediaQuery.of(context).size.width;
      case CrudoDashboardWidgetSize.third:
        return MediaQuery.of(context).size.width / 3;
    }
  }
}

enum CrudoDashboardWidgetSize {
  half,
  full,
  third,
}
