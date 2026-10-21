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
      fromInstall ? 'ride_${name}_new_v1' : 'ride_${name}_v1';

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

/// Book-a-ride guide, two linear variants per app: from a fresh install (install,
/// sign up, OTP, location permission, then booking) or for someone already signed in. Logical stages only: each app's exact
/// screens vary by version, so the wording avoids naming specific buttons, and
/// screenshot annotations stay empty until checked against real screenshots
/// (see assets/workflows/MANIFEST.md).
///
/// Marathi copy should be reviewed by a native speaker before release.
WorkflowDefinition rideWorkflow(RideApp app, {required bool fromInstall}) {
  final a = app.displayName;
  // Named by step id so both variants share the same screenshot files.
  String shot(String stepId) =>
      'assets/workflows/${app.name}/${app.name}_$stepId.png';

  return WorkflowDefinition(
    id: app.workflowId(fromInstall: fromInstall),
    title: LocalizedText(en: 'Book a ride with $a', mr: '$a वर राइड बुक करा'),
    steps: [
      if (fromInstall)
        WorkflowStep(
          id: 'install_app',
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
          screenshot: StepScreenshot(
            asset: shot('install_app'),
            description: LocalizedText(
              en: '$a in the Play Store with the Install button',
              mr: 'Install बटणासह Play Store मधील $a',
            ),
          ),
        ),
      WorkflowStep(
        id: 'open_app',
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
        screenshot: StepScreenshot(
          asset: shot('open_app'),
          description: LocalizedText(
            en: 'The $a app icon on a phone home screen',
            mr: 'फोनच्या होम स्क्रीनवरील $a ॲपचे चिन्ह',
          ),
        ),
      ),
      if (fromInstall) ...[
        WorkflowStep(
          id: 'enter_phone',
          title: const LocalizedText(
            en: 'Enter your mobile number',
            mr: 'तुमचा मोबाईल नंबर लिहा',
          ),
          instruction: LocalizedText(
            en:
                '$a will ask for your mobile number to create your account. Type '
                'your number and continue.',
            mr:
                'तुमचे खाते तयार करण्यासाठी $a तुमचा मोबाईल नंबर विचारेल. तुमचा नंबर '
                'लिहा आणि पुढे जा.',
          ),
          simplerInstruction: const LocalizedText(
            en: 'Type your 10-digit mobile number in the box, then tap continue.',
            mr: 'जागेत तुमचा १० अंकी मोबाईल नंबर लिहा, मग पुढे जाण्यासाठी दाबा.',
          ),
          screenshot: StepScreenshot(
            asset: shot('enter_phone'),
            description: LocalizedText(
              en: '$a asking for a mobile number',
              mr: 'मोबाईल नंबर विचारणारी $a स्क्रीन',
            ),
          ),
        ),
        WorkflowStep(
          id: 'enter_otp',
          title: const LocalizedText(
            en: 'Enter the code from SMS',
            mr: 'SMS मधील कोड लिहा',
          ),
          instruction: LocalizedText(
            en:
                '$a sends a one-time code (OTP) to your phone by SMS. Type it only '
                'into $a. Never tell this code to anyone, not even Saathi.',
            mr:
                '$a तुमच्या फोनवर SMS ने एक-वेळ कोड (OTP) पाठवेल. तो फक्त $a मध्येच '
                'लिहा. हा कोड कोणालाही सांगू नका, साथीलाही नाही.',
          ),
          simplerInstruction: LocalizedText(
            en:
                'Look for a new SMS with a short number. Type that number into $a. '
                'Do not say it out loud.',
            mr:
                'नवीन SMS मध्ये एक छोटा नंबर पाहा. तो नंबर $a मध्ये लिहा. तो मोठ्याने '
                'बोलू नका.',
          ),
          sensitivity: Sensitivity.secretCode,
          screenshot: StepScreenshot(
            asset: shot('enter_otp'),
            description: LocalizedText(
              en: '$a asking for the OTP code',
              mr: 'OTP कोड विचारणारी $a स्क्रीन',
            ),
          ),
        ),
        WorkflowStep(
          id: 'profile_details',
          title: const LocalizedText(
            en: 'Add your details if asked',
            mr: 'विचारल्यास तुमची माहिती भरा',
          ),
          instruction: LocalizedText(
            en:
                'If $a asks for your name or email, fill them in. Read anything it '
                'asks you to accept. You can skip anything that is optional.',
            mr:
                '$a ने तुमचे नाव किंवा ईमेल विचारल्यास ते भरा. स्वीकारायला सांगितलेले '
                'सगळे वाचा. जे ऐच्छिक आहे ते तुम्ही वगळू शकता.',
          ),
          simplerInstruction: const LocalizedText(
            en:
                'Type your name if asked. If you are not sure about something, '
                'you can ask Saathi.',
            mr:
                'विचारल्यास तुमचे नाव लिहा. एखाद्या गोष्टीबद्दल खात्री नसल्यास साथीला '
                'विचारा.',
          ),
          screenshot: StepScreenshot(
            asset: shot('profile_details'),
            description: LocalizedText(
              en: '$a asking for name and details',
              mr: 'नाव आणि माहिती विचारणारी $a स्क्रीन',
            ),
          ),
        ),
        WorkflowStep(
          id: 'allow_location',
          title: const LocalizedText(
            en: 'Allow your location',
            mr: 'लोकेशनला परवानगी द्या',
          ),
          instruction: LocalizedText(
            en:
                '$a asks to use your location so it can find your pickup point. '
                'When your phone asks, choose to allow it while using the app.',
            mr:
                'तुमचे पिकअपचे ठिकाण शोधण्यासाठी $a तुमचे लोकेशन वापरण्याची परवानगी '
                'मागेल. फोन विचारेल तेव्हा, ॲप वापरत असताना परवानगी द्या.',
          ),
          simplerInstruction: const LocalizedText(
            en:
                'A box will pop up asking about location. Tap the option that '
                'allows it while using the app.',
            mr:
                'लोकेशनबद्दल विचारणारा एक बॉक्स येईल. ॲप वापरत असताना परवानगी देणाऱ्या '
                'पर्यायावर दाबा.',
          ),
          screenshot: StepScreenshot(
            asset: shot('allow_location'),
            description: const LocalizedText(
              en: 'Android location permission pop-up',
              mr: 'Android लोकेशन परवानगीचा बॉक्स',
            ),
          ),
        ),
      ],
      WorkflowStep(
        id: 'find_locations',
        title: const LocalizedText(
          en: 'Find pickup and destination',
          mr: 'पिकअप आणि पोहोचण्याचे ठिकाण शोधा',
        ),
        instruction: LocalizedText(
          en:
              'On the $a screen, look for your pickup point and the place where '
              'you can enter where you want to go.',
          mr:
              '$a च्या स्क्रीनवर तुमचे पिकअपचे ठिकाण आणि तुम्हाला कुठे जायचे आहे ते '
              'लिहिण्याची जागा शोधा.',
        ),
        simplerInstruction: LocalizedText(
          en:
              'Look at the $a screen slowly. Find the part that asks where you '
              'want to go.',
          mr: '$a ची स्क्रीन सावकाश पाहा. कुठे जायचे आहे असे विचारणारा भाग शोधा.',
        ),
        screenshot: StepScreenshot(
          asset: shot('find_locations'),
          description: LocalizedText(
            en: '$a home screen showing pickup and destination',
            mr: 'पिकअप आणि पोहोचण्याचे ठिकाण दाखवणारी $a ची मुख्य स्क्रीन',
          ),
        ),
      ),
      WorkflowStep(
        id: 'enter_destination',
        title: const LocalizedText(
          en: 'Enter your destination',
          mr: 'पोहोचण्याचे ठिकाण लिहा',
        ),
        instruction: const LocalizedText(
          en:
              'Tap the place for your destination and type where you want to go. '
              'Then choose the right place from the list.',
          mr:
              'पोहोचण्याच्या ठिकाणाच्या जागेवर दाबा आणि तुम्हाला जिथे जायचे आहे ते '
              'लिहा. मग यादीतून योग्य ठिकाण निवडा.',
        ),
        simplerInstruction: const LocalizedText(
          en:
              'Tap the box, type the name of the place, then tap the correct '
              'place in the list that appears.',
          mr:
              'जागेवर दाबा, ठिकाणाचे नाव लिहा, आणि खाली दिसणाऱ्या यादीतील योग्य '
              'ठिकाणावर दाबा.',
        ),
        helpers: const {StepHelper.copyText},
        screenshot: StepScreenshot(
          asset: shot('enter_destination'),
          description: LocalizedText(
            en: '$a destination search with a list of places',
            mr: 'ठिकाणांच्या यादीसह $a मधील ठिकाण शोध',
          ),
        ),
      ),
      WorkflowStep(
        id: 'check_locations',
        title: const LocalizedText(
          en: 'Check both places',
          mr: 'दोन्ही ठिकाणे तपासा',
        ),
        instruction: LocalizedText(
          en:
              'Read the pickup and destination that $a shows. Make sure both are '
              'correct before you go on.',
          mr:
              '$a दाखवत असलेले पिकअप आणि पोहोचण्याचे ठिकाण वाचा. पुढे जाण्याआधी '
              'दोन्ही बरोबर आहेत ना, याची खात्री करा.',
        ),
        simplerInstruction: const LocalizedText(
          en: 'Read both addresses slowly. If one is wrong, tap it to change it.',
          mr: 'दोन्ही पत्ते सावकाश वाचा. एखादा चुकीचा असेल, तर तो बदलण्यासाठी त्यावर दाबा.',
        ),
        screenshot: StepScreenshot(
          asset: shot('check_locations'),
          description: LocalizedText(
            en: '$a showing the chosen pickup and destination',
            mr: 'निवडलेले पिकअप आणि पोहोचण्याचे ठिकाण दाखवणारी $a स्क्रीन',
          ),
        ),
      ),
      WorkflowStep(
        id: 'review_rides',
        title: const LocalizedText(
          en: 'Look at the ride options',
          mr: 'गाड्यांचे पर्याय पाहा',
        ),
        instruction: LocalizedText(
          en:
              '$a shows different kinds of rides. Read the options on your screen '
              'and choose one you are comfortable with.',
          mr:
              '$a वेगवेगळ्या प्रकारच्या गाड्या दाखवते. तुमच्या स्क्रीनवरचे पर्याय वाचा '
              'आणि तुम्हाला योग्य वाटेल तो निवडा.',
        ),
        simplerInstruction: const LocalizedText(
          en: 'Read the name and details of each option. Then tap one.',
          mr: 'प्रत्येक पर्यायाचे नाव आणि माहिती वाचा. मग एकावर दाबा.',
        ),
        screenshot: StepScreenshot(
          asset: shot('review_rides'),
          description: LocalizedText(
            en: 'List of ride types offered by $a',
            mr: '$a ने दाखवलेल्या गाड्यांच्या प्रकारांची यादी',
          ),
        ),
      ),
      WorkflowStep(
        id: 'check_fare',
        title: const LocalizedText(en: 'Check the fare', mr: 'भाडे तपासा'),
        instruction: LocalizedText(
          en:
              'Before booking, read the fare and trip details $a shows for your '
              'ride. Fares can change, so go by what $a shows you now.',
          mr:
              'बुक करण्याआधी, तुमच्या गाडीचे भाडे आणि प्रवासाची माहिती नीट वाचा. भाडे '
              'बदलू शकते, म्हणून $a आत्ता जे दाखवत आहे तेच पाहा.',
        ),
        simplerInstruction: const LocalizedText(
          en:
              'Read the amount shown on the screen. If it does not feel right, '
              'you can stop here.',
          mr: 'स्क्रीनवर दाखवलेली रक्कम वाचा. ती योग्य वाटत नसेल, तर इथेच थांबू शकता.',
        ),
        sensitivity: Sensitivity.money,
        screenshot: StepScreenshot(
          asset: shot('check_fare'),
          description: LocalizedText(
            en: '$a showing the fare for the chosen ride',
            mr: 'निवडलेल्या गाडीचे भाडे दाखवणारी $a स्क्रीन',
          ),
        ),
      ),
      WorkflowStep(
        id: 'decide_booking',
        title: const LocalizedText(
          en: 'Book only if you are happy',
          mr: 'खात्री असेल तरच बुक करा',
        ),
        instruction: LocalizedText(
          en:
              'If everything looks right and you want to go ahead, tap the book '
              'button in $a yourself. If you are not sure, you can stop here. '
              'Nothing is booked until you tap it.',
          mr:
              'सगळे बरोबर असेल आणि तुम्हाला पुढे जायचे असेल, तर $a मधील बुक करण्याचे '
              'बटण स्वतः दाबा. खात्री नसेल तर इथेच थांबा. तुम्ही बटण दाबेपर्यंत '
              'काहीही बुक होत नाही.',
        ),
        simplerInstruction: const LocalizedText(
          en:
              'Only tap book if you want this ride. If you do not, do not tap '
              'anything.',
          mr: 'ही राइड हवी असेल तरच बुक बटण दाबा. नको असेल तर काहीही दाबू नका.',
        ),
        sensitivity: Sensitivity.money,
        screenshot: StepScreenshot(
          asset: shot('decide_booking'),
          description: LocalizedText(
            en: '$a screen with the button to book the ride',
            mr: 'राइड बुक करण्याच्या बटणासह $a स्क्रीन',
          ),
        ),
      ),
      WorkflowStep(
        id: 'confirm_outcome',
        kind: StepKind.outcome,
        title: const LocalizedText(en: 'What happened?', mr: 'काय झाले?'),
        instruction: LocalizedText(
          en:
              'Look at $a. Does it show that your ride is booked? Tell Saathi '
              'what you see.',
          mr:
              '$a कडे पाहा. तुमची राइड बुक झाल्याचे ते दाखवत आहे का? तुम्हाला जे दिसते '
              'ते साथीला सांगा.',
        ),
        simplerInstruction: LocalizedText(
          en: 'Check the $a screen. Does it say your ride is confirmed?',
          mr: '$a ची स्क्रीन पाहा. राइड पक्की झाल्याचे दिसते का?',
        ),
        screenshot: StepScreenshot(
          asset: shot('confirm_outcome'),
          description: LocalizedText(
            en: '$a screen after a ride is booked',
            mr: 'राइड बुक झाल्यानंतरची $a स्क्रीन',
          ),
        ),
      ),
    ],
  );
}
