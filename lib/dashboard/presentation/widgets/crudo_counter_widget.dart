import 'package:crud_o/dashboard/presentation/widgets/crudo_dashboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:smooth_counter/smooth_counter.dart';

class CrudoCounterWidget extends StatelessWidget {
  final String title;
  final int value;
  final CrudoDashboardWidgetSize size;

  CrudoCounterWidget(
      {required this.value, required this.title, required this.size});

  CrudoCounterWidget.half({required this.value, required this.title})
      : size = CrudoDashboardWidgetSize.half;

  CrudoCounterWidget.full({required this.value, required this.title})
      : size = CrudoDashboardWidgetSize.full;

  CrudoCounterWidget.third({required this.value, required this.title})
      : size = CrudoDashboardWidgetSize.third;

  @override
  Widget build(BuildContext context) {
    return CrudoDashboardWidget(
        size: size,
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title),
            SmoothCounter(
              count: value,
              textStyle: TextStyle(
                  fontSize: 50, color: Theme.of(context).colorScheme.tertiary),
              duration: Duration(milliseconds: 2000),
            ),
          ],
        )));
  }
}
