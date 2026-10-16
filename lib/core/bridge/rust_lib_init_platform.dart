import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

/// Native consumers retain FRB's default library loading.
Future<ExternalLibrary?> loadRustExternalLibrary() async => null;

/// Browser readiness has no native counterpart.
void markRustLibraryReady() {}
