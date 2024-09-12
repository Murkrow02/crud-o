import 'package:flutter/material.dart';

class CrudoDashboardWidget extends StatelessWidget {

  final CrudoDashboardWidgetSize size;
  const CrudoDashboardWidget({super.key, required this.size});
  const CrudoDashboardWidget.half({super.key}) : size = CrudoDashboardWidgetSize.half;
  const CrudoDashboardWidget.full({super.key}) : size = CrudoDashboardWidgetSize.full;
  const CrudoDashboardWidget.third({super.key}) : size = CrudoDashboardWidgetSize.third;


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      width: _getWidth(context),
      height: 150,
      child: const Card(
        child: Center(
          child: Text('Widget'),
        ),
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
