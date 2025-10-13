import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/annotation_category.dart';

class AnnotationService {
  static Future<List<AnnotationCategory>> loadSchema() async {
    try {
      final jsonString = await rootBundle.loadString('assets/annotation_schema.json');
      final data = json.decode(jsonString);
      final categories = (data['categories'] as List)
          .map((c) => AnnotationCategory.fromJson(c))
          .toList();
      return categories;
    } catch (e) {
      throw Exception('Failed to load annotation schema: $e');
    }
  }
}
