import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:c2pa_view/core/theme/c2pa_theme.dart';
import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/features/shared/widgets/credential_indicator.dart';

/// Sticky header at the top of the detail panel.
class DetailHeader extends StatefulWidget {
  final ManifestViewData data;

  const DetailHeader({super.key, required this.data});

  @override
  State<DetailHeader> createState() => _DetailHeaderState();
}

class _DetailHeaderState extends State<DetailHeader> {
  bool _copied = false;

  Future<void> _copyJson() async {
    final raw = widget.data.rawJson;
    if (raw == null) return;
    final jsonString = const JsonEncoder.withIndent('  ').convert(raw);
    await Clipboard.setData(ClipboardData(text: jsonString));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
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
              if (data.rawJson != null)
                Tooltip(
                  message: _copied ? 'Copied!' : 'Copy manifest JSON',
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
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy_outlined,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          CredentialIndicator(result: data.validationResult),
          if (data.issuer != null || data.signedDate != null) ...[
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

  String _issuedByLine(ManifestViewData data) {
    final parts = <String>[];
    if (data.issuer != null) parts.add('Issued by ${data.issuer}');
    if (data.signedDate != null) {
      final formatted = DateFormat.yMMMd().add_jm().format(data.signedDate!);
      if (parts.isEmpty) {
        parts.add('Issued on $formatted');
      } else {
        parts.add('on $formatted');
      }
    }
    return parts.join(' ');
  }
}
