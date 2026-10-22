// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'साथी';

  @override
  String get onboardingTitle => 'रोजच्या ॲप्ससाठी तुमचा सोबती.';

  @override
  String get onboardingBody =>
      'तुम्हाला काय करायचे आहे ते साथीला सांगा. आम्ही तुम्हाला एका वेळी एक पाऊल मार्गदर्शन करू.';

  @override
  String get getStarted => 'सुरू करा';

  @override
  String get chooseLanguage => 'तुमची भाषा निवडा';

  @override
  String get privacyNote =>
      'नियंत्रण तुमच्याकडेच राहते. साथी तुमच्यासाठी कधीही बटण दाबत नाही, बुक करत नाही किंवा पैसे भरत नाही.';

  @override
  String get homeHeading => 'तुम्हाला कशासाठी मदत हवी आहे?';

  @override
  String get homeSubheading => 'मी तुम्हाला एका वेळी एक पाऊल मार्गदर्शन करेन.';

  @override
  String get talkToSaathi => 'साथीशी बोला';

  @override
  String get voiceCardBody =>
      'इंग्रजी किंवा मराठीत बोला. साथी ऐकेल आणि मार्गदर्शन करेल.';

  @override
  String get startTalking => 'बोलायला सुरुवात करा';

  @override
  String get openCall => 'कॉल उघडा';

  @override
  String get guidesHeading => 'मार्गदर्शक';

  @override
  String get taskBookCab => 'राइड बुक करा';

  @override
  String get taskBookCabDetail =>
      'Ola, Uber किंवा Rapido साठी टप्प्याटप्प्याने मदत';

  @override
  String get continueGuide => 'पुढे सुरू ठेवा';

  @override
  String get startOver => 'पुन्हा सुरुवात करा';

  @override
  String stepOf(int current, int total) {
    return 'पायरी $current / $total';
  }

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get voiceIdle => 'तुम्ही तयार असाल तेव्हा';

  @override
  String get voiceIdleHint =>
      'बोलायला सुरुवात करा वर दाबा आणि तुम्हाला काय करायचे आहे ते सांगा.';

  @override
  String get voiceRequestingPermission => 'परवानगीची वाट पाहत आहे';

  @override
  String get voiceRequestingPermissionHint =>
      'साथीला तुमचे बोलणे ऐकू यावे म्हणून मायक्रोफोनला परवानगी द्या.';

  @override
  String get voiceConnecting => 'साथीशी जोडत आहे';

  @override
  String get voiceConnectingHint => 'याला सहसा काही सेकंद लागतात.';

  @override
  String get voiceListening => 'ऐकत आहे';

  @override
  String get voiceListeningHint => 'नेहमीसारखे बोला. साथी तुमचे ऐकत आहे.';

  @override
  String get voiceSpeaking => 'साथी बोलत आहे';

  @override
  String get voiceSpeakingHint => 'तुम्ही कधीही मध्ये बोलू शकता.';

  @override
  String get voiceMuted => 'मायक्रोफोन थांबवला आहे';

  @override
  String get voiceMutedHint =>
      'तुम्ही अनम्यूट करेपर्यंत साथीला तुमचे ऐकू येणार नाही.';

  @override
  String get voiceEnded => 'कॉल संपला';

  @override
  String get voiceEndedHint => 'तुम्हाला हवे तेव्हा साथीशी पुन्हा बोलू शकता.';

  @override
  String get voiceDisconnected => 'व्हॉइस कॉल संपला';

  @override
  String get voiceDisconnectedHint =>
      'तुमची प्रगती जतन केली आहे. तुम्ही पुन्हा बोलू शकता.';

  @override
  String get voiceFailed => 'कॉल सुरू होऊ शकला नाही';

  @override
  String get errMicDenied =>
      'तुमचे ऐकण्यासाठी साथीला मायक्रोफोन लागतो. सेटिंग्जमध्ये तुम्ही परवानगी देऊ शकता.';

  @override
  String get errNotConfigured =>
      'या फोनवर अजून व्हॉइस सुरू केलेला नाही. तरीही तुम्ही टप्प्याटप्प्याचे मार्गदर्शन वापरू शकता.';

  @override
  String get errNetwork =>
      'साथीपर्यंत पोहोचता आले नाही. इंटरनेट तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get errBusy =>
      'साथी सध्या व्यस्त आहे. एका मिनिटाने पुन्हा प्रयत्न करा.';

  @override
  String get errUnavailable =>
      'या फोनवर सध्या व्हॉइस चालू शकत नाही. तरीही तुम्ही मार्गदर्शन वापरू शकता.';

  @override
  String get errGeneric => 'काहीतरी चुकले. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get endCall => 'कॉल संपवा';

  @override
  String get mute => 'म्यूट करा';

  @override
  String get unmute => 'अनम्यूट करा';

  @override
  String get tryAgain => 'पुन्हा प्रयत्न करा';

  @override
  String get talkAgain => 'पुन्हा बोला';

  @override
  String get openSettings => 'सेटिंग्ज उघडा';

  @override
  String get backToGuide => 'मार्गदर्शनाकडे परत जा';

  @override
  String get currentStepLabel => 'सध्याची पायरी';

  @override
  String get voiceNoGuideHint =>
      'असे म्हणून पाहा: “मला कॅब बुक करायला मदत करा”.';

  @override
  String get micRationaleTitle => 'साथीला तुमचा मायक्रोफोन हवा आहे';

  @override
  String get micRationaleBody =>
      'म्हणजे तुम्ही काय बोलता ते साथीला ऐकू येईल. मायक्रोफोन फक्त कॉल चालू असतानाच वापरला जातो, आणि तुम्ही कधीही कॉल संपवू शकता.';

  @override
  String get continueAction => 'पुढे जा';

  @override
  String get notNow => 'आत्ता नको';

  @override
  String get iveDoneThis => 'मी हे केले';

  @override
  String get repeatInstructions => 'पुन्हा सांगा';

  @override
  String get needHelp => 'मला मदत हवी';

  @override
  String get back => 'मागे';

  @override
  String get exitGuide => 'मार्गदर्शन बंद करा';

  @override
  String get sensitiveNote =>
      'यात पैशांचा व्यवहार आहे. सावकाश करा — निर्णय फक्त तुमचा आहे.';

  @override
  String get voiceHeardDone =>
      'ही पायरी झाली असे तुम्ही म्हणालात, असे साथीने ऐकले.';

  @override
  String get yesDone => 'हो, झाले';

  @override
  String get notYet => 'अजून नाही';

  @override
  String get simplerHeading => 'सोप्या शब्दांत';

  @override
  String get outcomeBooked => 'हो, माझी राइड बुक झाली';

  @override
  String get outcomeNotBooked => 'नाही, मी बुक केली नाही';

  @override
  String get progressSaved => 'तुमची प्रगती जतन केली आहे.';

  @override
  String get saveFailed =>
      'तुमची प्रगती जतन करता आली नाही. काहीही बदलले नाही — कृपया पुन्हा प्रयत्न करा.';

  @override
  String get actionNotPossible => 'या पायरीवर हे करता येत नाही.';

  @override
  String get helpTitle => 'साथी कशी मदत करू शकतो?';

  @override
  String get helpRepeat => 'पुन्हा सांगा';

  @override
  String get helpSimpler => 'आणखी सोप्या भाषेत सांगा';

  @override
  String get helpShowAgain => 'चित्र पुन्हा दाखवा';

  @override
  String get helpGoBack => 'एक पायरी मागे जा';

  @override
  String get helpStop => 'आत्तासाठी थांबा';

  @override
  String get helpTalk => 'साथीशी बोला';

  @override
  String get copyHelperButton => 'साथीमधून पत्ता कॉपी करा';

  @override
  String get copySheetTitle => 'पत्ता कॉपी करा';

  @override
  String get copySheetBody =>
      'पत्ता इथे लिहा आणि कॉपी करा. मग तुमच्या राइड ॲपमध्ये ठिकाणाच्या जागेवर दाबून धरा आणि Paste वर दाबा. साथी तुमच्यासाठी पेस्ट करू शकत नाही.';

  @override
  String get copyFieldLabel => 'पत्ता';

  @override
  String get copyAction => 'कॉपी करा';

  @override
  String get copied => 'कॉपी झाले. आता तुमचे राइड ॲप उघडा आणि स्वतः पेस्ट करा.';

  @override
  String get copyEmpty => 'आधी पत्ता लिहा.';

  @override
  String get copyFailed => 'कॉपी करता आले नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get screenshotPlaceholderTitle => 'चित्र लवकरच येईल';

  @override
  String get screenshotPlaceholderBody =>
      'तात्पुरते चित्र — ॲपचा खरा स्क्रीनशॉट अजून जोडलेला नाही.';

  @override
  String screenshotLabel(String description) {
    return 'स्क्रीनशॉट: $description';
  }

  @override
  String get completedTitle => 'छान केलेत';

  @override
  String completedBody(String app) {
    return '$app ने तुमची राइड बुक केली असे तुम्ही साथीला सांगितले. हे तुम्ही स्वतः केलेत. राइडची माहिती $app मध्ये दिसेल.';
  }

  @override
  String get notCompletedTitle => 'काही हरकत नाही';

  @override
  String get notCompletedBody =>
      'साथीमार्फत काहीही बुक झाले नाही. तुम्हाला हवे तेव्हा पुन्हा प्रयत्न करू शकता.';

  @override
  String get done => 'झाले';

  @override
  String get returnHome => 'मुख्य स्क्रीनवर जा';

  @override
  String get restoreIncompatible =>
      'तुम्ही शेवटी वापरल्यानंतर हे मार्गदर्शन बदलले आहे. कृपया पुन्हा सुरुवात करा.';

  @override
  String get restoreFailed =>
      'तुमची जतन केलेली प्रगती उघडता आली नाही. तुम्ही पुन्हा सुरुवात करू शकता.';

  @override
  String get workflowMissing => 'हे मार्गदर्शन सध्या उपलब्ध नाही.';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsPrivacy => 'गोपनीयता';

  @override
  String get settingsPrivacyBody =>
      'साथी मार्गदर्शन करतो, पण तुमच्यासाठी कधीही बटण दाबत नाही, लिहित नाही, बुक करत नाही किंवा पैसे भरत नाही. तुमची प्रगती या फोनवर जतन होते आणि तिची एक प्रत साथीच्या क्लाउडमध्ये ठेवली जाते. साथीला तुमचे बोलणे समजावे म्हणून व्हॉइस कॉल आमचा व्हॉइस भागीदार Bolna हाताळतो. OTP, PIN किंवा पासवर्ड साथीला कधीही सांगू नका.';

  @override
  String get settingsVersion => 'आवृत्ती';

  @override
  String get settingsDiagnostics => 'व्हॉइस तपासणी (डेव्हलपर्ससाठी)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMarathi => 'मराठी';

  @override
  String get chooseAppTitle => 'तुम्ही कोणते ॲप वापरता?';

  @override
  String get chooseAppBody =>
      'तुमच्या फोनवर आधीपासून असलेल्या ॲपमध्ये साथी तुम्हाला मार्गदर्शन करेल.';

  @override
  String continueWithApp(String app) {
    return '$app मध्ये पुढे सुरू ठेवा';
  }

  @override
  String setupQuestion(String app) {
    return 'तुमच्या फोनवर $app आधीच सुरू केलेले आहे का?';
  }

  @override
  String get setupYes => 'हो, मी आधीच साइन इन केले आहे';

  @override
  String get setupYesDetail => 'राइड बुक करण्यापासून सुरुवात करा';

  @override
  String get setupNo => 'नाही, इन्स्टॉल करायला मदत करा';

  @override
  String get setupNoDetail =>
      'ॲप इन्स्टॉल करणे आणि साइन अप करण्यापासून सुरुवात करा';

  @override
  String get secretCodeNote =>
      'हा कोड कोणालाही सांगू नका. साथी तो कधीही विचारणार नाही.';

  @override
  String get resumeTitle => 'जिथे थांबलात तिथून पुढे सुरू करायचे?';

  @override
  String get resumeNew => 'नवीन सुरू करा';

  @override
  String inProgressApp(String app) {
    return 'सुरू आहे: $app';
  }

  @override
  String get callSaathi => 'साथीला कॉल करा';

  @override
  String get callAgain => 'पुन्हा कॉल करा';

  @override
  String get allowMic => 'मायक्रोफोनला परवानगी द्या';

  @override
  String alreadyUsing(String app) {
    return '$app आधीपासून वापरता का?';
  }

  @override
  String get yesShort => 'हो';

  @override
  String get noNewUser => 'नाही, नवीन आहे';

  @override
  String get newRide => 'नवीन राइड';

  @override
  String get heroTapEn => 'Tap to get help';

  @override
  String get heroTapMr => 'मदतीसाठी टॅप करा';

  @override
  String get askAnything => 'या ॲप्सबद्दल मला काहीही विचारा';

  @override
  String get browseGuides => 'मार्गदर्शक पाहा';

  @override
  String get askSomethingElse => 'आणखी काही विचारा';

  @override
  String get tapToTalk => 'बोलण्यासाठी टॅप करा';

  @override
  String get allDone => 'झाले!';

  @override
  String get topicDoneBody => 'तुम्ही हे मार्गदर्शन पूर्ण केले.';

  @override
  String guidesFor(String app) {
    return '$app साठी मार्गदर्शक';
  }

  @override
  String get startGuide => 'सुरू करा';

  @override
  String get agentGreeting =>
      'नमस्कार! मी साथी. Ola, Uber, Rapido, Google Pay, PhonePe आणि WhatsApp वापरायला मी मदत करते. सांगा, काय हवे आहे?';
}
