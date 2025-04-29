import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter/material.dart';

class IngredientListWidget extends StatelessWidget {
  final List<Ingredient> ingredients;
  final TextStyle? sectionTitleStyle;
  final TextStyle? contentStyle;

  const IngredientListWidget({
    super.key,
    required this.ingredients,
    this.sectionTitleStyle,
    this.contentStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingredients:', style: sectionTitleStyle),
        const SizedBox(height: 8),
        ...ingredients.map((ingredient) => Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(
            '- ${ingredient.title ?? 'Unknown'}',
            style: contentStyle,
          ),
        )),
      ],
    );
  }
}
