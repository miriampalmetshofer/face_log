import 'package:flutter/material.dart';

class AnnotationCategory {
  final String id;
  final String title;
  final String inputType;
  final List<AnnotationOption> options;
  final List<AnnotationCategory> subcategories;
  final String? visibleIf;

  AnnotationCategory({
    required this.id,
    required this.title,
    required this.inputType,
    this.options = const [],
    this.subcategories = const [],
    this.visibleIf,
  });

  factory AnnotationCategory.fromJson(Map<String, dynamic> json) {
    return AnnotationCategory(
      id: json['id'],
      title: json['title'],
      inputType: json['input_type'],
      visibleIf: json['visible_if'],
      options:
          (json['options'] as List<dynamic>?)
              ?.map((o) => AnnotationOption.fromJson(o))
              .toList() ??
          [],
    );
  }
}

class AnnotationOption {
  final String id;
  final String label;

  AnnotationOption({required this.id, required this.label});

  factory AnnotationOption.fromJson(Map<String, dynamic> json) {
    return AnnotationOption(id: json['id'], label: json['label']);
  }
}

class AnnotationForm extends StatefulWidget {
  final List<AnnotationCategory> categories;

  const AnnotationForm({super.key, required this.categories});

  @override
  State<AnnotationForm> createState() => _AnnotationFormState();
}

class _AnnotationFormState extends State<AnnotationForm> {
  Map<String, dynamic> answers = {};

  Widget _buildCategory(AnnotationCategory category) {
    if (category.visibleIf != null) {
      final parentValue = answers.values.contains(category.visibleIf);
      if (!parentValue) return const SizedBox.shrink();
    }

    Widget content;

    switch (category.inputType) {
      case "single_choice":
        content = DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: category.title),
          initialValue: answers[category.id],
          items: category.options
              .map((o) => DropdownMenuItem(value: o.id, child: Text(o.label)))
              .toList(),
          onChanged: (val) {
            setState(() => answers[category.id] = val);
          },
        );
        break;

      case "multiple_choice":
        content = Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.title,
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
              ...category.options.map((o) {
                final selected =
                    (answers[category.id] ?? <String>[]) as List<String>;
                return CheckboxListTile(
                  title: Text(o.label),
                  value: selected.contains(o.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selected.add(o.id);
                      } else {
                        selected.remove(o.id);
                      }
                      answers[category.id] = selected;
                    });
                  },
                );
              }).toList(),
            ],
          ),
        );
        break;

      case "text":
        content = TextField(
          decoration: InputDecoration(labelText: category.title),
          onChanged: (val) => answers[category.id] = val,
        );
        break;

      default:
        content = const SizedBox.shrink();
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: widget.categories.map(_buildCategory).toList(),
    );
  }
}
