import 'package:flutter/widgets.dart';

import 'validation_result.dart';

/// A compact, self-contained summary of a single C2PA manifest suitable for
/// display in a tree node card or an ingredient list item.
///
/// Carries exactly the fields needed by the display widget -- nothing about
/// parent manifests, child manifests, or other contextual data.
@immutable
class ManifestSummary {
  final String? title;
  final ImageProvider? thumbnail;
  final ValidationResult validationResult;
  final String? issuer;

  const ManifestSummary({
    this.title,
    this.thumbnail,
    this.validationResult = const ValidationResult.noCredential(),
    this.issuer,
  });
}
