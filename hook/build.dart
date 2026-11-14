import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

import 'native_capabilities.dart';

import 'cargo_dependencies.dart';

Future<void> main(final List<String> args) async {
  await build(args, (final input, final output) async {
    final nativeOutput = BuildOutputBuilder();
    await FlutterRustBridgeNativeAssetsBuilder(
      enableDefaultFeatures: false,
      features: c2paCargoFeatures(
        input.userDefines['c2pa_http'],
        openssl: input.userDefines['c2pa_openssl'],
      ),
      extraCargoEnvironmentVariables: {
        'CARGO_BUILD_JOBS': '1',
        'CARGO_INCREMENTAL': '0',
        ..._appleCargoEnvironment(input.json),
        ...configuredCargoEnvironment(
          cargoHome: input.userDefines['cargo_home'],
          cargoOffline: input.userDefines['cargo_offline'],
          resolveCargoHome: () => input.userDefines.path('cargo_home'),
        ),
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

/// Optional host build configuration, never media/verifier policy.
/// Validate raw types before path(): hooks silently treats non-strings as absent.
Map<String, String> configuredCargoEnvironment({
  required final Object? cargoHome,
  required final Object? cargoOffline,
  required final Uri? Function() resolveCargoHome,
}) {
  if (cargoHome != null && (cargoHome is! String || cargoHome.trim().isEmpty)) {
    throw const FormatException('cargo_home must be a nonempty path string');
  }
  if (cargoOffline != null && cargoOffline is! bool) {
    throw const FormatException('cargo_offline must be a boolean');
  }
  String? home;
  if (cargoHome != null) {
    try {
      final uri = resolveCargoHome();
      if (uri == null ||
          uri.scheme != 'file' ||
          !uri.isAbsolute ||
          uri.hasQuery ||
          uri.hasFragment) {
        throw const FormatException('cargo_home must resolve to a file URI');
      }
      home = Directory.fromUri(uri).path;
      if (home.trim().isEmpty) {
        throw const FormatException('cargo_home resolved to an empty path');
      }
    } on Object {
      throw const FormatException(
        'cargo_home must resolve to a valid file path',
      );
    }
  }
  return {
    'CARGO_HOME': ?home,
    if (cargoOffline != null) 'CARGO_NET_OFFLINE': '$cargoOffline',
  };
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
