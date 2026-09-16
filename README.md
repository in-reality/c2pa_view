# c2pa_view

A Flutter plugin for reading and displaying [C2PA](https://c2pa.org/) (Coalition for Content Provenance and Authenticity) content credentials. It extracts embedded C2PA manifests from media files using the official `c2pa-rs` Rust library and renders provenance data as interactive Flutter widgets.

- 🗃️ Read C2PA manifests from files or raw bytes.
- 🌳 Display an interactive provenance tree with a detail panel
- 📜 Show manifest details as a popup overlay from any button
- 🔍 Access structured provenance data: actions, ingredients, signatures, EXIF, AI generation info, and more
- ✅ Full validation with trust-list checking

<img src="https://raw.githubusercontent.com/in-reality/c2pa_view/refs/heads/main/screenshots/c2pa_view_screenshot.png" />

## Setup

### Version compatibility note

This package intentionally pins `flutter_rust_bridge` to a specific tested
version (`2.12.0`) instead of a broad range.

If you need a different FRB version, update it together with regenerated
bindings and verify all target platforms before publishing.

### Initialization

Before any C2PA operations, initialize the Rust library once at app startup:

```dart
import 'package:c2pa_view/c2pa_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const MyApp());
}
```

### Loading a ManifestStore

A `ManifestStore` is the root object containing all C2PA manifests found in a file. Create one from any source:

```dart
// From a local file path
final store = ManifestStore.fromLocalPath('/path/to/image.jpg');

// From raw bytes and MIME type
final store = ManifestStore.fromBytes(imageBytes, 'image/jpeg');

// From a detached sidecar (.c2pa) plus the bound asset bytes
final store = await ManifestStore.fromDetached(
  manifestBytes: sidecarBytes,
  assetBytes: imageBytes,
  assetFormat: 'image/jpeg',
);

// From a URL (async)
final store = await ManifestStore.fromUrl('https://example.com/image.jpg');
```

All methods return `null` if no C2PA manifest is found. For detached reads,
invalid manifest bytes throw; hash/signature problems appear in
`validationStatus` / `validation_results` like embedded manifests.

### API summary

| Entry point | Input | Validation |
|-------------|-------|------------|
| `ManifestStore.fromLocalPath` | File path | Embedded manifest; optional trust anchors |
| `ManifestStore.fromBytes` | Asset bytes + MIME | Embedded manifest; optional trust anchors |
| `ManifestStore.fromUrl` | HTTP URL | Embedded manifest; optional trust anchors |
| `ManifestStore.fromDetached` | Sidecar bytes + asset bytes + MIME | Full hash binding and signatures; optional trust anchors |
| `getManifestStoreJsonFromBytes` | Manifest-store bytes only | **Unverified** (no asset binding) |
| `getDetachedManifestJsonFromBytes` | Sidecar + asset bytes | Validated detached read (JSON) |

Web builds load the regenerated `web/pkg/` artifacts (`scripts/sync_web_pkg.sh`
after Rust changes). Detached validation uses the same FRB/WASM exports as
native.

**VM integration:** `flutter test test/detached_manifest_test.dart` (requires the
monorepo signing corpus; uses `dart:io` — not a Chrome target).

**Web smoke (manual, testfiles_app):**

1. From `frontend/c2pa_view`, run `scripts/sync_web_pkg.sh`.
2. `cd testfiles_app && flutter run -d chrome`.
3. Confirm the home screen loads without a Rust init timeout banner.
4. Tap **Validate detached sidecar** on the **Detached sidecar check** card.
5. Expect `validation_state: Valid` and `(assertion.dataHash.match present)`.
   Without trust-list initialization, `signingCredential.untrusted` in the JSON
   is normal — the smoke check only requires hash binding success.

## Usage: Full Viewer

`C2paManifestViewer` shows an interactive provenance tree on the left and a detail panel on the right. Clicking a tree node updates the detail panel.

```dart
import 'package:c2pa_view/c2pa_view.dart';

// 1. Load the manifest store
final store = ManifestStore.fromBytes(imageBytes, 'image/jpeg');
if (store == null) return const Text('No manifest found');

// 2. Build the provenance graph (DAG of all manifests)
final graph = ProvenanceMapper.mapToGraph(store);

// 3. Display the full viewer wrapped in a theme
C2paViewerTheme(
  data: const C2paViewerThemeData(),
  child: C2paManifestViewer(
    graph: graph,
    mimeType: 'image/jpeg',
    mediaImage: MemoryImage(imageBytes), // fallback when no embedded thumbnail
  ),
);
```

See [`testfiles_app/lib/main.dart`](testfiles_app/lib/main.dart) — the `ManifestViewerPage` class demonstrates this pattern with network-loaded images.

## Usage: Popup from an Icon Button

`showManifestDetailPopup` opens a positioned overlay anchored to any widget. This is useful for adding a "content credentials" button to image thumbnails.

```dart
import 'package:c2pa_view/c2pa_view.dart';

// 1. Load the manifest store
final store = ManifestStore.fromBytes(imageBytes, 'image/jpeg');
if (store == null) return;

// 2. Get the active manifest and map it to a view model
final manifest = store.manifests[store.activeManifest]!;
final viewData = ManifestViewDataMapper.map(manifest);

// 3. Use a Builder to get a BuildContext anchored to the button
Builder(
  builder: (buttonContext) {
    return IconButton(
      icon: const Icon(Icons.verified_user),
      onPressed: () {
        showManifestDetailPopup(
          buttonContext,
          data: viewData,
          mimeType: 'image/jpeg',
          mediaImage: MemoryImage(imageBytes),
        );
      },
    );
  },
);
```

See [`testfiles_app/lib/main.dart`](testfiles_app/lib/main.dart) — the `_PopupDemoCard` class demonstrates this pattern with a thumbnail and icon button.

## Theming

Wrap your widget tree with `C2paViewerTheme` to customize the appearance. All c2pa_view widgets read from this theme, falling back to defaults when absent.

```dart
C2paViewerTheme(
  data: const C2paViewerThemeData(
    validColor: Color(0xFF1B8D3E),
    invalidColor: Color(0xFFD93025),
    sidebarWidth: 400,
  ),
  child: C2paManifestViewer(graph: graph),
);

// Dark mode
C2paViewerTheme(
  data: C2paViewerThemeData.dark(),
  child: C2paManifestViewer(graph: graph),
);
```

`C2paViewerThemeData` controls: validation status colors, surface/border/text colors, six text style tiers, layout dimensions (sidebar width, thumbnail size, node spacing), and border radii.

## Data-Only Usage

You can use the package purely for data extraction without any widgets:

```dart
final store = ManifestStore.fromLocalPath('/path/to/image.jpg');
if (store == null) return;

final manifest = store.manifests[store.activeManifest]!;

// Access structured data
print(manifest.title);
print(manifest.signatureInfo?.issuer);
print(manifest.ingredients.length);
print(manifest.actions?.map((a) => a.action));

// Or get the raw JSON string
final json = C2paBridgeService.getManifestJsonFromFile('/path/to/image.jpg');
```

## Platforms

This is an FFI plugin with native Rust code compiled for all platforms:

| Platform | Status |
|----------|--------|
| Android  | Supported |
| iOS      | Supported |
| Linux    | Supported |
| macOS    | Supported |
| Windows  | Supported |
