import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

Future<void> main(final List<String> args) async {
  await build(args, (final input, final output) async {
    await const FlutterRustBridgeNativeAssetsBuilder(
      extraCargoEnvironmentVariables: {
        'CARGO_BUILD_JOBS': '1',
        'CARGO_INCREMENTAL': '0',
      },
    ).run(input: input, output: output);
  });
}
