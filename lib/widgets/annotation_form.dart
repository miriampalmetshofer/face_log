import 'package:flutter/material.dart';
import '../models/annotation_category.dart';

class AnnotationForm extends StatefulWidget {
  final List<AnnotationCategory> categories;

  const AnnotationForm({super.key, required this.categories});

  @override
  State<AnnotationForm> createState() => _AnnotationFormState();
}

class _AnnotationFormState extends State<AnnotationForm> {
  final Map<String, dynamic> answers = {};

  bool _shouldShowCategory(AnnotationCategory category) {
    if (category.visibleIf == null) return true;

    // Parse visibleIf format: "parentId:optionId"
    final parts = category.visibleIf!.split(':');
    if (parts.length != 2) return true;

    final parentId = parts[0];
    final requiredOptionId = parts[1];

    final parentAnswer = answers[parentId];

    // For single choice, check if the answer matches
    if (parentAnswer is String) {
      return parentAnswer == requiredOptionId;
    }

    // For multiple choice, check if the list contains the required option
    if (parentAnswer is List) {
      return parentAnswer.contains(requiredOptionId);
    }

    return false;
  }

  List<Widget> _buildCategoryWithSubcategories(AnnotationCategory category) {
    if (!_shouldShowCategory(category)) return [];

    final widgets = <Widget>[_buildCategoryWidget(category)];

    // Add subcategories if they exist and should be visible
    for (final subcategory in category.subcategories) {
      widgets.addAll(_buildCategoryWithSubcategories(subcategory));
    }

    return widgets;
  }

  Widget _buildCategoryWidget(AnnotationCategory category) {
    Widget content;

    switch (category.inputType) {
      case "single_choice":
        content = Padding(
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
            ),
            value: answers[category.id],
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
            onChanged: (val) {
              setState(() => answers[category.id] = val);
            },
            hint: const Text('Auswählen...'),
          ),
        );
        break;

      case "multiple_choice":
        content = Container(
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
                answers[category.id] ??= <String>[];
                final selected = answers[category.id] as List<String>;
                return CheckboxListTile(
                  title: Text(o.label),
                  value: selected.contains(o.id),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selected.add(o.id);
                      } else {
                        selected.remove(o.id);
                      }
                    });
                  },
                );
              }),
            ],
          ),
        );
        break;

      case "text":
        content = Padding(
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
            onChanged: (val) => setState(() => answers[category.id] = val),
          ),
        );
        break;

      default:
        content = const SizedBox.shrink();
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final allWidgets = <Widget>[];
    for (final category in widget.categories) {
      allWidgets.addAll(_buildCategoryWithSubcategories(category));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: allWidgets,
    );
  }
}

/// Non-scrollable version of annotation form for use in SingleChildScrollView
class AnnotationFormContent extends StatefulWidget {
  final List<AnnotationCategory> categories;

  const AnnotationFormContent({super.key, required this.categories});

  @override
  State<AnnotationFormContent> createState() => _AnnotationFormContentState();
}

class _AnnotationFormContentState extends State<AnnotationFormContent> {
  final Map<String, dynamic> answers = {};

  bool _shouldShowCategory(AnnotationCategory category) {
    if (category.visibleIf == null) return true;

    // Parse visibleIf format: "parentId:optionId"
    final parts = category.visibleIf!.split(':');
    if (parts.length != 2) return true;

    final parentId = parts[0];
    final requiredOptionId = parts[1];

    final parentAnswer = answers[parentId];

    // For single choice, check if the answer matches
    if (parentAnswer is String) {
      return parentAnswer == requiredOptionId;
    }

    // For multiple choice, check if the list contains the required option
    if (parentAnswer is List) {
      return parentAnswer.contains(requiredOptionId);
    }

    return false;
  }

  List<Widget> _buildCategoryWithSubcategories(AnnotationCategory category) {
    if (!_shouldShowCategory(category)) return [];

    final widgets = <Widget>[_buildCategoryWidget(category)];

    // Add subcategories if they exist and should be visible
    for (final subcategory in category.subcategories) {
      widgets.addAll(_buildCategoryWithSubcategories(subcategory));
    }

    return widgets;
  }

  Widget _buildCategoryWidget(AnnotationCategory category) {
    Widget content;

    switch (category.inputType) {
      case "single_choice":
        content = Padding(
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
            ),
            value: answers[category.id],
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
            onChanged: (val) {
              setState(() => answers[category.id] = val);
            },
            hint: const Text('Auswählen...'),
          ),
        );
        break;

      case "multiple_choice":
        content = Container(
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
                answers[category.id] ??= <String>[];
                final selected = answers[category.id] as List<String>;
                return CheckboxListTile(
                  title: Text(o.label),
                  value: selected.contains(o.id),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selected.add(o.id);
                      } else {
                        selected.remove(o.id);
                      }
                    });
                  },
                );
              }),
            ],
          ),
        );
        break;

      case "text":
        content = Padding(
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
            onChanged: (val) => setState(() => answers[category.id] = val),
          ),
        );
        break;

      default:
        content = const SizedBox.shrink();
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final allWidgets = <Widget>[];
    for (final category in widget.categories) {
      allWidgets.addAll(_buildCategoryWithSubcategories(category));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: allWidgets,
      ),
    );
  }
}
