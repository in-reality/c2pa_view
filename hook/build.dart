import 'package:code_assets/code_assets.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

import 'cargo_dependencies.dart';

Future<void> main(final List<String> args) async {
  await build(args, (final input, final output) async {
    final nativeOutput = BuildOutputBuilder();
    await FlutterRustBridgeNativeAssetsBuilder(
      extraCargoEnvironmentVariables: {
        'CARGO_BUILD_JOBS': '1',
        'CARGO_INCREMENTAL': '0',
        ..._appleCargoEnvironment(input.json),
      },
    ).run(input: input, output: nativeOutput);
    // Keep the builder's bundle assets, replacing its incorrectly split inputs.
    for (final asset in nativeOutput.build().assets.code) {
      output.assets.code.add(asset);
      final library = asset.file;
      if (library != null) {
        output.dependencies.addAll(
          cargoDependencies(
            library: library,
            crate: input.packageRoot.resolve('rust/'),
          ),
        );
      }
    }
  });
}

/// Preserves loadable Apple libraries and forwards the iOS minimum into Cargo.
///
/// The Rust native-assets builder replaces the process environment and does
/// not pass this minimum through. Without it, OpenSSL records the SDK version
/// while rustc links at its default. The iOS SDK hides `___chkstk_darwin` for
/// that default, so the native library fails to link.
Map<String, String> _appleCargoEnvironment(final Map<String, Object?> json) {
  final config = json['config'];
  if (config is! Map) {
    return const {};
  }
  final extensions = config['extensions'];
  if (extensions is! Map) {
    return const {};
  }
  final codeAssets = extensions['code_assets'];
  if (codeAssets is! Map) {
    return const {};
  }
  final targetOS = codeAssets['target_os'];
  final environment = <String, String>{
    // Rust 1.97's stripping can misalign Mach-O LINKEDIT (rust-lang/rust#157750).
    if (targetOS == 'ios' || targetOS == 'macos')
      'CARGO_PROFILE_RELEASE_STRIP': 'none',
  };
  if (targetOS != 'ios') {
    return environment;
  }
  final ios = codeAssets['ios'];
  if (ios is! Map) {
    return environment;
  }
  final version = ios['target_version'];
  if (version is! int) {
    return environment;
  }
  return {...environment, 'IPHONEOS_DEPLOYMENT_TARGET': '$version.0'};
}
