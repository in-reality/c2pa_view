// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'c2pa_view_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class C2paViewLocalizationsEn extends C2paViewLocalizations {
  C2paViewLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get credentialIndicatorInvalid => 'Invalid';

  @override
  String get credentialIndicatorUntrusted => 'Untrusted';

  @override
  String get credentialIndicatorNotVerified => 'Not verified';

  @override
  String get credentialIndicatorNoCR => 'No CR';

  @override
  String get rustInitBannerRustLibraryFailedToLoad =>
      'Rust library failed to load';

  @override
  String get zoomControlsZoomIn => 'Zoom in';

  @override
  String get zoomControlsFitToView => 'Fit to view';

  @override
  String get zoomControlsZoomOut => 'Zoom out';

  @override
  String get processSectionProcess => 'Process';

  @override
  String get processSectionTheAppOrDeviceUsedToProduceThisContentRecorded =>
      'The app or device used to produce this content recorded the following information:';

  @override
  String get processSectionAppOrDeviceUsed => 'App or device used';

  @override
  String get processSectionAIToolUsed => 'AI tool used';

  @override
  String get processSectionEditsAndActivity => 'Edits and activity';

  @override
  String get processSectionIngredients => 'Ingredients';

  @override
  String get errorBannerTheContentCredentialSSigningCertificateIsNotInAny =>
      'The Content Credential\'s signing certificate is not in any trust list. Verify the issuer before trusting this content.';

  @override
  String get customFieldsSectionCustomFields => 'Custom Fields';

  @override
  String
  get customFieldsSectionAdditionalVendorSpecificOrNonStandardDataFoundInThis =>
      'Additional vendor-specific or non-standard data found in this Content Credential.';

  @override
  String get cameraCaptureSectionCameraCaptureDetails =>
      'Camera capture details';

  @override
  String
  get cameraCaptureSectionAdditionalDataSourcedFromTheCameraUsedToTakeAn =>
      'Additional data sourced from the camera used to take an image or video. EXIF data can be edited by the content producer.';

  @override
  String get cameraCaptureSectionCreator => 'Creator';

  @override
  String get cameraCaptureSectionCopyright => 'Copyright';

  @override
  String get cameraCaptureSectionCaptureDate => 'Capture date';

  @override
  String get cameraCaptureSectionAdditionalEXIFData => 'Additional EXIF data';

  @override
  String get cameraCaptureSectionCamera => 'Camera';

  @override
  String get cameraCaptureSectionLens => 'Lens';

  @override
  String get cameraCaptureSectionDimensions => 'Dimensions';

  @override
  String get cameraCaptureSectionFocalLength => 'Focal length';

  @override
  String get cameraCaptureSectionExposure => 'Exposure';

  @override
  String get cameraCaptureSectionApproximateLocation => 'Approximate location';

  @override
  String get aboutSectionAboutThisContentCredential =>
      'About this Content Credential';

  @override
  String get aboutSectionAdditionalMetadata => 'Additional metadata';

  @override
  String get aboutSectionIssuedBy => 'Issued by';

  @override
  String
  get aboutSectionThisIsTheOrganizationDeviceOrIndividualThatRecordedThe =>
      'This is the organization, device, or individual that recorded the details above and signed this Content Credential.';

  @override
  String get aboutSectionIssuedOn => 'Issued on';

  @override
  String get aboutSectionProducer => 'Producer';

  @override
  String get aboutSectionSocialAccounts => 'Social accounts';

  @override
  String get aboutSectionAITraining => 'AI training';

  @override
  String get aboutSectionTheCreatorDoesNotWantThisContentUsedForAI =>
      'The creator does not want this content used for AI training.';

  @override
  String get tamperedPlaceholderValidationProblemDetails =>
      'Validation problem details';

  @override
  String get tamperedPlaceholderNoErrorCodedValidationEntriesWereReported =>
      'No error-coded validation entries were reported.';

  @override
  String get tamperedPlaceholderCopy => 'Copy';

  @override
  String get tamperedPlaceholderClose => 'Close';

  @override
  String
  get tamperedPlaceholderThisFileMayHaveBeenTamperedWithItsContentCredentials =>
      'This file may have been tampered with. Its Content Credentials can\'t be verified or viewed.';

  @override
  String get detailHeaderCopied => 'Copied!';

  @override
  String get detailHeaderCopyManifestJSON => 'Copy manifest JSON';

  @override
  String detailHeaderIssuedByDataIssuer(String dataIssuer) {
    return 'Issued by $dataIssuer';
  }

  @override
  String detailHeaderIssuedOnFormatted(String formatted) {
    return 'Issued on $formatted';
  }

  @override
  String detailHeaderOnFormatted(String formatted) {
    return 'on $formatted';
  }

  @override
  String get manifestDetailPopupDismissManifestDetails =>
      'Dismiss manifest details';

  @override
  String get actionCreated => 'Created';

  @override
  String get actionOpened => 'Opened';

  @override
  String get actionPlaced => 'Placed';

  @override
  String get actionEdited => 'Edited';

  @override
  String get actionCropped => 'Cropped';

  @override
  String get actionResized => 'Resized';

  @override
  String get actionColorAdjustments => 'Color adjustments';

  @override
  String get actionDrawing => 'Drawing';

  @override
  String get actionFiltered => 'Filtered';

  @override
  String get actionOrientation => 'Orientation changed';

  @override
  String get actionPublished => 'Published';

  @override
  String get actionTranscoded => 'Transcoded';

  @override
  String get actionUnknown => 'Unknown action';

  @override
  String get generativeAiGenerated =>
      'This content was generated with an AI tool.';

  @override
  String get generativeCompositeWithAi =>
      'This content combines multiple pieces of content. At least one was generated with an AI tool.';

  @override
  String get generativeLegacy =>
      'This content may include AI-generated elements.';

  @override
  String get aiBadge => 'AI';

  @override
  String credentialIssuedByOn(String issuer, String date) {
    return 'Issued by $issuer on $date';
  }

  @override
  String credentialIssuedBy(String issuer) {
    return 'Issued by $issuer';
  }

  @override
  String credentialIssuedOn(String date) {
    return 'Issued on $date';
  }
}
