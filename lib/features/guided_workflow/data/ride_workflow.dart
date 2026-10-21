import '../domain/workflow.dart';

/// Ride-hailing apps covered by the first guide.
enum RideApp {
  ola('Ola'),
  uber('Uber'),
  rapido('Rapido');

  const RideApp(this.displayName);

  /// Brand names are never translated.
  final String displayName;

  /// [fromInstall]: the guide starts at installing the app and signing up.
  String workflowId({required bool fromInstall}) =>
      fromInstall ? 'ride_${name}_new_v2' : 'ride_${name}_v2';

  static RideApp? fromWorkflowId(String id) {
    for (final app in values) {
      if (id == app.workflowId(fromInstall: true) ||
          id == app.workflowId(fromInstall: false)) {
        return app;
      }
    }
    return null;
  }
}

/// Step order per app, from screen recordings of a real new-user sign-up and
/// booking (2026-10-21, Android). The apps differ: Uber asks for location before the
/// phone number and offers a passkey; Ola and Uber ask to confirm the pickup pin
/// after the book button; Rapido books directly.
const _setupSteps = {
  RideApp.ola: [
    'install_app',
    'open_app',
    'enter_phone',
    'enter_otp',
    'allow_location',
  ],
  RideApp.uber: [
    'install_app',
    'open_app',
    'allow_location',
    'enter_phone',
    'enter_otp',
    'optional_setup',
  ],
  RideApp.rapido: [
    'install_app',
    'open_app',
    'enter_phone',
    'enter_otp',
    'allow_location',
  ],
};

const _bookingSteps = {
  RideApp.ola: [
    'find_locations',
    'enter_destination',
    'check_locations',
    'review_rides',
    'check_fare',
    'decide_booking',
    'confirm_pickup',
    'confirm_outcome',
  ],
  RideApp.uber: [
    'find_locations',
    'enter_destination',
    'check_locations',
    'review_rides',
    'check_fare',
    'decide_booking',
    'confirm_pickup',
    'confirm_outcome',
  ],
  RideApp.rapido: [
    'find_locations',
    'enter_destination',
    'check_locations',
    'review_rides',
    'check_fare',
    'decide_booking',
    'confirm_outcome',
  ],
};

/// Book-a-ride guide for [app]: from a fresh install (install, sign up, OTP,
/// permissions, then booking) or for someone already signed in.
///
/// Marathi copy should be reviewed by a native speaker before release.
WorkflowDefinition rideWorkflow(RideApp app, {required bool fromInstall}) {
  final ids = [
    if (fromInstall) ..._setupSteps[app]! else 'open_app',
    ..._bookingSteps[app]!,
  ];
  return WorkflowDefinition(
    id: app.workflowId(fromInstall: fromInstall),
    title: LocalizedText(
      en: 'Book a ride with ${app.displayName}',
      mr: '${app.displayName} वर राइड बुक करा',
    ),
    steps: [for (final id in ids) _step(app, id)],
  );
}

/// Screens recorded for each app. Other steps show a labelled placeholder.
const _recorded = {
  RideApp.ola: {
    'open_app',
    'enter_phone',
    'enter_otp',
    'allow_location',
    'find_locations',
    'enter_destination',
    'check_locations',
    'review_rides',
    'check_fare',
    'decide_booking',
    'confirm_pickup',
    'confirm_outcome',
  },
  RideApp.uber: {
    'open_app',
    'allow_location',
    'enter_phone',
    'enter_otp',
    'optional_setup',
    'find_locations',
    'enter_destination',
    'check_locations',
    'review_rides',
    'check_fare',
    'decide_booking',
    'confirm_pickup',
  },
  RideApp.rapido: {
    'open_app',
    'enter_phone',
    'enter_otp',
    'allow_location',
    'find_locations',
    'enter_destination',
    'check_locations',
    'review_rides',
    'check_fare',
    'decide_booking',
  },
};

/// True when a real (redacted) screenshot exists for this step.
bool hasRecordedScreenshot(RideApp app, String stepId) =>
    _recorded[app]!.contains(stepId);

