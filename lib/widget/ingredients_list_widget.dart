import 'package:c2pa_view/c2pa_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that displays a list of ingredients from a C2PA manifest.
class IngredientListWidget extends StatelessWidget {

  /// Creates an instance of [IngredientListWidget].
  const IngredientListWidget({
    required this.ingredients, super.key,
    this.sectionTitleStyle,
    this.contentStyle,
  });

  /// The list of ingredients to display.
  final List<Ingredient> ingredients;

  /// The style for the section title.
  final TextStyle? sectionTitleStyle;

  /// The style for the content text.
  final TextStyle? contentStyle;

  @override
  Widget build(final BuildContext context) {
    if (ingredients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingredients:', style: sectionTitleStyle),
        const SizedBox(height: 8),
        ...ingredients.map((final ingredient) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            '- ${ingredient.title ?? 'Unknown'}',
            style: contentStyle,
          ),
        ),),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(IterableProperty<Ingredient>('ingredients', ingredients))
    ..add(DiagnosticsProperty<TextStyle?>(
        'sectionTitleStyle', sectionTitleStyle,),)
    ..add(DiagnosticsProperty<TextStyle?>('contentStyle', contentStyle));
  }
}
