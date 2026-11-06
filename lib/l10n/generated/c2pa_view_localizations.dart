import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'c2pa_view_localizations_da.dart';
import 'c2pa_view_localizations_en.dart';
import 'c2pa_view_localizations_es.dart';
import 'c2pa_view_localizations_it.dart';
import 'c2pa_view_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of C2paViewLocalizations
/// returned by `C2paViewLocalizations.of(context)`.
///
/// Applications need to include `C2paViewLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/c2pa_view_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: C2paViewLocalizations.localizationsDelegates,
///   supportedLocales: C2paViewLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the C2paViewLocalizations.supportedLocales
/// property.
abstract class C2paViewLocalizations {
  C2paViewLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static C2paViewLocalizations? of(BuildContext context) {
    return Localizations.of<C2paViewLocalizations>(
      context,
      C2paViewLocalizations,
    );
  }

  static const LocalizationsDelegate<C2paViewLocalizations> delegate =
      _C2paViewLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('da'),
    Locale('en'),
    Locale('es'),
    Locale('it'),
    Locale('pt'),
  ];

  /// credentialIndicator presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get credentialIndicatorInvalid;

  /// credentialIndicator presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Untrusted'**
  String get credentialIndicatorUntrusted;

  /// credentialIndicator presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get credentialIndicatorNotVerified;

  /// credentialIndicator presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'No CR'**
  String get credentialIndicatorNoCR;

  /// rustInitBanner presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Rust library failed to load'**
  String get rustInitBannerRustLibraryFailedToLoad;

  /// zoomControls presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomControlsZoomIn;

  /// zoomControls presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Fit to view'**
  String get zoomControlsFitToView;

  /// zoomControls presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomControlsZoomOut;

  /// processSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get processSectionProcess;

  /// processSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'The app or device used to produce this content recorded the following information:'**
  String get processSectionTheAppOrDeviceUsedToProduceThisContentRecorded;

  /// processSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'App or device used'**
  String get processSectionAppOrDeviceUsed;

  /// processSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'AI tool used'**
  String get processSectionAIToolUsed;

  /// processSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Edits and activity'**
  String get processSectionEditsAndActivity;

  /// processSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get processSectionIngredients;

  /// errorBanner presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'The Content Credential\'s signing certificate is not in any trust list. Verify the issuer before trusting this content.'**
  String get errorBannerTheContentCredentialSSigningCertificateIsNotInAny;

  /// customFieldsSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Custom Fields'**
  String get customFieldsSectionCustomFields;

  /// customFieldsSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Additional vendor-specific or non-standard data found in this Content Credential.'**
  String
  get customFieldsSectionAdditionalVendorSpecificOrNonStandardDataFoundInThis;

  /// cameraCaptureSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Camera capture details'**
  String get cameraCaptureSectionCameraCaptureDetails;

  /// cameraCaptureSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Additional data sourced from the camera used to take an image or video. EXIF data can be edited by the content producer.'**
  String get cameraCaptureSectionAdditionalDataSourcedFromTheCameraUsedToTakeAn;

  /// cameraCaptureSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get cameraCaptureSectionCreator;

  /// cameraCaptureSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get cameraCaptureSectionCopyright;

  /// cameraCaptureSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Capture date'**
  String get cameraCaptureSectionCaptureDate;

  /// cameraCaptureSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Additional EXIF data'**
  String get cameraCaptureSectionAdditionalEXIFData;

  /// cameraCaptureSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraCaptureSectionCamera;

  /// cameraCaptureSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Lens'**
  String get cameraCaptureSectionLens;

  /// cameraCaptureSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get cameraCaptureSectionDimensions;

  /// cameraCaptureSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Focal length'**
  String get cameraCaptureSectionFocalLength;

  /// cameraCaptureSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Exposure'**
  String get cameraCaptureSectionExposure;

  /// cameraCaptureSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Approximate location'**
  String get cameraCaptureSectionApproximateLocation;

  /// aboutSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'About this Content Credential'**
  String get aboutSectionAboutThisContentCredential;

  /// aboutSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Additional metadata'**
  String get aboutSectionAdditionalMetadata;

  /// aboutSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Issued by'**
  String get aboutSectionIssuedBy;

  /// aboutSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'This is the organization, device, or individual that recorded the details above and signed this Content Credential.'**
  String get aboutSectionThisIsTheOrganizationDeviceOrIndividualThatRecordedThe;

  /// aboutSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Issued on'**
  String get aboutSectionIssuedOn;

  /// aboutSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Producer'**
  String get aboutSectionProducer;

  /// aboutSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Social accounts'**
  String get aboutSectionSocialAccounts;

  /// aboutSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'AI training'**
  String get aboutSectionAITraining;

  /// aboutSection presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'The creator does not want this content used for AI training.'**
  String get aboutSectionTheCreatorDoesNotWantThisContentUsedForAI;

  /// tamperedPlaceholder presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Validation problem details'**
  String get tamperedPlaceholderValidationProblemDetails;

  /// tamperedPlaceholder presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'No error-coded validation entries were reported.'**
  String get tamperedPlaceholderNoErrorCodedValidationEntriesWereReported;

  /// tamperedPlaceholder presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get tamperedPlaceholderCopy;

  /// tamperedPlaceholder presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tamperedPlaceholderClose;

  /// tamperedPlaceholder presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'This file may have been tampered with. Its Content Credentials can\'t be verified or viewed.'**
  String
  get tamperedPlaceholderThisFileMayHaveBeenTamperedWithItsContentCredentials;

  /// detailHeader presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get detailHeaderCopied;

  /// detailHeader presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Copy manifest JSON'**
  String get detailHeaderCopyManifestJSON;

  /// detailHeader presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Issued by {dataIssuer}'**
  String detailHeaderIssuedByDataIssuer(String dataIssuer);

  /// detailHeader presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Issued on {formatted}'**
  String detailHeaderIssuedOnFormatted(String formatted);

  /// detailHeader presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'on {formatted}'**
  String detailHeaderOnFormatted(String formatted);

  /// manifestDetailPopup presentation copy. Translate the complete message; preserve user and signed-data values.
  ///
  /// In en, this message translates to:
  /// **'Dismiss manifest details'**
  String get manifestDetailPopupDismissManifestDetails;

  /// User-facing action Created. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get actionCreated;

  /// User-facing action Opened. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get actionOpened;

  /// User-facing action Placed. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get actionPlaced;

  /// User-facing action Edited. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get actionEdited;

  /// User-facing action Cropped. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Cropped'**
  String get actionCropped;

  /// User-facing action Resized. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Resized'**
  String get actionResized;

  /// User-facing action Color Adjustments. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Color adjustments'**
  String get actionColorAdjustments;

  /// User-facing action Drawing. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get actionDrawing;

  /// User-facing action Filtered. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get actionFiltered;

  /// User-facing action Orientation. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Orientation changed'**
  String get actionOrientation;

  /// User-facing action Published. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get actionPublished;

  /// User-facing action Transcoded. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Transcoded'**
  String get actionTranscoded;

  /// User-facing action Unknown. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'Unknown action'**
  String get actionUnknown;

  /// User-facing generative Ai Generated. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'This content was generated with an AI tool.'**
  String get generativeAiGenerated;

  /// User-facing generative Composite With Ai. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'This content combines multiple pieces of content. At least one was generated with an AI tool.'**
  String get generativeCompositeWithAi;

  /// User-facing generative Legacy. Translate the complete message.
  ///
  /// In en, this message translates to:
  /// **'This content may include AI-generated elements.'**
  String get generativeLegacy;

  /// Compact badge for an artificial-intelligence-generated action.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiBadge;

  /// Presentation message: credentialIssuedByOn. Use the active locale; preserve recorded and user values.
  ///
  /// In en, this message translates to:
  /// **'Issued by {issuer} on {date}'**
  String credentialIssuedByOn(String issuer, String date);

  /// Presentation message: credentialIssuedBy. Use the active locale; preserve recorded and user values.
  ///
  /// In en, this message translates to:
  /// **'Issued by {issuer}'**
  String credentialIssuedBy(String issuer);

  /// Presentation message: credentialIssuedOn. Use the active locale; preserve recorded and user values.
  ///
  /// In en, this message translates to:
  /// **'Issued on {date}'**
  String credentialIssuedOn(String date);
}

class _C2paViewLocalizationsDelegate
    extends LocalizationsDelegate<C2paViewLocalizations> {
  const _C2paViewLocalizationsDelegate();

  @override
  Future<C2paViewLocalizations> load(Locale locale) {
    return SynchronousFuture<C2paViewLocalizations>(
      lookupC2paViewLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['da', 'en', 'es', 'it', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_C2paViewLocalizationsDelegate old) => false;
}

C2paViewLocalizations lookupC2paViewLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return C2paViewLocalizationsDa();
    case 'en':
      return C2paViewLocalizationsEn();
    case 'es':
      return C2paViewLocalizationsEs();
    case 'it':
      return C2paViewLocalizationsIt();
    case 'pt':
      return C2paViewLocalizationsPt();
  }

  throw FlutterError(
    'C2paViewLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
