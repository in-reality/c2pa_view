// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'c2pa_view_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class C2paViewLocalizationsDa extends C2paViewLocalizations {
  C2paViewLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get credentialIndicatorInvalid => 'Ugyldig';

  @override
  String get credentialIndicatorUntrusted => 'Ikke betroet';

  @override
  String get credentialIndicatorNotVerified => 'Ikke verificeret';

  @override
  String get credentialIndicatorNoCR => 'Ingen CR';

  @override
  String get rustInitBannerRustLibraryFailedToLoad =>
      'Rust-biblioteket kunne ikke indlæses';

  @override
  String get zoomControlsZoomIn => 'Zoom ind';

  @override
  String get zoomControlsFitToView => 'Tilpas til visningen';

  @override
  String get zoomControlsZoomOut => 'Zoom ud';

  @override
  String get processSectionProcess => 'Proces';

  @override
  String get processSectionTheAppOrDeviceUsedToProduceThisContentRecorded =>
      'Appen eller enheden, der blev brugt til at skabe dette indhold, registrerede følgende oplysninger:';

  @override
  String get processSectionAppOrDeviceUsed => 'Anvendt app eller enhed';

  @override
  String get processSectionAIToolUsed => 'Anvendt AI-værktøj';

  @override
  String get processSectionEditsAndActivity => 'Redigeringer og aktivitet';

  @override
  String get processSectionIngredients => 'Kildematerialer';

  @override
  String get errorBannerTheContentCredentialSSigningCertificateIsNotInAny =>
      'Signeringscertifikatet for denne Content Credential findes ikke på nogen tillidsliste. Verificer udstederen, før du stoler på dette indhold.';

  @override
  String get customFieldsSectionCustomFields => 'Brugerdefinerede felter';

  @override
  String
  get customFieldsSectionAdditionalVendorSpecificOrNonStandardDataFoundInThis =>
      'Yderligere leverandørspecifikke eller ikke-standardiserede data fundet i denne Content Credential.';

  @override
  String get cameraCaptureSectionCameraCaptureDetails =>
      'Detaljer om kameraoptagelsen';

  @override
  String
  get cameraCaptureSectionAdditionalDataSourcedFromTheCameraUsedToTakeAn =>
      'Yderligere data fra det kamera, der blev brugt til at tage et billede eller optage en video. EXIF-data kan redigeres af indholdsproducenten.';

  @override
  String get cameraCaptureSectionCreator => 'Ophavsperson';

  @override
  String get cameraCaptureSectionCopyright => 'Ophavsret';

  @override
  String get cameraCaptureSectionCaptureDate => 'Optagelsesdato';

  @override
  String get cameraCaptureSectionAdditionalEXIFData => 'Yderligere EXIF-data';

  @override
  String get cameraCaptureSectionCamera => 'Kamera';

  @override
  String get cameraCaptureSectionLens => 'Objektiv';

  @override
  String get cameraCaptureSectionDimensions => 'Dimensioner';

  @override
  String get cameraCaptureSectionFocalLength => 'Brændvidde';

  @override
  String get cameraCaptureSectionExposure => 'Eksponering';

  @override
  String get cameraCaptureSectionApproximateLocation => 'Omtrentlig lokalitet';

  @override
  String get aboutSectionAboutThisContentCredential =>
      'Om denne Content Credential';

  @override
  String get aboutSectionAdditionalMetadata => 'Yderligere metadata';

  @override
  String get aboutSectionIssuedBy => 'Udstedt af';

  @override
  String
  get aboutSectionThisIsTheOrganizationDeviceOrIndividualThatRecordedThe =>
      'Dette er den organisation, enhed eller person, som registrerede oplysningerne ovenfor og signerede denne Content Credential.';

  @override
  String get aboutSectionIssuedOn => 'Udstedt den';

  @override
  String get aboutSectionProducer => 'Producent';

  @override
  String get aboutSectionSocialAccounts => 'Konti på sociale medier';

  @override
  String get aboutSectionAITraining => 'AI-træning';

  @override
  String get aboutSectionTheCreatorDoesNotWantThisContentUsedForAI =>
      'Ophavspersonen ønsker ikke, at dette indhold bruges til AI-træning.';

  @override
  String get tamperedPlaceholderValidationProblemDetails =>
      'Detaljer om valideringsproblemet';

  @override
  String get tamperedPlaceholderNoErrorCodedValidationEntriesWereReported =>
      'Ingen valideringsposter med fejlkoder blev rapporteret.';

  @override
  String get tamperedPlaceholderCopy => 'Kopiér';

  @override
  String get tamperedPlaceholderClose => 'Luk';

  @override
  String
  get tamperedPlaceholderThisFileMayHaveBeenTamperedWithItsContentCredentials =>
      'Denne fil kan være blevet manipuleret. Dens Content Credentials kan ikke verificeres eller vises.';

  @override
  String get detailHeaderCopied => 'Kopieret!';

  @override
  String get detailHeaderCopyManifestJSON => 'Kopiér manifestets JSON';

  @override
  String detailHeaderIssuedByDataIssuer(String dataIssuer) {
    return 'Udstedt af $dataIssuer';
  }

  @override
  String detailHeaderIssuedOnFormatted(String formatted) {
    return 'Udstedt den $formatted';
  }

  @override
  String detailHeaderOnFormatted(String formatted) {
    return 'den $formatted';
  }

  @override
  String get manifestDetailPopupDismissManifestDetails =>
      'Luk manifestdetaljer';

  @override
  String get actionCreated => 'Oprettet';

  @override
  String get actionOpened => 'Åbnet';

  @override
  String get actionPlaced => 'Placeret';

  @override
  String get actionEdited => 'Redigeret';

  @override
  String get actionCropped => 'Beskåret';

  @override
  String get actionResized => 'Størrelse ændret';

  @override
  String get actionColorAdjustments => 'Farvejusteringer';

  @override
  String get actionDrawing => 'Tegning';

  @override
  String get actionFiltered => 'Filtreret';

  @override
  String get actionOrientation => 'Orientering ændret';

  @override
  String get actionPublished => 'Offentliggjort';

  @override
  String get actionTranscoded => 'Transkodet';

  @override
  String get actionUnknown => 'Ukendt handling';

  @override
  String get generativeAiGenerated =>
      'Dette indhold er genereret med et AI-værktøj.';

  @override
  String get generativeCompositeWithAi =>
      'Dette indhold kombinerer flere stykker indhold. Mindst ét er genereret med et AI-værktøj.';

  @override
  String get generativeLegacy =>
      'Dette indhold kan indeholde AI-genererede elementer.';

  @override
  String get aiBadge => 'AI';

  @override
  String credentialIssuedByOn(String issuer, String date) {
    return 'Udstedt af $issuer den $date';
  }

  @override
  String credentialIssuedBy(String issuer) {
    return 'Udstedt af $issuer';
  }

  @override
  String credentialIssuedOn(String date) {
    return 'Udstedt den $date';
  }
}
