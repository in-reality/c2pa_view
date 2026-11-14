import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';
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

    for (final name in [
      'build.dart',
      'cargo_dependencies.dart',
      'native_capabilities.dart',
    ]) {
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
[features]
standalone-bridge = []
c2pa-http = []
c2pa-openssl = []
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
#[cfg(not(feature = "standalone-bridge"))]
compile_error!("hook must explicitly enable standalone-bridge");
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
    // Exercise the real hook entrypoint and public hook input configuration.
    // Reuse one output file: opt-out must replace a prior emitted asset.
    final hookOutput = root.uri.resolve('trials/output.json');
    Future<ProcessResult> trial(final Map<String, Object?> defines) async {
      final input = BuildInputBuilder()
        ..setupShared(
          packageRoot: root.uri,
          packageName: 'c2pa_view',
          outputDirectoryShared: root.uri.resolve('trials/shared/'),
          outputFile: hookOutput,
          userDefines: PackageUserDefines(
            workspacePubspec: PackageUserDefinesSource(
              defines: defines,
              basePath: root.uri,
            ),
          ),
        )
        ..setupBuildInput();
      input.config.setupBuild(linkingEnabled: false);
      input.addExtension(
        CodeAssetExtension(
          targetArchitecture: Architecture.current,
          targetOS: OS.current,
          linkModePreference: LinkModePreference.dynamic,
        ),
      );
      final inputFile = File.fromUri(root.uri.resolve('trials/input.json'));
      inputFile.parent.createSync(recursive: true);
      inputFile.writeAsStringSync(jsonEncode(input.build().json));
      return Process.run(dartExecutable.path, [
        'hook/build.dart',
        '--config=${inputFile.path}',
      ], workingDirectory: root.path);
    }

    Map outputJson() =>
        jsonDecode(File.fromUri(hookOutput).readAsStringSync()) as Map;
    for (final defines in <Map<String, Object?>>[
      {},
      {'build_native': true},
      {'build_native': null},
    ]) {
      final result = await trial(defines);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect((outputJson()['assets'] as List).length, 1);
      expect(
        jsonEncode(outputJson()['assets']),
        contains(OS.current.dylibFileName('c2pa_view')),
      );
    }
    // Cargo would fail with this manifest: false must return before the builder.
    final manifest = File('${root.path}/rust/Cargo.toml');
    final validManifest = manifest.readAsStringSync();
    manifest.writeAsStringSync('invalid Cargo manifest');
    final disabled = await trial({'build_native': false});
    expect(
      disabled.exitCode,
      0,
      reason: '${disabled.stdout}\n${disabled.stderr}',
    );
    expect(outputJson()['assets'] ?? [], isEmpty);
    expect(outputJson()['dependencies'] ?? [], isEmpty);
    manifest.writeAsStringSync(validManifest);
    for (final value in <Object>['false', 0, <Object>[], <String, Object>{}]) {
      final result = await trial({'build_native': value});
      expect(result.exitCode, isNot(0));
      expect(
        '${result.stdout}\n${result.stderr}',
        contains('build_native must be a boolean'),
      );
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
