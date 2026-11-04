import 'package:c2pa_view/l10n/generated/c2pa_view_localizations.dart';
import 'package:c2pa_view/l10n/generated/c2pa_view_localizations_en.dart';
import 'package:flutter/widgets.dart';

export 'package:c2pa_view/l10n/generated/c2pa_view_localizations.dart';

/// Uses the host locale, with English compatibility for existing consumers.
C2paViewLocalizations c2paViewL10n(final BuildContext context) =>
    C2paViewLocalizations.of(context) ?? C2paViewLocalizationsEn();
