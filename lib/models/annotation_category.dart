class AnnotationCategory {
  final String id;
  final String title;
  final String inputType;
  final List<AnnotationOption> options;
  final List<AnnotationCategory> subcategories;
  final String? visibleIf; // Format: "parentId:optionId" e.g., "umgebung:innenraum"
  final String? exampleImage; // Path to example image asset

  AnnotationCategory({
    required this.id,
    required this.title,
    required this.inputType,
    this.options = const [],
    this.subcategories = const [],
    this.visibleIf,
    this.exampleImage,
  });

  factory AnnotationCategory.fromJson(Map<String, dynamic> json) {
    return AnnotationCategory(
      id: json['id'],
      title: json['title'],
      inputType: json['input_type'],
      visibleIf: json['visible_if'],
      exampleImage: json['example_image'],
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
      'example_image': exampleImage,
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
