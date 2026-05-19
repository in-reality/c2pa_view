import 'package:c2pa_view/domain/models/manifest_summary.dart';
import 'package:c2pa_view/domain/models/validation_result.dart';
import 'package:c2pa_view/features/shared/widgets/manifest_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(final Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 280, height: 120, child: child),
      ),
    );

void main() {
  group('ManifestSummaryCard', () {
    testWidgets('omits the title widget when summary.title is null',
        (final tester) async {
      await tester.pumpWidget(
        _wrap(
          const ManifestSummaryCard(
            summary: ManifestSummary(
              validationResult: ValidationResult.valid(),
            ),
            variant: ManifestSummaryCardVariant.listItem,
          ),
        ),
      );

      // No "Untitled" fallback text should appear anywhere in the card.
      expect(find.text('Untitled'), findsNothing);
    });

    testWidgets('renders the title when summary.title is non-null',
        (final tester) async {
      await tester.pumpWidget(
        _wrap(
          const ManifestSummaryCard(
            summary: ManifestSummary(
              title: 'sample.jpg',
              validationResult: ValidationResult.valid(),
            ),
            variant: ManifestSummaryCardVariant.listItem,
          ),
        ),
      );

      expect(find.text('sample.jpg'), findsOneWidget);
    });

    testWidgets('renders the shortened CR label for valid credentials',
        (final tester) async {
      await tester.pumpWidget(
        _wrap(
          const ManifestSummaryCard(
            summary: ManifestSummary(
              title: 'sample.jpg',
              validationResult: ValidationResult.valid(),
            ),
            variant: ManifestSummaryCardVariant.listItem,
          ),
        ),
      );

      expect(find.text('CR'), findsOneWidget);
      expect(find.text('Content Credential'), findsNothing);
    });

    testWidgets('renders the shortened No CR label for missing credentials',
        (final tester) async {
      await tester.pumpWidget(
        _wrap(
          const ManifestSummaryCard(
            summary: ManifestSummary(),
            variant: ManifestSummaryCardVariant.listItem,
          ),
        ),
      );

      expect(find.text('No CR'), findsOneWidget);
      expect(find.text('No Content Credential'), findsNothing);
    });

    testWidgets('renders the shortened Untrusted label', (final tester) async {
      await tester.pumpWidget(
        _wrap(
          const ManifestSummaryCard(
            summary: ManifestSummary(
              title: 'sample.jpg',
              validationResult: ValidationResult.untrusted(),
            ),
            variant: ManifestSummaryCardVariant.listItem,
          ),
        ),
      );

      expect(find.text('Untrusted'), findsOneWidget);
      expect(find.text('Untrusted signer'), findsNothing);
    });

    testWidgets('renders the Invalid label unchanged', (final tester) async {
      await tester.pumpWidget(
        _wrap(
          const ManifestSummaryCard(
            summary: ManifestSummary(
              title: 'sample.jpg',
              validationResult: ValidationResult.invalid(),
            ),
            variant: ManifestSummaryCardVariant.listItem,
          ),
        ),
      );

      expect(find.text('Invalid'), findsOneWidget);
    });
  });
}
