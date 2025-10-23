import 'package:flutter/material.dart';
import '../../models/annotation_category.dart';

class CheckboxField extends StatelessWidget {
  final AnnotationCategory category;
  final bool currentValue;
  final ValueChanged<bool> onChanged;

  const CheckboxField({
    super.key,
    required this.category,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: CheckboxListTile(
        title: Text(
          category.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        value: currentValue,
        onChanged: (value) => onChanged(value ?? false),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
