import 'package:crud_o/dashboard/presentation/widgets/crudo_dashboard_widget.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/material.dart';
import 'package:smooth_counter/smooth_counter.dart';

class CrudoCounterWidget extends StatelessWidget {
  final String title;
  final int value;
  final CrudoDashboardWidgetSize size;

  const CrudoCounterWidget(
      {super.key, required this.value, required this.title, required this.size});

  const CrudoCounterWidget.half({super.key, required this.value, required this.title})
      : size = CrudoDashboardWidgetSize.half;

  const CrudoCounterWidget.full({super.key, required this.value, required this.title})
      : size = CrudoDashboardWidgetSize.full;

  const CrudoCounterWidget.third({super.key, required this.value, required this.title})
      : size = CrudoDashboardWidgetSize.third;

  @override
  Widget build(BuildContext context) {
    final themeConfig = CrudoConfiguration.theme();

    return CrudoDashboardWidget(
        size: size,
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: themeConfig.counterWidgetTitleFontSize,
                    color: Theme.of(context).colorScheme.primary)),
            SmoothCounter(
              count: value,
              textStyle: TextStyle(
                  fontSize: themeConfig.counterWidgetValueFontSize,
                  color: Theme.of(context).colorScheme.tertiary),
              duration: themeConfig.counterWidgetAnimationDuration,
            ),
          ],
        )));
  }
}
