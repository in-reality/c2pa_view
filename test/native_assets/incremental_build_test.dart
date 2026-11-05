import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('a source change rebuilds native code in a path with spaces', () async {
    final temporary = Directory.systemTemp.createTempSync(
      'c2pa native inputs ',
    );
    final root = Directory(temporary.resolveSymbolicLinksSync());
    addTearDown(() => root.deleteSync(recursive: true));
    void write(final String path, final String contents) {
      File('${root.path}/$path')
        ..createSync(recursive: true)
        ..writeAsStringSync(contents);
    }

    for (final name in ['build.dart', 'cargo_dependencies.dart']) {
      write('hook/$name', File('hook/$name').readAsStringSync());
    }
    write(
      'rust/rust-toolchain.toml',
      File('rust/rust-toolchain.toml').readAsStringSync(),
    );
    write('pubspec.yaml', '''
name: c2pa_view
environment:
  sdk: ^3.11.0
dependencies:
  code_assets: ">=1.2.1 <3.0.0"
  flutter_rust_bridge_hooks: 2.13.0
''');
    write('rust/Cargo.toml', '''
[package]
name = "c2pa_view"
version = "0.1.0"
edition = "2024"
[lib]
crate-type = ["cdylib", "staticlib"]
''');
    write('bin/main.dart', '''
import 'dart:ffi';
@Native<Int32 Function()>(
  symbol: 'build_revision',
  assetId: 'package:c2pa_view/src/rust/frb_generated.io.dart',
)
external int buildRevision();
void main() => print(buildRevision());
''');

    // Under flutter test, Platform.resolvedExecutable is flutter_tester.
    // Resolve the configured Flutter SDK instead of relying on PATH.
    final packageConfig = File('.dart_tool/package_config.json').absolute;
    final packages =
        (jsonDecode(packageConfig.readAsStringSync()) as Map)['packages']
            as List;
    final flutterPackage = packages.cast<Map>().singleWhere(
      (final package) => package['name'] == 'flutter',
    );
    final flutterRoot = Directory.fromUri(
      packageConfig.uri.resolve(flutterPackage['rootUri'] as String),
    ).uri;
    final dartExecutable = File.fromUri(
      flutterRoot.resolve(
        '../../bin/cache/dart-sdk/bin/'
        '${Platform.isWindows ? 'dart.exe' : 'dart'}',
      ),
    );
    expect(dartExecutable.existsSync(), isTrue, reason: dartExecutable.path);

    Future<String> dart(final List<String> arguments) async {
      final result = await Process.run(
        dartExecutable.path,
        arguments,
        workingDirectory: root.path,
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      return (result.stdout as String).trim();
    }

    void revision(final int value) => write('rust/src/lib.rs', '''
#[unsafe(no_mangle)]
pub extern "C" fn build_revision() -> i32 { $value }
''');

    await dart(['pub', 'get', '--offline']);
    revision(1);
    expect(await dart(['run', 'bin/main.dart']), endsWith('1'));
    // Settle any first-build Cargo.lock creation before testing invalidation.
    expect(await dart(['run', 'bin/main.dart']), endsWith('1'));
    revision(2);
    expect(await dart(['run', 'bin/main.dart']), endsWith('2'));
    expect(await dart(['run', 'bin/main.dart']), endsWith('2'));

    final outputs = Directory('${root.path}/.dart_tool/hooks_runner/c2pa_view')
        .listSync(recursive: true)
        .whereType<File>()
        .where((final file) => file.path.endsWith('/output.json'));
    final output = outputs.singleWhere((final file) {
      final json = jsonDecode(file.readAsStringSync()) as Map;
      return (json['dependencies'] as List? ?? []).contains(
        '${root.path}/rust/src/lib.rs',
      );
    });
    final timestamp = output.lastModifiedSync();
    expect(await dart(['run', 'bin/main.dart']), endsWith('2'));
    expect(
      output.lastModifiedSync(),
      timestamp,
      reason: 'An unchanged source must reuse the hook output.',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
