import 'package:c2pa_view/c2pa_view.dart';
import 'package:c2pa_view/features/manifest_detail/sections/thumbnail_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final compact in [false, true]) {
    testWidgets(
      'detail compact=$compact preserves facts and default presentation',
      (tester) async {
        const data = ManifestViewData(
          title: 'Original camera',
          issuer: 'Recorded issuer',
          validationResult: ValidationResult.notVerified(),
          actions: [
            ActionDisplayInfo(
              actionType: 'c2pa.orientation',
              label: 'Orientation changed',
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ManifestDetailContent(data: data, compact: compact),
            ),
          ),
        );
        expect(find.text('Original camera'), findsOneWidget);
        expect(find.text('Issued by Recorded issuer'), findsOneWidget);
        expect(find.text('Orientation changed'), findsOneWidget);
        expect(
          find.byType(ThumbnailSection),
          compact ? findsNothing : findsOneWidget,
        );
        expect(find.text('Process'), compact ? findsNothing : findsOneWidget);
        expect(
          find.text('EDITS AND ACTIVITY'),
          compact ? findsNothing : findsOneWidget,
        );
        expect(find.text('Edits'), compact ? findsOneWidget : findsNothing);
        expect(
          find.text('Not verified'),
          compact ? findsNothing : findsOneWidget,
        );
      },
    );
  }
}
