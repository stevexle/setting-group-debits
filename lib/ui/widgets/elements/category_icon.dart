import 'package:flutter/material.dart';
import '../../../models.dart';
import '../../ui_helpers.dart';

class CategoryIcon extends StatelessWidget {
  final Category category;
  final double size;
  final Color? color;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      UIHelpers.getCategoryIcon(category),
      size: size,
      color: color ?? UIHelpers.getCategoryColor(category),
    );
  }
}
