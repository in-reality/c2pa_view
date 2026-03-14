# c2pa_manifest_viewer

A reusable Flutter package providing widgets for viewing
[C2PA](https://c2pa.org/) content credentials manifests. Modeled after the
[verify-site](https://verify.contentauthenticity.org/) viewer by the Content
Authenticity Initiative.

## Features

- **Provenance Tree Viewer** — A zoomable, pannable tree visualization showing
  an asset and its ingredients with credential status indicators.
- **Manifest Detail Panel** — A sidebar panel displaying full manifest
  information: thumbnail, AI content summary, process details, EXIF / camera
  capture data, issuer info, and more.
- **Combined Viewer** — A convenience widget that places the tree and sidebar
  side-by-side, managing selection state automatically.
- **Customizable Theme** — Full control over colors, typography, and sizing
  through `C2paViewerThemeData`.

## Architecture

The package follows a **feature-first, clean architecture**:

```
lib/
├── c2pa_manifest_viewer.dart           # Public barrel export
└── src/
    ├── domain/models/                  # View models & data types
    │   ├── manifest_view_data.dart     # Sidebar view model
    │   ├── provenance_node.dart        # Tree node model
    │   └── validation_result.dart      # Credential status
    ├── features/
    │   ├── manifest_viewer.dart        # Combined viewer widget
    │   ├── provenance_tree/            # Tree visualization feature
    │   │   ├── provenance_tree_viewer.dart
    │   │   └── widgets/
    │   ├── manifest_detail/            # Sidebar detail feature
    │   │   ├── manifest_detail_panel.dart
    │   │   └── sections/
    │   └── shared/widgets/             # Reusable building blocks
    └── theme/
        └── c2pa_theme.dart             # Theming system
```

## Quick Start

### Combined Viewer

```dart
import 'package:c2pa_manifest_viewer/c2pa_manifest_viewer.dart';

C2paViewerTheme(
  data: const C2paViewerThemeData(),
  child: C2paManifestViewer(
    rootNode: ProvenanceNode(
      id: 'root',
      title: 'photo.jpg',
      validationResult: const ValidationResult.valid(),
      issuer: 'Adobe Inc.',
      signedDate: DateTime.now(),
      manifestViewData: ManifestViewData(
        title: 'photo.jpg',
        issuer: 'Adobe Inc.',
        signedDate: DateTime.now(),
        validationResult: const ValidationResult.valid(),
        // ... additional manifest data
      ),
      children: [
        // ingredient nodes
      ],
    ),
    onNodeSelected: (node) {
      print('Selected: ${node.title}');
    },
  ),
);
```

### Individual Widgets

Use the tree and sidebar independently for custom layouts:

```dart
Row(
  children: [
    Expanded(
      child: ProvenanceTreeViewer(
        rootNode: rootNode,
        selectedNodeId: selectedId,
        onNodeSelected: (node) => setState(() => selectedId = node.id),
      ),
    ),
    ManifestDetailPanel(
      data: selectedManifestData,
      onIngredientTap: (ingredient) { /* handle tap */ },
    ),
  ],
);
```

## View Models

### `ProvenanceNode`

Represents a node in the provenance tree:

| Field              | Type                | Description                               |
| ------------------ | ------------------- | ----------------------------------------- |
| `id`               | `String`            | Unique identifier                         |
| `title`            | `String?`           | Asset filename / title                    |
| `thumbnail`        | `ImageProvider?`    | Thumbnail image                           |
| `validationResult` | `ValidationResult`  | Credential status                         |
| `issuer`           | `String?`           | Certificate issuer                        |
| `signedDate`       | `DateTime?`         | Signature timestamp                       |
| `children`         | `List<…>`           | Ingredient nodes                          |
| `manifestViewData` | `ManifestViewData?` | Detail data shown when this node selected |

### `ManifestViewData`

Contains all data rendered in the detail sidebar:

| Field             | Type                           | Section          |
| ----------------- | ------------------------------ | ---------------- |
| `title`           | `String?`                      | Header           |
| `thumbnail`       | `ImageProvider?`               | Thumbnail        |
| `validationResult`| `ValidationResult`             | Header / Banner  |
| `issuer`          | `String?`                      | Header / About   |
| `signedDate`      | `DateTime?`                    | Header / About   |
| `generativeInfo`  | `GenerativeInfo?`              | Content Summary  |
| `claimGenerator`  | `ClaimGeneratorDisplayInfo?`   | Process          |
| `actions`         | `List<ActionDisplayInfo>`      | Process          |
| `ingredients`     | `List<IngredientDisplayInfo>`  | Process          |
| `aiToolsUsed`     | `List<String>`                 | Process          |
| `exifData`        | `ExifDisplayData?`             | Camera Capture   |
| `producer`        | `String?`                      | About            |
| `socialAccounts`  | `List<SocialAccountDisplayInfo>`| About           |
| `doNotTrain`      | `bool`                         | About            |

## Theming

Wrap your widget tree with `C2paViewerTheme`:

```dart
C2paViewerTheme(
  data: C2paViewerThemeData.dark(), // or customize individual properties
  child: ManifestDetailPanel(data: data),
);
```

## Detail Panel Sections

The sidebar mirrors the verify-site layout:

1. **Sticky Header** — Title, credential indicator, "Issued by X on Y"
2. **Error Banner** — Red (invalid) or orange (unrecognized) warning
3. **Thumbnail** — Large thumbnail with optional lightbox
4. **Content Summary** — AI generation information
5. **Process** (collapsible) — App/device, AI tools, actions, ingredients
6. **Camera Capture** (collapsible) — EXIF data, location
7. **About** (collapsible) — Issuer, date, producer, social accounts, AI training

## License

See [LICENSE](LICENSE).
