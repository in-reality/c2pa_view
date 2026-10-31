import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:c2pa_view/domain/entities/validation_status.dart';
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
    this.previewSource,
    this.inputValidationEvidence = const [],
    this.validationResult = const ValidationResult.noCredential(),
    this.issuer,
  });
  final String? title;
  final ImageProvider? thumbnail;

  /// Provenance of the preview, separate from this node’s credential.
  final PreviewSource? previewSource;

  /// Recorded input failures, with their containing claim, kept apart from current checks.
  final List<InputValidationEvidence> inputValidationEvidence;
  final ValidationResult validationResult;
  final String? issuer;
}

/// Identifies the claim attesting a displayed preview resource.
@immutable
class PreviewSource {
  const PreviewSource({
    required this.containingManifest,
    required this.validationResult,
    this.isIngredient = false,
  });

  /// Claim containing the resource reference (may depict a different claim).
  final String containingManifest;

  /// Current validation of the containing claim, never inherited by the node.
  /// Null means the supplied JSON did not include current reader diagnostics.
  final ValidationResult? validationResult;

  /// Whether the image came from a consuming claim's ingredient preview.
  final bool isIngredient;
}

/// A consuming claim's recorded failure to validate its imported input.
@immutable
class InputValidationEvidence {
  const InputValidationEvidence({
    required this.containingManifest,
    required this.failures,
    this.containingValidation,
  });

  /// Claim which recorded this import result, rather than the ancestor signature.
  final String containingManifest;

  /// Current validation of the claim recording the import; null when uncomputed.
  final ValidationResult? containingValidation;

  /// Non-trust failures retained even when the current certificate is trusted.
  final List<ValidationStatusEntry> failures;
}
