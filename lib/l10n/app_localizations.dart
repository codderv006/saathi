import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('en'),
    Locale('mr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Saathi'**
  String get appName;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your companion for everyday apps.'**
  String get onboardingTitle;

  /// No description provided for @onboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Tell Saathi what you want to do. We\'ll guide you one step at a time.'**
  String get onboardingBody;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'You stay in control. Saathi never taps, books or pays for you.'**
  String get privacyNote;

  /// No description provided for @homeHeading.
  ///
  /// In en, this message translates to:
  /// **'What would you like help with?'**
  String get homeHeading;

  /// No description provided for @homeSubheading.
  ///
  /// In en, this message translates to:
  /// **'I\'ll walk you through it, one step at a time.'**
  String get homeSubheading;

  /// No description provided for @talkToSaathi.
  ///
  /// In en, this message translates to:
  /// **'Talk to Saathi'**
  String get talkToSaathi;

  /// No description provided for @voiceCardBody.
  ///
  /// In en, this message translates to:
  /// **'Speak in English or Marathi. Saathi will listen and guide you.'**
  String get voiceCardBody;

  /// No description provided for @startTalking.
  ///
  /// In en, this message translates to:
  /// **'Start talking'**
  String get startTalking;

  /// No description provided for @openCall.
  ///
  /// In en, this message translates to:
  /// **'Open call'**
  String get openCall;

  /// No description provided for @guidesHeading.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get guidesHeading;

  /// No description provided for @taskBookCab.
  ///
  /// In en, this message translates to:
  /// **'Book a ride'**
  String get taskBookCab;

  /// No description provided for @taskBookCabDetail.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step help with Ola, Uber or Rapido'**
  String get taskBookCabDetail;

  /// No description provided for @continueGuide.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGuide;

  /// No description provided for @startOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOver;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @voiceIdle.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get voiceIdle;

  /// No description provided for @voiceIdleHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Start talking and say what you\'d like to do.'**
  String get voiceIdleHint;

  /// No description provided for @voiceRequestingPermission.
  ///
  /// In en, this message translates to:
  /// **'Waiting for permission'**
  String get voiceRequestingPermission;

  /// No description provided for @voiceRequestingPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Please allow the microphone so Saathi can hear you.'**
  String get voiceRequestingPermissionHint;

  /// No description provided for @voiceConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Saathi'**
  String get voiceConnecting;

  /// No description provided for @voiceConnectingHint.
  ///
  /// In en, this message translates to:
  /// **'This usually takes a few seconds.'**
  String get voiceConnectingHint;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get voiceListening;

  /// No description provided for @voiceListeningHint.
  ///
  /// In en, this message translates to:
  /// **'Speak naturally. Saathi can hear you.'**
  String get voiceListeningHint;

  /// No description provided for @voiceSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Saathi is speaking'**
  String get voiceSpeaking;

  /// No description provided for @voiceSpeakingHint.
  ///
  /// In en, this message translates to:
  /// **'You can interrupt any time.'**
  String get voiceSpeakingHint;

  /// No description provided for @voiceMuted.
  ///
  /// In en, this message translates to:
  /// **'Microphone paused'**
  String get voiceMuted;

  /// No description provided for @voiceMutedHint.
  ///
  /// In en, this message translates to:
  /// **'Saathi can\'t hear you until you unmute.'**
  String get voiceMutedHint;

  /// No description provided for @voiceEnded.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get voiceEnded;

  /// No description provided for @voiceEndedHint.
  ///
  /// In en, this message translates to:
  /// **'You can talk to Saathi again whenever you like.'**
  String get voiceEndedHint;

  /// No description provided for @voiceDisconnected.
  ///
  /// In en, this message translates to:
  /// **'The voice call ended'**
  String get voiceDisconnected;

  /// No description provided for @voiceDisconnectedHint.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved. You can talk again.'**
  String get voiceDisconnectedHint;

  /// No description provided for @voiceFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the call'**
  String get voiceFailed;

  /// No description provided for @errMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Saathi needs the microphone to hear you. You can allow it in Settings.'**
  String get errMicDenied;

  /// No description provided for @errNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Voice isn\'t set up on this phone yet. You can still use the step-by-step guide.'**
  String get errNotConfigured;

  /// No description provided for @errNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach Saathi. Check your internet connection and try again.'**
  String get errNetwork;

  /// No description provided for @errBusy.
  ///
  /// In en, this message translates to:
  /// **'Saathi is busy right now. Please try again in a minute.'**
  String get errBusy;

  /// No description provided for @errUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice can\'t run on this phone right now. You can still use the guide.'**
  String get errUnavailable;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @endCall.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get endCall;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @talkAgain.
  ///
  /// In en, this message translates to:
  /// **'Talk again'**
  String get talkAgain;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @backToGuide.
  ///
  /// In en, this message translates to:
  /// **'Back to your guide'**
  String get backToGuide;

  /// No description provided for @currentStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Current step'**
  String get currentStepLabel;

  /// No description provided for @voiceNoGuideHint.
  ///
  /// In en, this message translates to:
  /// **'Try saying “Help me book a cab”.'**
  String get voiceNoGuideHint;

  /// No description provided for @micRationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Saathi needs your microphone'**
  String get micRationaleTitle;

  /// No description provided for @micRationaleBody.
  ///
  /// In en, this message translates to:
  /// **'So Saathi can hear what you say. The microphone is only used while a call is on, and you can end it any time.'**
  String get micRationaleBody;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @iveDoneThis.
  ///
  /// In en, this message translates to:
  /// **'I\'ve done this'**
  String get iveDoneThis;

  /// No description provided for @repeatInstructions.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatInstructions;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'I need help'**
  String get needHelp;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @exitGuide.
  ///
  /// In en, this message translates to:
  /// **'Exit guide'**
  String get exitGuide;

  /// No description provided for @sensitiveNote.
  ///
  /// In en, this message translates to:
  /// **'This involves money. Take your time — only you decide.'**
  String get sensitiveNote;

  /// No description provided for @voiceHeardDone.
  ///
  /// In en, this message translates to:
  /// **'Saathi heard you say this step is done.'**
  String get voiceHeardDone;

  /// No description provided for @yesDone.
  ///
  /// In en, this message translates to:
  /// **'Yes, it\'s done'**
  String get yesDone;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @simplerHeading.
  ///
  /// In en, this message translates to:
  /// **'In simple words'**
  String get simplerHeading;

  /// No description provided for @outcomeBooked.
  ///
  /// In en, this message translates to:
  /// **'Yes, my ride is booked'**
  String get outcomeBooked;

  /// No description provided for @outcomeNotBooked.
  ///
  /// In en, this message translates to:
  /// **'No, I didn\'t book'**
  String get outcomeNotBooked;

  /// No description provided for @progressSaved.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved.'**
  String get progressSaved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your progress. Nothing was changed — please try again.'**
  String get saveFailed;

  /// No description provided for @actionNotPossible.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t possible on this step.'**
  String get actionNotPossible;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'How can Saathi help?'**
  String get helpTitle;

  /// No description provided for @helpRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat that'**
  String get helpRepeat;

  /// No description provided for @helpSimpler.
  ///
  /// In en, this message translates to:
  /// **'Explain it more simply'**
  String get helpSimpler;

  /// No description provided for @helpShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Show me the picture again'**
  String get helpShowAgain;

  /// No description provided for @helpGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back one step'**
  String get helpGoBack;

  /// No description provided for @helpStop.
  ///
  /// In en, this message translates to:
  /// **'Stop for now'**
  String get helpStop;

  /// No description provided for @helpTalk.
  ///
  /// In en, this message translates to:
  /// **'Talk to Saathi'**
  String get helpTalk;

  /// No description provided for @copyHelperButton.
  ///
  /// In en, this message translates to:
  /// **'Copy an address from Saathi'**
  String get copyHelperButton;

  /// No description provided for @copySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy an address'**
  String get copySheetTitle;

  /// No description provided for @copySheetBody.
  ///
  /// In en, this message translates to:
  /// **'Type the address here and copy it. Then, in your ride app, press and hold the destination box and tap Paste. Saathi can\'t paste it for you.'**
  String get copySheetBody;

  /// No description provided for @copyFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get copyFieldLabel;

  /// No description provided for @copyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyAction;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied. Now open your ride app and paste it yourself.'**
  String get copied;

  /// No description provided for @copyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type an address first.'**
  String get copyEmpty;

  /// No description provided for @copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t copy. Please try again.'**
  String get copyFailed;

  /// No description provided for @screenshotPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Picture coming soon'**
  String get screenshotPlaceholderTitle;

  /// No description provided for @screenshotPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Placeholder — the real app screenshot hasn\'t been added yet.'**
  String get screenshotPlaceholderBody;

  /// No description provided for @screenshotLabel.
  ///
  /// In en, this message translates to:
  /// **'Screenshot: {description}'**
  String screenshotLabel(String description);

  /// No description provided for @completedTitle.
  ///
  /// In en, this message translates to:
  /// **'Well done'**
  String get completedTitle;

  /// No description provided for @completedBody.
  ///
  /// In en, this message translates to:
  /// **'You told Saathi that {app} booked your ride. You did it yourself. {app} will show you the ride details.'**
  String completedBody(String app);

  /// No description provided for @notCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'No problem'**
  String get notCompletedTitle;

  /// No description provided for @notCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing was booked through Saathi. You can try again whenever you like.'**
  String get notCompletedBody;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @returnHome.
  ///
  /// In en, this message translates to:
  /// **'Return home'**
  String get returnHome;

  /// No description provided for @restoreIncompatible.
  ///
  /// In en, this message translates to:
  /// **'This guide has changed since you last used it. Please start again.'**
  String get restoreIncompatible;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your saved progress. You can start again.'**
  String get restoreFailed;

  /// No description provided for @workflowMissing.
  ///
  /// In en, this message translates to:
  /// **'This guide isn\'t available right now.'**
  String get workflowMissing;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Saathi guides you, but never taps, types, books or pays for you. Your guide progress is saved on this phone, with a backup copy in Saathi\'s cloud. Voice calls are handled by our voice partner, Bolna, so Saathi can understand you. Never share OTPs, PINs or passwords with Saathi.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Voice diagnostics (for developers)'**
  String get settingsDiagnostics;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageMarathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get languageMarathi;

  /// No description provided for @chooseAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Which app do you use?'**
  String get chooseAppTitle;

  /// No description provided for @chooseAppBody.
  ///
  /// In en, this message translates to:
  /// **'Saathi will guide you in the app you already have on your phone.'**
  String get chooseAppBody;

  /// No description provided for @continueWithApp.
  ///
  /// In en, this message translates to:
  /// **'Continue in {app}'**
  String continueWithApp(String app);

  /// No description provided for @setupQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is {app} already set up on your phone?'**
  String setupQuestion(String app);

  /// No description provided for @setupYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, I\'m already signed in'**
  String get setupYes;

  /// No description provided for @setupYesDetail.
  ///
  /// In en, this message translates to:
  /// **'Start from booking a ride'**
  String get setupYesDetail;

  /// No description provided for @setupNo.
  ///
  /// In en, this message translates to:
  /// **'No, help me install it'**
  String get setupNo;

  /// No description provided for @setupNoDetail.
  ///
  /// In en, this message translates to:
  /// **'Start from installing the app and signing up'**
  String get setupNoDetail;

  /// No description provided for @secretCodeNote.
  ///
  /// In en, this message translates to:
  /// **'Never share this code with anyone. Saathi will never ask for it.'**
  String get secretCodeNote;

  /// No description provided for @resumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off?'**
  String get resumeTitle;

  /// No description provided for @resumeNew.
  ///
  /// In en, this message translates to:
  /// **'Start a new one'**
  String get resumeNew;

  /// No description provided for @inProgressApp.
  ///
  /// In en, this message translates to:
  /// **'In progress: {app}'**
  String inProgressApp(String app);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
