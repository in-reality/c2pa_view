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

```dart
SingleChildScrollView showManifest(String path) {
  // We make a preview (optional) for showing the content with the manifest
  final preview = Image.file(
    File(path),
    height: 200,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return const Text('Error loading image');
    },
  );

  // Make content credentials widget with the preview
  final ccw = ContentCredentialsWidget(
    source: path,
    contentPreview: preview,
  );

  // We wrap in scrollable because the manifest can be long
  return SingleChildScrollView(
    child: ccw,
  );
}
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


