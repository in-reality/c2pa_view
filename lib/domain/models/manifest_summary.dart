import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:flutter/widgets.dart';

/// A compact, self-contained summary of a single C2PA manifest suitable for
/// display in a tree node card or an ingredient list item.
///
/// Carries exactly the fields needed by the display widget -- nothing about
/// parent manifests, child manifests, or other contextual data.
@immutable
class ManifestSummary {

  const ManifestSummary({
    this.title,
    this.thumbnail,
    this.validationResult = const ValidationResult.noCredential(),
    this.issuer,
  });
  final String? title;
  final ImageProvider? thumbnail;
  final ValidationResult validationResult;
  final String? issuer;
}
