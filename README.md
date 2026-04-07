# c2pa_view

A Flutter plugin for reading and displaying [C2PA](https://c2pa.org/) (Coalition for Content Provenance and Authenticity) content credentials. It extracts embedded C2PA manifests from media files using the official `c2pa-rs` Rust library and renders provenance data as interactive Flutter widgets.

- 🗃️ Read C2PA manifests from local files, URLs, or raw bytes
- 🌳 Display an interactive provenance tree with a detail panel
- 📜 Show manifest details as a popup overlay from any button
- 🔍 Access structured provenance data: actions, ingredients, signatures, EXIF, AI generation info, and more
- ✅ Full validation with trust-list checking

## Setup

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

// From a URL (async)
final store = await ManifestStore.fromUrl('https://example.com/image.jpg');
```

All methods return `null` if no C2PA manifest is found.

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
