# c2pa_view Modernization Plan

This plan covers the full modernization of the `c2pa_view` Flutter package: aligning
with the latest C2PA specification, enriching domain models, handling custom fields,
integrating the newer UI from `c2pa_viewer_new`, and cleaning up.

We are making these updates as breaking changes: no backward compatibility.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Phase 1 — Expand Rust Bridge](#2-phase-1--expand-rust-bridge)
3. [Phase 2 — Enrich Domain Entities](#3-phase-2--enrich-domain-entities)
4. [Phase 3 — Custom Fields Handling](#4-phase-3--custom-fields-handling)
5. [Phase 4 — Mapping Layer (Entities → View Models)](#5-phase-4--mapping-layer)
6. [Phase 5 — Integrate New UI](#6-phase-5--integrate-new-ui)
7. [Phase 6 — Delete `c2pa_viewer_new`](#7-phase-6--delete-c2pa_viewer_new)
8. [Phase 7 — Test Files App & Tests](#8-phase-7--test-files-app--tests)
9. [Migration Notes](#9-migration-notes)

---

## 1. Architecture Overview

### Target: Feature-First Clean Architecture

```
lib/
├── c2pa_view.dart                              # Public barrel export
│
├── core/                                       # Cross-cutting concerns
│   ├── bridge/
│   │   └── c2pa_bridge_service.dart            # Thin wrapper over raw FFI calls
│   ├── theme/
│   │   └── c2pa_theme.dart                     # Theming (from c2pa_viewer_new)
│   └── util/
│       ├── json_traverse.dart                  # JSON path / traversal helpers
│       └── custom_field_extractor.dart         # Custom field collection logic
│
├── domain/
│   ├── entities/                               # Immutable domain entities
│   │   ├── manifest_store.dart
│   │   ├── manifest.dart
│   │   ├── ingredient.dart
│   │   ├── action.dart
│   │   ├── manifest_assertion.dart
│   │   ├── signature_info.dart                 # NEW — structured
│   │   ├── validation_status.dart              # NEW
│   │   ├── claim_generator_info.dart           # NEW
│   │   ├── thumbnail_data.dart                 # NEW
│   │   ├── exif_data.dart                      # NEW — parsed from assertion
│   │   ├── creative_work.dart                  # NEW — schema.org metadata
│   │   ├── training_mining.dart                # NEW — do-not-train info
│   │   └── custom_field.dart                   # NEW — generic key-value
│   ├── mappers/                                # Entity → View-model conversion
│   │   ├── provenance_mapper.dart              # ManifestStore → ProvenanceNode tree
│   │   └── manifest_view_data_mapper.dart      # Manifest → ManifestViewData
│   └── repositories/                           # Data access abstraction
│       └── manifest_repository.dart            # File/URL/bytes → ManifestStore
│
├── features/
│   ├── manifest_viewer/                        # Top-level combined viewer
│   │   └── manifest_viewer.dart                # C2paManifestViewer widget
│   ├── provenance_tree/                        # Provenance tree feature
│   │   ├── provenance_tree_viewer.dart
│   │   └── widgets/
│   │       ├── tree_node_card.dart
│   │       ├── tree_edge_painter.dart
│   │       └── zoom_controls.dart
│   ├── manifest_detail/                        # Detail panel feature
│   │   ├── manifest_detail_panel.dart
│   │   └── sections/
│   │       ├── detail_header.dart
│   │       ├── error_banner.dart
│   │       ├── thumbnail_section.dart
│   │       ├── content_summary_section.dart
│   │       ├── process_section.dart
│   │       ├── camera_capture_section.dart
│   │       ├── about_section.dart
│   │       └── custom_fields_section.dart      # NEW — for custom assertions
│   ├── custom_fields/                          # Custom field display feature
│   │   ├── custom_fields_table.dart            # Key-value table widget
│   │   └── custom_field_detail_dialog.dart     # Expandable detail for nested data
│   └── shared/
│       └── widgets/
│           ├── ingredient_card.dart
│           ├── sub_section.dart
│           ├── credential_indicator.dart
│           ├── collapsible_section.dart
│           └── c2pa_thumbnail.dart
│
└── src/
    └── rust/                                   # Generated FRB code (untouched)
        ├── frb_generated.dart
        ├── frb_generated.io.dart
        ├── frb_generated.web.dart
        └── api/
            └── c2pa.dart
```

### Key Principles

- **Feature-first**: Each UI concern is a self-contained feature folder.
- **Domain entities are pure Dart**: No Flutter imports, Equatable-based, parsed from JSON.
- **Mappers bridge domain → UI**: View models (`ProvenanceNode`, `ManifestViewData`)
  are constructed by mapper classes, not by the entities themselves.
- **Rust bridge is isolated**: Only `core/bridge/` touches the FFI layer directly.
- **Custom fields are first-class**: Any non-standard assertion or field is captured
  and displayable.

---

## 2. Phase 1 — Expand Rust Bridge

### Current State

The Rust API exposes two functions that return `Reader::json()` — a JSON string of the
full manifest store. This is already comprehensive, but certain data is not easily
accessible from the JSON alone.

### Changes

#### 2.1 Pin the NorthGuard/c2pa-rs dependency

```toml
# rust/Cargo.toml — pin to a specific branch or tag
[dependencies]
c2pa = { git = "ssh://git@github.com/NorthGuard/c2pa-rs.git", branch = "main",
         features = ["file_io", "rust_native_crypto"] }
```

Consider adding a `rev = "..."` for reproducible builds, or committing `Cargo.lock`.

#### 2.2 Expose validation status

The `Reader` struct in c2pa-rs provides `validation_status()` which returns validation
results that aren't always in the JSON. Add a new Rust function:

```rust
#[flutter_rust_bridge::frb(sync)]
pub fn get_manifest_with_validation(
    file_bytes: Vec<u8>,
    format: String,
) -> Result<Option<String>, String> {
    let stream = std::io::Cursor::new(file_bytes);
    let reader = Reader::from_stream(&format, stream).ok();
    match reader {
        Some(r) => {
            // Build a combined JSON with manifest + validation
            let mut value: serde_json::Value = serde_json::from_str(&r.json())
                .map_err(|e| e.to_string())?;
            if let Some(statuses) = r.validation_status() {
                value["validation_status"] = serde_json::to_value(statuses)
                    .map_err(|e| e.to_string())?;
            }
            Ok(Some(value.to_string()))
        }
        None => Ok(None),
    }
}
```

#### 2.3 Expose thumbnail extraction

Thumbnails are embedded in C2PA manifests. The NorthGuard fork may expose thumbnail
bytes through the `Reader` API. Add a function to extract them:

```rust
#[flutter_rust_bridge::frb(sync)]
pub fn get_manifest_thumbnail(
    file_bytes: Vec<u8>,
    format: String,
) -> Result<Option<Vec<u8>>, String> {
    let stream = std::io::Cursor::new(file_bytes);
    let reader = Reader::from_stream(&format, stream)
        .map_err(|e| e.to_string())?;
    // Extract thumbnail from active manifest
    // Implementation depends on NorthGuard fork API
    todo!("Extract thumbnail bytes from reader")
}
```

> **Note**: The exact API depends on what the NorthGuard fork exposes. If thumbnails
> are already in the JSON as base64 in assertions (e.g. `c2pa.thumbnail.claim.jpeg`),
> they can be extracted on the Dart side instead.

#### 2.4 Existing functions

Remove `get_file_manifest` and `get_file_manifest_format` if they are no longer useful. We do not need backward compatibility.

#### 2.5 Regenerate FRB bindings

After adding new Rust functions:
```bash
flutter_rust_bridge_codegen generate
```

#### 2.6 Add `serde_json` dependency

```toml
[dependencies]
serde_json = "1"
```

### Deliverables

- [ ] Pin c2pa-rs dependency version/branch
- [ ] Add `get_manifest_with_validation` function
- [ ] Add `get_manifest_thumbnail` function (if needed)
- [ ] Add `serde_json` dependency
- [ ] Regenerate FRB bindings
- [ ] Commit `Cargo.lock` (remove from `.gitignore`)

---

## 3. Phase 2 — Enrich Domain Entities

### Current State

| Entity             | Fields                                                              |
|--------------------|---------------------------------------------------------------------|
| `ManifestStore`    | `activeManifest`, `manifests`                                       |
| `Manifest`         | `claimGenerator`, `title`, `format`, `signatureInfo` (raw Map),     |
|                    | `label`, `ingredients`, `assertions`, `actions`                     |
| `Action`           | `action`, `when`, `changed`, `parameters`, `creators`,              |
|                    | `sourceType`, `related`, `reason`, `description`                    |
| `Ingredient`       | `title`, `format`, `documentId`, `instanceId`, `provenance`,        |
|                    | `hash`, `activeManifest`, `description`, `informationalUri`, `label`|
| `ManifestAssertion`| `label`, `data` (raw Map), `instance`, `kind`                       |

### New Entities to Add

#### 3.1 `SignatureInfo`

Replace the raw `Map<String, dynamic>? signatureInfo` in `Manifest` with a structured entity.

```dart
class SignatureInfo extends Equatable {
  final String? issuer;
  final String? certSerialNumber;
  final DateTime? time;
  final String? algorithm;

  // Certificate chain info
  final List<CertificateInfo>? certificateChain;
}

class CertificateInfo extends Equatable {
  final String? subject;
  final String? issuer;
  final DateTime? notBefore;
  final DateTime? notAfter;
  final String? serialNumber;
}
```

**JSON path**: `manifest.signature_info` — fields: `issuer`, `cert_serial_number`,
`time`, `alg`.

#### 3.2 `ValidationStatus`

```dart
enum ValidationStatusCode {
  claimSignatureValidated,
  signingCredentialTrusted,
  timestampTrusted,
  // ... other codes from C2PA spec
  assertionHashedURIMismatch,
  algorithmUnsupported,
  unknown,
}

class ValidationStatusEntry extends Equatable {
  final String code;
  final String? url;
  final String? explanation;

  bool get isError => !code.contains('.validated') && !code.contains('.trusted');
}
```

**JSON path**: `manifest.validation_status` — an array of `{code, url, explanation}`.

#### 3.3 `ClaimGeneratorInfo`

```dart
class ClaimGeneratorInfo extends Equatable {
  final String name;
  final String? version;
  final Map<String, dynamic>? icon;
}
```

**JSON path**: `manifest.claim_generator_info` — an array of `{name, version, icon}`.

#### 3.4 `ThumbnailData`

```dart
class ThumbnailData extends Equatable {
  final String format;          // e.g. "image/jpeg"
  final String? identifier;     // assertion reference
  final Uint8List? data;        // raw bytes (if embedded/extracted)
}
```

**JSON path**: `manifest.thumbnail` — `{format, identifier}`. The actual bytes may
come from assertion data or from the Rust bridge thumbnail extraction function.

#### 3.5 `ExifData`

Parsed from the `stds.exif` or `stds.iptc` assertions.

```dart
class ExifData extends Equatable {
  final String? creator;
  final String? copyright;
  final DateTime? captureDate;
  final String? cameraMake;
  final String? cameraModel;
  final String? lensMake;
  final String? lensModel;
  final String? exposureTime;
  final String? fNumber;
  final String? focalLength;
  final String? iso;
  final int? width;
  final int? height;
  final double? latitude;
  final double? longitude;
}
```

**JSON path**: Extracted from assertion with label `stds.exif` (data contains EXIF
key-value pairs using EXIF tag names).

#### 3.6 `CreativeWork`

Parsed from `stds.schema-org.CreativeWork` assertion.

```dart
class CreativeWork extends Equatable {
  final String? author;
  final String? copyrightNotice;
  final String? copyrightHolder;
  final String? producer;
  final String? creditText;
  final String? website;
  final List<SocialAccount> socialAccounts;
  final Map<String, dynamic>? rawData;   // for custom fields within
}

class SocialAccount extends Equatable {
  final String platform;
  final String url;
}
```

**JSON path**: Assertion with label `stds.schema-org.CreativeWork`.

#### 3.7 `TrainingMining`

Parsed from `c2pa.training-mining` assertion.

```dart
class TrainingMining extends Equatable {
  final bool doNotTrain;
  final bool doNotMine;
  final Map<String, dynamic>? entries;    // per-use constraint entries
}
```

**JSON path**: Assertion with label `c2pa.training-mining` — contains `entries` array
with `use` and `constraint_info`.

#### 3.8 Expand `Manifest`

```dart
class Manifest extends Equatable {
  // Existing fields
  final String? claimGenerator;
  final String? title;
  final String? format;
  final String? label;
  final String? instanceId;                         // NEW
  final List<Ingredient> ingredients;
  final List<ManifestAssertion> assertions;
  final List<Action>? actions;

  // Structured replacements
  final SignatureInfo? signatureInfo;                // CHANGED: was Map
  final List<ClaimGeneratorInfo> claimGeneratorInfo; // NEW
  final ThumbnailData? thumbnail;                    // NEW

  // Parsed from assertions
  final ExifData? exifData;                          // NEW
  final CreativeWork? creativeWork;                   // NEW
  final TrainingMining? trainingMining;               // NEW

  // Validation
  final List<ValidationStatusEntry> validationStatus; // NEW

  // Custom fields (everything non-standard)
  final List<CustomField> customFields;               // NEW
}
```

#### 3.9 Expand `Ingredient`

Add fields from the C2PA spec that are currently missing:

```dart
class Ingredient extends Equatable {
  // ... existing fields ...

  // NEW fields
  final String? relationship;        // "parentOf", "componentOf", "inputTo"
  final ThumbnailData? thumbnail;    // ingredient thumbnail
  final ManifestStore? manifestStore; // nested manifest store if present
  final List<ValidationStatusEntry> validationStatus;
  final Map<String, dynamic>? metadata;
}
```

#### 3.10 Keep `ManifestAssertion` for raw/custom assertions

`ManifestAssertion` remains as-is — it stores the raw `label` + `data` map. This is
important for custom/unknown assertions that don't fit into any known entity.

### Assertion Routing Logic

During `Manifest.fromJson`, assertions should be routed:

| Assertion label                     | Parsed into              | Kept in assertions list? |
|-------------------------------------|--------------------------|--------------------------|
| `c2pa.actions`                      | `List<Action>`           | No (already done)        |
| `stds.exif`                         | `ExifData`               | No                       |
| `stds.schema-org.CreativeWork`      | `CreativeWork`           | No                       |
| `c2pa.training-mining`              | `TrainingMining`         | No                       |
| `c2pa.thumbnail.*`                  | `ThumbnailData`          | No                       |
| `c2pa.hash.*`                       | (internal, not displayed)| No                       |
| **Everything else** (custom/vendor) | `CustomField`            | Yes (kept in assertions) |

### Deliverables

- [ ] Create `SignatureInfo` entity
- [ ] Create `ValidationStatusEntry` entity
- [ ] Create `ClaimGeneratorInfo` entity
- [ ] Create `ThumbnailData` entity
- [ ] Create `ExifData` entity with assertion parser
- [ ] Create `CreativeWork` entity with assertion parser
- [ ] Create `TrainingMining` entity with assertion parser
- [ ] Create `CustomField` entity
- [ ] Expand `Manifest` with new fields + assertion routing
- [ ] Expand `Ingredient` with new fields
- [ ] Update `ManifestStore` to support validation status
- [ ] Update all `fromJson` factories
- [ ] Write unit tests for parsing

---

## 4. Phase 3 — Custom Fields Handling

### Problem

C2PA manifests can contain vendor-specific or application-specific assertions and fields
that don't fit the standard schema. These appear in several places:

1. **Custom assertions** — assertions with non-standard labels (e.g. `com.vendor.foo`)
2. **Custom parameters in actions** — the `parameters` map in actions can contain
   arbitrary vendor-specific data
3. **Extra fields in known assertions** — a `stds.exif` assertion might contain
   non-standard EXIF extensions
4. **Ingredient metadata** — ingredients can carry vendor-specific metadata
5. **Claim generator info extensions** — extra fields in `claim_generator_info`

### Solution: `CustomField` Entity

```dart
class CustomField extends Equatable {
  final String key;           // The field key or assertion label
  final dynamic value;        // The value (String, num, bool, Map, or List)
  final String source;        // Where it came from: "assertion", "action_parameter",
                              // "ingredient_metadata", "claim_generator_info", etc.
  final String? parentLabel;  // Parent context (e.g. assertion label, action name)

  bool get isSimple => value is String || value is num || value is bool;
  bool get isMap => value is Map;
  bool get isList => value is List;

  /// Flatten a nested Map/List into displayable key-value pairs.
  List<MapEntry<String, String>> toFlatEntries();
}
```

### Extraction Strategy

#### 4.1 Custom Assertions

After routing known assertions (exif, creative work, etc.), remaining assertions
are converted to `CustomField` entries:

```dart
for (final assertion in remainingAssertions) {
  customFields.add(CustomField(
    key: assertion.label,
    value: assertion.data,
    source: 'assertion',
  ));
}
```

#### 4.2 Custom Action Parameters

When parsing actions, any `parameters` that don't map to known fields:

```dart
for (final action in actions) {
  if (action.parameters != null) {
    for (final entry in action.parameters!.entries) {
      if (!_knownActionParams.contains(entry.key)) {
        customFields.add(CustomField(
          key: entry.key,
          value: entry.value,
          source: 'action_parameter',
          parentLabel: action.action,
        ));
      }
    }
  }
}
```

#### 4.3 Custom Fields in Known Assertions

When parsing `stds.exif`, `stds.schema-org.CreativeWork`, etc., collect any fields
that aren't part of the known schema:

```dart
// In ExifData.fromJson:
final knownKeys = {'creator', 'copyright', 'captureDate', ...};
final customEntries = json.entries
    .where((e) => !knownKeys.contains(e.key))
    .map((e) => CustomField(key: e.key, value: e.value, source: 'exif_extension'));
```

### Display Strategy

#### 4.4 `CustomFieldsTable` Widget

A simple widget that renders custom fields as a key-value table:

```dart
class CustomFieldsTable extends StatelessWidget {
  final List<CustomField> fields;

  // Renders as:
  // ┌────────────────┬──────────────────────┐
  // │ Key            │ Value                │
  // ├────────────────┼──────────────────────┤
  // │ com.vendor.foo │ bar                  │
  // │ customSetting  │ { nested: "object" } │  ← tap to expand
  // └────────────────┴──────────────────────┘
}
```

For simple values (string, number, bool): display inline.
For complex values (Map, List): show a summary with a "tap to expand" detail dialog
that renders the nested structure.

#### 4.5 `CustomFieldDetailDialog`

A dialog that renders nested JSON structures in a readable tree format:

```dart
class CustomFieldDetailDialog extends StatelessWidget {
  final CustomField field;

  // Shows key at top, then recursively renders the value tree
  // using indentation and collapsible sections.
}
```

#### 4.6 Integration Points

Custom fields appear in the detail panel:
- A new **"Custom Fields"** collapsible section at the bottom of `ManifestDetailPanel`
- Within each action's detail if it has custom parameters
- Within ingredients if they have custom metadata

### Deliverables

- [ ] Create `CustomField` entity with `toFlatEntries()`
- [ ] Implement custom field extraction in `Manifest.fromJson`
- [ ] Implement custom field extraction for action parameters
- [ ] Implement custom field extraction for known assertion extras
- [ ] Create `CustomFieldsTable` widget
- [ ] Create `CustomFieldDetailDialog` widget
- [ ] Add `CustomFieldsSection` to detail panel
- [ ] Write tests for custom field extraction

---

## 5. Phase 4 — Mapping Layer

### Purpose

Bridge the gap between domain entities (`ManifestStore`, `Manifest`, etc.) and
UI view models (`ProvenanceNode`, `ManifestViewData`, etc.) from `c2pa_viewer_new`.

### 5.1 `ProvenanceMapper`

Converts a `ManifestStore` into a `ProvenanceNode` tree.

```dart
class ProvenanceMapper {
  /// Build a provenance tree from a ManifestStore.
  ///
  /// The root node is the active manifest's asset.
  /// Children are ingredients, resolved recursively through the manifest store.
  static ProvenanceNode mapToTree(ManifestStore store) {
    final activeLabel = store.activeManifest;
    final activeManifest = store.manifests[activeLabel];
    if (activeManifest == null) throw StateError('No active manifest');

    return _buildNode(
      manifest: activeManifest,
      label: activeLabel!,
      store: store,
      visited: {},
    );
  }

  static ProvenanceNode _buildNode({
    required Manifest manifest,
    required String label,
    required ManifestStore store,
    required Set<String> visited,
  }) {
    visited.add(label);

    // Build children from ingredients
    final children = <ProvenanceNode>[];
    for (final ingredient in manifest.ingredients) {
      if (ingredient.activeManifest != null &&
          !visited.contains(ingredient.activeManifest)) {
        final childManifest = store.manifests[ingredient.activeManifest];
        if (childManifest != null) {
          children.add(_buildNode(
            manifest: childManifest,
            label: ingredient.activeManifest!,
            store: store,
            visited: visited,
          ));
        }
      } else {
        // Ingredient without manifest — leaf node
        children.add(ProvenanceNode(
          id: ingredient.label ?? ingredient.title ?? 'unknown',
          title: ingredient.title,
          validationResult: const ValidationResult.noCredential(),
        ));
      }
    }

    return ProvenanceNode(
      id: label,
      title: manifest.title,
      thumbnail: _extractThumbnail(manifest),
      validationResult: _mapValidation(manifest.validationStatus),
      issuer: manifest.signatureInfo?.issuer,
      signedDate: manifest.signatureInfo?.time,
      children: children,
      manifestViewData: ManifestViewDataMapper.map(manifest),
    );
  }
}
```

### 5.2 `ManifestViewDataMapper`

Converts a `Manifest` into a `ManifestViewData`.

```dart
class ManifestViewDataMapper {
  static ManifestViewData map(Manifest manifest) {
    return ManifestViewData(
      title: manifest.title,
      thumbnail: _toImageProvider(manifest.thumbnail),
      validationResult: _mapValidation(manifest.validationStatus),
      issuer: manifest.signatureInfo?.issuer,
      signedDate: manifest.signatureInfo?.time,
      generativeInfo: _extractGenerativeInfo(manifest),
      claimGenerator: _mapClaimGenerator(manifest),
      actions: _mapActions(manifest.actions),
      ingredients: _mapIngredients(manifest.ingredients),
      aiToolsUsed: _extractAiTools(manifest),
      exifData: _mapExif(manifest.exifData),
      producer: manifest.creativeWork?.producer,
      socialAccounts: _mapSocial(manifest.creativeWork?.socialAccounts),
      doNotTrain: manifest.trainingMining?.doNotTrain ?? false,
      website: manifest.creativeWork?.website,
      // NEW: custom fields for the UI
      customFields: manifest.customFields,
    );
  }
}
```

### 5.3 Validation Mapping

```dart
ValidationResult _mapValidation(List<ValidationStatusEntry> statuses) {
  if (statuses.isEmpty) return const ValidationResult.noCredential();
  final hasError = statuses.any((s) => s.isError);
  if (hasError) {
    final msg = statuses.where((s) => s.isError).map((s) => s.explanation).join('; ');
    return ValidationResult.invalid(msg);
  }
  return const ValidationResult.valid();
}
```

### 5.4 Generative Info Extraction

Detect AI generation from actions and assertions:
- Check for `digitalSourceType` in actions (e.g. `trainedAlgorithmicMedia`)
- Check for AI-related `softwareAgent` in actions
- Determine `GenerativeType` based on composition

### Deliverables

- [ ] Create `ProvenanceMapper` class
- [ ] Create `ManifestViewDataMapper` class
- [ ] Implement validation result mapping
- [ ] Implement generative info extraction
- [ ] Implement EXIF mapping
- [ ] Implement social account mapping
- [ ] Implement thumbnail `ImageProvider` creation
- [ ] Write unit tests for all mappers

---

## 6. Phase 5 — Integrate New UI

### Strategy

Copy UI code from `c2pa_viewer_new/lib/src/` into `c2pa_view/lib/`, adapting the
directory structure to the target architecture.

### 6.1 Files to Copy

| Source (c2pa_viewer_new)                              | Destination (c2pa_view)                                   |
|-------------------------------------------------------|-----------------------------------------------------------|
| `src/theme/c2pa_theme.dart`                           | `core/theme/c2pa_theme.dart`                              |
| `src/domain/models/provenance_node.dart`              | `domain/models/provenance_node.dart`                      |
| `src/domain/models/manifest_view_data.dart`           | `domain/models/manifest_view_data.dart`                   |
| `src/domain/models/validation_result.dart`            | `domain/models/validation_result.dart`                    |
| `src/features/manifest_viewer.dart`                   | `features/manifest_viewer/manifest_viewer.dart`           |
| `src/features/provenance_tree/` (all files)           | `features/provenance_tree/`                               |
| `src/features/manifest_detail/` (all files)           | `features/manifest_detail/`                               |
| `src/features/shared/widgets/` (all files)            | `features/shared/widgets/`                                |

### 6.2 Modifications Required

1. **Update all imports** from `package:c2pa_manifest_viewer/...` to
   `package:c2pa_view/...`.

2. **Add `ManifestViewData.customFields`** field to the view model:
   ```dart
   class ManifestViewData {
     // ... existing fields ...
     final List<CustomField> customFields;  // NEW
   }
   ```

3. **Add `CustomFieldsSection`** to `ManifestDetailPanel`:
   ```dart
   // After AboutSection:
   if (data.customFields.isNotEmpty)
     CustomFieldsSection(fields: data.customFields),
   ```

4. **Remove old widget/ directory**: Delete the old `lib/widget/` files:
   - `content_credentials_widget.dart`
   - `actions_list_widget.dart`
   - `assertions_list_widget.dart`
   - `ingredients_list_widget.dart`
   - `signature_info_widget.dart`

### 6.3 Update Barrel Export

```dart
// lib/c2pa_view.dart
export 'core/bridge/c2pa_bridge_service.dart';
export 'core/theme/c2pa_theme.dart';

export 'domain/entities/entities.dart';
export 'domain/models/provenance_node.dart';
export 'domain/models/manifest_view_data.dart';
export 'domain/models/validation_result.dart';
export 'domain/mappers/provenance_mapper.dart';

export 'features/manifest_viewer/manifest_viewer.dart';
export 'features/provenance_tree/provenance_tree_viewer.dart';
export 'features/manifest_detail/manifest_detail_panel.dart';
export 'features/custom_fields/custom_fields_table.dart';

export 'src/rust/frb_generated.dart' show RustLib;
```

### 6.4 Update `pubspec.yaml`

Add `intl` dependency (used by `c2pa_viewer_new` for date formatting):

```yaml
dependencies:
  equatable: ^2.0.7
  flutter_rust_bridge: ^2.9.0
  http: ^1.3.0
  intl: ^0.19.0          # NEW
  plugin_platform_interface: ^2.0.2
```

### Deliverables

- [ ] Copy theme files
- [ ] Copy domain models (ProvenanceNode, ManifestViewData, ValidationResult)
- [ ] Copy provenance tree feature
- [ ] Copy manifest detail feature
- [ ] Copy shared widgets
- [ ] Copy manifest viewer feature
- [ ] Update all imports
- [ ] Add CustomFieldsSection to detail panel
- [ ] Add custom fields to ManifestViewData
- [ ] Remove old widget/ directory
- [ ] Update barrel export
- [ ] Update pubspec.yaml
- [ ] Verify no broken imports

---

## 7. Phase 6 — Delete `c2pa_viewer_new`

### Steps

1. Verify all code has been integrated and tested.
2. Remove the entire `c2pa_viewer_new/` directory.
3. Remove any references to `c2pa_manifest_viewer` in the workspace.

```bash
rm -rf c2pa_viewer_new/
```

### Deliverables

- [ ] Verify integration is complete
- [ ] Delete `c2pa_viewer_new/` directory
- [ ] Verify no remaining references

---

## 8. Phase 7 — Test Files App & Tests

### 8.1 Update Example App

The testfiles_app should be updated to use the new UI:

```dart
// testfiles_app/lib/main.dart
import 'package:c2pa_view/c2pa_view.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: C2paViewerTheme(
        data: C2paViewerThemeData(),
        child: ManifestViewerPage(),
      ),
    );
  }
}

class ManifestViewerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Load file → ManifestStore → ProvenanceMapper → C2paManifestViewer
    final store = ManifestStore.fromLocalPath(filePath);
    if (store == null) return Text('No manifest');

    final rootNode = ProvenanceMapper.mapToTree(store);
    return C2paManifestViewer(rootNode: rootNode);
  }
}
```

### 8.2 Integration Tests

Update existing integration tests and add new ones:

- **Parsing tests**: Verify all new entities parse correctly from real C2PA JSON
- **Custom field tests**: Verify custom fields are extracted from various positions
- **Mapper tests**: Verify ProvenanceMapper builds correct tree structure
- **Widget tests**: Verify UI renders without errors

### 8.3 Unit Tests

- Test each entity's `fromJson` factory
- Test `CustomField.toFlatEntries()`
- Test `ProvenanceMapper.mapToTree()` with various manifest structures
- Test `ManifestViewDataMapper.map()` output

### Deliverables

- [ ] Update testfiles_app to use new UI
- [ ] Add entity parsing unit tests
- [ ] Add custom field extraction tests
- [ ] Add mapper unit tests
- [ ] Verify existing integration tests still pass

---

## 9. Migration Notes

### Breaking Changes

| Change                             | Migration path                                        |
|------------------------------------|-------------------------------------------------------|
| `ContentCredentialsWidget` removed | Use `C2paManifestViewer` with `ProvenanceMapper`      |
| `Manifest.signatureInfo` type      | Was `Map<String, dynamic>?`, now `SignatureInfo?`      |
| Old widget imports removed         | Update to new feature imports                         |
| `ManifestStore.fromLocalPath` etc. | Still works, but now returns enriched entities        |

### Execution Order

```
Phase 1 (Rust)  →  Phase 2 (Entities)  →  Phase 3 (Custom Fields)
                                              ↓
Phase 4 (Mappers)  →  Phase 5 (UI Integration)  →  Phase 6 (Cleanup)
                                                        ↓
                                                  Phase 7 (Tests)
```

Phases 2 and 3 can be worked on in parallel. Phase 4 depends on both.
Phase 5 depends on Phase 4. Phase 6 depends on Phase 5 verification.
