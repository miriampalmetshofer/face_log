import 'package:flutter/material.dart';
import '../../models/annotation_category.dart';

class TextInputField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: category.title,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 12.0,
          ),
        ),
        controller: TextEditingController(text: currentValue ?? ''),
        onChanged: onChanged,
      ),
    );
  }
}
