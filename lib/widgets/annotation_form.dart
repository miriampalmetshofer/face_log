import 'package:flutter/material.dart';
import '../models/annotation_category.dart';
import '../utils/form_visibility_helper.dart';
import 'form_fields/single_choice_dropdown.dart';
import 'form_fields/single_choice_radio.dart';
import 'form_fields/multiple_choice_checkboxes.dart';
import 'form_fields/text_input_field.dart';
import 'form_fields/form_header.dart';
import 'form_fields/checkbox_field.dart';

class AnnotationForm extends StatefulWidget {
  final List<AnnotationCategory> categories;

  const AnnotationForm({super.key, required this.categories});

  @override
  State<AnnotationForm> createState() => _AnnotationFormState();
}

class _AnnotationFormState extends State<AnnotationForm> {
  final Map<String, dynamic> answers = {};

  List<Widget> _buildCategoryWithSubcategories(AnnotationCategory category) {
    if (!FormVisibilityHelper.shouldShowCategory(category, answers)) {
      return [];
    }

    final widgets = <Widget>[_buildCategoryWidget(category)];

    // Add subcategories if they exist and should be visible
    for (final subcategory in category.subcategories) {
      widgets.addAll(_buildCategoryWithSubcategories(subcategory));
    }

    return widgets;
  }

  Widget _buildCategoryWidget(AnnotationCategory category) {
    switch (category.inputType) {
      case "single_choice":
        // Use dropdown only for top-level categories that have subcategories
        if (category.visibleIf == null && category.subcategories.isNotEmpty) {
          return SingleChoiceDropdown(
            category: category,
            currentValue: answers[category.id],
            onChanged: (val) => setState(() => answers[category.id] = val),
          );
        } else {
          // Use radio buttons for subcategories
          return SingleChoiceRadio(
            category: category,
            currentValue: answers[category.id],
            onChanged: (val) => setState(() => answers[category.id] = val),
          );
        }

      case "multiple_choice":
        answers[category.id] ??= <String>[];
        return MultipleChoiceCheckboxes(
          category: category,
          selectedValues: List<String>.from(answers[category.id] as List),
          onChanged: (updatedList) => setState(() => answers[category.id] = updatedList),
        );

      case "text":
        return TextInputField(
          category: category,
          currentValue: answers[category.id] as String?,
          onChanged: (val) => setState(() => answers[category.id] = val),
        );

      case "checkbox":
        return CheckboxField(
          category: category,
          currentValue: answers[category.id] == true,
          onChanged: (val) => setState(() => answers[category.id] = val),
        );

      case "header":
        return FormHeader(category: category);

      default:
        return const SizedBox.shrink();
    }
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
  final Map<String, dynamic>? initialAnswers;
  final void Function(Map<String, dynamic> answers)? onSave;
  final void Function(bool hasChanges)? onFormChanged;

  const AnnotationFormContent({
    super.key,
    required this.categories,
    this.initialAnswers,
    this.onSave,
    this.onFormChanged,
  });

  @override
  State<AnnotationFormContent> createState() => _AnnotationFormContentState();
}

class _AnnotationFormContentState extends State<AnnotationFormContent> {
  late final Map<String, dynamic> answers;
  late final Map<String, dynamic> initialAnswersCopy;

  @override
  void initState() {
    super.initState();
    // Initialize answers with initial values or empty map
    answers = widget.initialAnswers != null
        ? Map<String, dynamic>.from(widget.initialAnswers!)
        : {};
    // Keep a copy of initial answers to detect changes
    initialAnswersCopy = widget.initialAnswers != null
        ? Map<String, dynamic>.from(widget.initialAnswers!)
        : {};
  }

  bool _hasChanges() {
    // Deep comparison of answers and initialAnswersCopy
    if (answers.length != initialAnswersCopy.length) return true;

    for (final key in answers.keys) {
      final currentValue = answers[key];
      final initialValue = initialAnswersCopy[key];

      // Handle list comparison
      if (currentValue is List && initialValue is List) {
        if (currentValue.length != initialValue.length) return true;
        for (int i = 0; i < currentValue.length; i++) {
          if (currentValue[i] != initialValue[i]) return true;
        }
      } else if (currentValue != initialValue) {
        return true;
      }
    }

    return false;
  }

