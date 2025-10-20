import 'package:flutter/material.dart';

class SearchInput extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final String? initialValue;
  final bool autofocus;

  const SearchInput({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.initialValue,
    this.autofocus = false,
  });

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  late final TextEditingController _controller;
  String _lastNotifiedValue = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue ?? '';
    _lastNotifiedValue = initial;
    _controller = TextEditingController(text: initial);
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.initialValue ?? '';
    if (incoming != oldWidget.initialValue && incoming != _controller.text) {
      _lastNotifiedValue = incoming;
      _controller.value = TextEditingValue(
        text: incoming,
        selection: TextSelection.collapsed(offset: incoming.length),
      );
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final value = _controller.text;
    if (value != _lastNotifiedValue) {
      _lastNotifiedValue = value;
      widget.onChanged(value);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () => _controller.clear(),
                icon: const Icon(Icons.close),
              )
            : null,
        hintText: widget.hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
