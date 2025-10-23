import 'package:flutter/material.dart';
import '../../models/annotation_category.dart';
import '../example_image_dialog.dart';

class SingleChoiceDropdown extends StatelessWidget {
  final AnnotationCategory category;
  final String? currentValue;
  final ValueChanged<String?> onChanged;

  const SingleChoiceDropdown({
    super.key,
    required this.category,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: category.title,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ),
          suffixIcon: category.exampleImage != null
              ? IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    ExampleImageDialog.show(
                      context,
                      category.title,
                      category.exampleImage!,
                    );
                  },
                  tooltip: 'Beispiele anzeigen',
                )
              : null,
        ),
        initialValue: currentValue,
        isExpanded: true,
        items: category.options
            .map((o) => DropdownMenuItem(
                  value: o.id,
                  child: Text(
                    o.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        hint: const Text('Auswählen...'),
      ),
    );
  }
}