String _asset(RideApp app, String stepId) =>
    'assets/workflows/${app.name}/${app.name}_$stepId.jpg';

ScreenshotAnnotation _hl(
  double l,
  double t,
  double w,
  double h, {
  int? marker,
  String? en,
  String? mr,
}) => ScreenshotAnnotation(
  highlight: NormalizedRect(l, t, w, h),
  marker: marker,
  label: en == null ? null : LocalizedText(en: en, mr: mr!),
);

/// Highlights, measured on the recorded screenshots (fractions of the image).
final Map<(RideApp, String), List<ScreenshotAnnotation>> _annotations = {
  // ---- Ola
  (RideApp.ola, 'open_app'): [
    _hl(0.6, 0.175, 0.16, 0.12, en: 'Tap Ola', mr: 'Ola वर दाबा'),
  ],
  (RideApp.ola, 'enter_phone'): [
    _hl(0.1, 0.335, 0.8, 0.06, en: 'Type your number', mr: 'तुमचा नंबर लिहा'),
  ],
  (RideApp.ola, 'enter_otp'): [
    _hl(0.08, 0.33, 0.6, 0.07, en: 'The code goes here', mr: 'कोड इथे येतो'),
  ],
  (RideApp.ola, 'allow_location'): [
    _hl(0.26, 0.81, 0.48, 0.05, en: 'Tap this', mr: 'इथे दाबा'),
  ],
  (RideApp.ola, 'find_locations'): [
    _hl(
      0.02,
      0.375,
      0.96,
      0.08,
      en: 'Where you want to go',
      mr: 'कुठे जायचे ते इथे',
    ),
  ],
  (RideApp.ola, 'enter_destination'): [
    _hl(0.13, 0.185, 0.84, 0.045, en: 'Type the place', mr: 'ठिकाण लिहा'),
  ],
  (RideApp.ola, 'check_locations'): [
    _hl(
      0.2,
      0.075,
      0.52,
      0.095,
      en: 'Pickup and destination',
      mr: 'पिकअप आणि ठिकाण',
    ),
  ],
  (RideApp.ola, 'review_rides'): [_hl(0.02, 0.22, 0.96, 0.55)],
  (RideApp.ola, 'check_fare'): [
    _hl(0.03, 0.35, 0.94, 0.135, en: 'Ride and fare', mr: 'गाडी आणि भाडे'),
  ],
  (RideApp.ola, 'decide_booking'): [
    _hl(0.23, 0.9, 0.74, 0.08, en: 'Book button', mr: 'बुक बटण'),
  ],
  (RideApp.ola, 'confirm_pickup'): [
    _hl(
      0.44,
      0.355,
      0.12,
      0.06,
      marker: 1,
      en: 'Your pickup pin',
      mr: 'तुमचा पिकअप पिन',
    ),
    _hl(0.04, 0.915, 0.92, 0.07, marker: 2),
  ],
  (RideApp.ola, 'confirm_outcome'): [
    _hl(0.2, 0.275, 0.6, 0.05, en: 'Ride confirmed', mr: 'राइड पक्की झाली'),
  ],
  // ---- Uber
  (RideApp.uber, 'open_app'): [
    _hl(0.77, 0.445, 0.18, 0.115, en: 'Tap Uber', mr: 'Uber वर दाबा'),
  ],
  (RideApp.uber, 'allow_location'): [
    _hl(0.27, 0.505, 0.46, 0.05, en: 'Tap this', mr: 'इथे दाबा'),
  ],
  (RideApp.uber, 'enter_phone'): [
    _hl(
      0.35,
      0.435,
      0.62,
      0.065,
      marker: 1,
      en: 'Your number',
      mr: 'तुमचा नंबर',
    ),
    _hl(0.04, 0.515, 0.92, 0.065, marker: 2),
  ],
  (RideApp.uber, 'enter_otp'): [
    _hl(0.04, 0.285, 0.61, 0.07, en: 'Type the code here', mr: 'कोड इथे लिहा'),
  ],
  (RideApp.uber, 'optional_setup'): [
    _hl(
      0.04,
      0.905,
      0.92,
      0.075,
      en: 'You can tap Cancel',
      mr: 'Cancel वर दाबू शकता',
    ),
  ],
  (RideApp.uber, 'find_locations'): [
    _hl(0.05, 0.155, 0.9, 0.075, en: 'Where to?', mr: 'कुठे जायचे?'),
  ],
  (RideApp.uber, 'enter_destination'): [
    _hl(0.08, 0.2, 0.88, 0.045, en: 'Type the place', mr: 'ठिकाण लिहा'),
  ],
  (RideApp.uber, 'check_locations'): [
    _hl(0.37, 0.11, 0.43, 0.055, marker: 1),
    _hl(0.29, 0.385, 0.42, 0.055, marker: 2),
  ],
  (RideApp.uber, 'review_rides'): [_hl(0.03, 0.555, 0.94, 0.28)],
  (RideApp.uber, 'check_fare'): [
    _hl(0.04, 0.555, 0.92, 0.1, en: 'Ride and fare', mr: 'गाडी आणि भाडे'),
  ],
  (RideApp.uber, 'decide_booking'): [
    _hl(0.04, 0.905, 0.92, 0.075, en: 'Book button', mr: 'बुक बटण'),
  ],
  (RideApp.uber, 'confirm_pickup'): [
    _hl(
      0.44,
      0.32,
      0.12,
      0.07,
      marker: 1,
      en: 'Your pickup pin',
      mr: 'तुमचा पिकअप पिन',
    ),
    _hl(0.04, 0.905, 0.92, 0.075, marker: 2),
  ],
  // ---- Rapido
  (RideApp.rapido, 'open_app'): [
    _hl(0.41, 0.445, 0.18, 0.115, en: 'Tap Rapido', mr: 'Rapido वर दाबा'),
  ],
  (RideApp.rapido, 'enter_phone'): [
    _hl(0.16, 0.275, 0.83, 0.06, en: 'Type your number', mr: 'तुमचा नंबर लिहा'),
  ],
  (RideApp.rapido, 'enter_otp'): [
    _hl(0.04, 0.215, 0.91, 0.075, en: 'Type the code here', mr: 'कोड इथे लिहा'),
  ],
  (RideApp.rapido, 'allow_location'): [
    _hl(0.27, 0.548, 0.46, 0.05, en: 'Tap this', mr: 'इथे दाबा'),
  ],
  (RideApp.rapido, 'find_locations'): [
    _hl(
      0.04,
      0.2,
      0.92,
      0.07,
      en: 'Where you want to go',
      mr: 'कुठे जायचे ते इथे',
    ),
  ],
  (RideApp.rapido, 'enter_destination'): [
    _hl(0.2, 0.205, 0.75, 0.045, en: 'Type the place', mr: 'ठिकाण लिहा'),
  ],
  (RideApp.rapido, 'check_locations'): [
    _hl(0.22, 0.17, 0.45, 0.2, en: 'Your route', mr: 'तुमचा मार्ग'),
  ],
  (RideApp.rapido, 'review_rides'): [_hl(0.03, 0.47, 0.95, 0.33)],
  (RideApp.rapido, 'check_fare'): [
    _hl(0.035, 0.535, 0.93, 0.115, en: 'Ride and fare', mr: 'गाडी आणि भाडे'),
  ],
  (RideApp.rapido, 'decide_booking'): [
    _hl(0.04, 0.915, 0.92, 0.07, en: 'Book button', mr: 'बुक बटण'),
  ],
};

