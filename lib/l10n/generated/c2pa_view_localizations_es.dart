// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'c2pa_view_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class C2paViewLocalizationsEs extends C2paViewLocalizations {
  C2paViewLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get credentialIndicatorInvalid => 'No válido';

  @override
  String get credentialIndicatorUntrusted => 'No confiable';

  @override
  String get credentialIndicatorNotVerified => 'Sin verificar';

  @override
  String get credentialIndicatorNoCR => 'Sin CR';

  @override
  String get rustInitBannerRustLibraryFailedToLoad =>
      'No se pudo cargar la biblioteca Rust';

  @override
  String get zoomControlsZoomIn => 'Acercar';

  @override
  String get zoomControlsFitToView => 'Ajustar a la vista';

  @override
  String get zoomControlsZoomOut => 'Alejar';

  @override
  String get processSectionProcess => 'Proceso';

  @override
  String get processSectionTheAppOrDeviceUsedToProduceThisContentRecorded =>
      'La aplicación o el dispositivo utilizado para producir este contenido registró la siguiente información:';

  @override
  String get processSectionAppOrDeviceUsed =>
      'Aplicación o dispositivo utilizado';

  @override
  String get processSectionAIToolUsed => 'Herramienta de IA utilizada';

  @override
  String get processSectionEditsAndActivity => 'Ediciones y actividad';

  @override
  String get processSectionIngredients => 'Ingredientes';

  @override
  String get errorBannerTheContentCredentialSSigningCertificateIsNotInAny =>
      'El certificado de firma de Content Credentials no está en ninguna lista de confianza. Verifica al emisor antes de confiar en este contenido.';

  @override
  String get customFieldsSectionCustomFields => 'Campos personalizados';

  @override
  String
  get customFieldsSectionAdditionalVendorSpecificOrNonStandardDataFoundInThis =>
      'Datos adicionales específicos del proveedor o no estándar encontrados en estas Content Credentials.';

  @override
  String get cameraCaptureSectionCameraCaptureDetails =>
      'Detalles de captura de la cámara';

  @override
  String
  get cameraCaptureSectionAdditionalDataSourcedFromTheCameraUsedToTakeAn =>
      'Datos adicionales de la cámara utilizada para tomar una imagen o grabar un video. El productor del contenido puede editar los datos EXIF.';

  @override
  String get cameraCaptureSectionCreator => 'Creador';

  @override
  String get cameraCaptureSectionCopyright => 'Derechos de autor';

  @override
  String get cameraCaptureSectionCaptureDate => 'Fecha de captura';

  @override
  String get cameraCaptureSectionAdditionalEXIFData => 'Datos EXIF adicionales';

  @override
  String get cameraCaptureSectionCamera => 'Cámara';

  @override
  String get cameraCaptureSectionLens => 'Objetivo';

  @override
  String get cameraCaptureSectionDimensions => 'Dimensiones';

  @override
  String get cameraCaptureSectionFocalLength => 'Distancia focal';

  @override
  String get cameraCaptureSectionExposure => 'Exposición';

  @override
  String get cameraCaptureSectionApproximateLocation => 'Ubicación aproximada';

  @override
  String get aboutSectionAboutThisContentCredential =>
      'Acerca de estas Content Credentials';

  @override
  String get aboutSectionAdditionalMetadata => 'Metadatos adicionales';

  @override
  String get aboutSectionIssuedBy => 'Emitido por';

  @override
  String
  get aboutSectionThisIsTheOrganizationDeviceOrIndividualThatRecordedThe =>
      'Esta es la organización, el dispositivo o la persona que registró los detalles anteriores y firmó estas Content Credentials.';

  @override
  String get aboutSectionIssuedOn => 'Fecha de emisión';

  @override
  String get aboutSectionProducer => 'Productor';

  @override
  String get aboutSectionSocialAccounts => 'Cuentas de redes sociales';

  @override
  String get aboutSectionAITraining => 'Entrenamiento de IA';

  @override
  String get aboutSectionTheCreatorDoesNotWantThisContentUsedForAI =>
      'El creador no desea que este contenido se utilice para entrenar IA.';

  @override
  String get tamperedPlaceholderValidationProblemDetails =>
      'Detalles del problema de validación';

  @override
  String get tamperedPlaceholderNoErrorCodedValidationEntriesWereReported =>
      'No se notificaron entradas de validación con códigos de error.';

  @override
  String get tamperedPlaceholderCopy => 'Copiar';

  @override
  String get tamperedPlaceholderClose => 'Cerrar';

  @override
  String
  get tamperedPlaceholderThisFileMayHaveBeenTamperedWithItsContentCredentials =>
      'Este archivo puede haber sido manipulado. Sus Content Credentials no se pueden verificar ni visualizar.';

  @override
  String get detailHeaderCopied => '¡Copiado!';

  @override
  String get detailHeaderCopyManifestJSON => 'Copiar JSON del manifiesto';

  @override
  String detailHeaderIssuedByDataIssuer(String dataIssuer) {
    return 'Emitido por $dataIssuer';
  }

  @override
  String detailHeaderIssuedOnFormatted(String formatted) {
    return 'Emitido el $formatted';
  }

  @override
  String detailHeaderOnFormatted(String formatted) {
    return 'el $formatted';
  }

  @override
  String get manifestDetailPopupDismissManifestDetails =>
      'Cerrar detalles del manifiesto';

  @override
  String get actionCreated => 'Creado';

  @override
  String get actionOpened => 'Abierto';

  @override
  String get actionPlaced => 'Colocado';

  @override
  String get actionEdited => 'Editado';

  @override
  String get actionCropped => 'Recortado';

  @override
  String get actionResized => 'Tamaño modificado';

  @override
  String get actionColorAdjustments => 'Ajustes de color';

  @override
  String get actionDrawing => 'Dibujo';

  @override
  String get actionFiltered => 'Filtro aplicado';

  @override
  String get actionOrientation => 'Orientación modificada';

  @override
  String get actionPublished => 'Publicado';

  @override
  String get actionTranscoded => 'Transcodificado';

  @override
  String get actionUnknown => 'Acción desconocida';

  @override
  String get generativeAiGenerated =>
      'Este contenido se generó con una herramienta de IA.';

  @override
  String get generativeCompositeWithAi =>
      'Este contenido combina varios contenidos. Al menos uno se generó con una herramienta de IA.';

  @override
  String get generativeLegacy =>
      'Este contenido puede incluir elementos generados por IA.';

  @override
  String get aiBadge => 'IA';

  @override
  String credentialIssuedByOn(String issuer, String date) {
    return 'Emitido por $issuer el $date';
  }

  @override
  String credentialIssuedBy(String issuer) {
    return 'Emitido por $issuer';
  }

  @override
  String credentialIssuedOn(String date) {
    return 'Emitido el $date';
  }
}