  void _notifyFormChanged() {
    if (widget.onFormChanged != null) {
      widget.onFormChanged!(_hasChanges());
    }
  }

  List<String> _validateForm() {
    final missingFields = <String>[];
    _collectMissingFields(widget.categories, missingFields);
    return missingFields;
  }

  void _collectMissingFields(List<AnnotationCategory> categories, List<String> missingFields) {
    for (final category in categories) {
      if (!FormVisibilityHelper.shouldShowCategory(category, answers)) {
        continue;
      }

      if (category.inputType == "header") {
        _collectMissingFields(category.subcategories, missingFields);
        continue;
      }

      if (category.inputType == "checkbox") {
        continue;
      }

      if (category.id == "notes_text" || category.id == "notes") {
        continue;
      }

      final value = answers[category.id];
      bool isMissing = false;

      switch (category.inputType) {
        case "single_choice":
          isMissing = value == null || value.toString().isEmpty;
          break;

        case "multiple_choice":
          isMissing = value == null || (value is List && value.isEmpty);
          break;

        case "text":
          isMissing = value == null || (value is String && value.trim().isEmpty);
          break;
      }

      if (isMissing) {
        missingFields.add(category.title);
      }

      // Check subcategories
      _collectMissingFields(category.subcategories, missingFields);
    }
  }

  List<Widget> _buildCategoryWithSubcategories(AnnotationCategory category) {
    if (!FormVisibilityHelper.shouldShowCategory(category, answers)) {
      return [];
    }

    final widgets = <Widget>[_buildCategoryWidget(category)];

    // Add subcategories if they exist and should be visible
    for (final subcategory in category.subcategories) {
      widgets.addAll(_buildCategoryWithSubcategories(subcategory));
    }

    return widgets;
  }

  Widget _buildCategoryWidget(AnnotationCategory category) {
    switch (category.inputType) {
      case "single_choice":
        // Use dropdown only for top-level categories that have subcategories
        if (category.visibleIf == null && category.subcategories.isNotEmpty) {
          return SingleChoiceDropdown(
            category: category,
            currentValue: answers[category.id],
            onChanged: (val) {
              setState(() => answers[category.id] = val);
              _notifyFormChanged();
            },
          );
        } else {
          // Use radio buttons for subcategories
          return SingleChoiceRadio(
            category: category,
            currentValue: answers[category.id],
            onChanged: (val) {
              setState(() => answers[category.id] = val);
              _notifyFormChanged();
            },
          );
        }

      case "multiple_choice":
        answers[category.id] ??= <String>[];
        return MultipleChoiceCheckboxes(
          category: category,
          selectedValues: List<String>.from(answers[category.id] as List),
          onChanged: (updatedList) {
            setState(() => answers[category.id] = updatedList);
            _notifyFormChanged();
          },
        );

      case "text":
        return TextInputField(
          category: category,
          currentValue: answers[category.id] as String?,
          onChanged: (val) {
            setState(() => answers[category.id] = val);
            _notifyFormChanged();
          },
        );

      case "checkbox":
        return CheckboxField(
          category: category,
          currentValue: answers[category.id] == true,
          onChanged: (val) {
            setState(() => answers[category.id] = val);
            _notifyFormChanged();
          },
        );

      case "header":
        return FormHeader(category: category);

      default:
        return const SizedBox.shrink();
    }
  }

  void _handleSave() {
    final missingFields = _validateForm();

    if (missingFields.isNotEmpty) {
      // Show error dialog with missing fields
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Fehlende Pflichtfelder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bitte füllen Sie folgende Felder aus:'),
                const SizedBox(height: 12),
                ...missingFields.map((field) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('• $field', style: const TextStyle(fontWeight: FontWeight.w500)),
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Validation passed, call onSave
    widget.onSave!(answers);
  }

  @override
  Widget build(BuildContext context) {
    final allWidgets = <Widget>[];
    for (final category in widget.categories) {
      allWidgets.addAll(_buildCategoryWithSubcategories(category));
    }

    // Add save button if onSave callback is provided
    if (widget.onSave != null) {
      allWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Speichern',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: allWidgets,
      ),
    );
  }
}
