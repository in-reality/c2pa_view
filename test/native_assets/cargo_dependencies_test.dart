import 'dart:io';

import 'package:test/test.dart';

import '../../hook/cargo_dependencies.dart';

void main() {
  test('Cargo paths with escaped spaces remain whole dependencies', () {
    final dependencies = parseCargoDepInfo(
      r'/checkout\ with\ spaces/libviewer.so: '
      r'/checkout\ with\ spaces/src/lib.rs '
      r'/checkout\ with\ spaces/src/api.rs'
      '\n\n'
      r'/checkout\ with\ spaces/src/lib.rs:'
      '\n',
      baseDirectory: Uri.directory('/checkout with spaces/'),
    );
    expect(dependencies, {
      Uri.file('/checkout with spaces/src/lib.rs'),
      Uri.file('/checkout with spaces/src/api.rs'),
    });
  });

  test('Windows drive separators are not mistaken for rule separators', () {
    final dependencies = parseCargoDepInfo(
      r'C:\checkout\ with\ spaces\target\viewer.dll: '
      r'C:\checkout\ with\ spaces\src\lib.rs',
      baseDirectory: Uri.directory(r'C:\checkout with spaces', windows: true),
    );
    expect(dependencies, {
      Uri.file(r'C:\checkout with spaces\src\lib.rs', windows: true),
    });
  });

  test(
    'continuations, relative inputs, escapes and duplicates are handled',
    () {
      final dependencies = parseCargoDepInfo(
        'target/lib.so: src/lib.rs \\\n'
        r' src/file\ name.rs src/hash\#name.rs src/lib.rs'
        '\n# env-dep:VALUE=not-a-source\n',
        baseDirectory: Uri.directory('/checkout/'),
      );
      expect(dependencies, {
        Uri.file('/checkout/src/lib.rs'),
        Uri.file('/checkout/src/file name.rs'),
        Uri.file('/checkout/src/hash#name.rs'),
      });
    },
  );

  test(
    'tracks source content and Cargo config, excluding generated dep-info',
    () {
      final root = Directory.systemTemp.createTempSync(
        'cargo inputs with spaces ',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final source = File('${root.path}/src/lib.rs')
        ..createSync(recursive: true)
        ..writeAsStringSync('pub fn version() -> u8 { 1 }');
      final manifest = File('${root.path}/Cargo.toml')
        ..writeAsStringSync('[package]');
      final lock = File('${root.path}/Cargo.lock')
        ..writeAsStringSync('version = 4');
      final toolchain = File('${root.path}/rust-toolchain.toml')
        ..writeAsStringSync('[toolchain]');
      final library = File('${root.path}/target/libc2pa_view.so')
        ..createSync(recursive: true);
      final depfile = File('${root.path}/target/libc2pa_view.d')
        ..writeAsStringSync(
          '${library.path.replaceAll(' ', r'\ ')}: '
          '${source.path.replaceAll(' ', r'\ ')}\n',
        );

      final inputs = cargoDependencies(library: library.uri, crate: root.uri);
      expect(
        inputs,
        containsAll([source.uri, manifest.uri, lock.uri, toolchain.uri]),
      );
      expect(inputs, isNot(contains(depfile.uri)));
      expect(inputs, isNot(contains(library.uri)));
      expect(
        inputs.every((final uri) => File.fromUri(uri).existsSync()),
        isTrue,
      );
    },
  );

  test('missing or empty dep-info cannot silently cache a native build', () {
    final root = Directory.systemTemp.createTempSync('cargo missing inputs ');
    addTearDown(() => root.deleteSync(recursive: true));
    final library = root.uri.resolve('libc2pa_view.so');
    expect(
      () => cargoDependencies(library: library, crate: root.uri),
      throwsA(isA<FileSystemException>()),
    );
    File.fromUri(root.uri.resolve('libc2pa_view.d')).writeAsStringSync('');
    expect(
      () => cargoDependencies(library: library, crate: root.uri),
      throwsStateError,
    );
  });
}
