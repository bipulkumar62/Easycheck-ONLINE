import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// AppLocalizations handles multi-language support with Hindi as default,
/// strictly based on approved screen text from Stitch prototypes.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('hi', 'IN'),
    Locale('hi'),
    Locale('en', 'US'),
    Locale('en'),
  ];

  static const Locale defaultLocale = Locale('hi');

  static final Map<String, Map<String, String>> _localizedValues = {
    'hi': {
      // Common & Brand
      'appName': 'EasyCheck Online',
      'brandTagline': 'आधिकारिक मरीज़ पोर्टल',
      'liveDesksActive': 'लाइव क्लिनिक डेस्क सक्रिय',
      'instantAccess': 'तत्काल पहुंच',
      'privacyPolicy': 'गोपनीयता नीति',
      'termsOfService': 'सेवा की शर्तें',

      // Patient Login
      'patientLoginHeadline': 'आपके डॉक्टर, अब और भी करीब।',
      'patientLoginSubtitle':
          'एक ही शांत और सुरक्षित जगह पर अपने क्लिनिक की उपलब्धता और लाइव पर्ची अपडेट देखें।',
      'continueWithGoogle': 'Google के साथ जारी रखें',
      'opdParchiTracker': 'रियल-टाइम ओपीडी और पर्ची ट्रैकर',

      // Patient Navigation & Home
      'navHome': 'होम',
      'navMyClinics': 'मेरे क्लिनिक',
      'navSettings': 'सेटिंग्स',
      'searchPlaceholder': 'अस्पताल या डॉक्टर खोजें',
      'registeredClinics': 'पंजीकृत क्लिनिक',
      'liveQueue': 'लाइव कतार',
      'liveSync': 'लाइव सिंक',
      'todaysParchi': 'आज की पर्ची',
      'statusAvailable': 'उपलब्ध',
      'statusUnavailable': 'अनुपलब्ध',
      'sessionClosed': 'सत्र समाप्त • ऑफलाइन',

      // Patient Clinic Details
      'clinicDetails': 'क्लिनिक विवरण',
      'currentlyAvailable': 'वर्तमान में उपलब्ध',
      'todaysParchiCount': 'आज की पर्ची गणना',
      'yesterday': 'कल',
      'today': 'आज',
      'slips': 'पर्चियां',
      'planningYourVisit': 'अपनी यात्रा की योजना बनाना',
      'offHoursNotice': 'ऑफ-ऑवर्स और डॉक्टर अवकाश सूचना',

      // Admin Authentication & Console
      'clinicAdminTitle': 'क्लिनिक एडमिन',
      'adminSignInSubtitle': 'अपने क्लिनिक का प्रबंधन करने के लिए साइन इन करें।',
      'staffAccessOnly': 'केवल अधिकृत क्लिनिक कर्मचारियों के लिए।',
      'doctorAvailability': 'डॉक्टर की उपलब्धता',
      'statusDelayed': 'विलंबित',
      'statusOffDuty': 'ऑफ-ड्यूटी',
      'parchiIssued': 'पर्ची जारी की गई',
      'resetCount': 'गिनती 0 पर रीसेट करें',
      'accessNotAuthorized': 'पहुंच अधिकृत नहीं है',
      'switchGoogleAccount': 'Google खाता बदलें',
      'requestClinicAccess': 'क्लिनिक पहुंच का अनुरोध करें',
    },
    'en': {
      // Common & Brand
      'appName': 'EasyCheck Online',
      'brandTagline': 'Official Patient Portal',
      'liveDesksActive': 'Live Clinic Desks Active',
      'instantAccess': 'Instant Access',
      'privacyPolicy': 'Privacy Policy',
      'termsOfService': 'Terms of Service',

      // Patient Login
      'patientLoginHeadline': 'Your doctor, closer than ever.',
      'patientLoginSubtitle':
          'Check your clinic’s availability and live parchi updates in one calm, unified place.',
      'continueWithGoogle': 'Continue with Google',
      'opdParchiTracker': 'Real-time OPD & Parchi Tracker',

      // Patient Navigation & Home
      'navHome': 'Home',
      'navMyClinics': 'My Clinics',
      'navSettings': 'Settings',
      'searchPlaceholder': 'Search hospital or doctor',
      'registeredClinics': 'Registered Clinics',
      'liveQueue': 'Live Queue',
      'liveSync': 'Live Sync',
      'todaysParchi': 'Today’s Parchi',
      'statusAvailable': 'Available',
      'statusUnavailable': 'Unavailable',
      'sessionClosed': 'Session Closed · Offline',

      // Patient Clinic Details
      'clinicDetails': 'Clinic Details',
      'currentlyAvailable': 'Currently Available',
      'todaysParchiCount': 'Today’s Parchi Count',
      'yesterday': 'Yesterday',
      'today': 'Today',
      'slips': 'slips',
      'planningYourVisit': 'Planning Your Visit',
      'offHoursNotice': 'Off-Hours & Doctor Leave Notice',

      // Admin Authentication & Console
      'clinicAdminTitle': 'Clinic Admin',
      'adminSignInSubtitle': 'Sign in to manage your clinic.',
      'staffAccessOnly': 'Authorized clinic staff access only.',
      'doctorAvailability': 'Doctor Availability',
      'statusDelayed': 'Delayed',
      'statusOffDuty': 'Off-Duty',
      'parchiIssued': 'Parchi Issued',
      'resetCount': 'Reset count to 0',
      'accessNotAuthorized': 'Access Not Authorized',
      'switchGoogleAccount': 'Switch Google Account',
      'requestClinicAccess': 'Request Clinic Access',
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ??
        _localizedValues['hi']?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Getters for approved terms
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
