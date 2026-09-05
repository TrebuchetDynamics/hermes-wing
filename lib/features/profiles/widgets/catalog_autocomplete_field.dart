import 'package:flutter/material.dart';

/// A form field that keeps ordinary typing and keyboard operation available.
class CatalogAutocompleteField extends StatefulWidget {
  const CatalogAutocompleteField({
    required this.controller,
    required this.options,
    required this.label,
    required this.enabled,
    required this.validator,
    this.onChanged,
    this.searchLabels = const {},
    super.key,
  });

  final TextEditingController controller;
  final List<String> options;
  final Map<String, String> searchLabels;
  final String label;
  final bool enabled;
  final FormFieldValidator<String> validator;
  final ValueChanged<String>? onChanged;

  @override
  State<CatalogAutocompleteField> createState() =>
      _CatalogAutocompleteFieldState();
}

class _CatalogAutocompleteFieldState extends State<CatalogAutocompleteField> {
  final _focus = FocusNode();

  @override
  void didUpdateWidget(CatalogAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) _focus.unfocus();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Autocomplete<String>(
    textEditingController: widget.controller,
    focusNode: _focus,
    optionsMaxHeight: 240,
    optionsBuilder: (value) {
      if (!widget.enabled) return const <String>[];
      final query = value.text.trim().toLowerCase();
      return widget.options
          .where(
            (option) =>
                option.toLowerCase().contains(query) ||
                (widget.searchLabels[option]?.toLowerCase().contains(query) ??
                    false),
          )
          .take(12);
    },
    onSelected: widget.onChanged,
    fieldViewBuilder: (context, controller, focus, submit) => TextFormField(
      controller: controller,
      focusNode: focus,
      enabled: widget.enabled,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: (_) => submit(),
    ),
  );
}
