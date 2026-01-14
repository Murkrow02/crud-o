import 'package:crud_o_core/configuration/crudo_theme_config.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:crud_o_core/resources/resource_context.dart';
import 'package:crud_o_core/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';

/// A field that repeats n times a child form with modern styling.
/// Uses theme configuration for consistent styling.
class CrudoRepeaterField extends StatefulWidget {
  final CrudoFieldConfiguration config;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int initialItemCount;
  final bool autoFlattenData;
  final bool showAddButton;
  final Decoration? containerDecoration;
  final CrudoRepeaterController? controller;
  final String addButtonLabel;

  const CrudoRepeaterField({
    super.key,
    required this.config,
    required this.itemBuilder,
    this.initialItemCount = 1,
    this.autoFlattenData = true,
    this.showAddButton = true,
    this.containerDecoration,
    this.controller,
    this.addButtonLabel = 'Add item',
  });

  @override
  _CrudoRepeaterFieldState createState() => _CrudoRepeaterFieldState();
}

class _CrudoRepeaterFieldState extends State<CrudoRepeaterField> {
  int _itemsCount = 0;

  @override
  void initState() {
    super.initState();

    widget.controller?.bind(this);

    _itemsCount = context.readResourceContext().getCurrentOperationType() ==
            ResourceOperationType.view
        ? 0
        : (context.readFormContext().get('${widget.config.name}_count')
                as int? ??
            widget.initialItemCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    var alreadyFlattened = context.readFormContext().getExtra(
        '${widget.config.name}_flattened');

    if ((widget.autoFlattenData && alreadyFlattened == null) ||
        !alreadyFlattened) {
      var flattenedData = _autoFlattenData();
      flattenedData.forEach((key, value) {
        context.readFormContext().set(key, value);
      });
      context
          .readFormContext()
          .setExtra('${widget.config.name}_flattened', true);
    }

    final borderColor = theme.repeaterBorderColor ??
        colorScheme.outline.withOpacity(0.25);
    final backgroundColor = theme.repeaterBackgroundColor ??
        colorScheme.surface.withOpacity(0.5);

    return CrudoField(
      config: widget.config.copyWith(name: '${widget.config.name}_count'),
      viewModeBuilder: (context) => CrudoViewField(
          config: widget.config, child: _buildRepeaterItems(context)),
      editModeBuilder: (context, onChanged) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: widget.containerDecoration ??
              BoxDecoration(
                color: backgroundColor,
                border: Border.all(
                  color: borderColor,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(theme.repeaterBorderRadius),
              ),
          child: Column(
            children: [
              _buildRepeaterItems(context),
              if (widget.showAddButton && widget.config.shouldEnableField(context)) ...[
                const SizedBox(height: 12),
                _buildAddButton(context, theme, colorScheme),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, CrudoThemeConfig theme, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _addRepeaterItem,
        borderRadius: BorderRadius.circular(theme.fieldBorderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(theme.fieldBorderRadius),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.addButtonLabel,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepeaterItems(BuildContext context) {
    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    if (_itemsCount == 0 && widget.config.placeholder != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 32,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                widget.config.placeholder!,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _itemsCount,
      separatorBuilder: (context, index) => Divider(
        height: 24,
        color: colorScheme.outline.withOpacity(0.15),
      ),
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: widget.itemBuilder(context, index),
            ),
            if (context.readResourceContext().getCurrentOperationType() !=
                    ResourceOperationType.view &&
                widget.config.shouldEnableField(context))
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: _buildRemoveButton(context, index, theme, colorScheme),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRemoveButton(BuildContext context, int index, CrudoThemeConfig theme, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _removeRepeaterItem(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: theme.repeaterRemoveButtonSize,
          height: theme.repeaterRemoveButtonSize,
          decoration: BoxDecoration(
            color: colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 16,
            color: colorScheme.error,
          ),
        ),
      ),
    );
  }

  void _addRepeaterItem() {
    setState(() {
      _itemsCount++;
      context.readFormContext().set('${widget.config.name}_count', _itemsCount);
      widget.config.onChanged?.call(context, _itemsCount);
    });
  }

  void _removeRepeaterItem(int index) {
    var searchKey = '${widget.config.name}[$index].';
    var keysToRemove = context
        .readFormContext()
        .getFormData()
        .keys
        .where((key) => key.startsWith(searchKey))
        .toList();

    for (var key in keysToRemove) {
      context.readFormContext().unset(key);
    }

    for (int i = index + 1; i < _itemsCount; i++) {
      var oldKeyPrefix = '${widget.config.name}[$i].';
      var newKeyPrefix = '${widget.config.name}[${i - 1}].';

      var keysToUpdate = context
          .readFormContext()
          .getFormData()
          .keys
          .where((key) => key.startsWith(oldKeyPrefix))
          .toList();

      for (var key in keysToUpdate) {
        var newKey = key.replaceFirst(oldKeyPrefix, newKeyPrefix);
        var oldValue = context.readFormContext().get(key);
        context.readFormContext().set(newKey, oldValue);
        context.readFormContext().unset(key);
      }
    }

    setState(() {
      _itemsCount--;
      context.readFormContext().set('${widget.config.name}_count', _itemsCount);
      widget.config.onChanged?.call(context, _itemsCount);
    });
  }

  Map<String, dynamic> _autoFlattenData() {
    var key = widget.config.name;
    var items = context.readFormContext().get(key);

    context.readFormContext().unset(key);
    if (items == null || items is! List || items.isEmpty) {
      return {};
    }

    var flattenedData = <String, dynamic>{};
    void flatten(dynamic value, String currentKey) {
      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          var listItem = value[i];
          var newKey = '$currentKey[$i]';

          if (listItem is Map<String, dynamic>) {
            flatten(listItem, newKey);
          } else {
            flattenedData[newKey] = listItem;
          }
        }
      } else if (value is Map<String, dynamic>) {
        value.forEach((key, mapValue) {
          var newKey = '$currentKey.$key';
          flatten(mapValue, newKey);
        });
      } else {
        flattenedData[currentKey] = value;
      }
    }

    flatten(items, key);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _itemsCount = items.length;
      });
    });

    return flattenedData;
  }
}

class CrudoRepeaterController {
  _CrudoRepeaterFieldState? _state;

  /// Binds the controller to the repeater field's state
  void bind(_CrudoRepeaterFieldState state) {
    _state = state;
  }

  /// Adds a new item to the repeater
  void addItem() {
    _state?._addRepeaterItem();
  }

  /// Removes an item at the specified index
  void removeItem(int index) {
    _state?._removeRepeaterItem(index);
  }

  /// Retrieves the current count of items
  int get itemCount => _state?._itemsCount ?? 0;
}
