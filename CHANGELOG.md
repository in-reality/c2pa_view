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
