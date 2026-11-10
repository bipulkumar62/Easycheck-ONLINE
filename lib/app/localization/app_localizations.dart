import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// AppLocalizations handles Hindi/English support for the patient and clinic
/// surfaces. English is the fallback for any missing key so a half-translated
/// screen never shows a raw key.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('en'),
    Locale('hi', 'IN'),
    Locale('hi'),
  ];

  static const Locale defaultLocale = Locale('en');

  static final Map<String, Map<String, String>> _localizedValues = {
    'hi': {
      // Common & Brand
      'appName': 'EasyCheck Online',
      'brandTagline': 'आधिकारिक मरीज़ पोर्टल',
      'liveDesksActive': 'लाइव क्लिनिक डेस्क सक्रिय',
      'instantAccess': 'तत्काल पहुंच',
      'privacyPolicy': 'गोपनीयता नीति',
      'termsOfService': 'सेवा की शर्तें',
      'termsOfUse': 'उपयोग की शर्तें',
      'language': 'भाषा',
      'languageHindi': 'हिंदी',
      'languageEnglish': 'English',
      'chooseLanguage': 'भाषा चुनें',
      'back': 'वापस',
      'cancel': 'रद्द करें',
      'save': 'सेव करें',
      'close': 'बंद करें',
      'retry': 'फिर कोशिश करें',
      'edit': 'बदलें',
      'reset': 'रीसेट',
      'signOut': 'साइन आउट',
      'deleteAccount': 'खाता हटाएं',
      'search': 'खोजें',
      'today': 'आज',
      'yesterday': 'कल',
      'live': 'लाइव',
      'offline': 'ऑफलाइन',
      'active': 'सक्रिय',
      'notAvailable': 'उपलब्ध नहीं',

      // Welcome & quotes
      'welcome': 'स्वागत है',
      'welcomeBack': 'फिर से स्वागत है',
      'thoughtForToday': 'आज का विचार',
      'greetingMorning': 'सुप्रभात',
      'greetingAfternoon': 'नमस्कार',
      'greetingEvening': 'शुभ संध्या',
      'quote1': 'स्वास्थ्य ही सबसे बड़ा धन है।',
      'quote2': 'हर नया दिन एक नई उम्मीद लेकर आता है।',
      'quote3': 'अपनी सेहत पर ध्यान देना, खुद से प्यार करना है।',
      'quote4': 'शांत मन, स्वस्थ शरीर।',
      'quote5': 'छोटी-छोटी आदतें बड़ा बदलाव लाती हैं।',
      'quote6': 'मुस्कान सबसे अच्छी दवा है।',

      // Role selection
      'roleHeading': 'आप किस रूप में आगे बढ़ना चाहते हैं?',
      'roleSubtitle': 'EasyCheck का उपयोग करने का तरीका चुनें। साइन आउट करके बाद में बदल सकते हैं।',
      'patientRole': 'मरीज़',
      'patientRoleDescription':
          'क्लिनिक की उपलब्धता, लाइव पर्ची अपडेट और डॉक्टर की कतार देखें।',
      'patientRoleButton': 'मरीज़ के रूप में आगे बढ़ें',
      'staffRole': 'डॉक्टर / स्टाफ',
      'staffRoleDescription': 'अपने क्लिनिक की लाइव कतार और मरीज़ों की आवाजाही संभालें। डैशबोर्ड खुलने से पहले क्लिनिक पहुंच सत्यापित होती है।',
      'staffRoleButton': 'डॉक्टर/स्टाफ के रूप में आगे बढ़ें',
      'secureGoogleSignIn': 'Google खाते से सुरक्षित साइन-इन',
      'careConnected': 'देखभाल, हर पल जुड़ी',
      'officialPatientPortal': 'आधिकारिक मरीज़ पोर्टल',
      'languagePrompt': 'भाषा बदलने के लिए यहां टैप करें',

      // Patient login
      'patientLoginHeadline': 'आपके डॉक्टर, अब और भी करीब।',
      'patientLoginSubtitle': 'एक ही शांत और सुरक्षित जगह पर अपने क्लिनिक की उपलब्धता और लाइव पर्ची अपडेट देखें।',
      'continueWithGoogle': 'Google के साथ जारी रखें',
      'opdParchiTracker': 'रियल-टाइम ओपीडी और पर्ची ट्रैकर',
      'realTimeClinicUpdates': 'रियल-टाइम क्लिनिक अपडेट',
      'securePatientSignIn': 'सुरक्षित मरीज़ साइन-इन',
      'useDifferentAccount': 'दूसरे Google खाते का उपयोग करें',
      'securityBadge': 'सुरक्षित साइन-इन • आपकी जानकारी निजी रहती है',
      'backToRoleSelection': 'भूमिका चयन पर वापस जाएं',

      // Patient navigation & home
      'navHome': 'होम',
      'navMyClinics': 'मेरे क्लिनिक',
      'navSettings': 'सेटिंग्स',
      'searchPlaceholder': 'अस्पताल या डॉक्टर खोजें',
      'registeredClinics': 'पंजीकृत क्लिनिक',
      'liveQueue': 'लाइव कतार',
      'liveSync': 'लाइव सिंक',
      'todaysParchi': 'आज की पर्ची',
      'slips': 'पर्चियां',
      'statusDelayed': 'विलंबित',
      'statusOffDuty': 'ऑफ-ड्यूटी',
      'parchiIssued': 'पर्ची जारी की गई',
      'resetCount': 'गिनती 0 पर रीसेट करें',
      'accessNotAuthorized': 'पहुंच अधिकृत नहीं है',
      'switchGoogleAccount': 'Google खाता बदलें',
      'requestClinicAccess': 'क्लिनिक पहुंच का अनुरोध करें',
      'statusAvailable': 'उपलब्ध',
      'statusUnavailable': 'अनुपलब्ध',
      'sessionClosed': 'सत्र समाप्त • ऑफलाइन',
      'notifications': 'सूचनाएं',
      'noNewNotifications': 'कोई नई सूचना नहीं',
      'allCaughtUp': 'आप पूरी तरह अपडेट हैं',
      'notificationsEmptyBody':
          'क्लिनिक की उपलब्धता और लाइव पर्ची गिनती में बदलाव यहां दिखाई देंगे।',
      'activeCount': '{count} सक्रिय',
      'couldNotLoadClinics': 'क्लिनिक लोड नहीं हो सके',
      'checkConnection': 'अपना इंटरनेट कनेक्शन जांचें और फिर कोशिश करें।',
      'noClinicsMatch': 'आपकी खोज से कोई क्लिनिक नहीं मिला',
      'noClinicsAvailable': 'अभी कोई क्लिनिक उपलब्ध नहीं है',
      'tryDifferentSearch': 'किसी दूसरे अस्पताल, डॉक्टर या इलाके को खोजें।',
      'pullToRefresh':
          'रिफ्रेश करने के लिए नीचे खींचें। नए क्लिनिक यहां अपने आप दिखेंगे।',
      'noSavedClinics': 'अभी कोई सेव किया हुआ क्लिनिक नहीं',
      'noSavedClinicsBody': 'किसी क्लिनिक को खोलें और बुकमार्क पर टैप करें, ताकि उसकी लाइव कतार एक टैप में मिले।',
      'browseClinics': 'क्लिनिक देखें',
      'patientAccount': 'मरीज़ खाता',
      'notSignedIn': 'साइन इन नहीं है',
      'aboutEasyCheck': 'EasyCheck के बारे में',
      'aboutEasyCheckSubtitle': 'विशेषताएं, सुरक्षा और संस्करण',
      'deleteAccountSubtitle': 'अपनी मरीज़ प्रोफ़ाइल हमेशा के लिए हटाएं',
      'deletingAccount': 'खाता हटाया जा रहा है…',
      'deleteAccountQuestion': 'अपना खाता हटाएं?',
      'deleteAccountBody': 'इससे आपकी EasyCheck मरीज़ प्रोफ़ाइल और इस ऐप के लिए Google साइन-इन लिंक हमेशा के लिए हट जाएगा। कानून या क्लिनिक सुरक्षा के लिए आवश्यक लाइव कतार और ऑडिट रिकॉर्ड सुरक्षित रह सकते हैं। यह क्रिया वापस नहीं की जा सकती।',
      'deleteAccountConfirm': 'खाता हटाएं',
      'languageSection': 'ऐप की भाषा',
      'languageDescription': 'हिंदी और English के बीच एक टैप में बदलें।',

      // Notifications
      'justNow': 'अभी',
      'minutesAgo': '{count} मिनट पहले',
      'hoursAgo': '{count} घंटे पहले',
      'yesterdayLabel': 'कल',
      'daysAgo': '{count} दिन पहले',
      'newClinicAvailable': 'नया क्लिनिक उपलब्ध',
      'newClinicMessage': '{clinic} अब EasyCheck पर उपलब्ध है।',
      'clinicAvailableAgain': 'क्लिनिक फिर उपलब्ध',
      'clinicAvailableAgainMessage': '{clinic} फिर मरीज़ों को देख रहा है।',
      'clinicTemporarilyUnavailable': 'क्लिनिक अस्थायी रूप से उपलब्ध नहीं',
      'clinicUnavailableMessage': '{clinic} अभी ऑफलाइन है।',
      'clinicIsLive': 'क्लिनिक लाइव है',
      'clinicWentOffline': 'क्लिनिक ऑफलाइन हो गया',
      'clinicLiveMessage': '{clinic} अब मरीज़ों को देख रहा है।',
      'clinicOfflineMessage': '{clinic} अभी मरीज़ों को नहीं देख रहा है।',
      'doctorRunningLate': 'डॉक्टर देर से आ रहे हैं',
      'doctorLateMessage': '{clinic} ने देरी की सूचना दी है।',
      'doctorOffDuty': 'डॉक्टर ऑफ-ड्यूटी',
      'doctorOffDutyMessage': '{clinic} अभी मरीज़ों को नहीं देख रहा है।',
      'doctorAvailable': 'डॉक्टर उपलब्ध',
      'doctorAvailableMessage': '{clinic} मरीज़ों को देखने के लिए तैयार है।',
      'parchiIssuedTitle': 'पर्ची #{number} जारी',
      'parchiIssuedMessage': '{clinic} · आज की लाइव गिनती अब {number} है।',
      'unreadNotifications': '{count} नई सूचनाएं',

      // Clinic details
      'clinicDetails': 'क्लिनिक विवरण',
      'goBack': 'वापस जाएं',
      'clinicOfflineSubscription': 'क्लिनिक ऑफलाइन · सदस्यता निष्क्रिय',
      'doctorProfile': 'डॉक्टर प्रोफ़ाइल',
      'currentlyAvailable': 'वर्तमान में उपलब्ध',
      'addressNotListed': 'पता दर्ज नहीं है',
      'paused': 'रुका हुआ',
      'liveClinicCounter': 'लाइव क्लिनिक काउंटर',
      'waitingForLiveCounter': 'क्लिनिक के लाइव काउंटर का इंतजार है',
      'liveUpdated': 'लाइव · {time} पर अपडेट',
      'previousDayParchi': 'पिछले दिन की पर्ची गिनती',
      'currentDayLive': 'आज की लाइव गिनती',
      'planningYourVisit': 'अपनी यात्रा की योजना बनाना',
      'planningBody': 'अपनी यात्रा से पहले थोड़ी और जानकारी। क्लिनिक के ताज़ा अपडेट देखें और अपने समय की योजना आत्मविश्वास से बनाएं।',
      'offHoursNotice': 'ऑफ-अवर्स और डॉक्टर अवकाश सूचना',
      'standardProtocol': 'मानक प्रोटोकॉल',
      'offHoursBody': 'जब क्लिनिक सत्र बंद हो या डॉक्टर उपलब्ध न हों, तो अस्पष्ट स्थिति की जगह एक स्पष्ट सूचना दिखाई जाती है।',
      'sessionClosedOffline': 'सत्र समाप्त · ऑफलाइन',

      // Admin authentication
      'clinicAdminTitle': 'क्लिनिक एडमिन',
      'adminSignInSubtitle':
          'अपने क्लिनिक का प्रबंधन करने के लिए साइन इन करें।',
      'staffAccessOnly': 'केवल अधिकृत क्लिनिक कर्मचारियों के लिए।',
      'runClinicWithPrecision': 'अपने क्लिनिक को\nशांत सटीकता से चलाएं।',
      'runClinicSubtitle': 'लाइव कतार नियंत्रण, मरीज़ों की आवाजाही और सत्यापित स्टाफ पहुंच — एक ही परिचालन दृश्य में।',
      'liveQueueControl': 'लाइव कतार नियंत्रण',
      'liveQueueControlBody':
          'पर्ची गिनती और क्लिनिक स्थिति को तुरंत अपडेट करें।',
      'patientFlowVisibility': 'मरीज़ों की आवाजाही',
      'patientFlowVisibilityBody':
          'फ्रंट डेस्क और डॉक्टर के कक्ष को एक साथ रखें।',
      'roleVerifiedAccess': 'भूमिका-सत्यापित पहुंच',
      'roleVerifiedAccessBody':
          'केवल स्वीकृत क्लिनिक सदस्य ही कंसोल खोल सकते हैं।',
      'secureStaffAccess': 'सुरक्षित स्टाफ पहुंच',
      'adminSecurityBadge': 'सुरक्षित साइन-इन • केवल अधिकृत स्टाफ',

      // Admin dashboard
      'easycheckAdmin': 'EASYCHECK एडमिन',
      'liveQueueTab': 'लाइव कतार',
      'intakeTab': 'इनटेक',
      'staffTab': 'स्टाफ',
      'clinicTab': 'क्लिनिक',
      'todaysParchiCount': 'आज की पर्ची गिनती',
      'resetCountToZero': 'गिनती 0 पर रीसेट करें',
      'yesterdayParchi': 'कल की पर्ची',
      'doctorAvailability': 'डॉक्टर की उपलब्धता',
      'doctorProfileTitle': 'डॉक्टर प्रोफ़ाइल',
      'clinicPhotoTitle': 'क्लिनिक कवर फोटो',
      'doctorPhotoTitle': 'डॉक्टर फोटो',
      'changePhoto': 'फोटो बदलें',
      'couldNotOpenDashboard': 'डैशबोर्ड नहीं खुल सका',
      'thisQueueNotActive': 'यह कतार सत्र सक्रिय नहीं है।',
      'couldNotUpdateCounter':
          'काउंटर अपडेट नहीं हो सका। कनेक्शन जांचें और फिर कोशिश करें।',
      'parchiReset': 'पर्ची गिनती 0 पर रीसेट हो गई।',
      'couldNotResetCounter': 'काउंटर रीसेट नहीं हो सका। फिर कोशिश करें।',
      'yesterdayUpdated': 'कल की पर्ची गिनती अपडेट हो गई।',
      'couldNotUpdateYesterday':
          'कल की गिनती अपडेट नहीं हो सकी। फिर कोशिश करें।',
      'editYesterdayCount': 'कल की गिनती बदलें',
      'cropClinicPhoto': 'क्लिनिक कवर फोटो क्रॉप करें',
      'cropDoctorPhoto': 'डॉक्टर फोटो क्रॉप करें',
      'cropHint': 'स्लाइडर से फोटो का साइज़ और स्थिति चुनें।',
      'cropSize': 'फोटो का आकार (छोटा ↔ बड़ा)',
      'cropHorizontal': 'बाएं ↔ दाएं',
      'cropVertical': 'ऊपर ↔ नीचे',
      'cropReset': 'रीसेट करें',
      'cropUsePhoto': 'यह फोटो इस्तेमाल करें',
      'cropDecodeFailed': 'यह फोटो खोल नहीं सके। कोई दूसरी फोटो चुनें।',
      'cropExportFailed': 'फोटो तैयार नहीं हो सकी। फिर कोशिश करें।',

      // Shared UI labels
      'openProfileSettings': 'प्रोफ़ाइल सेटिंग्स खोलें',
      'clearSearch': 'खोज साफ़ करें',
      'subscriptionInactive': 'सदस्यता निष्क्रिय',
      'closedForSession': 'सत्र के लिए बंद',
      'todaysParchiCountLabel': 'आज की पर्ची: {count}',
      'clinicDisabledBody':
          '{clinic} को नेटवर्क प्रशासक द्वारा निष्क्रिय किया गया है। लाइव कतार रुकी हुई है, कृपया बाद में देखें।',
      'doctorTiming': 'डॉक्टर का समय',
      'setDoctorTiming': 'डॉक्टर का समय सेट करें',
      'doctorNotAssigned': 'डॉक्टर असाइन नहीं है',
      'todaysParchiChip': 'आज · {count} पर्ची',
      'doctorConsole': 'डॉक्टर कंसोल',
      'liveQueueStatus': 'लाइव कतार',
      'queuePausedStatus': 'कतार रुकी हुई',
      'editDoctorProfile': 'डॉक्टर प्रोफ़ाइल बदलें',
      'addClinicHours': 'मरीज़ों को दिखने वाला क्लिनिक समय जोड़ें',
      'updateSpecialty':
          'डॉक्टर की विशेषज्ञता दिखाने के लिए क्लिनिक प्रोफ़ाइल अपडेट करें।',
      'uploading': 'अपलोड हो रहा है…',
      'changeClinicPhoto': 'क्लिनिक फोटो बदलें',
      'clinicCoverPhoto': 'क्लिनिक कवर फोटो',
      'clinicCoverBody':
          'यह चौड़ी फोटो मरीज़ के होम कार्ड पर क्लिनिक के नाम के ऊपर दिखती है। क्लिनिक प्रवेश, रिसेप्शन या परामर्श कक्ष की साफ़ फोटो चुनें।',
      'doctorPhoto': 'डॉक्टर फोटो',
      'doctorPhotoBody':
          'यह फोटो क्लिनिक विवरण स्क्रीन पर डॉक्टर प्रोफ़ाइल में दिखती है। साफ़ पोर्ट्रेट फोटो चुनें।',
      'secureStaffSignIn': 'सुरक्षित स्टाफ साइन-इन',
      'useClinicGoogleAccount': 'अपने क्लिनिक के Google खाते का उपयोग करें',
      'verifiedClinicStaffSignIn': 'सत्यापित क्लिनिक स्टाफ साइन-इन',
      'verifiedAccess': 'सत्यापित पहुंच',
      'clinicMembershipChecked': 'साइन-इन के बाद क्लिनिक सदस्यता जांची जाती है।',
      'neverStoresPassword':
          'EasyCheck आपका Google पासवर्ड कभी संग्रहीत नहीं करता।',
      'newStaffRequestAccess':
          'नए स्टाफ अगली स्क्रीन से पहुंच का अनुरोध कर सकते हैं।',
      'authorizedStaffOnly': 'केवल अधिकृत क्लिनिक स्टाफ',
      'welcomeGuest': 'स्वागत है',
    },
    'en': {
      // Common & Brand
      'appName': 'EasyCheck Online',
      'brandTagline': 'Official Patient Portal',
      'liveDesksActive': 'Live Clinic Desks Active',
      'instantAccess': 'Instant Access',
      'privacyPolicy': 'Privacy Policy',
      'termsOfService': 'Terms of Service',
      'termsOfUse': 'Terms of Use',
      'language': 'Language',
      'languageHindi': 'हिंदी',
      'languageEnglish': 'English',
      'chooseLanguage': 'Choose language',
      'back': 'Back',
      'cancel': 'Cancel',
      'save': 'Save',
      'close': 'Close',
      'retry': 'Retry',
      'edit': 'Edit',
      'reset': 'Reset',
      'signOut': 'Sign out',
      'deleteAccount': 'Delete account',
      'search': 'Search',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'live': 'Live',
      'offline': 'Offline',
      'active': 'Active',
      'notAvailable': 'Not Available',

      // Welcome & quotes
      'welcome': 'Welcome',
      'welcomeBack': 'Welcome back',
      'thoughtForToday': 'Thought for today',
      'greetingMorning': 'Good morning',
      'greetingAfternoon': 'Good afternoon',
      'greetingEvening': 'Good evening',
      'quote1': 'Health is the greatest wealth.',
      'quote2': 'Every new day brings a new hope.',
      'quote3': 'Caring for your health is caring for yourself.',
      'quote4': 'A calm mind, a healthy body.',
      'quote5': 'Small habits create big changes.',
      'quote6': 'A smile is the best medicine.',

      // Role selection
      'roleHeading': 'How would you like to continue?',
      'roleSubtitle': 'Choose how you want to use EasyCheck. You can switch later by signing out.',
      'patientRole': 'Patient',
      'patientRoleDescription': 'Check clinic availability, live parchi updates and your doctor’s queue.',
      'patientRoleButton': 'Continue as Patient',
      'staffRole': 'Doctor / Staff',
      'staffRoleDescription': 'Manage your clinic’s live queue and patient flow. Clinic access is verified before the dashboard opens.',
      'staffRoleButton': 'Continue as Doctor/Staff',
      'secureGoogleSignIn': 'Secure sign-in with your Google account',
      'careConnected': 'CARE, CONNECTED',
      'officialPatientPortal': 'OFFICIAL PATIENT PORTAL',
      'languagePrompt': 'Tap here to change language',

      // Patient login
      'patientLoginHeadline': 'Your doctor, closer than ever.',
      'patientLoginSubtitle': 'Check your clinic’s availability and live parchi updates in one calm, unified place.',
      'continueWithGoogle': 'Continue with Google',
      'opdParchiTracker': 'Real-time OPD & Parchi Tracker',
      'realTimeClinicUpdates': 'REAL-TIME CLINIC UPDATES',
      'securePatientSignIn': 'Secure patient sign-in',
      'useDifferentAccount': 'Use a different Google account',
      'securityBadge': 'Secure sign-in • Your data stays private',
      'backToRoleSelection': 'Back to role selection',

      // Patient navigation & home
      'navHome': 'Home',
      'navMyClinics': 'My Clinics',
      'navSettings': 'Settings',
      'searchPlaceholder': 'Search hospital or doctor',
      'registeredClinics': 'Registered Clinics',
      'liveQueue': 'Live Queue',
      'liveSync': 'Live Sync',
      'todaysParchi': 'Today’s Parchi',
      'slips': 'slips',
      'statusDelayed': 'Delayed',
      'statusOffDuty': 'Off-Duty',
      'parchiIssued': 'Parchi Issued',
      'resetCount': 'Reset count to 0',
      'accessNotAuthorized': 'Access Not Authorized',
      'switchGoogleAccount': 'Switch Google Account',
      'requestClinicAccess': 'Request Clinic Access',
      'statusAvailable': 'Available',
      'statusUnavailable': 'Unavailable',
      'sessionClosed': 'Session Closed · Offline',
      'notifications': 'Notifications',
      'noNewNotifications': 'No new notifications',
      'allCaughtUp': 'You’re all caught up',
      'notificationsEmptyBody': 'Live parchi counts and clinic availability updates will appear here as they happen.',
      'activeCount': '{count} Active',
      'couldNotLoadClinics': 'Could not load clinics',
      'checkConnection': 'Check your connection and try again.',
      'noClinicsMatch': 'No clinics match your search',
      'noClinicsAvailable': 'No clinics available',
      'tryDifferentSearch': 'Try a different hospital, doctor, or area.',
      'pullToRefresh':
          'Pull down to refresh. New clinics appear here automatically.',
      'noSavedClinics': 'No saved clinics yet',
      'noSavedClinicsBody': 'Open a clinic and tap the bookmark to keep it here for one-tap access to its live queue.',
      'browseClinics': 'Browse clinics',
      'patientAccount': 'Patient account',
      'notSignedIn': 'Not signed in',
      'aboutEasyCheck': 'About EasyCheck',
      'aboutEasyCheckSubtitle': 'Features, safety and version',
      'deleteAccountSubtitle': 'Permanently remove your patient profile',
      'deletingAccount': 'Deleting account…',
      'deleteAccountQuestion': 'Delete your account?',
      'deleteAccountBody': 'This permanently deletes your EasyCheck patient profile and the Google sign-in link for this app. Live queue and clinic audit records may be retained where the law or clinic safety requires it. This action cannot be undone.',
      'deleteAccountConfirm': 'Delete account',
      'languageSection': 'App language',
      'languageDescription': 'Switch between Hindi and English in one tap.',

      // Notifications
      'justNow': 'Just now',
      'minutesAgo': '{count}m ago',
      'hoursAgo': '{count}h ago',
      'yesterdayLabel': 'Yesterday',
      'daysAgo': '{count}d ago',
      'newClinicAvailable': 'New clinic available',
      'newClinicMessage': '{clinic} is now listed on EasyCheck.',
      'clinicAvailableAgain': 'Clinic available again',
      'clinicAvailableAgainMessage': '{clinic} is accepting patients again.',
      'clinicTemporarilyUnavailable': 'Clinic temporarily unavailable',
      'clinicUnavailableMessage': '{clinic} is offline for now.',
      'clinicIsLive': 'Clinic is live',
      'clinicWentOffline': 'Clinic went offline',
      'clinicLiveMessage': '{clinic} is now accepting patients.',
      'clinicOfflineMessage': '{clinic} is not accepting patients right now.',
      'doctorRunningLate': 'Doctor running late',
      'doctorLateMessage': '{clinic} is reporting a delay.',
      'doctorOffDuty': 'Doctor off duty',
      'doctorOffDutyMessage': '{clinic} is not seeing patients right now.',
      'doctorAvailable': 'Doctor available',
      'doctorAvailableMessage': '{clinic} is ready to see patients.',
      'parchiIssuedTitle': 'Parchi #{number} issued',
      'parchiIssuedMessage': '{clinic} · today’s live count is now {number}.',
      'unreadNotifications': '{count} new',

      // Clinic details
      'clinicDetails': 'Clinic Details',
      'goBack': 'Go back',
      'clinicOfflineSubscription': 'Clinic offline · Subscription inactive',
      'doctorProfile': 'DOCTOR PROFILE',
      'currentlyAvailable': 'Currently Available',
      'addressNotListed': 'Address not listed',
      'paused': 'Paused',
      'liveClinicCounter': 'Live clinic counter',
      'waitingForLiveCounter': 'Waiting for the clinic’s live counter',
      'liveUpdated': 'Live · updated {time}',
      'previousDayParchi': 'Previous day’s parchi count',
      'currentDayLive': 'Current day’s live count',
      'planningYourVisit': 'Planning Your Visit',
      'planningBody': 'A little more clarity before your visit. Check the latest clinic updates and plan your time with greater confidence.',
      'offHoursNotice': 'Off-Hours & Doctor Leave Notice',
      'standardProtocol': 'Standard Protocol',
      'offHoursBody': 'When clinic session is closed or doctor is unavailable, a calm notice replaces the active count rather than an ambiguous status.',
      'sessionClosedOffline': 'Session Closed · Offline',

      // Admin authentication
      'clinicAdminTitle': 'Clinic Admin',
      'adminSignInSubtitle': 'Sign in to manage your clinic.',
      'staffAccessOnly': 'Authorized clinic staff access only.',
      'runClinicWithPrecision': 'Run your clinic with\ncalm precision.',
      'runClinicSubtitle': 'Live queue control, patient flow and verified staff access in one operational view.',
      'liveQueueControl': 'Live queue control',
      'liveQueueControlBody':
          'Update parchi counts and clinic status in real time.',
      'patientFlowVisibility': 'Patient flow visibility',
      'patientFlowVisibilityBody':
          'Keep the front desk and consulting room aligned.',
      'roleVerifiedAccess': 'Role-verified access',
      'roleVerifiedAccessBody':
          'Only approved clinic members can open the console.',
      'secureStaffAccess': 'SECURE STAFF ACCESS',
      'adminSecurityBadge': 'Secure sign-in • Authorized staff only',

      // Admin dashboard
      'easycheckAdmin': 'EASYCHECK ADMIN',
      'liveQueueTab': 'Live Queue',
      'intakeTab': 'Intake',
      'staffTab': 'Staff',
      'clinicTab': 'Clinic',
      'todaysParchiCount': "Today's Parchi Count",
      'resetCountToZero': 'Reset count to 0',
      'yesterdayParchi': 'YESTERDAY’S PARCHI',
      'doctorAvailability': 'Doctor Availability',
      'doctorProfileTitle': 'Doctor Profile',
      'clinicPhotoTitle': 'Clinic cover photo',
      'doctorPhotoTitle': 'Doctor photo',
      'changePhoto': 'Change photo',
      'couldNotOpenDashboard': 'Could not open the dashboard',
      'thisQueueNotActive': 'This queue session is not active.',
      'couldNotUpdateCounter':
          'Could not update the counter. Check your connection and try again.',
      'parchiReset': 'Parchi tally reset to 0.',
      'couldNotResetCounter': 'Could not reset the counter. Please try again.',
      'yesterdayUpdated': 'Yesterday’s parchi count updated.',
      'couldNotUpdateYesterday':
          'Could not update yesterday’s count. Please try again.',
      'editYesterdayCount': 'Edit yesterday’s count',
      'cropClinicPhoto': 'Crop clinic cover photo',
      'cropDoctorPhoto': 'Crop doctor photo',
      'cropHint': 'Use the sliders to choose the size and position.',
      'cropSize': 'Photo size (small ↔ large)',
      'cropHorizontal': 'Left ↔ right',
      'cropVertical': 'Up ↔ down',
      'cropReset': 'Reset',
      'cropUsePhoto': 'Use this photo',
      'cropDecodeFailed': 'Could not open this photo. Choose another one.',
      'cropExportFailed': 'Could not prepare the photo. Please try again.',

      // Shared UI labels
      'openProfileSettings': 'Open profile settings',
      'clearSearch': 'Clear search',
      'subscriptionInactive': 'Subscription inactive',
      'closedForSession': 'Closed for session',
      'todaysParchiCountLabel': "Today's Parchi: {count}",
      'clinicDisabledBody':
          '{clinic} is disabled by the network administrator. The live queue is paused, so please check back later.',
      'doctorTiming': 'DOCTOR TIMING',
      'setDoctorTiming': 'Set doctor timing',
      'doctorNotAssigned': 'Doctor not assigned',
      'todaysParchiChip': 'Today · {count} parchi',
      'doctorConsole': 'DOCTOR CONSOLE',
      'liveQueueStatus': 'LIVE QUEUE',
      'queuePausedStatus': 'QUEUE PAUSED',
      'editDoctorProfile': 'Edit doctor profile',
      'addClinicHours': 'Add clinic hours shown to patients',
      'updateSpecialty':
          'Update your clinic profile to show the doctor’s specialty.',
      'uploading': 'Uploading…',
      'changeClinicPhoto': 'Change clinic photo',
      'clinicCoverPhoto': 'Clinic cover photo',
      'clinicCoverBody':
          'This wide image appears on the patient home card above the clinic name. Use a clear photo of the clinic entrance, reception or consultation room.',
      'doctorPhoto': 'Doctor photo',
      'doctorPhotoBody':
          'This photo appears in the doctor profile on the clinic details screen. Choose a clear portrait.',
      'secureStaffSignIn': 'Secure staff sign-in',
      'useClinicGoogleAccount': 'Use your clinic Google account',
      'verifiedClinicStaffSignIn': 'Verified clinic staff sign-in',
      'verifiedAccess': 'VERIFIED ACCESS',
      'clinicMembershipChecked':
          'Clinic membership is checked after sign-in.',
      'neverStoresPassword':
          'EasyCheck never stores your Google password.',
      'newStaffRequestAccess':
          'New staff can request access from the next screen.',
      'authorizedStaffOnly': 'Authorized clinic staff only',
      'welcomeGuest': 'Welcome',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ??
        _localizedValues['en']?[key] ??
        _localizedValues['hi']?[key] ??
        key;
  }

  String t(String key) => translate(key);

  String _format(String key, Map<String, String> values) {
    var value = translate(key);
    for (final entry in values.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  String get languageCode => locale.languageCode;
  bool get isHindi => locale.languageCode == 'hi';

  String get appName => translate('appName');
  String get brandTagline => translate('brandTagline');
  String get liveDesksActive => translate('liveDesksActive');
  String get instantAccess => translate('instantAccess');
  String get privacyPolicy => translate('privacyPolicy');
  String get termsOfService => translate('termsOfService');

  String get patientLoginHeadline => translate('patientLoginHeadline');
  String get patientLoginSubtitle => translate('patientLoginSubtitle');
  String get continueWithGoogle => translate('continueWithGoogle');
  String get opdParchiTracker => translate('opdParchiTracker');

  String get navHome => translate('navHome');
  String get navMyClinics => translate('navMyClinics');
  String get navSettings => translate('navSettings');
  String get searchPlaceholder => translate('searchPlaceholder');
  String get registeredClinics => translate('registeredClinics');
  String get liveQueue => translate('liveQueue');
  String get liveSync => translate('liveSync');
  String get todaysParchi => translate('todaysParchi');
  String get statusAvailable => translate('statusAvailable');
  String get statusUnavailable => translate('statusUnavailable');
  String get sessionClosed => translate('sessionClosed');

  String get clinicDetails => translate('clinicDetails');
  String get currentlyAvailable => translate('currentlyAvailable');
  String get todaysParchiCount => translate('todaysParchiCount');
  String get yesterday => translate('yesterday');
  String get today => translate('today');
  String get slips => translate('slips');
  String get planningYourVisit => translate('planningYourVisit');
  String get offHoursNotice => translate('offHoursNotice');

  String get clinicAdminTitle => translate('clinicAdminTitle');
  String get adminSignInSubtitle => translate('adminSignInSubtitle');
  String get staffAccessOnly => translate('staffAccessOnly');
  String get doctorAvailability => translate('doctorAvailability');
  String get statusDelayed => translate('statusDelayed');
  String get statusOffDuty => translate('statusOffDuty');
  String get parchiIssued => translate('parchiIssued');
  String get resetCount => translate('resetCount');
  String get accessNotAuthorized => translate('accessNotAuthorized');
  String get switchGoogleAccount => translate('switchGoogleAccount');
  String get requestClinicAccess => translate('requestClinicAccess');

  String greetingForHour(int hour) {
    if (hour < 12) return translate('greetingMorning');
    if (hour < 17) return translate('greetingAfternoon');
    return translate('greetingEvening');
  }

  String welcomeNamed(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return translate('welcomeBack');
    return '${translate('welcomeBack')}, $trimmed';
  }

  String activeCount(int count) => _format('activeCount', {'count': '$count'});
  String unreadNotifications(int count) =>
      _format('unreadNotifications', {'count': '$count'});
  String minutesAgo(int count) => _format('minutesAgo', {'count': '$count'});
  String hoursAgo(int count) => _format('hoursAgo', {'count': '$count'});
  String daysAgo(int count) => _format('daysAgo', {'count': '$count'});
  String newClinicMessage(String clinic) =>
      _format('newClinicMessage', {'clinic': clinic});
  String clinicAvailableAgainMessage(String clinic) =>
      _format('clinicAvailableAgainMessage', {'clinic': clinic});
  String clinicUnavailableMessage(String clinic) =>
      _format('clinicUnavailableMessage', {'clinic': clinic});
  String clinicLiveMessage(String clinic) =>
      _format('clinicLiveMessage', {'clinic': clinic});
  String clinicOfflineMessage(String clinic) =>
      _format('clinicOfflineMessage', {'clinic': clinic});
  String doctorLateMessage(String clinic) =>
      _format('doctorLateMessage', {'clinic': clinic});
  String doctorOffDutyMessage(String clinic) =>
      _format('doctorOffDutyMessage', {'clinic': clinic});
  String doctorAvailableMessage(String clinic) =>
      _format('doctorAvailableMessage', {'clinic': clinic});
  String parchiIssuedTitle(int number) =>
      _format('parchiIssuedTitle', {'number': '$number'});
  String parchiIssuedMessage(String clinic, int number) =>
      _format('parchiIssuedMessage', {'clinic': clinic, 'number': '$number'});
  String liveUpdated(String time) => _format('liveUpdated', {'time': time});

  String quoteOfDay(int dayIndex) {
    final index = dayIndex % 6 + 1;
    return translate('quote$index');
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['hi', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