StepScreenshot _shot(RideApp app, String stepId, LocalizedText description) =>
    StepScreenshot(
      asset: _asset(app, stepId),
      description: description,
      annotations: hasRecordedScreenshot(app, stepId)
          ? _annotations[(app, stepId)] ?? const []
          : const [],
    );

WorkflowStep _step(RideApp app, String id) {
  final a = app.displayName;
  switch (id) {
    case 'install_app':
      return WorkflowStep(
        id: id,
        title: LocalizedText(en: 'Install $a', mr: '$a इन्स्टॉल करा'),
        instruction: LocalizedText(
          en:
              'Open the Play Store, search for $a and tap Install. Check the '
              'name and logo carefully so you get the real app, not a copy.',
          mr:
              'Play Store उघडा, $a शोधा आणि Install वर दाबा. खरे ॲपच मिळावे म्हणून '
              'नाव आणि लोगो नीट तपासा.',
        ),
        simplerInstruction: LocalizedText(
          en:
              'Open Play Store. Type $a in the search box. Tap Install and wait '
              'until it finishes.',
          mr:
              'Play Store उघडा. शोधण्याच्या जागेत $a लिहा. Install वर दाबा आणि ते '
              'पूर्ण होईपर्यंत थांबा.',
        ),
        screenshot: _shot(
          app,
          id,
          LocalizedText(
            en: '$a in the Play Store with the Install button',
            mr: 'Install बटणासह Play Store मधील $a',
          ),
        ),
      );
    case 'open_app':
      return WorkflowStep(
        id: id,
        title: LocalizedText(en: 'Open $a', mr: '$a उघडा'),
        instruction: LocalizedText(
          en:
              'Open the $a app on your phone. Saathi will guide you, but you will '
              'do each tap yourself.',
          mr:
              'तुमच्या फोनवर $a ॲप उघडा. साथी तुम्हाला मार्गदर्शन करेल, पण प्रत्येक '
              'बटण तुम्ही स्वतः दाबायचे आहे.',
        ),
        simplerInstruction: LocalizedText(
          en: 'Find the $a icon on your phone and tap it once.',
          mr: 'फोनवर $a चे चिन्ह शोधा आणि त्यावर एकदा दाबा.',
        ),
        screenshot: _shot(
          app,
          id,
          LocalizedText(
            en: 'The $a app icon on a phone screen',
            mr: 'फोनच्या स्क्रीनवरील $a ॲपचे चिन्ह',
          ),
        ),
      );
    case 'enter_phone':
      return WorkflowStep(
        id: id,
        title: const LocalizedText(
          en: 'Enter your mobile number',
          mr: 'तुमचा मोबाईल नंबर लिहा',
        ),
        instruction: LocalizedText(
          en:
              '$a asks for your mobile number. Type it and continue. If your '
              'phone shows a list of numbers, you can pick yours from it.',
          mr:
              '$a तुमचा मोबाईल नंबर विचारेल. तो लिहा आणि पुढे जा. फोनने नंबरांची यादी '
              'दाखवली, तर त्यातून तुमचा नंबर निवडू शकता.',
        ),
        simplerInstruction: const LocalizedText(
          en: 'Type your 10-digit mobile number in the box, then tap continue.',
          mr: 'जागेत तुमचा १० अंकी मोबाईल नंबर लिहा, मग पुढे जाण्यासाठी दाबा.',
        ),
        screenshot: _shot(
          app,
          id,
          LocalizedText(
            en: '$a asking for a mobile number',
            mr: 'मोबाईल नंबर विचारणारी $a स्क्रीन',
          ),
        ),
      );
    case 'enter_otp':
      return WorkflowStep(
        id: id,
        title: const LocalizedText(
          en: 'Enter the code you receive',
          mr: 'आलेला कोड लिहा',
        ),
        instruction: LocalizedText(
          en:
              '$a sends a one-time code (OTP) by SMS or WhatsApp. Sometimes it '
              'fills in by itself. If not, type it only into $a. Never tell this '
              'code to anyone, not even Saathi.',
          mr:
              '$a SMS किंवा WhatsApp वर एक-वेळ कोड (OTP) पाठवेल. कधी कधी तो आपोआप '
              'भरला जातो. नाही भरला, तर तो फक्त $a मध्येच लिहा. हा कोड कोणालाही '
              'सांगू नका, साथीलाही नाही.',
        ),
        simplerInstruction: LocalizedText(
          en:
              'Look for a new SMS or WhatsApp message with a short number. Type '
              'that number into $a. Do not say it out loud.',
          mr:
              'नवीन SMS किंवा WhatsApp मेसेजमध्ये एक छोटा नंबर पाहा. तो नंबर $a मध्ये '
              'लिहा. तो मोठ्याने बोलू नका.',
        ),
        sensitivity: Sensitivity.secretCode,
        screenshot: _shot(
          app,
          id,
          LocalizedText(
            en: '$a asking for the OTP code',
            mr: 'OTP कोड विचारणारी $a स्क्रीन',
          ),
        ),
      );
    case 'allow_location':
      return WorkflowStep(
        id: id,
        title: const LocalizedText(
          en: 'Allow your location',
          mr: 'लोकेशनला परवानगी द्या',
        ),
        instruction: LocalizedText(
          en:
              '$a asks to use your location to find your pickup point. Choose '
              '"While using the app". If it asks for other permissions and you '
              'are not sure, you can say no.',
          mr:
              'तुमचे पिकअपचे ठिकाण शोधण्यासाठी $a लोकेशन वापरण्याची परवानगी मागेल. '
              '"While using the app" निवडा. इतर परवानग्या मागितल्या आणि खात्री '
              'नसेल, तर नाही म्हणू शकता.',
        ),
        simplerInstruction: const LocalizedText(
          en:
              'A box will pop up asking about location. Tap "While using the '
              'app".',
          mr: 'लोकेशनबद्दल विचारणारा एक बॉक्स येईल. "While using the app" वर दाबा.',
        ),
        screenshot: _shot(
          app,
          id,
          const LocalizedText(
            en: 'Android location permission pop-up',
            mr: 'Android लोकेशन परवानगीचा बॉक्स',
          ),
        ),
      );
    case 'optional_setup':
      return WorkflowStep(
        id: id,
        title: const LocalizedText(
          en: 'Skip extra setup',
          mr: 'जास्तीची सेटिंग वगळा',
        ),
        instruction: LocalizedText(
          en:
              '$a may ask you to create a passkey. You do not need it to book a '
              'ride. You can tap Cancel.',
          mr:
              '$a तुम्हाला पासकी तयार करायला सांगू शकते. राइड बुक करण्यासाठी तिची गरज '
              'नाही. तुम्ही Cancel वर दाबू शकता.',
        ),
        simplerInstruction: const LocalizedText(
          en: 'If you see "Create a passkey", tap Cancel at the bottom.',
          mr: '"Create a passkey" दिसले, तर खाली Cancel वर दाबा.',
        ),
        screenshot: _shot(
          app,
          id,
          LocalizedText(
            en: '$a asking to create a passkey',
            mr: 'पासकी तयार करायला सांगणारी $a स्क्रीन',
          ),
        ),
      );
    case 'find_locations':
      return WorkflowStep(
        id: id,
        title: const LocalizedText(
          en: 'Find where to enter your destination',
          mr: 'ठिकाण लिहिण्याची जागा शोधा',
        ),
        instruction: LocalizedText(
          en:
              'On the $a home screen, find the box that asks where you want to '
              'go. Your pickup is usually your current location.',
          mr:
              '$a च्या मुख्य स्क्रीनवर कुठे जायचे आहे असे विचारणारी जागा शोधा. पिकअप '
              'सहसा तुमचे सध्याचे ठिकाण असते.',
        ),
        simplerInstruction: const LocalizedText(
          en: 'Look for the box that asks where you want to go, and tap it.',
          mr: 'कुठे जायचे आहे असे विचारणाऱ्या जागेवर दाबा.',
        ),
        screenshot: _shot(
          app,
          id,
          LocalizedText(
            en: '$a home screen with the destination box',
            mr: 'ठिकाणाच्या जागेसह $a ची मुख्य स्क्रीन',
          ),
        ),
      );
    case 'enter_destination':
      return WorkflowStep(
        id: id,
        title: const LocalizedText(
          en: 'Enter your destination',
          mr: 'पोहोचण्याचे ठिकाण लिहा',
        ),
        instruction: const LocalizedText(
          en:
              'Type where you want to go. Then choose the right place from the '
              'list that appears.',
          mr: 'तुम्हाला जिथे जायचे आहे ते लिहा. मग खाली येणाऱ्या यादीतून योग्य ठिकाण निवडा.',
        ),
        simplerInstruction: const LocalizedText(
          en:
              'Type the name of the place, then tap the correct place in the '
              'list.',
          mr: 'ठिकाणाचे नाव लिहा, मग यादीतील योग्य ठिकाणावर दाबा.',
        ),
        helpers: const {StepHelper.copyText},
        screenshot: _shot(
          app,
          id,
          LocalizedText(en: '$a destination search', mr: '$a मधील ठिकाण शोध'),
        ),
      );
    case 'check_locations':
      return WorkflowStep(
        id: id,
        title: const LocalizedText(
          en: 'Check both places',
          mr: 'दोन्ही ठिकाणे तपासा',
        ),
        instruction: LocalizedText(
          en:
              'Read the pickup and destination that $a shows. Make sure both are '
              'correct before you go on.',
          mr:
              '$a दाखवत असलेले पिकअप आणि पोहोचण्याचे ठिकाण वाचा. पुढे जाण्याआधी दोन्ही '
              'बरोबर आहेत ना, याची खात्री करा.',
        ),
        simplerInstruction: const LocalizedText(
          en: 'Read both places slowly. If one is wrong, tap it to change it.',
          mr:
              'दोन्ही ठिकाणे सावकाश वाचा. एखादे चुकीचे असेल, तर ते बदलण्यासाठी त्यावर '
              'दाबा.',
        ),
        screenshot: _shot(
          app,
          id,
          LocalizedText(
            en: '$a showing pickup and destination',
            mr: 'पिकअप आणि ठिकाण दाखवणारी $a स्क्रीन',
          ),
        ),
      );
    case 'review_rides':
      return WorkflowStep(
        id: id,
        title: const LocalizedText(
          en: 'Look at the ride options',
          mr: 'गाड्यांचे पर्याय पाहा',
        ),
        instruction: LocalizedText(
          en:
              '$a shows different kinds of rides, like bike, auto or cab, each '
              'with a time and price. Read them and tap the one you want.',
          mr:
              '$a बाईक, ऑटो किंवा कॅब असे वेगवेगळे पर्याय वेळ आणि किमतीसह दाखवते. ते '
              'वाचा आणि तुम्हाला हवा असलेला पर्याय निवडा.',
        ),
        simplerInstruction: const LocalizedText(
          en: 'Read each option. Then tap one.',
          mr: 'प्रत्येक पर्याय वाचा. मग एकावर दाबा.',
        ),
        screenshot: _shot(
          app,
          id,
          LocalizedText(
            en: 'Ride types offered by $a',
            mr: '$a ने दाखवलेले गाड्यांचे प्रकार',
          ),
        ),
      );
    case 'check_fare':
      return WorkflowStep(
        id: id,
        title: const LocalizedText(en: 'Check the fare', mr: 'भाडे तपासा'),
        instruction: LocalizedText(
          en:
              'Read the fare shown next to your ride, and how you will pay (for '
              'example cash). Fares can change, so go by what $a shows you now.',
          mr:
              'तुमच्या गाडीसमोर दाखवलेले भाडे आणि पैसे कसे द्यायचे (उदा. रोख) ते '
              'वाचा. भाडे बदलू शकते, म्हणून $a आत्ता जे दाखवत आहे तेच पाहा.',
        ),
        simplerInstruction: const LocalizedText(
          en:
              'Read the amount on the screen. If it does not feel right, you can '
              'stop here.',
          mr: 'स्क्रीनवरची रक्कम वाचा. ती योग्य वाटत नसेल, तर इथेच थांबू शकता.',
        ),
        sensitivity: Sensitivity.money,
        screenshot: _shot(
          app,
          id,
          LocalizedText(
            en: '$a showing the fare for the chosen ride',
            mr: 'निवडलेल्या गाडीचे भाडे दाखवणारी $a स्क्रीन',
          ),
        ),
      );
    case 'decide_booking':
      return WorkflowStep(
        id: id,
        title: const LocalizedText(
          en: 'Book only if you are happy',
          mr: 'खात्री असेल तरच बुक करा',
        ),
        instruction: LocalizedText(
          en:
              'If everything looks right and you want to go ahead, tap the book '
              'button at the bottom of $a yourself. If you are not sure, you can '
              'stop here. Nothing is booked until you tap it.',
          mr:
              'सगळे बरोबर असेल आणि पुढे जायचे असेल, तर $a च्या खालचे बुक बटण स्वतः '
              'दाबा. खात्री नसेल तर इथेच थांबा. तुम्ही दाबेपर्यंत काहीही बुक होत नाही.',
        ),
        simplerInstruction: const LocalizedText(
          en: 'Only tap book if you want this ride. If not, do not tap anything.',
          mr: 'ही राइड हवी असेल तरच बुक बटण दाबा. नको असेल तर काहीही दाबू नका.',
        ),
        sensitivity: Sensitivity.money,
        screenshot: _shot(
          app,
          id,
          LocalizedText(
            en: '$a screen with the book button',
            mr: 'बुक बटणासह $a स्क्रीन',
          ),
        ),
      );
    case 'confirm_pickup':
      return WorkflowStep(
        id: id,
        title: const LocalizedText(
          en: 'Confirm your pickup point',
          mr: 'पिकअपचे ठिकाण पक्के करा',
        ),
        instruction: LocalizedText(
          en:
              '$a shows a map with a pin. Check the pin is where you will be '
              'waiting, then tap the confirm button. $a then starts looking for a '
              'driver.',
          mr:
              '$a नकाशावर एक पिन दाखवेल. तुम्ही जिथे थांबणार आहात तिथेच पिन आहे ना ते '
              'तपासा, मग पक्के करण्याचे बटण दाबा. त्यानंतर $a ड्रायव्हर शोधायला '
              'सुरुवात करेल.',
        ),
        simplerInstruction: const LocalizedText(
          en: 'Check the pin on the map, then tap the button at the bottom.',
          mr: 'नकाशावरचा पिन तपासा, मग खालचे बटण दाबा.',
        ),
        sensitivity: Sensitivity.money,
        screenshot: _shot(
          app,
          id,
          LocalizedText(
            en: '$a asking to confirm the pickup point',
            mr: 'पिकअपचे ठिकाण पक्के करायला सांगणारी $a स्क्रीन',
          ),
        ),
      );
    case 'confirm_outcome':
      return WorkflowStep(
        id: id,
        kind: StepKind.outcome,
        title: const LocalizedText(en: 'What happened?', mr: 'काय झाले?'),
        instruction: LocalizedText(
          en:
              'Look at $a. Does it say your ride is confirmed? It may show the '
              'driver, the vehicle number and a ride code. Share that ride code '
              'only with your driver when you get in.',
          mr:
              '$a कडे पाहा. राइड पक्की झाल्याचे दिसते का? त्यात ड्रायव्हर, गाडीचा नंबर '
              'आणि एक राइड कोड दिसू शकतो. तो राइड कोड फक्त गाडीत बसताना तुमच्या '
              'ड्रायव्हरलाच सांगा.',
        ),
        simplerInstruction: LocalizedText(
          en: 'Check the $a screen. Does it say your ride is confirmed?',
          mr: '$a ची स्क्रीन पाहा. राइड पक्की झाल्याचे दिसते का?',
        ),
        screenshot: _shot(
          app,
          id,
          LocalizedText(
            en: '$a screen after a ride is confirmed',
            mr: 'राइड पक्की झाल्यानंतरची $a स्क्रीन',
          ),
        ),
      );
  }
  throw ArgumentError('Unknown ride step: $id');
}
