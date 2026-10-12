import 'app_strings_auto.dart';
import 'language_controller.dart';

/// Translate a key into the language the user picked.
///
///   Text(tr('skip'))
///   Text(tr('login_welcome', {'name': user.fullName}))   // "... {name} ..."
///
/// Falls back to English, then to the key itself, so a missing translation
/// never crashes the app.
///
/// HOW TO ADD A NEW TEXT (every teammate can do this for their own screens):
///   1. Add a line below:  'my_key': ['English', 'සිංහල', 'தமிழ்'],
///   2. In the screen use  Text(tr('my_key'))   (remove `const` in front of it).
String tr(String key, [Map<String, String>? params]) {
  final lang = LanguageController.instance.lang;
  final row = _strings[key];
  var text = key;
  if (row != null) {
    final i = lang.index;
    text = (i < row.length && row[i].isNotEmpty) ? row[i] : row[0];
  } else if (lang != AppLang.en) {
    text = _auto(key);
  }
  if (params != null) {
    params.forEach((k, v) => text = text.replaceAll('{$k}', _auto(v)));
  }
  return text;
}

/// Looks the English text up in the auto-generated dictionary.
String _auto(String text) {
  final lang = LanguageController.instance.lang;
  if (lang == AppLang.en) return text;
  final a = autoStrings[text];
  if (a == null) return text;
  final v = a[lang.index - 1];
  return v.isEmpty ? text : v;
}

