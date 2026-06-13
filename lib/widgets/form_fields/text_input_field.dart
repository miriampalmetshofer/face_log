import 'package:flutter/material.dart';
import '../../models/annotation_category.dart';

class TextInputField extends StatefulWidget {
  final AnnotationCategory category;
  final String? currentValue;
  final ValueChanged<String> onChanged;

  const TextInputField({
    super.key,
    required this.category,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  State<TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<TextInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue ?? '');
  }

  @override
  void didUpdateWidget(TextInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the value changed externally (not from user input)
    if (widget.currentValue != oldWidget.currentValue &&
        widget.currentValue != _controller.text) {
      _controller.text = widget.currentValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: widget.category.title,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 12.0,
          ),
        ),
        controller: _controller,
        onChanged: widget.onChanged,
      ),
    );
  }
}
