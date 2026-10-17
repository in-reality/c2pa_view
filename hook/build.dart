import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

Future<void> main(final List<String> args) async {
  await build(args, (final input, final output) async {
    await FlutterRustBridgeNativeAssetsBuilder(
      extraCargoEnvironmentVariables: {
        'CARGO_BUILD_JOBS': '1',
        'CARGO_INCREMENTAL': '0',
        ..._iosDeploymentTarget(input.json),
      },
    ).run(input: input, output: output);
  });
}

/// Forwards the hook's iOS minimum into Cargo.
///
/// The Rust native-assets builder replaces the process environment and does
/// not pass this minimum through. Without it, OpenSSL records the SDK version
/// while rustc links at its default. The iOS SDK hides `___chkstk_darwin` for
/// that default, so the native library fails to link.
Map<String, String> _iosDeploymentTarget(final Map<String, Object?> json) {
  final config = json['config'];
  if (config is! Map) {
    return const {};
  }
  final extensions = config['extensions'];
  if (extensions is! Map) {
    return const {};
  }
  final codeAssets = extensions['code_assets'];
  if (codeAssets is! Map || codeAssets['target_os'] != 'ios') {
    return const {};
  }
  final ios = codeAssets['ios'];
  if (ios is! Map) {
    return const {};
  }
  final version = ios['target_version'];
  if (version is! int) {
    return const {};
  }
  return {'IPHONEOS_DEPLOYMENT_TARGET': '$version.0'};
}
