class AnnotationCategory {
  final String id;
  final String title;
  final String inputType;
  final List<AnnotationOption> options;
  final List<AnnotationCategory> subcategories;
  final String? visibleIf; // Format: "parentId:optionId" e.g., "umgebung:innenraum"

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
      subcategories:
          (json['subcategories'] as List<dynamic>?)
              ?.map((c) => AnnotationCategory.fromJson(c))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'input_type': inputType,
      'visible_if': visibleIf,
      'options': options.map((o) => o.toJson()).toList(),
      'subcategories': subcategories.map((c) => c.toJson()).toList(),
    };
  }
}

class AnnotationOption {
  final String id;
  final String label;

  AnnotationOption({required this.id, required this.label});

  factory AnnotationOption.fromJson(Map<String, dynamic> json) {
    return AnnotationOption(id: json['id'], label: json['label']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
    };
  }
}
