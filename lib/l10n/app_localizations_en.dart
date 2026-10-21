// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Saathi';

  @override
  String get onboardingTitle => 'Your companion for everyday apps.';

  @override
  String get onboardingBody =>
      'Tell Saathi what you want to do. We\'ll guide you one step at a time.';

  @override
  String get getStarted => 'Get started';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get privacyNote =>
      'You stay in control. Saathi never taps, books or pays for you.';

  @override
  String get homeHeading => 'What would you like help with?';

  @override
  String get homeSubheading => 'I\'ll walk you through it, one step at a time.';

  @override
  String get talkToSaathi => 'Talk to Saathi';

  @override
  String get voiceCardBody =>
      'Speak in English or Marathi. Saathi will listen and guide you.';

  @override
  String get startTalking => 'Start talking';

  @override
  String get openCall => 'Open call';

  @override
  String get guidesHeading => 'Guides';

  @override
  String get taskBookCab => 'Book a ride';

  @override
  String get taskBookCabDetail => 'Step-by-step help with Ola, Uber or Rapido';

  @override
  String get continueGuide => 'Continue';

  @override
  String get startOver => 'Start over';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get settings => 'Settings';

  @override
  String get voiceIdle => 'Ready when you are';

  @override
  String get voiceIdleHint =>
      'Tap Start talking and say what you\'d like to do.';

  @override
  String get voiceRequestingPermission => 'Waiting for permission';

  @override
  String get voiceRequestingPermissionHint =>
      'Please allow the microphone so Saathi can hear you.';

  @override
  String get voiceConnecting => 'Connecting to Saathi';

  @override
  String get voiceConnectingHint => 'This usually takes a few seconds.';

  @override
  String get voiceListening => 'Listening';

  @override
  String get voiceListeningHint => 'Speak naturally. Saathi can hear you.';

  @override
  String get voiceSpeaking => 'Saathi is speaking';

  @override
  String get voiceSpeakingHint => 'You can interrupt any time.';

  @override
  String get voiceMuted => 'Microphone paused';

  @override
  String get voiceMutedHint => 'Saathi can\'t hear you until you unmute.';

  @override
  String get voiceEnded => 'Call ended';

  @override
  String get voiceEndedHint =>
      'You can talk to Saathi again whenever you like.';

  @override
  String get voiceDisconnected => 'The voice call ended';

  @override
  String get voiceDisconnectedHint =>
      'Your progress is saved. You can talk again.';

  @override
  String get voiceFailed => 'Couldn\'t start the call';

  @override
  String get errMicDenied =>
      'Saathi needs the microphone to hear you. You can allow it in Settings.';

  @override
  String get errNotConfigured =>
      'Voice isn\'t set up on this phone yet. You can still use the step-by-step guide.';

  @override
  String get errNetwork =>
      'Couldn\'t reach Saathi. Check your internet connection and try again.';

  @override
  String get errBusy =>
      'Saathi is busy right now. Please try again in a minute.';

  @override
  String get errUnavailable =>
      'Voice can\'t run on this phone right now. You can still use the guide.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get endCall => 'End call';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get tryAgain => 'Try again';

  @override
  String get talkAgain => 'Talk again';

  @override
  String get openSettings => 'Open settings';

  @override
  String get backToGuide => 'Back to your guide';

  @override
  String get currentStepLabel => 'Current step';

  @override
  String get voiceNoGuideHint => 'Try saying “Help me book a cab”.';

  @override
  String get micRationaleTitle => 'Saathi needs your microphone';

  @override
  String get micRationaleBody =>
      'So Saathi can hear what you say. The microphone is only used while a call is on, and you can end it any time.';

  @override
  String get continueAction => 'Continue';

  @override
  String get notNow => 'Not now';

  @override
  String get iveDoneThis => 'I\'ve done this';

  @override
  String get repeatInstructions => 'Repeat';

  @override
  String get needHelp => 'I need help';

  @override
  String get back => 'Back';

  @override
  String get exitGuide => 'Exit guide';

  @override
  String get sensitiveNote =>
      'This involves money. Take your time — only you decide.';

  @override
  String get voiceHeardDone => 'Saathi heard you say this step is done.';

  @override
  String get yesDone => 'Yes, it\'s done';

  @override
  String get notYet => 'Not yet';

  @override
  String get simplerHeading => 'In simple words';

  @override
  String get outcomeBooked => 'Yes, my ride is booked';

  @override
  String get outcomeNotBooked => 'No, I didn\'t book';

  @override
  String get progressSaved => 'Your progress is saved.';

  @override
  String get saveFailed =>
      'Couldn\'t save your progress. Nothing was changed — please try again.';

  @override
  String get actionNotPossible => 'That isn\'t possible on this step.';

  @override
  String get helpTitle => 'How can Saathi help?';

  @override
  String get helpRepeat => 'Repeat that';

  @override
  String get helpSimpler => 'Explain it more simply';

  @override
  String get helpShowAgain => 'Show me the picture again';

  @override
  String get helpGoBack => 'Go back one step';

  @override
  String get helpStop => 'Stop for now';

  @override
  String get helpTalk => 'Talk to Saathi';

  @override
  String get copyHelperButton => 'Copy an address from Saathi';

  @override
  String get copySheetTitle => 'Copy an address';

  @override
  String get copySheetBody =>
      'Type the address here and copy it. Then, in your ride app, press and hold the destination box and tap Paste. Saathi can\'t paste it for you.';

  @override
  String get copyFieldLabel => 'Address';

  @override
  String get copyAction => 'Copy';

  @override
  String get copied => 'Copied. Now open your ride app and paste it yourself.';

  @override
  String get copyEmpty => 'Type an address first.';

  @override
  String get copyFailed => 'Couldn\'t copy. Please try again.';

  @override
  String get screenshotPlaceholderTitle => 'Picture coming soon';

  @override
  String get screenshotPlaceholderBody =>
      'Placeholder — the real app screenshot hasn\'t been added yet.';

  @override
  String screenshotLabel(String description) {
    return 'Screenshot: $description';
  }

  @override
  String get completedTitle => 'Well done';

  @override
  String completedBody(String app) {
    return 'You told Saathi that $app booked your ride. You did it yourself. $app will show you the ride details.';
  }

  @override
  String get notCompletedTitle => 'No problem';

  @override
  String get notCompletedBody =>
      'Nothing was booked through Saathi. You can try again whenever you like.';

  @override
  String get done => 'Done';

  @override
  String get returnHome => 'Return home';

  @override
  String get restoreIncompatible =>
      'This guide has changed since you last used it. Please start again.';

  @override
  String get restoreFailed =>
      'Couldn\'t load your saved progress. You can start again.';

  @override
  String get workflowMissing => 'This guide isn\'t available right now.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacyBody =>
      'Saathi guides you, but never taps, types, books or pays for you. Your guide progress is saved on this phone, with a backup copy in Saathi\'s cloud. Voice calls are handled by our voice partner, Bolna, so Saathi can understand you. Never share OTPs, PINs or passwords with Saathi.';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsDiagnostics => 'Voice diagnostics (for developers)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMarathi => 'मराठी';

  @override
  String get chooseAppTitle => 'Which app do you use?';

  @override
  String get chooseAppBody =>
      'Saathi will guide you in the app you already have on your phone.';

  @override
  String continueWithApp(String app) {
    return 'Continue in $app';
  }

  @override
  String setupQuestion(String app) {
    return 'Is $app already set up on your phone?';
  }

  @override
  String get setupYes => 'Yes, I\'m already signed in';

  @override
  String get setupYesDetail => 'Start from booking a ride';

  @override
  String get setupNo => 'No, help me install it';

  @override
  String get setupNoDetail => 'Start from installing the app and signing up';

  @override
  String get secretCodeNote =>
      'Never share this code with anyone. Saathi will never ask for it.';

  @override
  String get resumeTitle => 'Continue where you left off?';

  @override
  String get resumeNew => 'Start a new one';

  @override
  String inProgressApp(String app) {
    return 'In progress: $app';
  }
}
