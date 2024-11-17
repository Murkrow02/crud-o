import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';

class CrudoTabbedFieldGroup extends StatefulWidget {
  final List<CrudoTabbedField> tabs;

  const CrudoTabbedFieldGroup({super.key, required this.tabs});

  @override
  State<CrudoTabbedFieldGroup> createState() => _CrudoTabbedFieldGroupState();
}

class _CrudoTabbedFieldGroupState extends State<CrudoTabbedFieldGroup> {
  int activeTabIndex = 0;

  // Get tabs headers
  Map<int, Widget> getTabsHeaders() {
    return {for (var i = 0; i < widget.tabs.length; i++) i: Text(widget.tabs[i].label)};
  }

  @override
  Widget build(BuildContext context) {
    // Ensure tabs are not empty
    assert(widget.tabs.isNotEmpty, 'Please provide at least one tab');

    return Column(
      children: [
        CustomSlidingSegmentedControl<int>(
          initialValue: activeTabIndex,
          children: getTabsHeaders(),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          thumbDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(milliseconds: 200),
          onValueChanged: (index) {
            setState(() {
              activeTabIndex = index;
            });
          },
        ),
        IndexedStack(
          index: activeTabIndex,
          children: widget.tabs.map((tab) => tab.child).toList(),
        ),
      ],
    );
  }
}


class CrudoTabbedField {
  final String label;
  final Widget child;

  CrudoTabbedField({required this.label, required this.child});
}
