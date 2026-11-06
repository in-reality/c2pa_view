// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'c2pa_view_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class C2paViewLocalizationsIt extends C2paViewLocalizations {
  C2paViewLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get credentialIndicatorInvalid => 'Non valido';

  @override
  String get credentialIndicatorUntrusted => 'Non attendibile';

  @override
  String get credentialIndicatorNotVerified => 'Non verificato';

  @override
  String get credentialIndicatorNoCR => 'Nessuna CR';

  @override
  String get rustInitBannerRustLibraryFailedToLoad =>
      'Caricamento della libreria Rust non riuscito';

  @override
  String get zoomControlsZoomIn => 'Ingrandisci';

  @override
  String get zoomControlsFitToView => 'Adatta alla vista';

  @override
  String get zoomControlsZoomOut => 'Riduci';

  @override
  String get processSectionProcess => 'Processo';

  @override
  String get processSectionTheAppOrDeviceUsedToProduceThisContentRecorded =>
      'L’app o il dispositivo usato per produrre questo contenuto ha registrato le seguenti informazioni:';

  @override
  String get processSectionAppOrDeviceUsed => 'App o dispositivo usato';

  @override
  String get processSectionAIToolUsed => 'Strumento IA usato';

  @override
  String get processSectionEditsAndActivity => 'Modifiche e attività';

  @override
  String get processSectionIngredients => 'Ingredienti';

  @override
  String get errorBannerTheContentCredentialSSigningCertificateIsNotInAny =>
      'Il certificato di firma delle Content Credentials non è presente in alcun elenco di fiducia. Verifica l’emittente prima di fidarti di questo contenuto.';

  @override
  String get customFieldsSectionCustomFields => 'Campi personalizzati';

  @override
  String
  get customFieldsSectionAdditionalVendorSpecificOrNonStandardDataFoundInThis =>
      'Dati aggiuntivi specifici del fornitore o non standard trovati in queste Content Credentials.';

  @override
  String get cameraCaptureSectionCameraCaptureDetails =>
      'Dettagli di acquisizione della fotocamera';

  @override
  String
  get cameraCaptureSectionAdditionalDataSourcedFromTheCameraUsedToTakeAn =>
      'Dati aggiuntivi provenienti dalla fotocamera usata per scattare una foto o registrare un video. I dati EXIF possono essere modificati da chi produce il contenuto.';

  @override
  String get cameraCaptureSectionCreator => 'Autore';

  @override
  String get cameraCaptureSectionCopyright => 'Copyright';

  @override
  String get cameraCaptureSectionCaptureDate => 'Data di acquisizione';

  @override
  String get cameraCaptureSectionAdditionalEXIFData => 'Dati EXIF aggiuntivi';

  @override
  String get cameraCaptureSectionCamera => 'Fotocamera';

  @override
  String get cameraCaptureSectionLens => 'Obiettivo';

  @override
  String get cameraCaptureSectionDimensions => 'Dimensioni';

  @override
  String get cameraCaptureSectionFocalLength => 'Lunghezza focale';

  @override
  String get cameraCaptureSectionExposure => 'Esposizione';

  @override
  String get cameraCaptureSectionApproximateLocation =>
      'Posizione approssimativa';

  @override
  String get aboutSectionAboutThisContentCredential =>
      'Informazioni su queste Content Credentials';

  @override
  String get aboutSectionAdditionalMetadata => 'Metadati aggiuntivi';

  @override
  String get aboutSectionIssuedBy => 'Emesso da';

  @override
  String
  get aboutSectionThisIsTheOrganizationDeviceOrIndividualThatRecordedThe =>
      'L’organizzazione, il dispositivo o la persona che ha registrato i dettagli riportati sopra e firmato queste Content Credentials.';

  @override
  String get aboutSectionIssuedOn => 'Emesso il';

  @override
  String get aboutSectionProducer => 'Produttore';

  @override
  String get aboutSectionSocialAccounts => 'Account social';

  @override
  String get aboutSectionAITraining => 'Addestramento dell’IA';

  @override
  String get aboutSectionTheCreatorDoesNotWantThisContentUsedForAI =>
      'L’autore non desidera che questo contenuto venga usato per l’addestramento dell’IA.';

  @override
  String get tamperedPlaceholderValidationProblemDetails =>
      'Dettagli del problema di convalida';

  @override
  String get tamperedPlaceholderNoErrorCodedValidationEntriesWereReported =>
      'Non sono state segnalate voci di convalida con codici di errore.';

  @override
  String get tamperedPlaceholderCopy => 'Copia';

  @override
  String get tamperedPlaceholderClose => 'Chiudi';

  @override
  String
  get tamperedPlaceholderThisFileMayHaveBeenTamperedWithItsContentCredentials =>
      'Questo file potrebbe essere stato manomesso. Le sue Content Credentials non possono essere verificate né visualizzate.';

  @override
  String get detailHeaderCopied => 'Copiato!';

  @override
  String get detailHeaderCopyManifestJSON => 'Copia JSON del manifest';

  @override
  String detailHeaderIssuedByDataIssuer(String dataIssuer) {
    return 'Emesso da $dataIssuer';
  }

  @override
  String detailHeaderIssuedOnFormatted(String formatted) {
    return 'Emesso il $formatted';
  }

  @override
  String detailHeaderOnFormatted(String formatted) {
    return 'il $formatted';
  }

  @override
  String get manifestDetailPopupDismissManifestDetails =>
      'Chiudi i dettagli del manifest';

  @override
  String get actionCreated => 'Creato';

  @override
  String get actionOpened => 'Aperto';

  @override
  String get actionPlaced => 'Inserito';

  @override
  String get actionEdited => 'Modificato';

  @override
  String get actionCropped => 'Ritagliato';

  @override
  String get actionResized => 'Ridimensionato';

  @override
  String get actionColorAdjustments => 'Regolazioni del colore';

  @override
  String get actionDrawing => 'Disegno';

  @override
  String get actionFiltered => 'Filtro applicato';

  @override
  String get actionOrientation => 'Orientamento modificato';

  @override
  String get actionPublished => 'Pubblicato';

  @override
  String get actionTranscoded => 'Transcodificato';

  @override
  String get actionUnknown => 'Azione sconosciuta';

  @override
  String get generativeAiGenerated =>
      'Questo contenuto è stato generato con uno strumento IA.';

  @override
  String get generativeCompositeWithAi =>
      'Questo contenuto combina più contenuti. Almeno uno è stato generato con uno strumento IA.';

  @override
  String get generativeLegacy =>
      'Questo contenuto potrebbe includere elementi generati dall’IA.';

  @override
  String get aiBadge => 'IA';

  @override
  String credentialIssuedByOn(String issuer, String date) {
    return 'Emesso da $issuer il $date';
  }

  @override
  String credentialIssuedBy(String issuer) {
    return 'Emesso da $issuer';
  }

  @override
  String credentialIssuedOn(String date) {
    return 'Emesso il $date';
  }
}
