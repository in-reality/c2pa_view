import 'package:c2pa_view/domain/models/manifest_view_data.dart';
import 'package:c2pa_view/features/manifest_detail/sections/process_section.dart';
import 'package:c2pa_view/l10n/generated/c2pa_view_localizations_en.dart';
import 'package:c2pa_view/l10n/localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Strings extends C2paViewLocalizationsEn {
  @override
  String get actionEdited => 'Localized default edit';
}

class _Delegate extends LocalizationsDelegate<C2paViewLocalizations> {
  const _Delegate();
  @override
  bool isSupported(final Locale locale) => locale.languageCode == 'en';
  @override
  Future<C2paViewLocalizations> load(final Locale locale) =>
      SynchronousFuture(_Strings());
  @override
  bool shouldReload(final _Delegate old) => false;
}

void main() {
  testWidgets('default actions localize while host labels remain verbatim', (
    final tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          _Delegate(),
          ...C2paViewLocalizations.localizationsDelegates,
        ],
        supportedLocales: C2paViewLocalizations.supportedLocales,
        home: Scaffold(
          body: ProcessSection(
            data: ManifestViewData(
              actions: [
                ActionDisplayInfo(actionType: 'c2pa.edited', label: 'Edited'),
                ActionDisplayInfo(
                  actionType: 'c2pa.edited',
                  label: 'Host-authored action label',
                ),
                ActionDisplayInfo(
                  actionType: 'custom.action',
                  label: 'Raw custom action',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Localized default edit'), findsOneWidget);
    expect(find.text('Host-authored action label'), findsOneWidget);
    expect(find.text('Raw custom action'), findsOneWidget);
    expect(find.text('Edited'), findsNothing);
  });
}
