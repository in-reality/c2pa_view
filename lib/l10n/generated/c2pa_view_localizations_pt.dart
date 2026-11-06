// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'c2pa_view_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class C2paViewLocalizationsPt extends C2paViewLocalizations {
  C2paViewLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get credentialIndicatorInvalid => 'Inválido';

  @override
  String get credentialIndicatorUntrusted => 'Confiança não estabelecida';

  @override
  String get credentialIndicatorNotVerified => 'Não verificado';

  @override
  String get credentialIndicatorNoCR => 'Sem CR';

  @override
  String get rustInitBannerRustLibraryFailedToLoad =>
      'Não foi possível carregar a biblioteca Rust';

  @override
  String get zoomControlsZoomIn => 'Ampliar';

  @override
  String get zoomControlsFitToView => 'Ajustar à vista';

  @override
  String get zoomControlsZoomOut => 'Reduzir';

  @override
  String get processSectionProcess => 'Processo';

  @override
  String get processSectionTheAppOrDeviceUsedToProduceThisContentRecorded =>
      'A aplicação ou o dispositivo usado para produzir este conteúdo registou as seguintes informações:';

  @override
  String get processSectionAppOrDeviceUsed => 'Aplicação ou dispositivo usado';

  @override
  String get processSectionAIToolUsed => 'Ferramenta de IA usada';

  @override
  String get processSectionEditsAndActivity => 'Edições e atividade';

  @override
  String get processSectionIngredients => 'Ingredientes';

  @override
  String get errorBannerTheContentCredentialSSigningCertificateIsNotInAny =>
      'O certificado de assinatura da credencial Content Credentials não consta de nenhuma lista de confiança. Verifique o emissor antes de confiar neste conteúdo.';

  @override
  String get customFieldsSectionCustomFields => 'Campos personalizados';

  @override
  String
  get customFieldsSectionAdditionalVendorSpecificOrNonStandardDataFoundInThis =>
      'Dados adicionais específicos do fornecedor ou não normalizados encontrados nesta credencial Content Credentials.';

  @override
  String get cameraCaptureSectionCameraCaptureDetails =>
      'Detalhes da captura com câmara';

  @override
  String
  get cameraCaptureSectionAdditionalDataSourcedFromTheCameraUsedToTakeAn =>
      'Dados adicionais provenientes da câmara usada para captar uma imagem ou um vídeo. Os dados EXIF podem ser editados pelo produtor do conteúdo.';

  @override
  String get cameraCaptureSectionCreator => 'Criador';

  @override
  String get cameraCaptureSectionCopyright => 'Direitos de autor';

  @override
  String get cameraCaptureSectionCaptureDate => 'Data da captura';

  @override
  String get cameraCaptureSectionAdditionalEXIFData => 'Dados EXIF adicionais';

  @override
  String get cameraCaptureSectionCamera => 'Câmara';

  @override
  String get cameraCaptureSectionLens => 'Objetiva';

  @override
  String get cameraCaptureSectionDimensions => 'Dimensões';

  @override
  String get cameraCaptureSectionFocalLength => 'Distância focal';

  @override
  String get cameraCaptureSectionExposure => 'Exposição';

  @override
  String get cameraCaptureSectionApproximateLocation =>
      'Localização aproximada';

  @override
  String get aboutSectionAboutThisContentCredential =>
      'Sobre esta credencial Content Credentials';

  @override
  String get aboutSectionAdditionalMetadata => 'Metadados adicionais';

  @override
  String get aboutSectionIssuedBy => 'Emitido por';

  @override
  String
  get aboutSectionThisIsTheOrganizationDeviceOrIndividualThatRecordedThe =>
      'Esta é a organização, o dispositivo ou a pessoa que registou os detalhes acima e assinou esta credencial Content Credentials.';

  @override
  String get aboutSectionIssuedOn => 'Emitido em';

  @override
  String get aboutSectionProducer => 'Produtor';

  @override
  String get aboutSectionSocialAccounts => 'Contas nas redes sociais';

  @override
  String get aboutSectionAITraining => 'Treino de IA';

  @override
  String get aboutSectionTheCreatorDoesNotWantThisContentUsedForAI =>
      'O criador não pretende que este conteúdo seja usado para treino de IA.';

  @override
  String get tamperedPlaceholderValidationProblemDetails =>
      'Detalhes do problema de validação';

  @override
  String get tamperedPlaceholderNoErrorCodedValidationEntriesWereReported =>
      'Não foram comunicadas entradas de validação com códigos de erro.';

  @override
  String get tamperedPlaceholderCopy => 'Copiar';

  @override
  String get tamperedPlaceholderClose => 'Fechar';

  @override
  String
  get tamperedPlaceholderThisFileMayHaveBeenTamperedWithItsContentCredentials =>
      'Este ficheiro pode ter sido adulterado. As suas Content Credentials não podem ser verificadas nem visualizadas.';

  @override
  String get detailHeaderCopied => 'Copiado!';

  @override
  String get detailHeaderCopyManifestJSON => 'Copiar JSON do manifesto';

  @override
  String detailHeaderIssuedByDataIssuer(String dataIssuer) {
    return 'Emitido por $dataIssuer';
  }

  @override
  String detailHeaderIssuedOnFormatted(String formatted) {
    return 'Emitido em $formatted';
  }

  @override
  String detailHeaderOnFormatted(String formatted) {
    return 'em $formatted';
  }

  @override
  String get manifestDetailPopupDismissManifestDetails =>
      'Fechar detalhes do manifesto';

  @override
  String get actionCreated => 'Criado';

  @override
  String get actionOpened => 'Aberto';

  @override
  String get actionPlaced => 'Inserido';

  @override
  String get actionEdited => 'Editado';

  @override
  String get actionCropped => 'Recortado';

  @override
  String get actionResized => 'Redimensionado';

  @override
  String get actionColorAdjustments => 'Ajustes de cor';

  @override
  String get actionDrawing => 'Desenho';

  @override
  String get actionFiltered => 'Filtrado';

  @override
  String get actionOrientation => 'Orientação alterada';

  @override
  String get actionPublished => 'Publicado';

  @override
  String get actionTranscoded => 'Transcodificado';

  @override
  String get actionUnknown => 'Ação desconhecida';

  @override
  String get generativeAiGenerated =>
      'Este conteúdo foi gerado com uma ferramenta de IA.';

  @override
  String get generativeCompositeWithAi =>
      'Este conteúdo combina vários conteúdos. Pelo menos um foi gerado com uma ferramenta de IA.';

  @override
  String get generativeLegacy =>
      'Este conteúdo pode incluir elementos gerados por IA.';

  @override
  String get aiBadge => 'IA';

  @override
  String credentialIssuedByOn(String issuer, String date) {
    return 'Emitido por $issuer em $date';
  }

  @override
  String credentialIssuedBy(String issuer) {
    return 'Emitido por $issuer';
  }

  @override
  String credentialIssuedOn(String date) {
    return 'Emitido em $date';
  }
}
