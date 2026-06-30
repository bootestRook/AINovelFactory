import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class AppSelectOption<T> {
  const AppSelectOption({
    required this.value,
    required this.label,
    this.description,
    this.leadingBuilder,
  });

  final T value;
  final String label;
  final String? description;
  final WidgetBuilder? leadingBuilder;
}

class AppSelectField<T> extends StatefulWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    this.itemHeight = 48,
  });

  final String label;
  final T? value;
  final String hint;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  final double itemHeight;

  @override
  State<AppSelectField<T>> createState() => _AppSelectFieldState<T>();
}

class _AppSelectFieldState<T> extends State<AppSelectField<T>> {
  static const _visibleItems = 4;

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final selectedOption = _selectedOption();

    return LayoutBuilder(
      builder: (context, constraints) {
        return MenuAnchor(
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(colors.card),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            elevation: const WidgetStatePropertyAll(8),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          menuChildren: [
            SizedBox(
              key: ValueKey('select-menu-${widget.label}'),
              width: constraints.maxWidth,
              height: widget.itemHeight *
                  (widget.options.length < _visibleItems
                      ? widget.options.length
                      : _visibleItems),
              child: Scrollbar(
                key: ValueKey('select-scrollbar-${widget.label}'),
                controller: _scrollController,
                thumbVisibility: widget.options.length > _visibleItems,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  itemExtent: widget.itemHeight,
                  primary: false,
                  itemCount: widget.options.length,
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final selected = option.value == widget.value;

                    return Builder(
                      builder: (context) {
                        return InkWell(
                          onTap: () {
                            widget.onChanged(option.value);
                            MenuController.maybeOf(context)?.close();
                          },
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            color: selected
                                ? colors.line.withValues(alpha: 0.5)
                                : colors.card,
                            child: _SelectOptionContent(option: option),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
          builder: (context, controller, child) {
            return InkWell(
              key: ValueKey('select-field-${widget.label}'),
              onTap: () {
                controller.isOpen ? controller.close() : controller.open();
              },
              child: InputDecorator(
                isEmpty: selectedOption == null,
                decoration: const InputDecoration(),
                child: Row(
                  children: [
                    Expanded(
                      child: selectedOption == null
                          ? Text(
                              widget.hint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: colors.muted),
                            )
                          : _SelectOptionContent(option: selectedOption),
                    ),
                    Icon(
                      controller.isOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: colors.muted,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  AppSelectOption<T>? _selectedOption() {
    for (final option in widget.options) {
      if (option.value == widget.value) {
        return option;
      }
    }
    return null;
  }
}

class _SelectOptionContent<T> extends StatelessWidget {
  const _SelectOptionContent({required this.option});

  final AppSelectOption<T> option;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final leading = option.leadingBuilder?.call(context);
    final description = option.description;

    return Row(
      children: [
        if (leading != null) ...[
          leading,
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.text),
              ),
              if (description != null) ...[
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
