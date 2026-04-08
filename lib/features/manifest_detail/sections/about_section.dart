import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/entities/custom_field.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/features/custom_fields/custom_fields_table.dart';
import 'package:c2pa_view/features/shared/widgets/collapsible_section.dart';
import 'package:c2pa_view/features/shared/widgets/sub_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Collapsible "About this Content Credential" section.
class AboutSection extends StatelessWidget {

  const AboutSection({
    required this.data, super.key,
    this.creativeWorkCustomFields = const [],
  });
  final ManifestViewData data;
  final List<CustomField> creativeWorkCustomFields;

  bool get _hasContent =>
      data.issuer != null ||
      data.signedDate != null ||
      data.producer != null ||
      data.socialAccounts.isNotEmpty ||
      data.doNotTrain ||
      creativeWorkCustomFields.isNotEmpty;

  @override
  Widget build(final BuildContext context) {
    if (!_hasContent) {
      return const SizedBox.shrink();
    }

    return CollapsibleSection(
      title: 'About this Content Credential',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.issuer != null) _IssuedBySubSection(issuer: data.issuer!),
          if (data.signedDate != null)
            _IssuedOnSubSection(date: data.signedDate!),
          if (data.producer != null)
            _ProducerSubSection(producer: data.producer!),
          if (data.socialAccounts.isNotEmpty)
            _SocialAccountsSubSection(accounts: data.socialAccounts),
          if (data.doNotTrain) const _DoNotTrainSubSection(),
          if (creativeWorkCustomFields.isNotEmpty)
            SubSection(
              label: 'Additional metadata',
              child: CustomFieldsTable(fields: creativeWorkCustomFields),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(DiagnosticsProperty<ManifestViewData>('data', data))
    ..add(IterableProperty<CustomField>('creativeWorkCustomFields', creativeWorkCustomFields));
  }
}

class _IssuedBySubSection extends StatelessWidget {
  const _IssuedBySubSection({required this.issuer});
  final String issuer;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return SubSection(
      label: 'Issued by',
      child: Row(
        children: [
          Expanded(
            child: Text(
              issuer,
              style: theme.bodyStyle.copyWith(color: theme.textPrimaryColor),
            ),
          ),
          Tooltip(
            message:
                'This is the organization, device, or individual '
                'that recorded the details above and signed this '
                'Content Credential.',
            child: Icon(Icons.help_outline, size: 16, color: theme.iconColor),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('issuer', issuer));
  }
}

class _IssuedOnSubSection extends StatelessWidget {
  const _IssuedOnSubSection({required this.date});
  final DateTime date;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    return SubSection(
      label: 'Issued on',
      child: Text(
        DateFormat.yMMMd().add_jm().format(date),
        style: theme.bodyStyle.copyWith(color: theme.textPrimaryColor),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<DateTime>('date', date));
  }
}

class _ProducerSubSection extends StatelessWidget {
  const _ProducerSubSection({required this.producer});
  final String producer;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    return SubSection(
      label: 'Producer',
      child: Text(
        producer,
        style: theme.bodyStyle.copyWith(color: theme.textPrimaryColor),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('producer', producer));
  }
}

class _SocialAccountsSubSection extends StatelessWidget {
  const _SocialAccountsSubSection({required this.accounts});
  final List<SocialAccountDisplayInfo> accounts;

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    return SubSection(
      label: 'Social accounts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final account in accounts)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.link, size: 14, color: theme.iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${account.platform}: ${account.url}',
                      style: theme.bodySmallStyle.copyWith(
                        color: theme.textPrimaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
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
    properties.add(IterableProperty<SocialAccountDisplayInfo>('accounts', accounts));
  }
}

class _DoNotTrainSubSection extends StatelessWidget {
  const _DoNotTrainSubSection();

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    return SubSection(
      label: 'AI training',
      child: Row(
        children: [
          Icon(Icons.block, size: 16, color: theme.invalidColor),
          const SizedBox(width: 6),
          Text(
            'The creator does not want this content used for AI training.',
            style: theme.bodySmallStyle.copyWith(color: theme.textPrimaryColor),
          ),
        ],
      ),
    );
  }
}
