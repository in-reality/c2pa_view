import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:c2pa_view/domain/entities/validation_status.dart';
import 'package:flutter/widgets.dart';

/// A compact, self-contained summary of a single C2PA manifest suitable for
/// display in a tree node card or an ingredient list item.
///
/// Preview and recorded ingredient evidence retain their own source context;
/// neither changes the current credential result.
@immutable
class ManifestSummary {
  const ManifestSummary({
    this.title,
    this.thumbnail,
    this.previewSource,
    this.inputValidationEvidence = const [],
    this.ingredientDescriptions = const [],
    this.validationResult = const ValidationResult.noCredential(),
    this.issuer,
  });
  final String? title;
  final ImageProvider? thumbnail;

  /// Provenance of the preview, separate from this node’s credential.
  final PreviewSource? previewSource;

  /// Recorded input failures, with their containing claim, kept apart from current checks.
  final List<InputValidationEvidence> inputValidationEvidence;

  /// Verbatim recorded prose, retaining consuming-claim and edge context.
  final List<IngredientDescription> ingredientDescriptions;
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

/// Recorded ingredient prose and its original edge, independent of trust.
@immutable
class IngredientDescription {
  /// Preserves payload text and structural attribution without interpretation.
  const IngredientDescription({
    required this.containingManifest,
    required this.ingredientIndex,
    required this.description,
    this.ingredientLabel,
    this.ingredientTitle,
    this.targetManifest,
    this.isExternalIncomingEdge = false,
  });

  /// Claim containing this ingredient assertion.
  final String containingManifest;

  /// Array position, distinguishing parallel edges with equal optional labels.
  final int ingredientIndex;

  /// Original nonempty text; never a viewer-established verification result.
  final String description;

  /// Original ingredient assertion label, when recorded.
  final String? ingredientLabel;

  /// Original ingredient title, when recorded.
  final String? ingredientTitle;

  /// Referenced claim, which may be absent from the loaded store.
  final String? targetManifest;

  /// Whether this edge comes only from outside the summary's directed ancestry.
  /// Cycle edges already in that ancestry stay false, even if they also point
  /// into this node. This distinguishes other parents in ingredient rows; it
  /// never controls prose visibility or credential validity.
  final bool isExternalIncomingEdge;

  /// Payload attribution plus array position; adds no semantic heading.
  String get sourceLabel =>
      '$containingManifest → '
      '${ingredientLabel ?? ingredientTitle ?? targetManifest ?? ''} '
      '[$ingredientIndex]';
}
