/// Reusable Flutter widgets for viewing C2PA content credentials manifests.
///
/// This package provides two primary widgets:
///
/// - [ProvenanceTreeViewer] — A zoomable, pannable tree showing the asset
///   and its ingredients with credential status indicators.
/// - [ManifestDetailPanel] — A sidebar panel showing detailed manifest
///   information including thumbnail, process, EXIF, and issuer data.
///
/// Use [C2paManifestViewer] for a combined layout with both widgets,
/// or use them independently for custom arrangements.
///
/// ## Quick Start
///
/// ```dart
/// C2paManifestViewer(
///   rootNode: ProvenanceNode(
///     id: 'root',
///     title: 'photo.jpg',
///     validationResult: ValidationResult.valid(),
///     manifestViewData: ManifestViewData(
///       title: 'photo.jpg',
///       issuer: 'Adobe',
///       signedDate: DateTime.now(),
///     ),
///   ),
/// )
/// ```
library;

// Domain models
export 'src/domain/models/manifest_view_data.dart';
export 'src/domain/models/provenance_node.dart';
export 'src/domain/models/validation_result.dart';

// Theme
export 'src/theme/c2pa_theme.dart';

// Feature: Combined viewer
export 'src/features/manifest_viewer.dart';

// Feature: Provenance tree
export 'src/features/provenance_tree/provenance_tree_viewer.dart';

// Feature: Manifest detail panel
export 'src/features/manifest_detail/manifest_detail_panel.dart';

// Feature: Shared widgets
export 'src/features/shared/widgets/c2pa_thumbnail.dart';
export 'src/features/shared/widgets/collapsible_section.dart';
export 'src/features/shared/widgets/credential_indicator.dart';
export 'src/features/shared/widgets/ingredient_card.dart';
export 'src/features/shared/widgets/sub_section.dart';
