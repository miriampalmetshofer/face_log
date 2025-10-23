import 'package:flutter/material.dart';
import '../../models/annotation_category.dart';
import '../example_image_dialog.dart';

class SingleChoiceRadio extends StatelessWidget {
  final AnnotationCategory category;
  final String? currentValue;
  final ValueChanged<String?> onChanged;

  const SingleChoiceRadio({
    super.key,
    required this.category,
    required this.currentValue,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  category.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (category.exampleImage != null)
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    ExampleImageDialog.show(
                      context,
                      category.title,
                      category.exampleImage!,
                    );
                  },
                  tooltip: 'Beispiele anzeigen',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...category.options.map((o) {
            return RadioListTile<String>(
              title: Text(o.label),
              value: o.id,
              groupValue: currentValue,
              contentPadding: EdgeInsets.zero,
              onChanged: onChanged,
            );
          }),
        ],
      ),
    );
  }
}