// Order in every list: [English, සිංහල (Sinhala), தமிழ் (Tamil)]
const Map<String, List<String>> _strings = {
  // ── Common ────────────────────────────────────────────────────────────────
  'language': ['Language', 'භාෂාව', 'மொழி'],
  'continue': ['Continue', 'ඉදිරියට', 'தொடரவும்'],
  'skip': ['Skip', 'මඟ හරින්න', 'தவிர்'],
  'next': ['Next', 'ඊළඟ', 'அடுத்து'],
  'get_started': ['Get Started', 'ආරම්භ කරන්න', 'தொடங்குங்கள்'],
  'cancel': ['Cancel', 'අවලංගු කරන්න', 'ரத்து செய்'],
  'ok': ['OK', 'හරි', 'சரி'],
  'show_original': ['Show original', 'මුල් පාඨය පෙන්වන්න', 'மூலத்தைக் காட்டு'],
  'show_translation': [
    'Show translation',
    'පරිවර්තනය පෙන්වන්න',
    'மொழிபெயர்ப்பைக் காட்டு'
  ],
  'translated_auto': [
    'Auto-translated',
    'ස්වයංක්‍රීයව පරිවර්තනය කළා',
    'தானாக மொழிபெயர்க்கப்பட்டது'
  ],

  // ── Language picker ───────────────────────────────────────────────────────
  'pick_title': [
    'Choose your language',
    'ඔබගේ භාෂාව තෝරන්න',
    'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்'
  ],
  'pick_sub': [
    'You can change this any time from the language button.',
    'භාෂා බොත්තමෙන් ඕනෑම වේලාවක මෙය වෙනස් කළ හැක.',
    'மொழி பொத்தானிலிருந்து எப்போது வேண்டுமானாலும் இதை மாற்றலாம்.'
  ],

  // ── Onboarding ────────────────────────────────────────────────────────────
  'ob1_tag': ['RADAR SURVEILLANCE', 'රේඩාර් නිරීක්ෂණය', 'ரேடார் கண்காணிப்பு'],
  'ob1_title': [
    'Early Warning & Flood Alerts',
    'ඉදිරි අනතුරු ඇඟවීම් සහ ගංවතුර නිවේදන',
    'முன்னெச்சரிக்கை & வெள்ள எச்சரிக்கைகள்'
  ],
  'ob1_desc': [
    'Receive instant satellite alerts and predictive water level forecasts before floodwaters reach your residential sector.',
    'ගංවතුර ඔබේ ප්‍රදේශයට පැමිණීමට පෙර ක්ෂණික චන්ද්‍රිකා අනතුරු ඇඟවීම් සහ ජල මට්ටම් පුරෝකථන ලබා ගන්න.',
    'வெள்ளநீர் உங்கள் குடியிருப்புப் பகுதியை அடைவதற்கு முன் உடனடி செயற்கைக்கோள் எச்சரிக்கைகளையும் நீர்மட்ட முன்னறிவிப்புகளையும் பெறுங்கள்.'
  ],
  'ob1_tl': [
    'RADAR LIVE • SECTOR 04',
    'රේඩාර් සජීවී • කලාපය 04',
    'ரேடார் நேரலை • பிரிவு 04'
  ],
  'ob1_tr': [
    'HIGH RISK ALERT',
    'ඉහළ අවදානම් අනතුරු ඇඟවීම',
    'அதிக ஆபத்து எச்சரிக்கை'
  ],
  'ob1_tele': [
    'SATELLITE SURGE: 65mm/hr • RIVER MONITOR ACTIVE',
    'චන්ද්‍රිකා දත්ත: පැයට මි.මී. 65 • ගංගා නිරීක්ෂණය සක්‍රියයි',
    'செயற்கைக்கோள் தரவு: மணிக்கு 65மிமீ • ஆற்று கண்காணிப்பு செயலில்'
  ],
  'ob2_tag': ['GROUND INTELLIGENCE', 'ක්ෂේත්‍ර තොරතුරු', 'களத் தகவல்'],
  'ob2_title': [
    'Rapid Community Reporting',
    'ඉක්මන් ප්‍රජා වාර්තාකරණය',
    'விரைவான சமூக அறிக்கையிடல்'
  ],
  'ob2_desc': [
    'Capture geotagged hazard photos and transmit instant alerts to the Disaster Operations Room—even with zero internet connection.',
    'ස්ථානය සහිත අනතුරු ඡායාරූප ගෙන, අන්තර්ජාල සම්බන්ධතාවයක් නොමැතිව වුවද ආපදා මෙහෙයුම් කාමරයට ක්ෂණික ඇඟවීම් යවන්න.',
    'இருப்பிடக் குறியுடன் ஆபத்துப் படங்களை எடுத்து, இணைய இணைப்பு இல்லாவிட்டாலும் பேரிடர் செயல்பாட்டு அறைக்கு உடனடி எச்சரிக்கைகளை அனுப்புங்கள்.'
  ],
  'ob2_tl': [
    'INCIDENT CAM • DMC VERIFIED',
    'සිදුවීම් කැමරාව • DMC තහවුරුයි',
    'சம்பவ கேமரா • DMC சரிபார்த்தது'
  ],
  'ob2_tr': [
    'OFFLINE QUEUE ACTIVE',
    'නොබැඳි පෝලිම සක්‍රියයි',
    'ஆஃப்லைன் வரிசை செயலில்'
  ],
  'ob2_tele': [
    'GPS: 6.9271° N, 79.8612° E • VERIFICATION LOCKED',
    'GPS: 6.9271° N, 79.8612° E • තහවුරු කිරීම අගුළු දමා ඇත',
    'GPS: 6.9271° N, 79.8612° E • சரிபார்ப்பு பூட்டப்பட்டது'
  ],
  'ob3_tag': [
    'LIFE-SAVING NAVIGATION',
    'ජීවිත ගලවන මාර්ගෝපදේශනය',
    'உயிர்காக்கும் வழிகாட்டுதல்'
  ],
  'ob3_title': [
    'Safe Routes & Relief Shelters',
    'ආරක්ෂිත මාර්ග සහ සහන කඳවුරු',
    'பாதுகாப்பான பாதைகள் & நிவாரண முகாம்கள்'
  ],
  'ob3_desc': [
    'Navigate through real-time safe elevation corridors avoiding flood zones directly to active emergency camps and relief centers.',
    'ගංවතුර කලාප මඟහරිමින් සජීවී ආරක්ෂිත උස් මාර්ග හරහා ක්‍රියාත්මක හදිසි කඳවුරු සහ සහන මධ්‍යස්ථාන වෙත කෙලින්ම ගමන් කරන්න.',
    'வெள்ளப் பகுதிகளைத் தவிர்த்து, நேரடி பாதுகாப்பான உயரமான பாதைகள் வழியாக செயல்பாட்டில் உள்ள அவசர முகாம்கள் மற்றும் நிவாரண மையங்களுக்குச் செல்லுங்கள்.'
  ],
  'ob3_tl': [
    'EVAC ROUTE ACTIVE • 3.2 KM',
    'ඉවත්වීමේ මාර්ගය සක්‍රියයි • කි.මී. 3.2',
    'வெளியேற்றப் பாதை செயலில் • 3.2 கிமீ'
  ],
  'ob3_tr': ['SHELTER ZONE A', 'කඳවුරු කලාපය A', 'முகாம் பகுதி A'],
  'ob3_tele': [
    'RELIEF STATUS: FOOD, WATER & MEDICAL STOCKED',
    'සහන තත්ත්වය: ආහාර, වතුර සහ වෛද්‍ය ද්‍රව්‍ය තොග තිබේ',
    'நிவாரண நிலை: உணவு, தண்ணீர் & மருத்துவப் பொருட்கள் கையிருப்பில்'
  ],

  // ── Login ─────────────────────────────────────────────────────────────────
  'login_enter_email': [
    'Please enter your email address to log in.',
    'ඇතුල් වීමට ඔබගේ ඊමේල් ලිපිනය ඇතුළත් කරන්න.',
    'உள்நுழைய உங்கள் மின்னஞ்சல் முகவரியை உள்ளிடுங்கள்.'
  ],
  'login_enter_password': [
    'Please enter your password.',
    'කරුණාකර ඔබගේ මුරපදය ඇතුළත් කරන්න.',
    'உங்கள் கடவுச்சொல்லை உள்ளிடுங்கள்.'
  ],
  'login_welcome': [
    'Welcome, {name}! Connected to Firebase.',
    'ආයුබෝවන්, {name}! Firebase වෙත සම්බන්ධ විය.',
    'வரவேற்கிறோம், {name}! Firebase உடன் இணைக்கப்பட்டது.'
  ],
  'otp_need_email': [
    'Please enter your email address first to receive the OTP code.',
    'OTP කේතය ලබා ගැනීමට පළමුව ඔබගේ ඊමේල් ලිපිනය ඇතුළත් කරන්න.',
    'OTP குறியீட்டைப் பெற முதலில் உங்கள் மின்னஞ்சல் முகவரியை உள்ளிடுங்கள்.'
  ],
  'otp_sent_snack': [
    'OTP Code sent to {email}: {otp} (Valid for 5 mins)',
    'OTP කේතය {email} වෙත යැව්වා: {otp} (මිනිත්තු 5ක් වලංගුයි)',
    'OTP குறியீடு {email} க்கு அனுப்பப்பட்டது: {otp} (5 நிமிடங்கள் செல்லுபடியாகும்)'
  ],
  'reset_title': [
    'Reset PIN / Password',
    'PIN / මුරපදය යළි සකසන්න',
    'PIN / கடவுச்சொல்லை மீட்டமை'
  ],
  'otp_via_email': [
    'OTP Verification via Email',
    'ඊමේල් හරහා OTP තහවුරු කිරීම',
    'மின்னஞ்சல் வழி OTP சரிபார்ப்பு'
  ],
  'otp_sent_to': [
    'OTP sent to: {email}\nTest Code: {otp}',
    'OTP යැවූයේ: {email}\nපරීක්ෂණ කේතය: {otp}',
    'OTP அனுப்பப்பட்டது: {email}\nசோதனைக் குறியீடு: {otp}'
  ],
  'enter_otp': [
    'ENTER 6-DIGIT OTP CODE',
    'ඉලක්කම් 6ක OTP කේතය ඇතුළත් කරන්න',
    '6 இலக்க OTP குறியீட்டை உள்ளிடுக'
  ],
  'new_pin': ['NEW PIN / PASSWORD', 'නව PIN / මුරපදය', 'புதிய PIN / கடவுச்சொல்'],
  'new_pin_hint': [
    'Enter new secure PIN or password',
    'නව ආරක්ෂිත PIN හෝ මුරපදය ඇතුළත් කරන්න',
    'புதிய பாதுகாப்பான PIN அல்லது கடவுச்சொல்லை உள்ளிடுக'
  ],
  'otp_invalid': [
    'Invalid OTP code. Please enter the code sent to your email.',
    'OTP කේතය වැරදියි. ඔබගේ ඊමේලයට එවූ කේතය ඇතුළත් කරන්න.',
    'தவறான OTP குறியீடு. உங்கள் மின்னஞ்சலுக்கு அனுப்பிய குறியீட்டை உள்ளிடுங்கள்.'
  ],
  'pin_invalid': [
    'Please enter a valid PIN or password (min 4 characters).',
    'වලංගු PIN හෝ මුරපදයක් ඇතුළත් කරන්න (අවම අක්ෂර 4).',
    'செல்லுபடியாகும் PIN அல்லது கடவுச்சொல்லை உள்ளிடுங்கள் (குறைந்தது 4 எழுத்துகள்).'
  ],
  'pin_updated': [
    'PIN successfully updated in Firebase! You can now log in.',
    'PIN සාර්ථකව යාවත්කාලීන විය! දැන් ඇතුල් විය හැක.',
    'PIN வெற்றிகரமாகப் புதுப்பிக்கப்பட்டது! இப்போது உள்நுழையலாம்.'
  ],
  'verify_update': [
    'VERIFY OTP & UPDATE PIN',
    'OTP තහවුරු කර PIN යාවත්කාලීන කරන්න',
    'OTP சரிபார்த்து PIN ஐப் புதுப்பிக்கவும்'
  ],
  'portal_title': [
    'Secure Portal Login',
    'ආරක්ෂිත ද්වාර පිවිසුම',
    'பாதுகாப்பான நுழைவு'
  ],
  'disaster_system': [
    'Disaster Response System',
    'ආපදා ප්‍රතිචාර පද්ධතිය',
    'பேரிடர் மறுமொழி அமைப்பு'
  ],
  'municipal': [
    'Municipal Dispatch Authorization v4.2',
    'මහ නගර සභා යැවීමේ අවසරය v4.2',
    'நகராட்சி அனுப்பீட்டு அங்கீகாரம் v4.2'
  ],
  'work_email': [
    'OFFICIAL WORK EMAIL',
    'නිල වැඩ ඊමේල්',
    'அதிகாரப்பூர்வ பணி மின்னஞ்சல்'
  ],
  'enter_email': [
    'Enter your email',
    'ඔබගේ ඊමේල් ඇතුළත් කරන්න',
    'உங்கள் மின்னஞ்சலை உள்ளிடுக'
  ],
  'password': ['PASSWORD', 'මුරපදය', 'கடவுச்சொல்'],
  'enter_password': [
    'Enter your password',
    'ඔබගේ මුරපදය ඇතුළත් කරන්න',
    'உங்கள் கடவுச்சொல்லை உள்ளிடுக'
  ],
  'remember': [
    'Remember credentials',
    'තොරතුරු මතක තබා ගන්න',
    'விவரங்களை நினைவில் கொள்'
  ],
  'reset_pin_q': ['Reset PIN?', 'PIN යළි සකසන්නද?', 'PIN ஐ மீட்டமைக்கவா?'],
  'login_btn': [
    'AUTHENTICATE & LOGIN',
    'සත්‍යාපනය කර ඇතුල් වන්න',
    'அங்கீகரித்து உள்நுழை'
  ],
  'new_officer': ['New member? ', 'නව සාමාජිකයෙක්ද? ', 'புதிய உறுப்பினரா? '],
  'registration': ['Registration', 'ලියාපදිංචිය', 'பதிவு'],

  // ── Citizen registration ──────────────────────────────────────────────────
  'reg_accept': [
    'Please accept the flood early warning agreement to proceed.',
    'ඉදිරියට යාමට ගංවතුර පූර්ව අනතුරු ඇඟවීමේ ගිවිසුම පිළිගන්න.',
    'தொடர, வெள்ள முன்னெச்சரிக்கை ஒப்பந்தத்தை ஏற்றுக்கொள்ளுங்கள்.'
  ],
  'reg_saved': [
    'Saved to Firebase Firestore! Log in as {name}.',
    'සුරැකිණි! {name} ලෙස ඇතුල් වන්න.',
    'சேமிக்கப்பட்டது! {name} ஆக உள்நுழையுங்கள்.'
  ],
  'reg_error': [
    'Firebase Registration Error: {err}',
    'ලියාපදිංචි දෝෂය: {err}',
    'பதிவு பிழை: {err}'
  ],
  'citizen_reg': [
    'Citizen Registration',
    'පුරවැසි ලියාපදිංචිය',
    'குடிமக்கள் பதிவு'
  ],
  'civilian_acct': [
    'Early Warning Civilian Account',
    'පූර්ව අනතුරු ඇඟවීම් පුරවැසි ගිණුම',
    'முன்னெச்சரிக்கை குடிமக்கள் கணக்கு'
  ],
  'network': [
    'Flood & Disaster Preparedness Network',
    'ගංවතුර සහ ආපදා සූදානම් ජාලය',
    'வெள்ளம் & பேரிடர் தயார்நிலை வலையமைப்பு'
  ],
  'full_name': ['FULL NAME', 'සම්පූර්ණ නම', 'முழுப் பெயர்'],
  'enter_full_name': [
    'Enter your full name',
    'ඔබගේ සම්පූර්ණ නම ඇතුළත් කරන්න',
    'உங்கள் முழுப் பெயரை உள்ளிடுக'
  ],
  'enter_name_err': [
    'Please enter your name',
    'කරුණාකර ඔබගේ නම ඇතුළත් කරන්න',
    'உங்கள் பெயரை உள்ளிடுங்கள்'
  ],
  'email_address': ['EMAIL ADDRESS', 'ඊමේල් ලිපිනය', 'மின்னஞ்சல் முகவரி'],
  'valid_email_err': [
    'Please enter a valid email address',
    'වලංගු ඊමේල් ලිපිනයක් ඇතුළත් කරන්න',
    'செல்லுபடியாகும் மின்னஞ்சல் முகவரியை உள்ளிடுங்கள்'
  ],
  'phone': ['PHONE NUMBER', 'දුරකථන අංකය', 'தொலைபேசி எண்'],
  'enter_phone': [
    'Enter phone number',
    'දුරකථන අංකය ඇතුළත් කරන්න',
    'தொலைபேசி எண்ணை உள்ளிடுக'
  ],
  'nic': [
    'NATIONAL ID (NIC)',
    'ජාතික හැඳුනුම්පත (NIC)',
    'தேசிய அடையாள அட்டை (NIC)'
  ],
  'enter_nic': ['Enter NIC', 'NIC ඇතුළත් කරන්න', 'NIC ஐ உள்ளிடுக'],
  'district': ['DISTRICT', 'දිස්ත්‍රික්කය', 'மாவட்டம்'],
  'enter_district': [
    'Enter district',
    'දිස්ත්‍රික්කය ඇතුළත් කරන්න',
    'மாவட்டத்தை உள்ளிடுக'
  ],
  'city': ['CITY', 'නගරය', 'நகரம்'],
  'enter_city': ['Enter city', 'නගරය ඇතුළත් කරන්න', 'நகரத்தை உள்ளிடுக'],
  'flood_zone_label': [
    'RESIDENTIAL FLOOD ZONE / SECTOR',
    'පදිංචි ගංවතුර කලාපය / අංශය',
    'குடியிருப்பு வெள்ளப் பகுதி / பிரிவு'
  ],
  'custom_zone_label': [
    'TYPE YOUR CUSTOM FLOOD ZONE / AREA',
    'ඔබගේ ගංවතුර කලාපය / ප්‍රදේශය ටයිප් කරන්න',
    'உங்கள் வெள்ளப் பகுதியை / இடத்தை உள்ளிடுக'
  ],
  'custom_zone_hint': [
    'e.g. Wellampitiya GN Div 5 / Sedawatta Lowland',
    'උදා: වැල්ලම්පිටිය ග්‍රා.නි. කොට්ඨාසය 5 / සෙදවත්ත පහත් බිම',
    'எ.கா: வெல்லம்பிட்டிய GN பிரிவு 5 / சேதவத்த தாழ்நிலம்'
  ],
  'custom_zone_err': [
    'Please specify your custom flood zone',
    'ඔබගේ ගංවතුර කලාපය සඳහන් කරන්න',
    'உங்கள் வெள்ளப் பகுதியைக் குறிப்பிடுங்கள்'
  ],
  'pw_short': [
    'Password too short',
    'මුරපදය ඉතා කෙටියි',
    'கடவுச்சொல் மிகச் சிறியது'
  ],
  'confirm_pw': [
    'CONFIRM PASSWORD',
    'මුරපදය තහවුරු කරන්න',
    'கடவுச்சொல்லை உறுதிசெய்'
  ],
  'pw_mismatch': [
    'Passwords do not match',
    'මුරපද නොගැලපේ',
    'கடவுச்சொற்கள் பொருந்தவில்லை'
  ],
  'agree_sms': [
    'I agree to receive SMS & push emergency flood alerts for my residential sector and consent to location-based early warning broadcasts.',
    'මගේ පදිංචි ප්‍රදේශය සඳහා හදිසි ගංවතුර SMS සහ push අනතුරු ඇඟවීම් ලැබීමට මම එකඟ වෙමි, ස්ථානය පදනම් කරගත් පූර්ව අනතුරු ඇඟවීම් විකාශනවලටද මම කැමැත්ත දෙමි.',
    'எனது குடியிருப்புப் பகுதிக்கான அவசர வெள்ள SMS மற்றும் push எச்சரிக்கைகளைப் பெற நான் ஒப்புக்கொள்கிறேன்; இருப்பிடம் சார்ந்த முன்னெச்சரிக்கை ஒளிபரப்புகளுக்கும் சம்மதிக்கிறேன்.'
  ],
  'complete_reg': [
    'COMPLETE REGISTRATION',
    'ලියාපදිංචිය සම්පූර්ණ කරන්න',
    'பதிவை முடிக்கவும்'
  ],
  'have_acct': [
    'Already have an account? ',
    'දැනටමත් ගිණුමක් තිබේද? ',
    'ஏற்கனவே கணக்கு உள்ளதா? '
  ],
  'login_here': ['Log In here', 'මෙතනින් ඇතුල් වන්න', 'இங்கே உள்நுழைக'],
};
