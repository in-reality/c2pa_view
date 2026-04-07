# c2pa_view — AI Context

## Overview

`c2pa_view` is an open-source Flutter plugin that reads and displays [C2PA](https://c2pa.org/) (Coalition for Content Provenance and Authenticity) content credentials. It extracts embedded C2PA manifests from media files using the official `c2pa-rs` Rust library via Flutter Rust Bridge, then renders the provenance data as interactive Flutter widgets.

**Package name:** `c2pa_view`
**Version:** 0.1.1
**Homepage:** https://github.com/in-reality/c2pa_view
**Platforms:** Android, iOS, Linux, macOS, Windows (FFI plugin)

## Architecture

### Data Flow

```
File / URL / Bytes
       ↓
  Rust FFI (c2pa-rs)  →  JSON string with validation_status
       ↓
  ManifestStore.fromJson()  →  Domain entities (Equatable)
       ↓  (two display paths)
       ├── ProvenanceMapper.mapToGraph()  →  ProvenanceGraph
       │       ↓
       │   C2paManifestViewer          (full view: tree + detail panel)
       │
       └── ManifestViewDataMapper.map()  →  ManifestViewData
               ↓
           showManifestDetailPopup()    (popup overlay from a button)
```

### Layer Structure

```
lib/
├── c2pa_view.dart                      # Barrel export (public API)
├── api.dart                            # Legacy free-function API
├── core/
│   ├── bridge/c2pa_bridge_service.dart # Static wrapper: FFI → ManifestStore
│   └── theme/c2pa_theme.dart           # C2paViewerThemeData + InheritedWidget
├── domain/
│   ├── entities/                       # Raw C2PA JSON → Equatable domain models
│   ├── models/                         # Display-ready view models
│   └── mappers/                        # Entity → ViewModel transformations
├── features/
│   ├── manifest_viewer/                # C2paManifestViewer (composite widget)
│   ├── provenance_tree/                # Zoomable/pannable DAG viewer
│   ├── manifest_detail/                # Detail panel, popup, content sections
│   ├── custom_fields/                  # Vendor-specific assertion table
│   └── shared/widgets/                 # Reusable cards, indicators, sections
└── src/rust/                           # Generated flutter_rust_bridge bindings
```

### Rust Layer

The `rust/` directory contains a Cargo crate (`cdylib` + `staticlib` + `lib`) that wraps `c2pa-rs`. Four sync FFI functions are exposed:

| Function | Input | Output |
|---|---|---|
| `get_file_manifest` | bytes + file path | manifest JSON (MIME guessed from path) |
| `get_file_manifest_format` | bytes + MIME type | manifest JSON |
| `get_manifest_with_validation` | bytes + MIME type | manifest JSON with `validation_status` injected |
| `get_manifest_with_validation_from_path` | bytes + file path | manifest JSON with `validation_status` injected |

The Dart-side `C2paBridgeService` and `ManifestStore` convenience constructors default to the validation-aware variants.

### Domain Entities

All entities use `Equatable` for value equality.

| Entity | C2PA Concept |
|---|---|
| `ManifestStore` | Root: contains all manifests, the active manifest label, and top-level validation |
| `Manifest` | Single manifest with assertions, signature, ingredients, actions |
| `Ingredient` | Source file reference (may link to another manifest) |
| `Action` | Recorded editing/creation action (e.g. `c2pa.created`, `c2pa.edited`) |
| `SignatureInfo` / `CertificateInfo` | Signing certificate chain data |
| `ExifData` | EXIF metadata (camera, lens, exposure, GPS) |
| `CreativeWork` / `SocialAccount` | schema.org CreativeWork assertion |
| `TrainingMining` | AI training/mining preference (`c2pa.training-mining`) |
| `ThumbnailData` | Embedded thumbnail (raw bytes or data URI) |
| `CustomField` | Generic key-value for vendor-specific assertions |
| `ValidationStatusEntry` | Individual validation check result (code + URL + explanation) |

### View Models

| Model | Purpose |
|---|---|
| `ManifestViewData` | All display-ready data for one manifest's detail view |
| `ManifestSummary` | Compact summary (title, thumbnail, validation status, issuer) |
| `ProvenanceGraph` / `ProvenanceNode` / `ProvenanceEdge` | DAG structure for the tree viewer |
| `ValidationResult` / `ValidationStatus` | Normalized validation state (valid / invalid / untrusted / unrecognized / noCredential) |
| `GenerativeInfo` / `GenerativeType` | AI generation detection |

### Widgets

| Widget | Description |
|---|---|
| `C2paManifestViewer` | Full composite: provenance tree (left) + detail panel (right) |
| `ProvenanceTreeViewer` | Zoomable, pannable DAG with interactive node selection |
| `ManifestDetailPanel` | Fixed-width sidebar showing manifest details |
| `ManifestDetailContent` | Scrollable detail body (used by both panel and popup) |
| `showManifestDetailPopup()` | Anchored popup overlay showing manifest details |
| `CustomFieldsTable` | Flattened key-value table for vendor-specific fields |

### Theme

`C2paViewerThemeData` is propagated via `C2paViewerTheme` (an `InheritedWidget`). It controls:
- Validation status colors (valid, invalid, untrusted, unrecognized, no-credential)
- Surface/border/text/icon colors
- Six text style tiers (titleLarge through label)
- Layout dimensions (sidebar width, thumbnail size, node dimensions, spacing)
- Border radii

A `C2paViewerThemeData.dark()` factory provides dark-mode defaults.

## Dependencies

| Dependency | Role |
|---|---|
| `flutter_rust_bridge` 2.11.1 | Rust ↔ Dart FFI bridge |
| `c2pa-rs` (fork: NorthGuard/c2pa-rs) | C2PA manifest reading and validation |
| `equatable` | Value equality for domain entities |
| `http` | URL fetching for `fromUrl` |
| `intl` | Date formatting in detail views |

## Initialization

Before any C2PA operations, the Rust library must be initialized:

```dart
await RustLib.init();
```

This loads the native binary (or WASM on web). Must be called once, typically in `main()` after `WidgetsFlutterBinding.ensureInitialized()`.

## Key Patterns

- **Entities are immutable.** All domain entities extend `Equatable` and have `const` constructors.
- **Mappers are pure static classes.** `ProvenanceMapper` and `ManifestViewDataMapper` contain only static methods with no side effects.
- **Two display paths.** The full viewer (`C2paManifestViewer`) needs a `ProvenanceGraph`; the popup (`showManifestDetailPopup`) needs a `ManifestViewData`. Both are derived from the same `ManifestStore`.
- **Theme is opt-in.** Widgets fall back to `C2paViewerThemeData.defaults` when no `C2paViewerTheme` ancestor exists.
- **Generated code in `src/rust/`.** Never hand-edit files under `lib/src/rust/` — run `flutter_rust_bridge_codegen generate` after modifying `rust/src/api/*.rs`.

## Testing

- `testfiles_app/` is a standalone Flutter app that loads C2PA test files from URLs and demonstrates both the full viewer and the popup.
- `testfiles_app/integration_test/` contains integration tests for manifest parsing.
- `rust/tests/validate_evidence.rs` contains Rust-level tests validating positive files, negative (tampered) files, and files with no manifest.
