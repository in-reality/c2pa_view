## 0.5.0 (2026-09-16)

### Added

- Validated detached (sidecar) manifest reads via
  `ManifestStore.fromDetached` / `getDetachedManifestJsonFromBytes`, binding
  manifest-store JUMBF bytes to asset bytes with full hash and signature
  validation (native FFI and web WASM).
- Rust helpers `get_detached_manifest_with_validation*` and trust-anchor
  variants; web `*Utf8` return shapes match the embedded read path.

### Changed

- `getManifestStoreJsonFromBytes` is documented as an **unverified** store-only
  read (`verify_after_reading: false`); use the detached validated API when
  trust input is required.

## 0.2.0 (2026-04-08)

Major rewrite of the package architecture and UI.

- Added interactive provenance graph and detail experience via
  `C2paManifestViewer` and `ProvenanceTreeViewer`.
- Added popup detail support with `showManifestDetailPopup`.
- Replaced legacy display flow with modular domain entities, mappers,
  and feature widgets.
- Improved manifest parsing and validation mapping.
- Updated Rust bridge integration and retained multi-platform FFI
  support (Android, iOS, Linux, macOS, Windows).

## 0.1.1 (2025-05-02)

### Fixes
- Fixed image link in README.md

## 0.1.0 (2025-04-30)

Initial release of the `c2pa_view` package, providing basic C2PA manifest reading and display 
capabilities.
Note that it is not the intention of this package to be used for creating or editing C2PA manifests.

### Features
- Initial implementation of C2PA manifest reading from:
  - Local files
  - URLs
  - Raw bytes
- Basic UI components for displaying content credentials:
  - `ContentCredentialsWidget` for displaying manifest information
  - Support for content preview
  - Customizable styling options
- Manifest information display:
  - Content metadata (title, format, claim generator)
  - Actions performed on the content
  - Ingredients (source files) used
  - Assertions about the content
  - Signature information
- Basic error handling for missing manifests

### Technical Details
- Built with `Flutter`
- Uses `Rust` for core C2PA manifest parsing: `c2pa` crate
- Supports basic styling customization through TextStyle parameters

### Known Limitations
- Early stage implementation
- Limited error handling
- Basic UI customization options
