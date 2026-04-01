import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class LocalizationService {
  static const LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  const LocalizationService._internal();

  static LocalizationService get instance => _instance;
  static const Map<String, Locale> supportedLocales = {
    'English': Locale('en', 'US'),
    'हिन्दी': Locale('hi', 'IN'),
    'বাংলা': Locale('bn', 'BD'),
    'தமிழ்': Locale('ta', 'IN'),
  };

  static Map<String, String> _localizedStrings = {};
  static String _currentLanguage = 'English';

  static String get currentLanguage => _currentLanguage;
  static Locale get currentLocale => supportedLocales[_currentLanguage] ?? const Locale('en', 'US');

  static Future<void> load(String languageName) async {
    _currentLanguage = languageName;
    final locale = supportedLocales[languageName];
    if (locale == null) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/locale/${locale.languageCode}.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      // Fallback to default translations if file doesn't exist
      _localizedStrings = _getDefaultTranslations(locale.languageCode);
    }
  }

  static String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Shorthand method
  static String t(String key) => translate(key);

  static Map<String, String> _getDefaultTranslations(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return {
          'home': 'घर',
          'daily': 'दैनिक',
          'med_bot': 'मेड बॉट',
          'profile': 'प्रोफ़ाइल',
          'settings': 'सेटिंग्स',
          'edit_profile': 'प्रोफ़ाइल संपादित करें',
          'full_name': 'पूरा नाम',
          'email_address': 'ईमेल पता',
          'phone_number': 'फोन नंबर',
          'save': 'सेव करें',
          'cancel': 'रद्द करें',
          'hello_medical_assistant': 'हैलो! मैं आपका मेडिकल असिस्टेंट हूं',
          'ask_health_question': 'स्वास्थ्य, लक्षण या दवाओं के बारे में कुछ भी पूछें।',
          'account_management': 'खाता प्रबंधन',
          'change_password': 'पासवर्ड बदलें',
          'delete_account': 'खाता हटाएं',
          'log_out': 'लॉग आउट',
          'notifications': 'सूचनाएं',
          'appearance': 'दिखावट',
          'language': 'भाषा',
          'dark_mode': 'डार्क मोड',
        };
      case 'bn':
        return {
          'home': 'হোম',
          'daily': 'দৈনিক',
          'med_bot': 'মেড বট',
          'profile': 'প্রোফাইল',
          'settings': 'সেটিংস',
          'edit_profile': 'প্রোফাইল সম্পাদনা',
          'full_name': 'পূর্ণ নাম',
          'email_address': 'ইমেইল ঠিকানা',
          'phone_number': 'ফোন নম্বর',
          'save': 'সেভ করুন',
          'cancel': 'বাতিল',
          'hello_medical_assistant': 'হ্যালো! আমি আপনার মেডিকেল সহায়ক',
          'ask_health_question': 'স্বাস্থ্য, উপসর্গ বা ওষুধ সম্পর্কে যে কোনো কিছু জিজ্ঞাসা করুন।',
          'account_management': 'অ্যাকাউন্ট ব্যবস্থাপনা',
          'change_password': 'পাসওয়ার্ড পরিবর্তন',
          'delete_account': 'অ্যাকাউন্ট মুছুন',
          'log_out': 'লগ আউট',
          'notifications': 'বিজ্ঞপ্তি',
          'appearance': 'চেহারা',
          'language': 'ভাষা',
          'dark_mode': 'ডার্ক মোড',
        };
      case 'ta':
        return {
          'home': 'முகப்பு',
          'daily': 'தினசரி',
          'med_bot': 'மெட் போட்',
          'profile': 'சுயவிவரம்',
          'settings': 'அமைப்புகள்',
          'edit_profile': 'சுயவிவரத்தை திருத்து',
          'full_name': 'முழு பெயர்',
          'email_address': 'மின்னஞ்சல் முகவரி',
          'phone_number': 'தொலைபேசி எண்',
          'save': 'சேமி',
          'cancel': 'ரத்து செய்',
          'hello_medical_assistant': 'வணக்கம்! நான் உங்கள் மருத்துவ உதவியாளர்',
          'ask_health_question': 'உடல்நலம், அறிகுறிகள் அல்லது மருந்துகள் பற்றி எதையும் கேளுங்கள்.',
          'account_management': 'கணக்கு நிர்வாகம்',
          'change_password': 'கடவுச்சொல்லை மாற்று',
          'delete_account': 'கணக்கை நீக்கு',
          'log_out': 'வெளியேறு',
          'notifications': 'அறிவிப்புகள்',
          'appearance': 'தோற்றம்',
          'language': 'மொழி',
          'dark_mode': 'இருண்ட பயன்முறை',
        };
      default:
        return {}; // English is the default
    }
  }
}

// Extension for easy access to translations
extension LocalizedContext on BuildContext {
  String tr(String key) => LocalizationService.translate(key);
}