import 'dart:convert';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/features/shared/widgets/credential_indicator.dart';
import 'package:c2pa_view/l10n/localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Sticky header at the top of the detail panel.
class DetailHeader extends StatefulWidget {
  const DetailHeader({required this.data, super.key});
  final ManifestViewData data;

  @override
  State<DetailHeader> createState() => _DetailHeaderState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ManifestViewData>('data', data));
  }
}

class _DetailHeaderState extends State<DetailHeader> {
  bool _copied = false;

  Future<void> _copyJson() async {
    final raw = widget.data.rawJson;
    if (raw == null) {
      return;
    }
    final jsonString = const JsonEncoder.withIndent('  ').convert(raw);
    await Clipboard.setData(ClipboardData(text: jsonString));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final theme = C2paViewerTheme.of(context);
    final data = widget.data;

    return Container(
      color: theme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: data.title != null
                    ? Text(
                        data.title!,
                        style: theme.titleLargeStyle.copyWith(
                          color: theme.textPrimaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(),
              ),
              if (data.rawJson != null && !data.validationResult.isInvalid)
                Tooltip(
                  message: _copied
                      ? c2paViewL10n(context).detailHeaderCopied
                      : c2paViewL10n(context).detailHeaderCopyManifestJSON,
                  child: IconButton(
                    onPressed: _copyJson,
                    iconSize: 18,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      foregroundColor: _copied
                          ? theme.validColor
                          : theme.iconColor,
                    ),
                    icon: Icon(_copied ? Icons.check : Icons.copy_outlined),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          CredentialIndicator(result: data.validationResult),
          if (!data.validationResult.isInvalid &&
              (data.issuer != null || data.signedDate != null)) ...[
            const SizedBox(height: 4),
            Text(
              _issuedByLine(data),
              style: theme.bodySmallStyle.copyWith(
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _issuedByLine(final ManifestViewData data) {
    final strings = c2paViewL10n(context);
    final issuer = data.issuer;
    final date = data.signedDate;
    final formatted = date == null
        ? null
        : DateFormat.yMMMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).add_jm().format(date);
    if (issuer != null && formatted != null) {
      return strings.credentialIssuedByOn(issuer, formatted);
    }
    if (issuer != null) {
      return strings.credentialIssuedBy(issuer);
    }
    if (formatted != null) {
      return strings.credentialIssuedOn(formatted);
    }
    return '';
  }
}
