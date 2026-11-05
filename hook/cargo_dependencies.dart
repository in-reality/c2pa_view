import 'dart:io';

/// Tracks Cargo's actual inputs, including checkout paths containing spaces.
///
/// native_toolchain_rust currently splits dep-info on every space. Recover
/// those inputs until upstream understands Makefile escaping. Tracking the
/// generated depfile itself would invalidate every otherwise unchanged build.
Set<Uri> cargoDependencies({
  required final Uri library,
  required final Uri crate,
}) {
  final depfile = File.fromUri(
    library.replace(path: library.path.replaceFirst(RegExp(r'\.[^.]+$'), '.d')),
  );
  final inputs = parseCargoDepInfo(
    depfile.readAsStringSync(),
    baseDirectory: crate,
  );
  if (inputs.isEmpty ||
      inputs.any((final uri) => !File.fromUri(uri).existsSync())) {
    throw StateError('Cargo dep-info must identify existing source files');
  }
  for (final name in [
    'Cargo.toml',
    'Cargo.lock',
    'rust-toolchain.toml',
    'build.rs',
  ]) {
    final file = File.fromUri(crate.resolve(name));
    if (file.existsSync()) {
      inputs.add(file.uri);
    }
  }
  return inputs;
}

/// Reads dependency rules without treating escaped spaces as path separators.
///
/// Empty phony rules and Cargo's environment comments are not file inputs.
Set<Uri> parseCargoDepInfo(
  final String contents, {
  required final Uri baseDirectory,
}) {
  final inputs = <Uri>{};
  final logicalLines = contents.replaceAll(RegExp(r'\\\r?\n'), ' ').split('\n');
  for (final line in logicalLines) {
    if (line.trimLeft().startsWith('#')) {
      continue;
    }
    final separator = RegExp(r'(?<!\\):(?:\s|$)').firstMatch(line);
    if (separator == null) {
      continue;
    }
    final dependencies = line.substring(separator.end);
    for (final token in RegExp(
      r'(?:\\[ \t\\#:]|[^\s])+',
    ).allMatches(dependencies)) {
      final path = token
          .group(0)!
          .replaceAllMapped(
            RegExp(r'\\([ \t\\#:])'),
            (final match) => match.group(1)!,
          )
          .replaceAll(r'$$', r'$');
      final windows =
          Platform.isWindows || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
      inputs.add(baseDirectory.resolveUri(Uri.file(path, windows: windows)));
    }
  }
  return inputs;
}
