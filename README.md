# c2pa_view

A Flutter package for reading and displaying C2PA (Coalition for Content Provenance and Authenticity) manifests in your Flutter applications.

## Overview

C2PA is an open technical standard that provides publishers, creators, and consumers with tools to trace the origin of different types of media. This Flutter package allows you to:

- 📃 Read C2PA manifests from local files, URLs, or raw bytes
- 🎨 Display content credentials in a customizable UI
- 🔍 Access detailed information about media provenance, including:
  - Content format and generator information
  - Actions performed on the content
  - Ingredients (source files) used
  - Assertions about the content
  - Signature information


## Example

In the example directory we use the following code to show a C2PA manifest from a local file:
```dart
// We make a preview (optional) for showing the content with the manifest
final preview = Image.file(
  file,
  height: 200,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return const Text('Error loading image');
  },
);

// Get manifest store from file
final manifestStore = ManifestStore.fromLocalPath(file.path);

// Check if manifest store is null (if there is no manifest)
if (manifestStore == null) {
  return const SingleChildScrollView(
    child: Text('No manifest found'),
  );
}

// Make content credentials widget with manifest store and preview
// We wrap in scrollable as the manifest can be long
final ccw = SingleChildScrollView(
  child: ContentCredentialsWidget(
    manifestStore: manifestStore,
    contentPreview: preview,
  ),
);
```

The `ManifestStrore` can be created in multiple ways:
```dart
// From a local path
final store = ManifestStore.fromLocalPath('/local/path/to/file.jpg');

// From bytes and format / mime-type
final bytes = [...]; // Your image bytes
final store4 = ManifestStore.fromBytes(bytes, 'image/jpeg');

// From a URL
final store = await ManifestStore.fromUrl('https://example.com/image.jpg');
```

## Customization

The `ContentCredentialsWidget` supports various styling options:

```dart
ContentCredentialsWidget(
  source: path,
  contentPreview: preview,
  titleStyle: TextStyle(...),
  sectionTitleStyle: TextStyle(...),
  contentLabelStyle: TextStyle(...),
  contentStyle: TextStyle(...),
)
```

## Note

This package was created during a Hackathon sprint and is in a very early stage.
We hope to develop further and provide more features in the future 😁


