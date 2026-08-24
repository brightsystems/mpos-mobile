import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Lightweight, code-generation-free localization for the app UI strings.
///
/// Supported languages: English (en), Amharic (am), Tigrinya (ti),
/// Afaan Oromo (om). Access via `AppLocalizations.of(context)`.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<String> supportedLanguageCodes = ['en', 'am', 'ti', 'om'];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ?? const AppLocalizations(Locale('en'));

  String _t(String key) {
    final table = _values[locale.languageCode] ?? _values['en']!;
    return table[key] ?? _values['en']![key] ?? key;
  }

  String get appName => _t('appName');

  // POS shell navigation.
  String get navSell => _t('navSell');
  String get navMenu => _t('navMenu');
  String get navTables => _t('navTables');
  String get navAccount => _t('navAccount');

  // Admin shell navigation.
  String get navHome => _t('navHome');
  String get navOrders => _t('navOrders');
  String get navStaff => _t('navStaff');
  String get navMore => _t('navMore');

  // Settings / account.
  String get language => _t('language');
  String get chooseLanguage => _t('chooseLanguage');
  String get theme => _t('theme');
  String get lightMode => _t('lightMode');
  String get darkMode => _t('darkMode');
  String get signOut => _t('signOut');
  String get endShift => _t('endShift');
  String get mode => _t('mode');
  String get demoMock => _t('demoMock');
  String get dashboard => _t('dashboard');
  String get role => _t('role');
  String get organization => _t('organization');

  // Admin "More" sections.
  String get sectionBusiness => _t('sectionBusiness');
  String get sectionApp => _t('sectionApp');
  String get branches => _t('branches');
  String get companyProfile => _t('companyProfile');
  String get taxes => _t('taxes');
  String get paymentGateways => _t('paymentGateways');
  String get morEInvoice => _t('morEInvoice');
  String get bankSettlement => _t('bankSettlement');

  // Common.
  String get close => _t('close');
  String get notSignedIn => _t('notSignedIn');

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'appName': 'MPOS',
      'navSell': 'Sell',
      'navMenu': 'Menu',
      'navTables': 'Tables',
      'navAccount': 'Account',
      'navHome': 'Home',
      'navOrders': 'Orders',
      'navStaff': 'Staff',
      'navMore': 'More',
      'language': 'Language',
      'chooseLanguage': 'Choose language',
      'theme': 'Theme',
      'lightMode': 'Light mode',
      'darkMode': 'Dark mode',
      'signOut': 'Sign out',
      'endShift': 'End shift',
      'mode': 'Mode',
      'demoMock': 'Demo / Mock',
      'dashboard': 'Dashboard',
      'role': 'Role',
      'organization': 'Organization',
      'sectionBusiness': 'Business',
      'sectionApp': 'App',
      'branches': 'Branches',
      'companyProfile': 'Company profile',
      'taxes': 'Taxes',
      'paymentGateways': 'Payment gateways',
      'morEInvoice': 'MOR e-invoice',
      'bankSettlement': 'Bank & settlement',
      'close': 'Close',
      'notSignedIn': 'Not signed in.',
    },
    'am': {
      'appName': 'MPOS',
      'navSell': 'ሽያጭ',
      'navMenu': 'ምናሌ',
      'navTables': 'ጠረጴዛዎች',
      'navAccount': 'መለያ',
      'navHome': 'መነሻ',
      'navOrders': 'ትዕዛዞች',
      'navStaff': 'ሰራተኞች',
      'navMore': 'ተጨማሪ',
      'language': 'ቋንቋ',
      'chooseLanguage': 'ቋንቋ ይምረጡ',
      'theme': 'ገጽታ',
      'lightMode': 'ብሩህ ገጽታ',
      'darkMode': 'ጨለማ ገጽታ',
      'signOut': 'ውጣ',
      'endShift': 'ፈረቃ አጠናቅ',
      'mode': 'ሁነታ',
      'demoMock': 'ማሳያ / ሙከራ',
      'dashboard': 'ዳሽቦርድ',
      'role': 'ሚና',
      'organization': 'ድርጅት',
      'sectionBusiness': 'ንግድ',
      'sectionApp': 'መተግበሪያ',
      'branches': 'ቅርንጫፎች',
      'companyProfile': 'የኩባንያ መገለጫ',
      'taxes': 'ግብሮች',
      'paymentGateways': 'የክፍያ መንገዶች',
      'morEInvoice': 'MOR ኢ-ደረሰኝ',
      'bankSettlement': 'ባንክ እና ሰፈራ',
      'close': 'ዝጋ',
      'notSignedIn': 'አልገቡም።',
    },
    'ti': {
      'appName': 'MPOS',
      'navSell': 'ሽያጥ',
      'navMenu': 'ሜኑ',
      'navTables': 'ጣውላታት',
      'navAccount': 'ሕሳብ',
      'navHome': 'መነሻ',
      'navOrders': 'ትእዛዛት',
      'navStaff': 'ሰራሕተኛታት',
      'navMore': 'ተወሳኺ',
      'language': 'ቋንቋ',
      'chooseLanguage': 'ቋንቋ ምረጽ',
      'theme': 'ገጽታ',
      'lightMode': 'ብሩህ ገጽታ',
      'darkMode': 'ጸሊም ገጽታ',
      'signOut': 'ውጻእ',
      'endShift': 'ፈረቓ ወድእ',
      'mode': 'ኩነታት',
      'demoMock': 'ማሳያ / ፈተነ',
      'dashboard': 'ዳሽቦርድ',
      'role': 'ተራ',
      'organization': 'ውድብ',
      'sectionBusiness': 'ንግዲ',
      'sectionApp': 'ኣፕሊኬሽን',
      'branches': 'ጨንፈራት',
      'companyProfile': 'መግለጺ ኩባንያ',
      'taxes': 'ግብርታት',
      'paymentGateways': 'መንገድታት ክፍሊት',
      'morEInvoice': 'MOR ኢ-ቅብሊት',
      'bankSettlement': 'ባንክን ኣከፋፍላን',
      'close': 'ዕጸው',
      'notSignedIn': 'ኣይኣተኹምን።',
    },
    'om': {
      'appName': 'MPOS',
      'navSell': 'Gurgurtaa',
      'navMenu': 'Baafata',
      'navTables': 'Minjaala',
      'navAccount': 'Herrega',
      'navHome': 'Mana',
      'navOrders': 'Ajajawwan',
      'navStaff': "Hojjettoota",
      'navMore': 'Dabalata',
      'language': 'Afaan',
      'chooseLanguage': 'Afaan filadhu',
      'theme': 'Bifa',
      'lightMode': 'Bifa ifaa',
      'darkMode': 'Bifa dukkanaa',
      'signOut': "Ba'i",
      'endShift': 'Shiftii xumuri',
      'mode': 'Haala',
      'demoMock': 'Agarsiisa / Yaalii',
      'dashboard': 'Daashboordii',
      'role': "Ga'ee",
      'organization': 'Dhaabbata',
      'sectionBusiness': 'Daldala',
      'sectionApp': 'Aappii',
      'branches': 'Damee',
      'companyProfile': 'Ibsa dhaabbataa',
      'taxes': 'Gibira',
      'paymentGateways': 'Karaa kaffaltii',
      'morEInvoice': 'MOR e-invoice',
      'bankSettlement': 'Baankii fi kaffaltii',
      'close': 'Cufi',
      'notSignedIn': 'Hin seenne.',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLanguageCodes.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
