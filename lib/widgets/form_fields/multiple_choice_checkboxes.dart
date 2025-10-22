import 'package:flutter/material.dart';
import '../../models/annotation_category.dart';

class MultipleChoiceCheckboxes extends StatelessWidget {
  final AnnotationCategory category;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;

  const MultipleChoiceCheckboxes({
    super.key,
    required this.category,
    required this.selectedValues,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...category.options.map((o) {
            return CheckboxListTile(
              title: Text(o.label),
              value: selectedValues.contains(o.id),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) {
                final updatedList = List<String>.from(selectedValues);
                if (checked == true) {
                  updatedList.add(o.id);
                } else {
                  updatedList.remove(o.id);
                }
                onChanged(updatedList);
              },
            );
          }),
        ],
      ),
    );
  }
}
