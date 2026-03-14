import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/manifest_view_data.dart';
import '../../../theme/c2pa_theme.dart';
import '../../shared/widgets/credential_indicator.dart';

/// Sticky header at the top of the detail panel.
///
/// Shows the asset title, "Issued by {issuer} on {date}", and
/// a credential status indicator.
class DetailHeader extends StatelessWidget {
  final ManifestViewData data;

  const DetailHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = C2paViewerTheme.of(context);

    return Container(
      color: theme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.title != null)
            Text(
              data.title!,
              style: theme.titleLargeStyle.copyWith(
                color: theme.textPrimaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          CredentialIndicator(result: data.validationResult),
          if (data.issuer != null || data.signedDate != null) ...[
            const SizedBox(height: 4),
            Text(
              _issuedByLine,
              style: theme.bodySmallStyle.copyWith(
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _issuedByLine {
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
