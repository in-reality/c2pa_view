import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/entities/custom_field.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/features/custom_fields/custom_fields_table.dart';
import 'package:c2pa_view/features/shared/widgets/collapsible_section.dart';
import 'package:c2pa_view/features/shared/widgets/sub_section.dart';

/// Collapsible "About this Content Credential" section.
class AboutSection extends StatelessWidget {
  final ManifestViewData data;
  final List<CustomField> creativeWorkCustomFields;

  const AboutSection({
    super.key,
    required this.data,
    this.creativeWorkCustomFields = const [],
  });

  bool get _hasContent =>
      data.issuer != null ||
      data.signedDate != null ||
      data.producer != null ||
      data.socialAccounts.isNotEmpty ||
      data.doNotTrain ||
      creativeWorkCustomFields.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasContent) return const SizedBox.shrink();

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
}

class _IssuedBySubSection extends StatelessWidget {
  final String issuer;
  const _IssuedBySubSection({required this.issuer});

  @override
  Widget build(BuildContext context) {
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
}

class _IssuedOnSubSection extends StatelessWidget {
  final DateTime date;
  const _IssuedOnSubSection({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    return SubSection(
      label: 'Issued on',
      child: Text(
        DateFormat.yMMMd().add_jm().format(date),
        style: theme.bodyStyle.copyWith(color: theme.textPrimaryColor),
      ),
    );
  }
}

class _ProducerSubSection extends StatelessWidget {
  final String producer;
  const _ProducerSubSection({required this.producer});

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    return SubSection(
      label: 'Producer',
      child: Text(
        producer,
        style: theme.bodyStyle.copyWith(color: theme.textPrimaryColor),
      ),
    );
  }
}

class _SocialAccountsSubSection extends StatelessWidget {
  final List<SocialAccountDisplayInfo> accounts;
  const _SocialAccountsSubSection({required this.accounts});

  @override
  Widget build(BuildContext context) {
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
}

class _DoNotTrainSubSection extends StatelessWidget {
  const _DoNotTrainSubSection();

  @override
  Widget build(BuildContext context) {
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
