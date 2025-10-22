import 'package:flutter/material.dart';
import '../../models/annotation_category.dart';

class FormHeader extends StatelessWidget {
  final AnnotationCategory category;

  const FormHeader({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          category.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
