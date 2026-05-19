import 'package:c2pa_view/features/shared/widgets/rust_init_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(final Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('categoriseRustInitError', () {
    test('classifies content-hash-mismatch exception messages', () {
      const message =
          'Content hash on Dart side (123) is different from Rust side '
          '(456), indicating out-of-sync code.';
      expect(
        categoriseRustInitError(message),
        RustInitErrorCategory.contentHashMismatch,
      );
    });

    test('classifies WASM / CORS / fetch failures as webLoadFailure', () {
      expect(
        categoriseRustInitError('Failed to load WASM module'),
        RustInitErrorCategory.webLoadFailure,
      );
      expect(
        categoriseRustInitError('Blocked by CORS policy'),
        RustInitErrorCategory.webLoadFailure,
      );
      expect(
        categoriseRustInitError('Could not fetch the artefact'),
        RustInitErrorCategory.webLoadFailure,
      );
    });

    test('classifies timeout messages', () {
      expect(
        categoriseRustInitError('RustLib.init timed out after 15s'),
        RustInitErrorCategory.timeout,
      );
    });

    test('falls back to unknown for unfamiliar messages', () {
      expect(
        categoriseRustInitError('Some other thing went wrong'),
        RustInitErrorCategory.unknown,
      );
    });
  });

  group('RustInitErrorBanner', () {
    testWidgets('renders the title and the raw message in debug mode',
        (final tester) async {
      await tester.pumpWidget(
        _wrap(
          const RustInitErrorBanner(
            message: 'Content hash on Dart side (1) vs Rust side (2)',
          ),
        ),
      );

      expect(find.text('Rust library failed to load'), findsOneWidget);
      expect(
        find.textContaining('Content hash on Dart side'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders the content-hash remediation block for matching messages',
      (final tester) async {
        await tester.pumpWidget(
          _wrap(
            const RustInitErrorBanner(
              message:
                  'Content hash on Dart side (1) is different from Rust '
                  'side (2), indicating out-of-sync code.',
            ),
          ),
        );

        expect(
          find.textContaining('Dart bindings are out of sync'),
          findsOneWidget,
        );
        expect(
          find.text('flutter_rust_bridge_codegen generate'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders the web-load remediation for WASM errors',
        (final tester) async {
      await tester.pumpWidget(
        _wrap(
          const RustInitErrorBanner(
            message: 'Could not load wasm artefact (fetch failed)',
          ),
        ),
      );

      expect(
        find.textContaining('Rust/WASM artefact under web/pkg/'),
        findsOneWidget,
      );
      expect(find.text('./scripts/sync_web_pkg.sh'), findsOneWidget);
    });

    testWidgets('renders the timeout remediation for deadline messages',
        (final tester) async {
      await tester.pumpWidget(
        _wrap(
          const RustInitErrorBanner(
            message: 'RustLib.init timed out after 15s',
          ),
        ),
      );

      expect(
        find.textContaining('RustLib.init exceeded its 15s deadline'),
        findsOneWidget,
      );
    });

    testWidgets('renders the unknown-category remediation as a fallback',
        (final tester) async {
      await tester.pumpWidget(
        _wrap(
          const RustInitErrorBanner(message: 'Unknown failure mode'),
        ),
      );

      expect(
        find.textContaining(
          "RustLib.init failed for a reason this banner doesn't",
        ),
        findsOneWidget,
      );
    });
  });
}
