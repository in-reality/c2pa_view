import 'dart:async';

/// Host-backend tests start without the standalone bridge. Override the parent
/// test bootstrap so accidental standalone dispatch cannot inherit a loaded API.
Future<void> testExecutable(final FutureOr<void> Function() testMain) async {
  await testMain();
}
