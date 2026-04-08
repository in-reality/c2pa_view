import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/features/custom_fields/custom_fields_table.dart';
import 'package:c2pa_view/features/shared/widgets/collapsible_section.dart';
import 'package:c2pa_view/features/shared/widgets/ingredient_card.dart';
import 'package:c2pa_view/features/shared/widgets/sub_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Collapsible "Process" section showing claim generator, AI tools,
/// actions, and ingredients.
class ProcessSection extends StatelessWidget {

  const ProcessSection({required this.data, super.key, this.onIngredientTap});
  final ManifestViewData data;
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;

  bool get _hasContent =>
      data.claimGenerator != null ||
      data.aiToolsUsed.isNotEmpty ||
      data.actions.isNotEmpty ||
      data.ingredients.isNotEmpty;

  @override
  Widget build(final BuildContext context) {
    if (!_hasContent) {
      return const SizedBox.shrink();
    }

    return CollapsibleSection(
      title: 'Process',
      description:
          'The app or device used to produce this content '
          'recorded the following information:',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.claimGenerator != null) _AppDeviceSubSection(data: data),
          if (data.aiToolsUsed.isNotEmpty) _AiToolSubSection(data: data),
          if (data.actions.isNotEmpty) _ActionsSubSection(data: data),
          if (data.ingredients.isNotEmpty)
            _IngredientsSubSection(
              data: data,
              onIngredientTap: onIngredientTap,
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ManifestViewData>('data', data))
    ..add(ObjectFlagProperty<ValueChanged<IngredientDisplayInfo>?>.has('onIngredientTap', onIngredientTap));
  }
}

class _AppDeviceSubSection extends StatelessWidget {
  const _AppDeviceSubSection({required this.data});
  final ManifestViewData data;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    final gen = data.claimGenerator!;

    return SubSection(
      label: 'App or device used',
      child: Row(
        children: [
          if (gen.icon != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image(
                image: gen.icon!,
                width: 24,
                height: 24,
                errorBuilder:
                    (_, final __, final ___) =>
                        Icon(Icons.apps, size: 24, color: theme.iconColor),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            Icon(Icons.apps, size: 24, color: theme.iconColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              gen.displayLabel,
              style: theme.bodyStyle.copyWith(color: theme.textPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ManifestViewData>('data', data));
  }
}

class _AiToolSubSection extends StatelessWidget {
  const _AiToolSubSection({required this.data});
  final ManifestViewData data;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return SubSection(
      label: 'AI tool used',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final agent in data.aiToolsUsed)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: theme.iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      agent,
                      style: theme.bodyStyle.copyWith(
                        color: theme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ManifestViewData>('data', data));
  }
}

class _ActionsSubSection extends StatelessWidget {
  const _ActionsSubSection({required this.data});
  final ManifestViewData data;

  @override
  Widget build(final BuildContext context) => SubSection(
      label: 'Edits and activity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final action in data.actions) _ActionRow(action: action),
        ],
      ),
    );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ManifestViewData>('data', data));
  }
}

class _ActionRow extends StatefulWidget {
  const _ActionRow({required this.action});
  final ActionDisplayInfo action;

  @override
  State<_ActionRow> createState() => _ActionRowState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ActionDisplayInfo>('action', action));
  }
}

class _ActionRowState extends State<_ActionRow> {
  bool _expanded = false;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    final action = widget.action;
    final hasParams = action.customParams.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconForAction(action.actionType),
                size: 16,
                color:
                    action.isAiGenerated
                        ? theme.unrecognizedColor
                        : theme.iconColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action.label,
                  style: theme.bodyStyle.copyWith(
                    color: theme.textPrimaryColor,
                  ),
                ),
              ),
              if (action.isAiGenerated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.unrecognizedColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AI',
                    style: theme.labelStyle.copyWith(
                      color: theme.unrecognizedColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              if (hasParams)
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: theme.iconColor,
                    ),
                  ),
                ),
            ],
          ),
          if (hasParams && _expanded) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: CustomFieldsTable(fields: action.customParams),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForAction(final String actionType) {
    const icons = {
      'c2pa.created': Icons.add_circle_outline,
      'c2pa.opened': Icons.folder_open,
      'c2pa.placed': Icons.layers,
      'c2pa.edited': Icons.edit,
      'c2pa.cropped': Icons.crop,
      'c2pa.resized': Icons.photo_size_select_large,
      'c2pa.color_adjustments': Icons.palette,
      'c2pa.drawing': Icons.brush,
      'c2pa.filtered': Icons.filter,
      'c2pa.orientation': Icons.screen_rotation,
      'c2pa.published': Icons.publish,
      'c2pa.transcoded': Icons.transform,
    };
    return icons[actionType] ?? Icons.circle_outlined;
  }
}

class _IngredientsSubSection extends StatelessWidget {

  const _IngredientsSubSection({required this.data, this.onIngredientTap});
  final ManifestViewData data;
  final ValueChanged<IngredientDisplayInfo>? onIngredientTap;

  @override
  Widget build(final BuildContext context) => SubSection(
      label: 'Ingredients',
      child: Column(
        children: [
          for (int i = 0; i < data.ingredients.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            IngredientCard(
              ingredient: data.ingredients[i],
              onTap:
                  onIngredientTap != null
                      ? () => onIngredientTap!(data.ingredients[i])
                      : null,
            ),
          ],
        ],
      ),
    );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ManifestViewData>('data', data))
    ..add(ObjectFlagProperty<ValueChanged<IngredientDisplayInfo>?>.has('onIngredientTap', onIngredientTap));
  }
}
