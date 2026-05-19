import 'dart:convert';

import 'package:c2pa_view/domain/entities/validation_status.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:c2pa_view/features/manifest_detail/sections/tampered_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _failures = [
  ValidationStatusEntry(
    code: 'assertion.dataHash.mismatch',
    url: 'https://example.com/dataHash',
    explanation: 'Data hash mismatch',
  ),
];

Widget _wrap(final Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('TamperedPlaceholder', () {
    testWidgets(
      'renders the warning copy and does not open the dialog before 10 taps',
      (final tester) async {
        await tester.pumpWidget(
          _wrap(
            const TamperedPlaceholder(
              result: ValidationResult.invalid(),
              failures: _failures,
              validationState: 'INVALID',
            ),
          ),
        );

        expect(
          find.textContaining('This file may have been tampered with'),
          findsOneWidget,
        );

        final placeholder = find.byType(TamperedPlaceholder);
        for (var i = 0; i < 9; i++) {
          await tester.tap(placeholder);
          await tester.pump();
        }

        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('opens an AlertDialog with failure details on the 10th tap',
        (final tester) async {
      await tester.pumpWidget(
        _wrap(
          const TamperedPlaceholder(
            result: ValidationResult.invalid(),
            failures: _failures,
            validationState: 'INVALID',
          ),
        ),
      );

      final placeholder = find.byType(TamperedPlaceholder);
      for (var i = 0; i < 10; i++) {
        await tester.tap(placeholder);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Validation problem details'), findsOneWidget);
      expect(find.text('assertion.dataHash.mismatch'), findsOneWidget);
      expect(find.text('Data hash mismatch'), findsOneWidget);
    });

    testWidgets('Copy button writes pretty-printed JSON to the clipboard',
        (final tester) async {
      Map<String, dynamic>? captured;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (final call) async {
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments as Map<dynamic, dynamic>;
            captured = jsonDecode(args['text'] as String)
                as Map<String, dynamic>;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(
        _wrap(
          const TamperedPlaceholder(
            result: ValidationResult.invalid(),
            failures: _failures,
            validationState: 'INVALID',
          ),
        ),
      );

      final placeholder = find.byType(TamperedPlaceholder);
      for (var i = 0; i < 10; i++) {
        await tester.tap(placeholder);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Copy'));
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!['validation_state'], 'INVALID');
      final failures = captured!['failures'] as List<dynamic>;
      expect(failures.length, 1);
      expect((failures.first as Map<String, dynamic>)['code'],
          'assertion.dataHash.mismatch');
    });

    testWidgets('Closing the dialog resets the tap counter',
        (final tester) async {
      await tester.pumpWidget(
        _wrap(
          const TamperedPlaceholder(
            result: ValidationResult.invalid(),
            failures: _failures,
          ),
        ),
      );

      final placeholder = find.byType(TamperedPlaceholder);
      for (var i = 0; i < 10; i++) {
        await tester.tap(placeholder);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      // After reset, 9 more taps must not reopen the dialog.
      for (var i = 0; i < 9; i++) {
        await tester.tap(placeholder);
        await tester.pump();
      }
      expect(find.byType(AlertDialog), findsNothing);

      // The 10th tap opens it again.
      await tester.tap(placeholder);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
