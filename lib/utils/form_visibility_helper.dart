import '../models/annotation_category.dart';

class FormVisibilityHelper {
  static bool shouldShowCategory(
    AnnotationCategory category,
    Map<String, dynamic> answers,
  ) {
    if (category.visibleIf == null) return true;

    // Parse visibleIf format: "parentId:optionId"
    final parts = category.visibleIf!.split(':');
    if (parts.length != 2) return true;

    final parentId = parts[0];
    final requiredOptionId = parts[1];

    final parentAnswer = answers[parentId];

    // For checkbox, check if the boolean value matches
    if (requiredOptionId == 'true' || requiredOptionId == 'false') {
      final requiredBool = requiredOptionId == 'true';
      return parentAnswer == requiredBool;
    }

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
}
