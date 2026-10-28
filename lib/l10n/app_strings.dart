import 'package:flutter/widgets.dart';
import '../services/localization_service.dart';

/// Centralized, high-coverage localization dictionary for Gujarati (gu), Hindi (hi), and English (en).
/// Supports both key-based lookup AND direct text-phrase lookup (Gujarati or English phrase).
class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _localizedValues = {
    // =============================================================
    // 1. General & System Actions
    // =============================================================
    'app_name': {
      'gu': 'સોસાયટી મેનેજર',
      'hi': 'सोसायटी मैनेजर',
      'en': 'Society Manager',
    },
    'select_language': {
      'gu': 'ભાષા પસંદ કરો',
      'hi': 'अपनी भाषा चुनें',
      'en': 'Select Language',
    },
    'save': {
      'gu': 'સાચવો',
      'hi': 'सहेजें',
      'en': 'Save',
    },
    'cancel': {
      'gu': 'રદ કરો',
      'hi': 'रद्द करें',
      'en': 'Cancel',
    },
    'delete': {
      'gu': 'કાઢી નાખો',
      'hi': 'हटाएं',
      'en': 'Delete',
    },
    'edit': {
      'gu': 'ફેરફાર કરો',
      'hi': 'संपादित करें',
      'en': 'Edit',
    },
    'confirm': {
      'gu': 'ખાતરી કરો',
      'hi': 'पुष्टि करें',
      'en': 'Confirm',
    },
    'submit': {
      'gu': 'સબમિટ કરો',
      'hi': 'जमा करें',
      'en': 'Submit',
    },
    'close': {
      'gu': 'બંધ કરો',
      'hi': 'बंद करें',
      'en': 'Close',
    },
    'back': {
      'gu': 'પાછા જાઓ',
      'hi': 'वापस जाएं',
      'en': 'Back',
    },
    'search': {
      'gu': 'શોધો...',
      'hi': 'खोजें...',
      'en': 'Search...',
    },
    'filter': {
      'gu': 'ફિલ્ટર',
      'hi': 'फ़िल्टर',
      'en': 'Filter',
    },
    'all': {
      'gu': 'બધા',
      'hi': 'सभी',
      'en': 'All',
    },
    'yes': {
      'gu': 'હા',
      'hi': 'हाँ',
      'en': 'Yes',
    },
    'no': {
      'gu': 'ના',
      'hi': 'नहीं',
      'en': 'No',
    },
    'logout': {
      'gu': 'લોગઆઉટ',
      'hi': 'लॉगआउट',
      'en': 'Logout',
    },
    'logout_confirm': {
      'gu': 'શું તમે ખરેખર લોગઆઉટ કરવા માંગો છો?',
      'hi': 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
      'en': 'Are you sure you want to logout?',
    },
    'loading': {
      'gu': 'લોડ થઈ રહ્યું છે...',
      'hi': 'लोड हो रहा है...',
      'en': 'Loading...',
    },
    'error': {
      'gu': 'ભૂલ',
      'hi': 'त्रुटि',
      'en': 'Error',
    },
    'success': {
      'gu': 'સફળતા',
      'hi': 'सफलता',
      'en': 'Success',
    },
    'warning': {
      'gu': 'ચેતવણી',
      'hi': 'चेतावनी',
      'en': 'Warning',
    },
    'view_all': {
      'gu': 'બધા જુઓ',
      'hi': 'सभी देखें',
      'en': 'View All',
    },
    'refresh': {
      'gu': 'રિફ્રેશ કરો',
      'hi': 'रिफ्रेश करें',
      'en': 'Refresh',
    },
    'no_data': {
      'gu': 'કોઈ ડેટા ઉપલબ્ધ નથી',
      'hi': 'कोई डेटा उपलब्ध नहीं है',
      'en': 'No data available',
    },
    'details': {
      'gu': 'વિગતો',
      'hi': 'विवरण',
      'en': 'Details',
    },
    'download': {
      'gu': 'ડાઉનલોડ',
      'hi': 'डाउनलोड',
      'en': 'Download',
    },
    'share': {
      'gu': 'શેર કરો',
      'hi': 'शेयर करें',
      'en': 'Share',
    },
    'status': {
      'gu': 'સ્ટેટસ',
      'hi': 'स्थिति (Status)',
      'en': 'Status',
    },
    'total': {
      'gu': 'કુલ',
      'hi': 'कुल',
      'en': 'Total',
    },
    'action': {
      'gu': 'ક્રિયા',
      'hi': 'कार्रवाई',
      'en': 'Action',
    },
    'date': {
      'gu': 'તારીખ',
      'hi': 'तारीख',
      'en': 'Date',
    },
    'time': {
      'gu': 'સમય',
      'hi': 'समय',
      'en': 'Time',
    },

    // =============================================================
    // 2. Roles & User Profiles
    // =============================================================
    'role_super_admin': {
      'gu': 'સુપર એડમિન',
      'hi': 'सुपर एडमिन',
      'en': 'Super Admin',
    },
    'role_admin': {
      'gu': 'સોસાયટી એડમિન',
      'hi': 'सोसायटी एडमिन',
      'en': 'Society Admin',
    },
    'role_sub_admin': {
      'gu': 'સબ એડમિન',
      'hi': 'उप एडमिन',
      'en': 'Sub Admin',
    },
    'role_committee': {
      'gu': 'કમિટી સભ્ય',
      'hi': 'कमेटी सदस्य',
      'en': 'Committee Member',
    },
    'role_member': {
      'gu': 'સોસાયટી સભ્ય',
      'hi': 'सोसायटी सदस्य',
      'en': 'Society Member',
    },
    'role_guard': {
      'gu': 'સિક્યુરિટી ગાર્ડ',
      'hi': 'सुरक्षा गार्ड',
      'en': 'Security Guard',
    },
    'role_watchman': {
      'gu': 'વોચમેન સ્ટાફ',
      'hi': 'वॉचमैन स्टाफ',
      'en': 'Watchman Staff',
    },
    'role_visitor': {
      'gu': 'મુલાકાતી',
      'hi': 'आगंतुक (Visitor)',
      'en': 'Visitor',
    },

    // =============================================================
    // 3. Login Screen
    // =============================================================
    'login_hero_title': {
      'gu': 'સ્માર્ટ પ્રિમાઇસીસ સુરક્ષા',
      'hi': 'स्मार्ट परिसर सुरक्षा',
      'en': 'Smart Premises Security',
    },
    'login_hero_subtitle': {
      'gu': 'રેસીડેન્સી, બંગલો, શોપિંગ મોલ અને હાઇબ્રિડ સોસાયટી પોર્ટલ',
      'hi': 'रेजीडेंसी, बंगला, शॉपिंग मॉल और हाइब्रिड सोसायटी पोर्टल',
      'en': 'Residency, Villas, Shopping Mall & Hybrid Society Portal',
    },
    'login_to_account': {
      'gu': 'તમારા એકાઉન્ટમાં લૉગિન કરો',
      'hi': 'अपने खाते में लॉगिन करें',
      'en': 'Login to Your Account',
    },
    'login_subtitle': {
      'gu': 'એડમિન, કમિટી સભ્ય, ગાર્ડ કે મેમ્બર — ઓટોમેટિક ડિટેક્શન સાથે પ્રવેશ.',
      'hi': 'एडमिन, कमेटी सदस्य, गार्ड या सदस्य — ऑटोमैटिक डिटेक्शन के साथ प्रवेश।',
      'en': 'Admin, Committee, Guard or Member — Auto role detection.',
    },
    'auto_role_detection': {
      'gu': 'ઓટોમેટિક રોલ ડિટેક્શન (Auto Role)',
      'hi': 'स्वचालित भूमिका पहचान (Auto Role)',
      'en': 'Automatic Role Detection (Auto Role)',
    },
    'auto_role_desc': {
      'gu': 'કોઈપણ રોલ પસંદ કરવાની જરૂર નથી — ફક્ત ઈમેલ/મોબાઇલ અને પાસવર્ડથી લૉગિન કરો. સિસ્ટમ આપમેળે આપનો રોલ ઓળખી ડેશબોર્ડ ખોલશે.',
      'hi': 'कोई भी भूमिका चुनने की आवश्यकता नहीं है — केवल ईमेल/मोबाइल और पासवर्ड से लॉगिन करें। सिस्टम स्वचालित रूप से आपकी भूमिका पहचान लेगा।',
      'en': 'No need to select a role — simply log in with your email/mobile and password. The system auto-identifies your role.',
    },
    'role_badge_admin': {
      'gu': '👑 એડમિન',
      'hi': '👑 एडमिन',
      'en': '👑 Admin',
    },
    'role_badge_committee': {
      'gu': '🎖️ કમિટી / સબ-એડમિન',
      'hi': '🎖️ कमेटी / उप-एडमिन',
      'en': '🎖️ Committee / Sub-Admin',
    },
    'role_badge_guard': {
      'gu': '🛡️ સિક્યુરિટી ગાર્ડ',
      'hi': '🛡️ सुरक्षा गार्ड',
      'en': '🛡️ Security Guard',
    },
    'role_badge_member': {
      'gu': '🏠 સોસાયટી સભ્ય',
      'hi': '🏠 सोसायटी सदस्य',
      'en': '🏠 Society Member',
    },
    'email_or_phone_label': {
      'gu': 'ઇમેઇલ અથવા મોબાઇલ નંબર',
      'hi': 'ईमेल या मोबाइल नंबर',
      'en': 'Email or Mobile Number',
    },
    'email_or_phone_hint': {
      'gu': 'તમારો રજીસ્ટર્ડ ઇમેઇલ કે ફોન',
      'hi': 'आपका पंजीकृत ईमेल या फोन',
      'en': 'Your registered email or phone',
    },
    'password_label': {
      'gu': 'પાસવર્ડ',
      'hi': 'पासवर्ड',
      'en': 'Password',
    },
    'password_hint': {
      'gu': 'તમારો ગુપ્ત પાસવર્ડ',
      'hi': 'आपका पासवर्ड',
      'en': 'Your secret password',
    },
    'forgot_password': {
      'gu': 'પાસવર્ડ ભૂલી ગયા?',
      'hi': 'पासवर्ड भूल गए?',
      'en': 'Forgot Password?',
    },
    'login_button': {
      'gu': 'લૉગિન કરો',
      'hi': 'लॉगिन करें',
      'en': 'Login',
    },
    'logging_in': {
      'gu': 'ચકાસણી ચાલુ છે...',
      'hi': 'सत्यापन जारी है...',
      'en': 'Verifying...',
    },
    'how_to_get_account': {
      'gu': 'નવું એકાઉન્ટ કેવી રીતે મેળવવું?',
      'hi': 'नया खाता कैसे प्राप्त करें?',
      'en': 'How to get an account?',
    },
    'account_policy_sub': {
      'gu': 'કોઈપણ સભ્ય કે એડમિન જાતે એકાઉન્ટ બનાવી શકતા નથી. અધિકૃત પ્રક્રિયા જાણો →',
      'hi': 'कोई भी सदस्य या एडमिन स्वयं खाता नहीं बना सकता। अधिकृत प्रक्रिया जानें →',
      'en': 'Self-registration is not allowed. Learn the official access process →',
    },
    'input_required': {
      'gu': 'કૃપા કરીને ઇમેઇલ અથવા મોબાઇલ નંબર અને પાસવર્ડ દાખલ કરો.',
      'hi': 'कृपया ईमेल या मोबाइल नंबर और पासवर्ड दर्ज करें।',
      'en': 'Please enter email or phone and password.',
    },

    // =============================================================
    // 4. Member Portal & Dashboard
    // =============================================================
    'my_society': {
      'gu': 'માય સોસાયટી',
      'hi': 'मेरी सोसायटी',
      'en': 'My Society',
    },
    'member_portal': {
      'gu': 'મેમ્બર પોર્ટલ • ૨૪×૭ સુરક્ષિત નિવાસ',
      'hi': 'सदस्य पोर्टल • २४×७ सुरक्षित निवास',
      'en': 'Member Portal • 24x7 Secure Living',
    },
    'admin_control_center': {
      'gu': 'એડમિન કંટ્રોલ સેન્ટર • ૨૪×૭ લાઈવ',
      'hi': 'एडमिन कंट्रोल सेंटर • २४×७ लाइव',
      'en': 'Admin Control Center • 24x7 Live',
    },
    'recent_visitors': {
      'gu': 'તાજેતરના મુલાકાતીઓ',
      'hi': 'हाल के आगंतुक',
      'en': 'Recent Visitors',
    },
    'quick_actions': {
      'gu': 'ઝડપી સેવાઓ',
      'hi': 'त्वरित सेवाएं',
      'en': 'Quick Actions',
    },
    'sos_emergency': {
      'gu': 'ઇમરજન્સી SOS મદદ',
      'hi': 'आपातकालीन SOS सहायता',
      'en': 'Emergency SOS Help',
    },
    'notifications': {
      'gu': 'નોટિફિકેશન અને એલર્ટ્સ',
      'hi': 'सूचनाएं और अलर्ट',
      'en': 'Notifications & Alerts',
    },
    'maintenance': {
      'gu': 'મેન્ટેનન્સ',
      'hi': 'मेंटेनेंस',
      'en': 'Maintenance',
    },
    'pay_maintenance': {
      'gu': 'મેન્ટેનન્સ ભરો',
      'hi': 'मेंटेनेंस भरें',
      'en': 'Pay Maintenance',
    },
    'pre_approve': {
      'gu': 'પૂર્વ મંજૂરી (Pre-Approve)',
      'hi': 'पूर्व स्वीकृति (Pre-Approve)',
      'en': 'Pre-Approve Visitor',
    },
    'complaints': {
      'gu': 'ફરિયાદો',
      'hi': 'शिकायतें',
      'en': 'Complaints',
    },
    'vehicles': {
      'gu': 'વાહનો',
      'hi': 'वाहन',
      'en': 'Vehicles',
    },
    'daily_staff': {
      'gu': 'દૈનિક સ્ટાફ',
      'hi': 'दैनिक कर्मचारी',
      'en': 'Daily Staff',
    },
    'visitors': {
      'gu': 'મુલાકાતીઓ',
      'hi': 'आगंतुक',
      'en': 'Visitors',
    },
    'accounts': {
      'gu': 'હિસાબ-કિતાબ',
      'hi': 'लेखा-जोखा',
      'en': 'Accounts',
    },
    'polls': {
      'gu': 'નિર્ણય મતદાન',
      'hi': 'निर्णय मतदान',
      'en': 'Polls & Voting',
    },
    'amenities': {
      'gu': 'સુવિધાઓ બુકિંગ',
      'hi': 'सुविधाएं बुकिंग',
      'en': 'Amenities Booking',
    },
    'guard_patrol': {
      'gu': 'ગાર્ડ પેટ્રોલિંગ',
      'hi': 'गार्ड पेट्रोलिंग',
      'en': 'Guard Patrol',
    },
    'guest_pass_title': {
      'gu': 'ગેસ્ટ પાસ (QR)',
      'hi': 'गेस्ट पास (QR)',
      'en': 'Guest Pass (QR)',
    },
    'guest_pass_sub': {
      'gu': 'પ્રી-એપ્રુવલ પાસ',
      'hi': 'पूर्व-स्वीकृति पास',
      'en': 'Pre-Approval Pass',
    },
    'maintenance_bill_title': {
      'gu': 'મેન્ટેનન્સ બિલ',
      'hi': 'मेंटेनेंस बिल',
      'en': 'Maintenance Bill',
    },
    'maintenance_bill_sub': {
      'gu': 'ઓનલાઇન પે & રસીદ',
      'hi': 'ऑनलाइन भुगतान व रसीद',
      'en': 'Online Pay & Receipt',
    },
    'complaint_action_title': {
      'gu': 'ફરિયાદ',
      'hi': 'शिकायत',
      'en': 'Complaint',
    },
    'complaint_action_sub': {
      'gu': 'સહાય & નિકાલ',
      'hi': 'सहायता व समाधान',
      'en': 'Help & Resolution',
    },
    'daily_staff_title': {
      'gu': 'કાયમી સ્ટાફ',
      'hi': 'दैनिक कर्मचारी',
      'en': 'Daily Staff',
    },
    'daily_staff_sub': {
      'gu': 'મેઇડ, ડ્રાઇવર',
      'hi': 'मेड, ड्राइवर',
      'en': 'Maid, Driver',
    },
    'vehicles_action_title': {
      'gu': 'વાહનો & સ્લોટ',
      'hi': 'वाहन व स्लॉट',
      'en': 'Vehicles & Slot',
    },
    'vehicles_action_sub': {
      'gu': 'પાર્કિંગ કંટ્રોલ',
      'hi': 'पार्किंग नियंत्रण',
      'en': 'Parking Control',
    },
    'society_accounts_title': {
      'gu': 'સોસાયટી હિસાબ & તિજોરી ફંડ',
      'hi': 'सोसायटी लेखा-जोखा और फंड',
      'en': 'Society Accounts & Treasury',
    },
    'society_accounts_sub': {
      'gu': 'બચત, વોચમેન પગાર, સફાઈ, લાઈટ બિલ & ખર્ચ વિગત',
      'hi': 'बचत, गार्ड वेतन, सफाई, बिजली बिल व खर्च विवरण',
      'en': 'Savings, Guard salary, Cleaning, Power bill & Expenses',
    },
    'view_accounts_btn': {
      'gu': 'હિસાબ જુઓ',
      'hi': 'लेखा देखें',
      'en': 'View Accounts',
    },
    'society_polls_card_title': {
      'gu': 'સોસાયટી નિર્ણય મતદાન',
      'hi': 'सोसायटी निर्णय मतदान',
      'en': 'Society Decision Polls',
    },
    'society_polls_card_sub': {
      'gu': 'તમારો કિંમતી મત સોસાયટીના વિકાસ માટે',
      'hi': 'आपका कीमती वोट सोसायटी के विकास के लिए',
      'en': 'Your valuable vote for society growth',
    },
    'vote_now_btn': {
      'gu': 'મત આપો',
      'hi': 'वोट दें',
      'en': 'Vote Now',
    },
    'amenities_card_title': {
      'gu': 'સોસાયટી સુવિધાઓ & ક્લબહાઉસ',
      'hi': 'सोसायटी सुविधाएं और क्लबहाउस',
      'en': 'Society Amenities & Clubhouse',
    },
    'amenities_card_sub': {
      'gu': 'હોલ, જીમ, ટેરેસ, સ્લોટ બુકિંગ & નિયમો',
      'hi': 'हॉल, जिम, छत, स्लॉट बुकिंग और नियम',
      'en': 'Hall, Gym, Terrace, Slot Booking & Rules',
    },
    'book_amenity_btn': {
      'gu': 'બુક કરો',
      'hi': 'बुक करें',
      'en': 'Book Slot',
    },
    'patrol_card_title': {
      'gu': 'ગાર્ડ નાઇટ પેટ્રોલિંગ ટ્રેકર',
      'hi': 'गार्ड नाइट पेट्रोलिंग ट्रैकर',
      'en': 'Guard Night Patrol Tracker',
    },
    'patrol_card_sub': {
      'gu': 'QR ચેકપોઇન્ટ લાઈવ સ્કેનિંગ અને પેટ્રોલિંગ હિસ્ટ્રી',
      'hi': 'QR चेकपॉइंट लाइव स्कैनिंग व हिस्ट्री',
      'en': 'Live QR Checkpoint Scanning & History',
    },
    'view_patrol_btn': {
      'gu': 'ટ્રેકિંગ જુઓ',
      'hi': 'ट्रैकिंग देखें',
      'en': 'View Patrol',
    },
    'scope_my_flat': {
      'gu': 'મારા ફ્લેટ',
      'hi': 'मेरा फ्लैट',
      'en': 'My Unit',
    },
    'scope_all_society': {
      'gu': 'સમગ્ર સોસાયટી',
      'hi': 'पूरी सोसायटी',
      'en': 'All Society',
    },
    'filter_all': {
      'gu': 'બધા',
      'hi': 'सभी',
      'en': 'All',
    },
    'filter_pending': {
      'gu': 'પેન્ડિંગ',
      'hi': 'लंबित',
      'en': 'Pending',
    },
    'filter_approved': {
      'gu': 'મંજૂર',
      'hi': 'स्वीकृत',
      'en': 'Approved',
    },
    'filter_rejected': {
      'gu': 'અસ્વીકાર',
      'hi': 'अस्वीकृत',
      'en': 'Rejected',
    },
    'no_visitors_found': {
      'gu': 'આ કેટેગરીમાં કોઈ મુલાકાતી મળ્યા નથી',
      'hi': 'इस श्रेणी में कोई आगंतुक नहीं मिला',
      'en': 'No visitors found in this category',
    },

    // =============================================================
    // 5. Gate Security & Watchman Screen
    // =============================================================
    'gate_control': {
      'gu': 'ગેટ કન્ટ્રોલ',
      'hi': 'गेट नियंत्रण (Gate Control)',
      'en': 'Gate Control',
    },
    'visitor_entry': {
      'gu': 'મુલાકાતી નોંધણી',
      'hi': 'आगंतुक प्रविष्टि',
      'en': 'Visitor Entry',
    },
    'visitor_history': {
      'gu': 'મુલાકાતી ઇતિહાસ',
      'hi': 'आगंतुक इतिहास',
      'en': 'Visitor History',
    },
    'vehicle_search': {
      'gu': 'વાહન સર્ચ (Vehicle Search)',
      'hi': 'वाहन खोज (Vehicle Search)',
      'en': 'Vehicle Search',
    },
    'emergency_and_staff': {
      'gu': 'ઈમરજન્સી & સ્ટાફ',
      'hi': 'आपातकालीन व स्टाफ',
      'en': 'Emergency & Staff',
    },
    'emergency_sos_alert': {
      'gu': 'ઇમરજન્સી SOS એલર્ટ',
      'hi': 'आपातकालीन SOS अलर्ट',
      'en': 'Emergency SOS Alert',
    },
    'visitor_name': {
      'gu': 'મુલાકાતીનું પૂરું નામ',
      'hi': 'आगंतुक का पूरा नाम',
      'en': 'Visitor Full Name',
    },
    'visitor_phone': {
      'gu': 'મોબાઇલ નંબર',
      'hi': 'मोबाइल नंबर',
      'en': 'Mobile Number',
    },
    'visit_purpose': {
      'gu': 'મુલાકાતનો હેતુ',
      'hi': 'आने का उद्देश्य',
      'en': 'Purpose of Visit',
    },
    'vehicle_number': {
      'gu': 'વાહન નંબર (જો હોય તો)',
      'hi': 'वाहन संख्या (यदि कोई हो)',
      'en': 'Vehicle Number (Optional)',
    },
    'select_flat_or_member': {
      'gu': 'ફ્લેટ / સભ્ય પસંદ કરો',
      'hi': 'फ्लैट / सदस्य चुनें',
      'en': 'Select Flat / Member',
    },
    'entry_time': {
      'gu': 'પ્રવેશ સમય',
      'hi': 'प्रवेश समय',
      'en': 'Entry Time',
    },
    'exit_time': {
      'gu': 'બહાર નીકળ્યા સમય',
      'hi': 'प्रस्थान समय',
      'en': 'Exit Time',
    },
    'allow_entry': {
      'gu': 'પ્રવેશ મંજૂરી આપો',
      'hi': 'प्रवेश की अनुमति दें',
      'en': 'Approve Entry',
    },
    'deny_entry': {
      'gu': 'પ્રવેશ નકારો',
      'hi': 'प्रवेश अस्वीकार करें',
      'en': 'Deny Entry',
    },

    // =============================================================
    // 6. Admin Dashboard & Operations
    // =============================================================
    'admin_total_flats': {
      'gu': 'કુલ ફ્લેટ્સ/યુનિટ્સ',
      'hi': 'कुल फ्लैट्स/यूनिट्स',
      'en': 'Total Flats/Units',
    },
    'admin_total_members': {
      'gu': 'કુલ સભ્યો',
      'hi': 'कुल सदस्य',
      'en': 'Total Members',
    },
    'admin_total_vehicles': {
      'gu': 'નોંધાયેલા વાહનો',
      'hi': 'पंजीकृत वाहन',
      'en': 'Registered Vehicles',
    },
    'admin_pending_complaints': {
      'gu': 'બાકી ફરિયાદો',
      'hi': 'लंबित शिकायतें',
      'en': 'Pending Complaints',
    },
    'admin_today_visitors': {
      'gu': 'આજના મુલાકાતીઓ',
      'hi': 'आज के आगंतुक',
      'en': 'Today\'s Visitors',
    },
    'admin_btn_add_member': {
      'gu': 'સભ્ય ઉમેરો',
      'hi': 'सदस्य जोड़ें',
      'en': 'Add Member',
    },
    'admin_btn_broadcast': {
      'gu': 'સંદેશ પ્રસારણ',
      'hi': 'संदेश प्रसारण',
      'en': 'Broadcast Notice',
    },
    'admin_btn_maintenance': {
      'gu': 'મેન્ટેનન્સ મેનેજમેન્ટ',
      'hi': 'मेंटेनेंस प्रबंधन',
      'en': 'Maintenance Mgmt',
    },
    'admin_btn_complaints': {
      'gu': 'ફરિયાદ નિવારણ',
      'hi': 'शिकायत निवारण',
      'en': 'Complaints Portal',
    },
    'admin_btn_visitors': {
      'gu': 'મુલાકાતી રિપોર્ટ',
      'hi': 'आगंतुक रिपोर्ट',
      'en': 'Visitor Reports',
    },
    'admin_btn_parking': {
      'gu': 'પાર્કિંગ કંટ્રોલ',
      'hi': 'पार्किंग नियंत्रण',
      'en': 'Parking Control',
    },
    'admin_btn_polls': {
      'gu': 'ડિજિટલ પોલિંગ',
      'hi': 'डिजिटल पोलिंग',
      'en': 'Digital Polling',
    },
    'admin_btn_amenities': {
      'gu': 'એમેનિટીઝ & હોલ',
      'hi': 'सुविधाएं और हॉल',
      'en': 'Amenities & Hall',
    },
    'admin_btn_patrol': {
      'gu': 'ગાર્ડ પેટ્રોલિંગ',
      'hi': 'गार्ड पेट्रोलिंग',
      'en': 'Guard Patrol',
    },
    'admin_btn_accounts': {
      'gu': 'સોસાયટી હિસાબ',
      'hi': 'સોસાયટી લેખા',
      'en': 'Society Accounts',
    },
    'admin_btn_setup_wizard': {
      'gu': 'સોસાયટી આર્કિટેક્ચર સેટઅપ',
      'hi': 'સોસાયટી આર્કિટેક્ચર સેટઅપ',
      'en': 'Architecture Setup',
    },

    // =============================================================
    // 7. Polls & Voting Module
    // =============================================================
    'polls_title': {
      'gu': 'સોસાયટી નિર્ણય મતદાન',
      'hi': 'सोसायटी निर्णय मतदान',
      'en': 'Society Decision Polls',
    },
    'polls_subtitle': {
      'gu': 'આપનો કિંમતી મત સોસાયટીના વિકાસ માટે',
      'hi': 'समाज के विकास के लिए आपका बहुमूल्य वोट',
      'en': 'Your valuable vote for society development',
    },
    'admin_polls_title': {
      'gu': 'સોસાયટી ડિજિટલ પોલિંગ',
      'hi': 'सोसायटी डिजिटल पोलिंग',
      'en': 'Society Digital Polling',
    },
    'admin_polls_subtitle': {
      'gu': 'પારદર્શક નિર્ણય & મતદાન કેન્દ્ર',
      'hi': 'पारदर्शी निर्णय एवं मतदान केंद्र',
      'en': 'Transparent Decisions & Polling Hub',
    },
    'active_polls': {
      'gu': 'સક્રિય પોલ (Active)',
      'hi': 'सक्रिय पोल (Active)',
      'en': 'Active Polls',
    },
    'active_polls_capsule': {
      'gu': 'સક્રિય પોલ',
      'hi': 'सक्रिय पोल',
      'en': 'Active Polls',
    },
    'past_decisions_capsule': {
      'gu': 'ભૂતકાળના નિર્ણયો',
      'hi': 'पुराने निर्णय',
      'en': 'Past Decisions',
    },
    'closed_polls': {
      'gu': 'પૂર્ણ / બંધ (Closed)',
      'hi': 'समाप्त / बंद (Closed)',
      'en': 'Closed Polls',
    },
    'create_poll': {
      'gu': 'નવો પોલ બનાવો',
      'hi': 'नया पोल बनाएं',
      'en': 'Create New Poll',
    },
    'create_poll_title': {
      'gu': 'પોલ વિષય / પ્રશ્ન',
      'hi': 'पोल विषय / प्रश्न',
      'en': 'Poll Question',
    },
    'poll_desc': {
      'gu': 'વિગતવાર વર્ણન (વૈકલ્પિક)',
      'hi': 'विस्तृत विवरण (वैकल्पिक)',
      'en': 'Detailed Description (Optional)',
    },
    'poll_options': {
      'gu': 'મતદાન વિકલ્પો',
      'hi': 'मतदान विकल्प',
      'en': 'Poll Options',
    },
    'add_option': {
      'gu': 'બીજો વિકલ્પ ઉમેરો',
      'hi': 'अन्य विकल्प जोड़ें',
      'en': 'Add Option',
    },
    'poll_category': {
      'gu': 'કેટેગરી પસંદ કરો',
      'hi': 'श्रेणी चुनें',
      'en': 'Select Category',
    },
    'target_audience': {
      'gu': 'મતદાન પાત્રતા / વિંગ લક્ષ્ય',
      'hi': 'मतदान पात्रता / विंग लक्ष्य',
      'en': 'Target Audience / Wing',
    },
    'all_society': {
      'gu': 'સમગ્ર સોસાયટી (All Wings)',
      'hi': 'पूरी सोसायटी (सभी विंग)',
      'en': 'All Society (All Wings)',
    },
    'specific_wing': {
      'gu': 'ચોક્કસ બ્લોક / વિંગ',
      'hi': 'विशिष्ट ब्लॉक / विंग',
      'en': 'Specific Block / Wing',
    },
    'expiry_date': {
      'gu': 'અંતિમ સમય (Expiry)',
      'hi': 'अंतिम समय (Expiry)',
      'en': 'Expiry Date & Time',
    },
    'publish_poll': {
      'gu': 'પોલ પ્રકાશિત કરો',
      'hi': 'पोल प्रकाशित करें',
      'en': 'Publish Poll',
    },
    'cast_vote': {
      'gu': 'આપનો મત આપો',
      'hi': 'अपना वोट दें',
      'en': 'Cast Your Vote',
    },
    'voted_successfully': {
      'gu': 'આપનો મત સફળતાપૂર્વક નોંધાઈ ગયો છે!',
      'hi': 'आपका वोट सफलतापूर्वक दर्ज हो गया है!',
      'en': 'Your vote has been cast successfully!',
    },
    'already_voted': {
      'gu': 'તમે આ પોલમાં મતદાન કરી દીધું છે',
      'hi': 'आप इस पोल में मतदान कर चुके हैं',
      'en': 'You have already voted in this poll',
    },
    'total_votes': {
      'gu': 'કુલ મતો',
      'hi': 'कुल वोट',
      'en': 'Total Votes',
    },
    'winner_option': {
      'gu': 'સૌથી વધુ મત મેળવનાર વિકલ્પ',
      'hi': 'सबसे अधिक वोट पाने वाला विकल्प',
      'en': 'Leading Option',
    },
    'confirm_vote_dialog': {
      'gu': 'શું તમે આ વિકલ્પ પર આપનો મત આપવા માંગો છો?',
      'hi': 'क्या आप इस विकल्प पर अपना वोट देना चाहते हैं?',
      'en': 'Do you want to confirm your vote for this option?',
    },
    'vote_recorded_live': {
      'gu': 'મતદાન રીયલ-ટાઇમ અપડેટ થશે',
      'hi': 'वोट रियल-टाइम अपडेट होगा',
      'en': 'Votes update in real-time',
    },
    'no_active_polls': {
      'gu': 'હાલમાં કોઈ સક્રિય પોલ ચાલુ નથી',
      'hi': 'वर्तमान में कोई सक्रिय पोल नहीं है',
      'en': 'No active polls at this time',
    },
    'no_closed_polls': {
      'gu': 'હજુ સુધી કોઈ પૂર્ણ થયેલ પોલ નથી',
      'hi': 'अभी तक कोई समाप्त पोल नहीं है',
      'en': 'No closed polls yet',
    },
    'poll_closed_badge': {
      'gu': 'પૂર્ણ થયેલ',
      'hi': 'समाप्त',
      'en': 'Closed',
    },
    'poll_active_badge': {
      'gu': 'ચાલુ',
      'hi': 'सक्रिय',
      'en': 'Active',
    },

    // =============================================================
    // 8. Amenities Module
    // =============================================================
    'amenities_title': {
      'gu': 'સોસાયટી ક્લબહાઉસ & સુવિધાઓ',
      'hi': 'सोसायटी क्लबहाउस और सुविधाएं',
      'en': 'Society Clubhouse & Amenities',
    },
    'amenities_subtitle': {
      'gu': 'સરળ & પારદર્શક ઓનલાઈન બુકિંગ',
      'hi': 'सरल और पारदर्शी ऑनलाइन बुकिंग',
      'en': 'Seamless & Transparent Booking',
    },
    'book_now': {
      'gu': 'હમણાં બુક કરો',
      'hi': 'अभी बुक करें',
      'en': 'Book Now',
    },
    'booking_history': {
      'gu': 'મારા બુકિંગ્સ',
      'hi': 'मेरी बुकिंग्स',
      'en': 'My Bookings',
    },
    'slots_available': {
      'gu': 'સ્લોટ્સ ઉપલબ્ધ',
      'hi': 'स्लॉट उपलब्ध',
      'en': 'Slots Available',
    },
    'status_pending': {
      'gu': 'મંજૂરી બાકી',
      'hi': 'स्वीकृति लंबित',
      'en': 'Pending Approval',
    },
    'status_approved': {
      'gu': 'મંજૂર થયેલ',
      'hi': 'स्वीकृत',
      'en': 'Approved',
    },
    'status_rejected': {
      'gu': 'અસ્વીકાર થયેલ',
      'hi': 'अस्वीकृत',
      'en': 'Rejected',
    },
    'status_cancelled': {
      'gu': 'રદ થયેલ',
      'hi': 'रद्द किया गया',
      'en': 'Cancelled',
    },
    'amenity_rules': {
      'gu': 'નિયમો & શરતો',
      'hi': 'नियम और शर्तें',
      'en': 'Rules & Guidelines',
    },

    // =============================================================
    // 9. Alerts, Toasts & Notifications
    // =============================================================
    'approval_granted': {
      'gu': 'મુલાકાતીને પ્રવેશ મંજૂરી અપાઈ.',
      'hi': 'आगंतुक को प्रवेश स्वीकृति दी गई।',
      'en': 'Visitor entry has been approved.',
    },
    'approval_denied': {
      'gu': 'મુલાકાતી પ્રવેશ નકારવામાં આવ્યો.',
      'hi': 'आगंतुक प्रवेश अस्वीकार किया गया।',
      'en': 'Visitor entry has been denied.',
    },
    'internet_error': {
      'gu': 'કૃપા કરીને આપનું ઇન્ટરનેટ કનેક્શન તપાસો.',
      'hi': 'कृपया अपना इंटरनेट कनेक्शन जांचें।',
      'en': 'Please check your internet connection.',
    },
    'try_again': {
      'gu': 'ફરી પ્રયાસ કરો',
      'hi': 'पुनः प्रयास करें',
      'en': 'Try Again',
    },
    'language_changed_toast': {
      'gu': 'ભાષા સફળતાપૂર્વક બદલાઈ ગઈ છે (ગુજરાતી)',
      'hi': 'भाषा सफलतापूर्वक बदल दी गई है (हिन्दी)',
      'en': 'Language changed to English',
    },

    // =============================================================
    // 10. Common Action Badges, Tags & Universal UI Elements
    // =============================================================
    'action_save': {'gu': 'સાચવો', 'hi': 'सहेजें', 'en': 'Save'},
    'action_cancel': {'gu': 'રદ કરો', 'hi': 'रद्द करें', 'en': 'Cancel'},
    'action_delete': {'gu': 'કાઢી નાખો', 'hi': 'हटाएं', 'en': 'Delete'},
    'action_edit': {'gu': 'ફેરફાર કરો', 'hi': 'संपादित करें', 'en': 'Edit'},
    'action_submit': {'gu': 'સબમિટ કરો', 'hi': 'जमा करें', 'en': 'Submit'},
    'action_close': {'gu': 'બંધ કરો', 'hi': 'बंद करें', 'en': 'Close'},
    'action_back': {'gu': 'પાછા જાઓ', 'hi': 'वापस जाएं', 'en': 'Back'},
    'action_view_all': {'gu': 'બધા જુઓ', 'hi': 'सभी देखें', 'en': 'View All'},
    'action_search': {'gu': 'શોધો', 'hi': 'खोजें', 'en': 'Search'},
    'label_members': {'gu': 'સભ્યો', 'hi': 'सदस्य', 'en': 'Members'},
    'label_member': {'gu': 'મેમ્બર', 'hi': 'सदस्य', 'en': 'Member'},
    'label_watchman': {'gu': 'વોચમેન', 'hi': 'वॉचमैन', 'en': 'Watchman'},
    'label_complaint': {'gu': 'ફરિયાદ', 'hi': 'शिकायत', 'en': 'Complaint'},
    'label_complaints': {'gu': 'ફરિયાદો', 'hi': 'शिकायतें', 'en': 'Complaints'},
    'label_maintenance': {'gu': 'મેન્ટેનન્સ', 'hi': 'मेंटेनेंस', 'en': 'Maintenance'},
    'label_vehicles': {'gu': 'વાહનો', 'hi': 'वाहन', 'en': 'Vehicles'},
    'label_visitors': {'gu': 'મુલાકાતીઓ', 'hi': 'आगंतुक', 'en': 'Visitors'},
    'action_logout': {'gu': 'લોગઆઉટ', 'hi': 'लॉगआउट', 'en': 'Logout'},
    'action_login': {'gu': 'લૉગિન કરો', 'hi': 'लॉगिन करें', 'en': 'Login'},
    'action_cast_vote': {'gu': 'આપનો મત આપો', 'hi': 'अपना वोट दें', 'en': 'Cast Vote'},
    'action_vote_now': {'gu': 'મત આપો', 'hi': 'वोट दें', 'en': 'Vote Now'},
    'action_book_now': {'gu': 'બુક કરો', 'hi': 'बुक करें', 'en': 'Book Now'},
    'action_view_accounts': {'gu': 'હિસાબ જુઓ', 'hi': 'लेखा देखें', 'en': 'View Accounts'},
    'action_view_patrol': {'gu': 'ટ્રેકિંગ જુઓ', 'hi': 'ट्रैकिंग देखें', 'en': 'View Patrol'},
    'scope_my_flat_btn': {'gu': 'મારા ફ્લેટ', 'hi': 'मेरा फ्लैट', 'en': 'My Flat'},
    'scope_all_society_btn': {'gu': 'સમગ્ર સોસાયટી', 'hi': 'पूरी सोसायटी', 'en': 'All Society'},
    'status_pending_badge': {'gu': 'પેન્ડિંગ', 'hi': 'लंबित', 'en': 'Pending'},
    'status_approved_badge': {'gu': 'મંજૂર', 'hi': 'स्वीकृत', 'en': 'Approved'},
    'status_rejected_badge': {'gu': 'અસ્વીકાર', 'hi': 'अस्वीकृत', 'en': 'Rejected'},
    'status_checked_out_badge': {'gu': 'બહાર ગયા', 'hi': 'प्रस्थान किया', 'en': 'Checked Out'},
    'status_inside_badge': {'gu': 'અંદર છે', 'hi': 'अंदर हैं', 'en': 'Inside'},
    'filter_today_btn': {'gu': 'આજે', 'hi': 'आज', 'en': 'Today'},
    'filter_seven_days_btn': {'gu': '૭ દિવસ', 'hi': '७ दिन', 'en': '7 Days'},
    'filter_thirty_days_btn': {'gu': '૩૦ દિવસ', 'hi': '३० दिन', 'en': '30 Days'},
    'label_total_count': {'gu': 'કુલ', 'hi': 'कुल', 'en': 'Total'},
    'action_view_details': {'gu': 'વિગતો જુઓ', 'hi': 'विवरण देखें', 'en': 'View Details'},

    // Screen Titles & Subtitles
    'screen_visitor_history_tracking': {
      'gu': 'વિઝિટર હિસ્ટ્રી & ટ્રેકિંગ',
      'hi': 'आगंतुक इतिहास और ट्रैकिंग',
      'en': 'Visitor History & Tracking',
    },
    'sub_gate_entry_exit_status': {
      'gu': 'ગેટ એન્ટ્રી, એક્ઝિટ અને લાઈવ સ્ટેટસ',
      'hi': 'गेट एंट्री, एग्जिट और लाइव स्टेटस',
      'en': 'Gate entry, exit and live status',
    },
    'screen_guest_pre_approval_pass': {
      'gu': 'મહેમાન પૂર્વ-મંજૂરી & પાસ',
      'hi': 'अतिथि पूर्व-स्वीकृति और पास',
      'en': 'Guest Pre-Approval & Pass',
    },
    'sub_digital_entry_qr_invitation': {
      'gu': 'QR ડિજિટલ એન્ટ્રી અને ગેસ્ટ ઇન્વિટેશન',
      'hi': 'QR डिजिटल एंट्री और गेस्ट आमंत्रण',
      'en': 'QR Digital Entry & Guest Invitation',
    },
    'screen_my_vehicles_parking_slot': {
      'gu': 'મારા વાહનો & પાર્કિંગ સ્લોટ',
      'hi': 'मेरे वाहन और पार्किंग स्लॉट',
      'en': 'My Vehicles & Parking Slots',
    },
    'sub_plate_slot_allotment_pass': {
      'gu': 'નંબર પ્લેટ, સ્લોટ એલોટમેન્ટ અને ડિજિટલ પાસ',
      'hi': 'नंबर प्लेट, स्लॉट आवंटन और डिजिटल पास',
      'en': 'Number plate, slot allotment and digital pass',
    },
    'screen_society_complaint_redressal': {
      'gu': 'સોસાયટી ફરિયાદ નિવારણ',
      'hi': 'सोसायटी शिकायत निवारण',
      'en': 'Society Complaint Redressal',
    },
    'sub_register_issue_track_status': {
      'gu': 'સમસ્યા નોંધાવો & સ્ટેટસ ટ્રેક કરો',
      'hi': 'समस्या दर्ज करें और स्थिति ट्रैक करें',
      'en': 'Register issue & track status',
    },
    'screen_society_accounts_fund': {
      'gu': 'સોસાયટી હિસાબ & ફંડ',
      'hi': 'सोसायटी हिसाब और फंड',
      'en': 'Society Accounts & Fund',
    },
    'sub_transparent_savings_expense_detail': {
      'gu': 'પારદર્શક તિજોરી બચત & ખર્ચ વિગત',
      'hi': 'पारदर्शी बचत व खर्च विवरण',
      'en': 'Transparent savings & expense details',
    },
    'screen_daily_staff_helpers': {
      'gu': 'કાયમી સ્ટાફ & હેલ્પર્સ',
      'hi': 'दैनिक कर्मचारी और सहायक',
      'en': 'Daily Staff & Helpers',
    },
    'sub_domestic_staff_gate_pass': {
      'gu': 'કામવાળા, ડ્રાઈવર & રસોઈયા ગેટ પાસ',
      'hi': 'सहायक, ड्राइवर और रसोइया गेट पास',
      'en': 'Maid, driver & cook gate pass',
    },
    'screen_amenities_hall_booking': {
      'gu': 'એમેનિટીઝ & હોલ બુકિંગ',
      'hi': 'सुविधाएं और हॉल बुकिंग',
      'en': 'Amenities & Hall Booking',
    },
    'sub_party_hall_amenities_booking': {
      'gu': 'વાડી, પાર્ટી હોલ & સુવિધાઓનું બુકિંગ',
      'hi': 'कम्युनिटी हॉल व सुविधाओं की बुकिंग',
      'en': 'Party hall & amenities booking',
    },
    'screen_maintenance_accounts': {
      'gu': 'મેન્ટેનન્સ & હિસાબ',
      'hi': 'मेंटेनेंस और हिसाब',
      'en': 'Maintenance & Accounts',
    },
    'screen_user_registration': {
      'gu': 'યુઝર રજીસ્ટ્રેશન',
      'hi': 'यूज़र पंजीकरण',
      'en': 'User Registration',
    },
    'sub_add_member_watchman_admin': {
      'gu': 'સોસાયટી મેમ્બર, વોચમેન અથવા એડમિન એડ કરો',
      'hi': 'सोसायटी सदस्य, वॉचमैन या एडमिन जोड़ें',
      'en': 'Add society member, watchman or admin',
    },
    'screen_add_new_block_wing': {
      'gu': 'નવો બ્લોક / વિંગ ઉમેરો',
      'hi': 'नया ब्लॉक / विंग जोड़ें',
      'en': 'Add New Block / Wing',
    },
    'sub_block_flat_structure': {
      'gu': 'બ્લોક & ફ્લેટ માળખું',
      'hi': 'ब्लॉक और फ्लैट संरचना',
      'en': 'Block & Flat Structure',
    },
    'screen_notice_board_circular': {
      'gu': 'નોટિસ બોર્ડ & પરિપત્ર',
      'hi': 'सूचना पट्ट व परिपत्र',
      'en': 'Notice Board & Circular',
    },
    'sub_send_notice_all_members': {
      'gu': 'તમામ સભ્યોને નોટિસ મોકલો',
      'hi': 'सभी सदस्यों को सूचना भेजें',
      'en': 'Send notice to all members',
    },
    'screen_visitor_report': {
      'gu': 'મુલાકાતી રિપોર્ટ',
      'hi': 'આગંતુક રિપોર્ટ',
      'en': 'Visitor Report',
    },
    'sub_gate_entry_history_analytics': {
      'gu': 'ગેટ એન્ટ્રી હિસ્ટ્રી & એનાલિટિક્સ',
      'hi': 'गेट एंट्री इतिहास और विश्लेषण',
      'en': 'Gate entry history & analytics',
    },
    'screen_watchman_patrol_tracking': {
      'gu': 'વોચમેન પેટ્રોલિંગ ટ્રેકિંગ',
      'hi': 'वॉचमैन पेट्रोलिंग ट्रैकिंग',
      'en': 'Watchman Patrol Tracking',
    },
    'sub_qr_checkpoint_night_round': {
      'gu': 'QR ચેકપોઇન્ટ સ્કેન & નાઇટ રાઉન્ડ',
      'hi': 'QR चेकपॉइंट स्कैन और नाइट राउंड',
      'en': 'QR Checkpoint scan & night round',
    },
    'screen_bank_account_settings': {
      'gu': 'બેંક ખાતા સેટિંગ્સ',
      'hi': 'बैंक खाता सेटिंग्स',
      'en': 'Bank Account Settings',
    },
    'sub_society_official_account_qr': {
      'gu': 'સોસાયટી ઓફિશિયલ એકાઉન્ટ & QR',
      'hi': 'सोसायटी आधिकारिक खाता और QR',
      'en': 'Society Official Account & QR',
    },
    'screen_member_signature_sheet': {
      'gu': 'સભ્ય સહી પત્રક',
      'hi': 'सदस्य हस्ताक्षर पत्रक',
      'en': 'Member Signature Sheet',
    },
    'sub_general_meeting_attendance_resolution': {
      'gu': 'જનરલ મીટિંગ હાજરી & ઠરાવ',
      'hi': 'जनरल मीटिंग उपस्थिति व प्रस्ताव',
      'en': 'General Meeting attendance & resolution',
    },
    'screen_members_directory': {
      'gu': 'સભ્યોની ડિરેક્ટરી',
      'hi': 'सदस्य निर्देशिका',
      'en': 'Members Directory',
    },
    'sub_all_members_staff_contacts': {
      'gu': 'તમામ સભ્યો & સ્ટાફ સંપર્ક',
      'hi': 'सभी सदस्य और कर्मचारी संपर्क',
      'en': 'All members & staff contacts',
    },
    'screen_watchman_management': {
      'gu': 'વોચમેન મેનેજમેન્ટ',
      'hi': 'वॉचमैन प्रबंधन',
      'en': 'Watchman Management',
    },
    'sub_security_guards_list_status': {
      'gu': 'સિક્યુરિટી ગાર્ડ્સ યાદી & સ્ટેટસ',
      'hi': 'सुरक्षा गार्ड सूची और स्थिति',
      'en': 'Security guards list & status',
    },
    'screen_emergency_helpline_numbers': {
      'gu': 'ઇમરજન્સી હેલ્પલાઇન નંબરો',
      'hi': 'आपातकालीन हेल्पलाइन नंबर',
      'en': 'Emergency Helpline Numbers',
    },
    'sub_police_fire_ambulance_doctor': {
      'gu': 'પોલીસ, ફાયર, એમ્બ્યુલન્સ અને ડોક્ટર',
      'hi': 'पुलिस, फायर, एम्बुलेंस और डॉक्टर',
      'en': 'Police, Fire, Ambulance & Doctor',
    },
    'screen_parking_slot_management': {
      'gu': 'પાર્કિંગ સ્લોટ મેનેજમેન્ટ',
      'hi': 'पार्किंग स्लॉट प्रबंधन',
      'en': 'Parking Slot Management',
    },
    'sub_society_parking_allocation': {
      'gu': 'સોસાયટી પાર્કિંગ એલોકેશન',
      'hi': 'सोसायटी पार्किंग आवंटन',
      'en': 'Society parking allocation',
    },
    'screen_security_guard_patrol': {
      'gu': 'સિક્યુરિટી ગાર્ડ પેટ્રોલિંગ',
      'hi': 'सुरक्षा गार्ड पेट्रोलिंग',
      'en': 'Security Guard Patrol',
    },
    'sub_qr_code_scanning_route_check': {
      'gu': 'QR કોડ સ્કેનિંગ & રૂટ ચેક',
      'hi': 'QR कोड स्कैनिंग और रूट चेक',
      'en': 'QR code scanning & route check',
    },
    'header_gate_control': {
      'gu': 'ગેટ કન્ટ્રોલ',
      'hi': 'गेट नियंत्रण',
      'en': 'Gate Control',
    },

    // Tabs and Segments
    'tab_new_entry_full': {
      'gu': 'નવી એન્ટ્રી (New Entry)',
      'hi': 'नई एंट्री (New Entry)',
      'en': 'New Entry',
    },
    'tab_visitor_logs_full': {
      'gu': 'મુલાકાત હિસ્ટ્રી (Logs)',
      'hi': 'आगंतुक इतिहास (Logs)',
      'en': 'Visitor Logs',
    },
    'tab_vehicle_search_full': {
      'gu': 'વાહન સર્ચ (Vehicle Search)',
      'hi': 'वाहन खोज (Vehicle Search)',
      'en': 'Vehicle Search',
    },
    'tab_emergency_and_staff': {
      'gu': 'ઈમરજન્સી & સ્ટાફ',
      'hi': 'आपातकाल व स्टाफ',
      'en': 'Emergency & Staff',
    },
    'tab_emergency_sos_alert': {
      'gu': 'ઇમરજન્સી SOS એલર્ટ',
      'hi': 'आपातकालीन SOS अलर्ट',
      'en': 'Emergency SOS Alert',
    },
    'tab_new_entry_short': {
      'gu': 'નવી એન્ટ્રી',
      'hi': 'नई एंट्री',
      'en': 'New Entry',
    },
    'tab_visitor_history_short': {
      'gu': 'મુલાકાત હિસ્ટ્રી',
      'hi': 'आगंतुक इतिहास',
      'en': 'Visitor History',
    },
    'tab_amenities_icon_header': {
      'gu': '🏛️ સુવિધાઓ (Amenities)',
      'hi': '🏛️ सुविधाएं (Amenities)',
      'en': '🏛️ Amenities',
    },
    'tab_my_bookings_icon_header': {
      'gu': '🎫 મારાં બુકિંગ્સ (My Bookings)',
      'hi': '🎫 मेरी बुकिंग्स (My Bookings)',
      'en': '🎫 My Bookings',
    },
    'tab_my_complaints': {
      'gu': 'મારી ફરિયાદો',
      'hi': 'मेरी शिकायतें',
      'en': 'My Complaints',
    },
    'tab_register_new_complaint': {
      'gu': 'નવી ફરિયાદ નોંધાવો',
      'hi': 'नई शिकायत दर्ज करें',
      'en': 'Register New Complaint',
    },
    'tab_my_vehicles': {
      'gu': 'મારા વાહનો',
      'hi': 'मेरे वाहन',
      'en': 'My Vehicles',
    },
    'tab_add_new_vehicle': {
      'gu': 'નવું વાહન ઉમેરો',
      'hi': 'नया वाहन जोड़ें',
      'en': 'Add New Vehicle',
    },
    'tab_my_flat_plural': {
      'gu': 'મારા ફ્લેટના',
      'hi': 'मेरे फ्लैट के',
      'en': 'My Flat',
    },
    'tab_all_society_plural': {
      'gu': 'સમગ્ર સોસાયટીના',
      'hi': 'पूरी सोसायटी के',
      'en': 'All Society',
    },

    // Form inputs and prompts
    'form_visitor_details_card': {
      'gu': 'મુલાકાતીની વિગત (Visitor Details)',
      'hi': 'आगंतुक विवरण (Visitor Details)',
      'en': 'Visitor Details',
    },
    'field_visitor_full_name': {
      'gu': 'મુલાકાતીનું પૂરું નામ',
      'hi': 'आगंतुक का पूरा नाम',
      'en': 'Visitor Full Name',
    },
    'field_mobile_number': {
      'gu': 'મોબાઇલ નંબર',
      'hi': 'मोबाइल नंबर',
      'en': 'Mobile Number',
    },
    'field_vehicle_number_opt': {
      'gu': 'વાહન નંબર (જો હોય તો)',
      'hi': 'वाहन नंबर (यदि हो तो)',
      'en': 'Vehicle Number (if any)',
    },
    'field_visit_purpose': {
      'gu': 'મુલાકાતનો હેતુ',
      'hi': 'मुलाकात का उद्देश्य',
      'en': 'Purpose of Visit',
    },
    'field_flat_number_block': {
      'gu': 'ફ્લેટ નંબર / બ્લોક',
      'hi': 'फ्लैट नंबर / ब्लॉक',
      'en': 'Flat / Unit & Block',
    },
    'btn_request_approval_full': {
      'gu': 'પરવાનગી મોકલો (Request Approval)',
      'hi': 'स्वीकृति भेजें (Request Approval)',
      'en': 'Request Approval',
    },
    'btn_direct_entry_full': {
      'gu': 'સીધો પ્રવેશ આપો (Direct Entry)',
      'hi': 'सीधा प्रवेश दें (Direct Entry)',
      'en': 'Direct Entry',
    },
    'header_security_visitor_register': {
      'gu': 'સિક્યુરિટી વિઝિટર રજિસ્ટર',
      'hi': 'सुरक्षा आगंतुक रजिस्टर',
      'en': 'Security Visitor Register',
    },
    'sub_live_security_gate': {
      'gu': 'લાઇવ સિક્યુરિટી ગેટ',
      'hi': 'लाइव सुरक्षा गेट',
      'en': 'Live Security Gate',
    },
    'hint_search_visitor': {
      'gu': 'નામ, ફોન, હેતુ કે ફ્લેટ નંબર શોધો...',
      'hi': 'नाम, फोन, उद्देश्य या फ्लैट खोजें...',
      'en': 'Search name, phone, purpose or flat...',
    },
    'empty_no_visitors_found': {
      'gu': 'કોઈ મુલાકાતી મળ્યા નથી',
      'hi': 'कोई आगंतुक नहीं मिला',
      'en': 'No visitors found',
    },
    'header_add_vehicle_assign_slot': {
      'gu': 'નવું વાહન ઉમેરો & સ્લોટ ફાળવો',
      'hi': 'नया वाहन जोड़ें और स्लॉट आवंटित करें',
      'en': 'Add New Vehicle & Assign Slot',
    },
    'type_two_wheeler': {
      'gu': 'ટુ-વ્હીલર',
      'hi': 'दोपहिया (2 Wheeler)',
      'en': 'Two-Wheeler',
    },
    'type_four_wheeler': {
      'gu': 'ફોર-વ્હીલર',
      'hi': 'चार पहिया (4 Wheeler)',
      'en': 'Four-Wheeler',
    },
    'type_bicycle': {
      'gu': 'સાયકલ',
      'hi': 'साइकिल',
      'en': 'Bicycle',
    },
    'type_other_vehicle': {
      'gu': 'અન્ય વાહન',
      'hi': 'अन्य वाहन',
      'en': 'Other Vehicle',
    },
    'field_vehicle_number': {
      'gu': 'વાહન નંબર',
      'hi': 'वाहन नंबर',
      'en': 'Vehicle Number',
    },
    'field_vehicle_model_name': {
      'gu': 'વાહનનું મોડેલ / નામ',
      'hi': 'वाहन का मॉडल / नाम',
      'en': 'Vehicle Model / Name',
    },
    'field_parking_slot': {
      'gu': 'પાર્કિંગ સ્લોટ',
      'hi': 'पार्किंग स्लॉट',
      'en': 'Parking Slot',
    },
    'header_registered_vehicles': {
      'gu': 'રજીસ્ટર્ડ વાહનો',
      'hi': 'पंजीकृत वाहन',
      'en': 'Registered Vehicles',
    },
    'empty_no_vehicles_registered': {
      'gu': 'કોઈ વાહન રજીસ્ટર નથી',
      'hi': 'कोई वाहन पंजीकृत नहीं है',
      'en': 'No vehicles registered',
    },
    'btn_generate_bulk_bills': {
      'gu': 'બલ્ક બિલ જનરેટ',
      'hi': 'थोक बिल जनरेट',
      'en': 'Generate Bulk Bills',
    },
    'header_society_payment_qr': {
      'gu': 'સોસાયટી પેમેન્ટ QR',
      'hi': 'सोसायटी भुगतान QR',
      'en': 'Society Payment QR',
    },
    'header_upi_settings': {
      'gu': 'UPI સેટિંગ્સ',
      'hi': 'UPI सेटिंग्स',
      'en': 'UPI Settings',
    },
    'btn_send_due_reminder': {
      'gu': 'ડ્યુ રીમાઇન્ડર મોકલો',
      'hi': 'बकाया अनुस्मारक भेजें',
      'en': 'Send Due Reminder',
    },
    'btn_view_pdf_statement': {
      'gu': 'PDF હિસાબ જુઓ',
      'hi': 'PDF लेखा देखें',
      'en': 'View PDF Statement',
    },
    'header_account_statement_pdf': {
      'gu': 'હિસાબ સ્ટેટમેન્ટ PDF',
      'hi': 'लेखा विवरण PDF',
      'en': 'Account Statement PDF',
    },
    'btn_send_broadcast_notice': {
      'gu': 'બ્રોડકાસ્ટ નોટિસ મોકલો',
      'hi': 'प्रसारण सूचना भेजें',
      'en': 'Send Broadcast Notice',
    },
    'btn_create_new_poll': {
      'gu': 'નવો પોલ બનાવો',
      'hi': 'नया पोल बनाएं',
      'en': 'Create New Poll',
    },
    'header_poll_details': {
      'gu': 'મતદાન વિગતો',
      'hi': 'મતદાન વિવરણ',
      'en': 'Poll Details',
    },
    'field_full_address': {
      'gu': 'સંપૂર્ણ સરનામું',
      'hi': 'पूरा पता',
      'en': 'Full Address',
    },
    'field_emergency_contact': {
      'gu': 'ઇમરજન્સી કોન્ટેક્ટ',
      'hi': 'आपातकालीन संपर्क',
      'en': 'Emergency Contact',
    },
    'purpose_relative_family': {
      'gu': '👪 સગા-સંબંધી',
      'hi': '👪 रिश्तेदार व परिवार',
      'en': '👪 Relative / Family',
    },
    'purpose_delivery_courier': {
      'gu': '📦 ડિલિવરી / કુરિયર',
      'hi': '📦 डिलीवरी / कूरियर',
      'en': '📦 Delivery / Courier',
    },
    'purpose_cab_driver': {
      'gu': '🚗 કેબ / ડ્રાઈવર',
      'hi': '🚗 कैब / ड्राइवर',
      'en': '🚗 Cab / Driver',
    },
    'purpose_service_repair': {
      'gu': '🔧 સર્વિસ / રિપેર',
      'hi': '🔧 सर्विस / मरम्मत',
      'en': '🔧 Service / Repair',
    },
    'purpose_friend_visitor': {
      'gu': '🤝 મિત્ર / મુલાકાતી',
      'hi': '🤝 मित्र / आगंतुक',
      'en': '🤝 Friend / Visitor',
    },
    'header_society_services_suspended': {
      'gu': 'સોસાયટી સેવાઓ અસ્થાયી સ્થગિત છે',
      'hi': 'सोसायटी सेवाएं अस्थायी रूप से निलंबित हैं',
      'en': 'Society services are temporarily suspended',
    },
    'label_contact_info': {
      'gu': 'સંપર્ક માહિતી:',
      'hi': 'संपर्क जानकारी:',
      'en': 'Contact Information:',
    },
    'header_add_new_block_floor': {
      'gu': 'નવો બ્લોક / ફ્લોર ઉમેરો',
      'hi': 'नया ब्लॉक / मंजिल जोड़ें',
      'en': 'Add New Block / Floor',
    },
    'header_digital_notice_board': {
      'gu': 'ડિજિટલ નોટિસ બોર્ડ',
      'hi': 'डिजिटल नोटिस बोर्ड',
      'en': 'Digital Notice Board',
    },
    'sub_society_circular_announcements': {
      'gu': 'સોસાયટી પરિપત્ર અને સભાઓની જાહેરાત',
      'hi': 'सोसायटी परिपत्र और बैठकों की घोषणा',
      'en': 'Society circulars and meeting announcements',
    },
    'header_visitor_report_register': {
      'gu': 'વિઝિટર રિપોર્ટ & રજીસ્ટર',
      'hi': 'आगंतुक रिपोर्ट और रजिस्टर',
      'en': 'Visitor Report & Register',
    },
    'sub_visitor_entry_exit_approval_details': {
      'gu': 'મુલાકાતી એન્ટ્રી, એક્ઝિટ અને મંજૂરી વિગત',
      'hi': 'आगंतुक प्रवेश, निकास और स्वीकृति विवरण',
      'en': 'Visitor entry, exit and approval details',
    },
    'header_security_night_patrol_audit': {
      'gu': 'સુરક્ષા નાઈટ પેટ્રોલિંગ ઓડિટ',
      'hi': 'सुरक्षा नाइट पेट्रोलिंग ऑडिट',
      'en': 'Security Night Patrol Audit',
    },
    'sub_watchman_qr_night_security_report': {
      'gu': 'વોચમેન QR સ્કેન અને રાત્રિ સુરક્ષા રિપોર્ટ',
      'hi': 'वॉचमैन QR स्कैन और रात्रि सुरक्षा रिपोर्ट',
      'en': 'Watchman QR scan and night security report',
    },
    'header_patrol_guidelines': {
      'gu': 'પેટ્રોલિંગ માર્ગદર્શિકા',
      'hi': 'पेट्रोलिंग दिशानिर्देश',
      'en': 'Patrol Guidelines',
    },
    'header_society_bank_upi_settings': {
      'gu': 'સોસાયટી બેંક & UPI સેટિંગ્સ',
      'hi': 'सोसायटी बैंक और UPI सेटिंग्स',
      'en': 'Society Bank & UPI Settings',
    },
    'header_night_security_patrol': {
      'gu': 'રાત્રિ સુરક્ષા પેટ્રોલિંગ',
      'hi': 'रात्रि सुरक्षा पेट्रोलिंग',
      'en': 'Night Security Patrol',
    },
    'sub_checkpoint_qr_round_manager': {
      'gu': 'ચેકપોઇન્ટ QR સ્કેન અને રાઉન્ડ મેનેજર',
      'hi': 'चेकपॉइंट QR स्कैन और राउंड मैनेजर',
      'en': 'Checkpoint QR scan and round manager',
    },
    'btn_guide': {
      'gu': 'માર્ગદર્શિકા',
      'hi': 'मार्गदर्शिका',
      'en': 'Guide',
    },

    // Additional Screens & Operations (English Keys)
    'screen_admin_accounts': {
      'gu': 'સોસાયટી હિસાબ & ખર્ચ',
      'hi': 'सोसायटी हिसाब और खर्च',
      'en': 'Society Accounts & Expense',
    },
    'sub_admin_accounts': {
      'gu': 'તિજોરી ફંડ, આવક & ખર્ચ વ્યવસ્થાપન',
      'hi': 'कोषागार फंड, आय व खर्च प्रबंधन',
      'en': 'Treasury fund, income & expense management',
    },
    'btn_add_expense': {
      'gu': 'નવો ખર્ચ ઉમેરો',
      'hi': 'नया खर्च जोड़ें',
      'en': 'Add New Expense',
    },
    'screen_emergency_directory': {
      'gu': 'ઈમરજન્સી હેલ્પલાઇન ડિરેક્ટરી',
      'hi': 'आपातकालीन हेल्पलाइन निर्देशिका',
      'en': 'Emergency Helpline Directory',
    },
    'sub_emergency_directory': {
      'gu': 'પોલીસ, ૧૦૮, ફાયર અને તાત્કાલિક સેવાઓ',
      'hi': 'पुलिस, १०८, फायर और आपात सेवाएं',
      'en': 'Police, 108, Fire & emergency services',
    },
    'preset_police': {
      'gu': 'પોલીસ',
      'hi': 'पुलिस',
      'en': 'Police',
    },
    'preset_ambulance': {
      'gu': 'એમ્બ્યુલન્સ',
      'hi': 'एम्बुलेंस',
      'en': 'Ambulance',
    },
    'preset_fire_brigade': {
      'gu': 'ફાયર બ્રિગેડ',
      'hi': 'फायर ब्रिगेड',
      'en': 'Fire Brigade',
    },
    'preset_electrician': {
      'gu': 'ઇલેક્ટ્રિશિયન',
      'hi': 'इलेक्ट्रीशियन',
      'en': 'Electrician',
    },
    'preset_plumber': {
      'gu': 'પ્લમ્બર',
      'hi': 'प्लम्बर',
      'en': 'Plumber',
    },
    'preset_lift_service': {
      'gu': 'લિફ્ટ સર્વિસ',
      'hi': 'लिफ्ट सर्विस',
      'en': 'Lift Service',
    },
    'screen_admin_users': {
      'gu': 'સોસાયટી સભ્યો & સ્ટાફ',
      'hi': 'सोसायटी सदस्य और कर्मचारी',
      'en': 'Society Members & Staff',
    },
    'sub_admin_users': {
      'gu': 'મેમ્બર, વોચમેન અને એડમિન ડિરેક્ટરી',
      'hi': 'सदस्य, वॉचमैन और एडमिन निर्देशिका',
      'en': 'Member, watchman & admin directory',
    },
    'btn_add_user': {
      'gu': 'નવો યુઝર ઉમેરો',
      'hi': 'नया यूज़र जोड़ें',
      'en': 'Add New User',
    },
    'screen_admin_watchmen': {
      'gu': 'વોચમેન સિક્યોરિટી મેનેજમેન્ટ',
      'hi': 'वॉचमैन सुरक्षा प्रबंधन',
      'en': 'Watchmen Security Management',
    },
    'sub_admin_watchmen': {
      'gu': 'ગેટ ગાર્ડ્સ, ઓન-ડ્યુટી સ્ટેટસ & પિન કંટ્રોલ',
      'hi': 'गेट गार्ड्स, ऑन-ड्यूटी स्थिति व पिन नियंत्रण',
      'en': 'Gate guards, on-duty status & PIN control',
    },
    'btn_add_watchman': {
      'gu': 'નવો વોચમેન ઉમેરો',
      'hi': 'नया वॉचमैन जोड़ें',
      'en': 'Add New Watchman',
    },
    'screen_admin_complaints': {
      'gu': 'ફરિયાદ નિવારણ ડેસ્ક',
      'hi': 'शिकायत निवारण डेस्क',
      'en': 'Complaints Redressal Desk',
    },
    'sub_admin_complaints': {
      'gu': 'સભ્યોની સમસ્યાઓ અને રિઝોલ્યુશન સ્ટેટસ',
      'hi': 'सदस्यों की समस्याएं और निवारण स्थिति',
      'en': 'Member issues and resolution status',
    },
    'screen_member_signature_generator': {
      'gu': 'સભ્ય સહી પત્રક જનરેટર',
      'hi': 'सदस्य हस्ताक्षर पत्रक जनरेटर',
      'en': 'Member Signature Sheet Generator',
    },
    'sub_member_signature_generator': {
      'gu': 'વિષય & સહી કોલમ સાથે વિંગ-વાઇઝ PDF એક્સપોર્ટ',
      'hi': 'विषय व हस्ताक्षर कॉलम के साथ विंग-वार PDF निर्यात',
      'en': 'Wing-wise PDF export with resolution & sign columns',
    },
    'screen_live_broadcast': {
      'gu': 'લાઈવ બ્રોડકાસ્ટ',
      'hi': 'लाइव प्रसारण',
      'en': 'Live Broadcast',
    },
    'screen_personal_notice': {
      'gu': 'વ્યક્તિગત સૂચના',
      'hi': 'व्यक्तिगत सूचना',
      'en': 'Personal Notice',
    },
    'sub_broadcast_all_members': {
      'gu': 'સોસાયટીના તમામ સભ્યોને પુશ નોટિફિકેશન',
      'hi': 'सोसायटी के सभी सदस्यों को पुश सूचना',
      'en': 'Push notification to all society members',
    },
    'super_admin_live_engine': {
      'gu': 'LIVE ENGINE • કમાન્ડ સેન્ટર',
      'hi': 'LIVE ENGINE • कमांड सेंटर',
      'en': 'LIVE ENGINE • Command Center',
    },
    'tooltip_refresh_data': {
      'gu': 'ડેટા રિફ્રેશ કરો',
      'hi': 'डेटा रिफ्रेश करें',
      'en': 'Refresh Data',
    },
    'header_new_co_super_admin': {
      'gu': 'નવા કો-સુપર એડમિન',
      'hi': 'नया सह-सुपर एडमिन',
      'en': 'New Co-Super Admin',
    },
    'sub_super_admin_command_delegation': {
      'gu': 'Super Admin Command Center • સત્તા સોંપણી',
      'hi': 'Super Admin Command Center • अधिकार सौंपना',
      'en': 'Super Admin Command Center • Delegation',
    },
    'label_full_command_authority_warning': {
      'gu': 'સંપૂર્ણ કમાન્ડ અધિકાર ચેતવણી',
      'hi': 'पूर्ण कमांड अधिकार चेतावनी',
      'en': 'Full Command Authority Warning',
    },
    'desc_co_super_admin_warning': {
      'gu': 'કો-સુપર એડમિન પાસે તમામ સોસાયટીઓ, આર્થિક હિસાબો, સભ્યો અને ગ્લોબલ કિલ-સ્વિચનું પૂર્ણ નિયંત્રણ હશે. માત્ર વિશ્વાસુ વ્યક્તિને જ આ રોલ આપો.',
      'hi': 'सह-सुपर एडमिन के पास सभी सोसायटियों, वित्तीय खातों, सदस्यों और ग्लोबल किल-स्विच का पूर्ण नियंत्रण होगा। केवल विश्वसनीय व्यक्ति को ही यह भूमिका दें।',
      'en': 'Co-super admin will have full control over all societies, financial accounts, members and global kill-switch. Assign this role only to trusted individuals.',
    },
    'btn_grant_super_admin_authority': {
      'gu': 'સુપર એડમિન સત્તા આપો',
      'hi': 'सुपर एडमिन अधिकार प्रदान करें',
      'en': 'Grant Super Admin Access',
    },
    'header_onboard_new_society': {
      'gu': 'નવી સોસાયટી ઓનબોર્ડ',
      'hi': 'नई सोसायटी ऑनबोर्ड करें',
      'en': 'Onboard New Society',
    },
    'sub_premise_registration_first_admin': {
      'gu': 'પરિસર રજીસ્ટ્રેશન અને પ્રથમ એડમિન ક્રિએશન',
      'hi': 'परिसर पंजीकरण और पहला व्यवस्थापक निर्माण',
      'en': 'Premises registration and first admin creation',
    },
    'header_instant_cloud_sync': {
      'gu': 'ઇન્સ્ટન્ટ ક્લાઉડ સિંક',
      'hi': 'त्वरित क्लाउड सिंक',
      'en': 'Instant Cloud Sync',
    },
    'desc_instant_cloud_sync': {
      'gu': 'ઓનબોર્ડ થતાં જ સોસાયટી લાઈવ થઈ જશે અને એડમિન આપેલા પાસવર્ડથી સીધા લોગિન થઈ શકશે.',
      'hi': 'ऑनबोर्ड होते ही सोसायटी लाइव हो जाएगी और एडमिन दिए गए पासवर्ड से सीधे लॉगिन कर सकेंगे।',
      'en': 'Upon onboarding, society will go live instantly and the admin can log in directly using the provided credentials.',
    },
    'btn_onboard_society_and_create_admin': {
      'gu': 'સોસાયટી ઓનબોર્ડ & એડમિન બનાવો',
      'hi': 'सोसायटी ऑनबोर्ड करें और एडमिन बनाएं',
      'en': 'Onboard Society & Create Admin',
    },
    'header_global_system_broadcast': {
      'gu': 'ગ્લોબલ સિસ્ટમ બ્રોડકાસ્ટ',
      'hi': 'ग्लोबल सिस्टम ब्रॉडकास्ट',
      'en': 'Global System Broadcast',
    },
    'sub_global_system_broadcast': {
      'gu': 'તમામ સોસાયટી અને સભ્યો સુધી ઓફિશિયલ નોટિસ મોકલો',
      'hi': 'सभी सोसायटियों और सदस्यों तक आधिकारिक नोटिस भेजें',
      'en': 'Send official notices to all societies and members',
    },
    'header_appeal_review_decision': {
      'gu': 'અપીલ રિવ્યુ & નિર્ણય',
      'hi': 'अपील समीक्षा एवं निर्णय',
      'en': 'Appeal Review & Decision',
    },
    'sub_super_admin_control_center': {
      'gu': 'સુપર એડમિન કંટ્રોલ સેન્ટર',
      'hi': 'सुपर एडमिन कंट्रोल सेंटर',
      'en': 'Super Admin Control Center',
    },
    'header_admin_service_suspended': {
      'gu': 'સોસાયટી એડમિન સેવા સ્થગિત છે',
      'hi': 'सोसायटी एडमिन सेवा निलंबित है',
      'en': 'Society admin service is suspended',
    },
    'sub_admin_service_frozen': {
      'gu': 'સુપર એડમિન / હેડ ઓફિસ દ્વારા આ પરિસરની કામગીરી અસ્થાયી રૂપે નિષ્ક્રિય (Freeze) કરવામાં આવી છે.',
      'hi': 'सुपर एडमिन / मुख्य कार्यालय द्वारा इस परिसर का संचालन अस्थायी रूप से निष्क्रिय (Freeze) कर दिया गया है।',
      'en': 'Operations for this premises have been temporarily suspended/frozen by Super Admin / Head Office.',
    },
    'expense_category_watchman_salary': {
      'gu': 'સિક્યોરિટી / વોચમેન પગાર',
      'hi': 'सुरक्षा / चौकीदार वेतन',
      'en': 'Watchman / Security Salary',
    },
    'expense_category_cleaning_staff': {
      'gu': 'સફાઈ કર્મચારી ખર્ચ',
      'hi': 'सफाई कर्मचारी खर्च',
      'en': 'Cleaning & Housekeeping',
    },
    'expense_category_electricity_common': {
      'gu': 'સામાન્ય લાઈટ બિલ (કોમન)',
      'hi': 'कॉमन बिजली बिल',
      'en': 'Common Electricity Bill',
    },
    'expense_category_lift_amc': {
      'gu': 'લિફ્ટ AMC & સર્વિસ',
      'hi': 'लिफ्ट एएमसी और सर्विस',
      'en': 'Lift Maintenance / AMC',
    },
    'expense_category_water_borewell': {
      'gu': 'પાણી & બોરવેલ ખર્ચ',
      'hi': 'पानी और बोरवेल खर्च',
      'en': 'Water Supply & Borewell',
    },
    'expense_category_festival_celebration': {
      'gu': 'તહેવાર ઉજવણી ખર્ચ',
      'hi': 'त्योहार उत्सव खर्च',
      'en': 'Festival & Celebrations',
    },
    'expense_category_repairs_maintenance': {
      'gu': 'રિપેરિંગ, કલર & પ્લમ્બિંગ',
      'hi': 'मरम्मत, पेंट और प्लंबिंग',
      'en': 'Repairs & Renovation',
    },
    'expense_category_gardening': {
      'gu': 'બગીચો / માળી ખર્ચ',
      'hi': 'बगीचा / माली खर्च',
      'en': 'Gardening & Landscape',
    },
    'expense_category_cctv_security': {
      'gu': 'CCTV & ગેટ સિક્યોરિટી',
      'hi': 'सीसीटीवी और गेट सुरक्षा',
      'en': 'CCTV & Security Hardware',
    },
    'expense_category_other': {
      'gu': 'અન્ય પરચુરણ ખર્ચ',
      'hi': 'अन्य विविध खर्च',
      'en': 'Miscellaneous / Other',
    },
    'expense_filter_all': {
      'gu': 'બધા ખર્ચ',
      'hi': 'सभी खर्च',
      'en': 'All Expenses',
    },
    'expense_treasury_fund_savings': {
      'gu': 'સોસાયટી તિજોરી ફંડ & બચત',
      'hi': 'सोसायटी खजाना फंड और बचत',
      'en': 'Society Treasury Fund & Savings',
    },
    'expense_current_balance': {
      'gu': 'વર્તમાન ચોખ્ખી બચત (Current Balance)',
      'hi': 'वर्तमान शुद्ध बचत (Current Balance)',
      'en': 'Current Net Balance',
    },
    'expense_total_income': {
      'gu': 'કુલ જમા આવક',
      'hi': 'कुल जमा आय',
      'en': 'Total Credit Income',
    },
    'expense_total_expenses': {
      'gu': 'કુલ થયેલ ખર્ચ',
      'hi': 'कुल किया गया खर्च',
      'en': 'Total Expenses Incurred',
    },
    'expense_add_entry': {
      'gu': 'નવો ખર્ચ નોંધો',
      'hi': 'नया खर्च दर्ज करें',
      'en': 'Record New Expense',
    },
    'expense_pdf_statement': {
      'gu': 'હિસાબ સ્ટેટમેન્ટ PDF',
      'hi': 'खाता विवरण पीडीएफ',
      'en': 'Accounts Statement PDF',
    },
    'expense_category_filter': {
      'gu': 'કેટેગરી મુજબ ખર્ચ ફિલ્ટર',
      'hi': 'श्रेणी अनुसार खर्च फ़िल्टर',
      'en': 'Filter Expenses by Category',
    },
    'expense_all_premises': {
      'gu': 'સમગ્ર પરિસર (All)',
      'hi': 'संपूर्ण परिसर (सभी)',
      'en': 'Entire Premises (All)',
    },
    'header_public_financial_accounts': {
      'gu': 'સોસાયટી જાહેર નાણાકીય હિસાબ',
      'hi': 'सोसायटी सार्वजनिक वित्तीय खाता',
      'en': 'Society Public Financial Accounts',
    },
    'label_society_treasury_fund': {
      'gu': 'સોસાયટીની કુલ બચત (Treasury Fund)',
      'hi': 'सोसायटी की कुल बचत (Treasury Fund)',
      'en': 'Total Society Savings (Treasury Fund)',
    },
    'label_total_maintenance_collected': {
      'gu': 'કુલ મેન્ટેનન્સ જમા',
      'hi': 'कुल मेंटेनेंस जमा',
      'en': 'Total Maintenance Collected',
    },
    'header_detailed_expense_ledger': {
      'gu': 'વિગતવાર ખર્ચ યાદી (Ledger)',
      'hi': 'विस्तृत खर्च सूची (लेज़र)',
      'en': 'Detailed Expense List (Ledger)',
    },
    'dialog_logout_confirmation_title': {
      'gu': 'લૉગઆઉટ કન્ફર્મેશન',
      'hi': 'लॉगआउट पुष्टि',
      'en': 'Logout Confirmation',
    },
    'dialog_session_securely_ended': {
      'gu': 'તમારું સત્ર સુરક્ષિત રીતે સમાપ્ત થશે',
      'hi': 'आपका सत्र सुरक्षित रूप से समाप्त हो जाएगा',
      'en': 'Your session will be securely ended',
    },
    'btn_no_cancel': {
      'gu': 'ના, રદ કરો',
      'hi': 'नहीं, रद्द करें',
      'en': 'No, Cancel',
    },
    'btn_yes_proceed': {
      'gu': 'હા, આગળ વધો',
      'hi': 'हाँ, आगे बढ़ें',
      'en': 'Yes, Proceed',
    },
    'btn_yes_logout': {
      'gu': 'હા, લૉગઆઉટ',
      'hi': 'हाँ, लॉगआउट',
      'en': 'Yes, Logout',
    },
    'label_view_all': {
      'gu': 'બધા જુઓ',
      'hi': 'सभी देखें',
      'en': 'View All',
    },
    'label_recent_members': {
      'gu': 'તાજેતરના સભ્યો',
      'hi': 'हाल के सदस्य',
      'en': 'Recent Members',
    },
    'btn_create_guest_pass': {
      'gu': 'મહેમાન માટે ગેસ્ટ પાસ બનાવો',
      'hi': 'अतिथि के लिए गेस्ट पास बनाएं',
      'en': 'Create Guest Pass for Visitor',
    },
    'btn_view_society_gate_live': {
      'gu': 'સોસાયટી ગેટ લાઈવ જુઓ',
      'hi': 'सोसायटी गेट लाइव देखें',
      'en': 'View Society Gate Live',
    },
    'btn_understood_ok': {
      'gu': 'સમજાયું (ઓકે)',
      'hi': 'समझ गया (ओके)',
      'en': 'Understood (OK)',
    },
    'btn_enter_code_manually': {
      'gu': 'મેન્યુઅલી કોડ દાખલ કરો',
      'hi': 'मैन्युअल रूप से कोड दर्ज करें',
      'en': 'Enter Code Manually',
    },
    'official_pdf_account': {
      'gu': 'ઓફિશિયલ PDF હિસાબ',
      'hi': 'आधिकारिक पीडीएफ खाता',
      'en': 'Official PDF account',
    },
    'no_costs_found': {
      'gu': 'કોઈ ખર્ચ મળ્યો નથી',
      'hi': 'कोई लागत नहीं मिली',
      'en': 'No costs found',
    },
    'click_the_button_below_to_register': {
      'gu': 'વોચમેન પગાર, સફાઈ ખર્ચ, લાઈટ બિલ કે અન્ય ખર્ચ નોંધવા માટે નીચે આપેલ બટન દબાવો.',
      'hi': 'चौकीदार का वेतन, सफाई खर्च, लाइट बिल या अन्य खर्च दर्ज करने के लिए नीचे दिए गए बटन पर क्लिक करें।',
      'en': 'Click the button below to register watchman salary, cleaning expenses, light bill or other expenses.',
    },
    'watchman_salary': {
      'gu': 'વોચમેન પગાર',
      'hi': 'चौकीदार का वेतन',
      'en': 'Watchman Salary',
    },
    'cleaning_staff_salary': {
      'gu': 'સફાઈ કર્મચારી પગાર',
      'hi': 'सफाई कर्मचारियों का वेतन',
      'en': 'Cleaning staff salary',
    },
    'common_light_bill': {
      'gu': 'કોમન લાઈટ બિલ',
      'hi': 'सामान्य प्रकाश विधेयक',
      'en': 'Common Light Bill',
    },
    'lift_amc_service': {
      'gu': 'લિફ્ટ AMC સર્વિસ',
      'hi': 'लिफ्ट एएमसी सेवा',
      'en': 'Lift AMC Service',
    },
    'water_motor_borewell': {
      'gu': 'પાણી મોટર / બોરવેલ',
      'hi': 'जल मोटर/बोरवेल',
      'en': 'Water Motor / Borewell',
    },
    'society_repairing': {
      'gu': 'સોસાયટી રિપેરિંગ',
      'hi': 'सोसायटी मरम्मत',
      'en': 'Society Repairing',
    },
    'garden_gardener': {
      'gu': 'બગીચો / માળી',
      'hi': 'बाग/माली',
      'en': 'Garden / Gardener',
    },
    'society_notes_the_new_expenditure': {
      'gu': 'સોસાયટી નવો ખર્ચ નોંધો',
      'hi': 'सोसायटी नए खर्च को नोट करती है',
      'en': 'Society notes the new expenditure',
    },
    'quick_selection_presets': {
      'gu': 'ઝડપી પસંદગી (Presets):',
      'hi': 'त्वरित चयन (प्रीसेट):',
      'en': 'Quick Selection (Presets):',
    },
    'expenditure_category': {
      'gu': 'ખર્ચ કેટેગરી (Category)',
      'hi': 'व्यय श्रेणी',
      'en': 'Expenditure Category',
    },
    'expenditure_title': {
      'gu': 'ખર્ચ શીર્ષક (Title)',
      'hi': 'व्यय शीर्षक',
      'en': 'Expenditure Title',
    },
    'eg_october_watchman_pay': {
      'gu': 'દા.ત. ઓક્ટોબર વોચમેન પગાર',
      'hi': 'जैसे अक्टूबर चौकीदार वेतन',
      'en': 'E.g. October watchman pay',
    },
    'amount': {
      'gu': 'રકમ (Amount ₹)',
      'hi': 'राशि ₹',
      'en': 'Amount ₹',
    },
    'who_paid_payee_name': {
      'gu': 'કોને ચૂકવ્યા? (Payee Name)',
      'hi': 'किसने भुगतान किया? (भुगतानकर्ता का नाम)',
      'en': 'Who paid? (Payee Name)',
    },
    'eg_rameshbhai_watchman_torrent_power_otis': {
      'gu': 'દા.ત. રમેશભાઈ વોચમેન, ટોરેન્ટ પાવર, ઓટીસ',
      'hi': 'जैसे रमेशभाई वॉचमैन, टोरेंट पावर, ओटिस',
      'en': 'E.g. Rameshbhai Watchman, Torrent Power, Otis',
    },
    'payment_mode': {
      'gu': 'ચુકવણી મોડ',
      'hi': 'भुगतान मोड',
      'en': 'Payment Mode',
    },
    'cash': {
      'gu': 'રોકડ (Cash)',
      'hi': 'नकद',
      'en': 'Cash',
    },
    'bank_transfer': {
      'gu': 'બેંક ટ્રાન્સફર',
      'hi': 'बैंक हस्तांतरण',
      'en': 'Bank transfer',
    },
    'check': {
      'gu': 'ચેક (Cheque)',
      'hi': 'जांचें',
      'en': 'Check',
    },
    'date_2': {
      'gu': 'તારીખ (Date)',
      'hi': 'दिनांक',
      'en': 'Date',
    },
    'optional_notes': {
      'gu': 'વિશેષ નોંધ (Optional Notes)',
      'hi': 'वैकल्पिक नोट्स',
      'en': 'Optional Notes',
    },
    'expenditure_scope': {
      'gu': 'ખર્ચ કાર્યક્ષેત્ર (Scope):',
      'hi': 'व्यय का दायरा:',
      'en': 'Expenditure Scope:',
    },
    'whole_premises_common': {
      'gu': 'સમગ્ર પરિસર (કોમન)',
      'hi': 'संपूर्ण परिसर (सामान्य)',
      'en': 'Whole Premises (Common)',
    },
    'a_certain_wingstreet': {
      'gu': 'ચોક્કસ વિંગ/શેરી',
      'hi': 'एक निश्चित विंग/सड़क',
      'en': 'A certain wing/street',
    },
    'which_wing_street_cost': {
      'gu': 'કઈ વિંગ / શેરીનો ખર્ચ છે?',
      'hi': 'किस विंग/स्ट्रीट की लागत?',
      'en': 'Which wing / street cost?',
    },
    'save_costs_successfully': {
      'gu': 'ખર્ચ સફળતાપૂર્વક સાચવો',
      'hi': 'लागत सफलतापूर्वक बचाएं',
      'en': 'Save costs successfully',
    },
    'please_enter_a_valid_title_and': {
      'gu': 'કૃપા કરીને માન્ય શીર્ષક અને રકમ દાખલ કરો',
      'hi': 'कृपया एक वैध शीर्षक और राशि दर्ज करें',
      'en': 'Please enter a valid title and amount',
    },
    'cost_added_successfully': {
      'gu': 'ખર્ચ સફળતાપૂર્વક ઉમેરાઈ ગયો!',
      'hi': 'लागत सफलतापूर्वक जोड़ी गई!',
      'en': 'Cost added successfully!',
    },
    'payment_date': {
      'gu': 'ચુકવણી તારીખ:',
      'hi': 'भुगतान तिथि:',
      'en': 'Payment Date:',
    },
    'paid_to': {
      'gu': 'કોને ચૂકવ્યા:',
      'hi': 'इन्हें भुगतान किया गया:',
      'en': 'Paid to:',
    },
    'payment_mode_2': {
      'gu': 'ચુકવણી મોડ:',
      'hi': 'भुगतान का प्रकार:',
      'en': 'Payment Mode:',
    },
    'note': {
      'gu': 'નોંધ:',
      'hi': 'ध्यान दें:',
      'en': 'Note:',
    },
    'registrant': {
      'gu': 'નોંધણી કરનાર:',
      'hi': 'पंजीकरणकर्ता:',
      'en': 'Registrant:',
    },
    'delete_the_cost': {
      'gu': 'ખર્ચ કાઢી નાખો',
      'hi': 'लागत हटाएँ',
      'en': 'Delete the cost',
    },
    'guaranteed_to_eliminate_costs': {
      'gu': 'ખર્ચ કાઢી નાખવાની ખાતરી',
      'hi': 'लागत ख़त्म करने की गारंटी',
      'en': 'Guaranteed to eliminate costs',
    },
    'cancelled': {
      'gu': 'રદ',
      'hi': 'रद्द कर दिया गया',
      'en': 'cancelled',
    },
    'yes_delete_it': {
      'gu': 'હા, કાઢી નાખો',
      'hi': 'हाँ, इसे हटा दें',
      'en': 'Yes, delete it',
    },
    'date_wise_ledger': {
      'gu': 'તારીખવાર ખાતાવહી',
      'hi': 'तिथिवार बही',
      'en': 'Date wise ledger',
    },
    'expenditure_category_2': {
      'gu': 'ખર્ચ કેટેગરી',
      'hi': 'व्यय श्रेणी',
      'en': 'Expenditure category',
    },
    'no_financial_entry_is_available': {
      'gu': 'કોઈ નાણાકીય એન્ટ્રી ઉપલબ્ધ નથી',
      'hi': 'कोई वित्तीय प्रविष्टि उपलब्ध नहीं है',
      'en': 'No financial entry is available',
    },
    'when_members_deposit_maintenance_or_register': {
      'gu': 'જ્યારે સભ્યો મેન્ટેનન્સ જમા કરશે અથવા એડમિન ખર્ચ નોંધશે, ત્યારે તારીખવાર સંપૂર્ણ પાસબુક અહીં દેખાશે.',
      'hi': 'जब सदस्य रखरखाव जमा करेंगे या प्रशासनिक व्यय दर्ज करेंगे, तो पूरी पासबुक यहां दिखाई देगी।',
      'en': 'When members deposit maintenance or register admin expenses, the complete passbook will appear here.',
    },
    'the_opening_salak': {
      'gu': 'શરૂઆતની સિલક',
      'hi': 'उद्घाटन सलाख',
      'en': 'The opening salak',
    },
    'total_deposit_expenditure': {
      'gu': 'કુલ જમા / ખર્ચ',
      'hi': 'कुल जमा/व्यय',
      'en': 'Total Deposit / Expenditure',
    },
    'the_current_ending_is_silak': {
      'gu': 'વર્તમાન આખર સિલક',
      'hi': 'वर्तमान अंत सिलाक है',
      'en': 'The current ending is Silak',
    },
    'latest_date_first': {
      'gu': 'નવીનતમ તારીખ પ્રથમ',
      'hi': 'सबसे पहले नवीनतम तारीख',
      'en': 'Latest date first',
    },
    'balance_on_that_date': {
      'gu': 'તે તારીખે તિજોરી સિલક (Balance):',
      'hi': 'उस तिथि पर शेष राशि:',
      'en': 'Balance on that date:',
    },
    'loading_account_passbook': {
      'gu': 'હિસાબ & પાસબુક લોડ થઈ રહી છે...',
      'hi': 'खाता और पासबुक लोड हो रहा है...',
      'en': 'Loading Account & Passbook...',
    },
    'enter_floor_name_and_valid_number': {
      'gu': 'ફ્લોરનું નામ અને દુકાનોની માન્ય સંખ્યા દાખલ કરો!',
      'hi': 'मंजिल का नाम और दुकानों की वैध संख्या दर्ज करें!',
      'en': 'Enter floor name and valid number of shops!',
    },
    'enter_a_valid_floor_range_eg': {
      'gu': 'માન્ય ફ્લોર રેન્જ (દા.ત. 2 થી 10) અને માળ દીઠ સંખ્યા લખો!',
      'hi': 'एक वैध मंजिल सीमा (जैसे 2 से 10) और प्रति मंजिल संख्या दर्ज करें!',
      'en': 'Enter a valid floor range (eg 2 to 10) and the number per floor!',
    },
    'write_shopping_zone_name_and_number': {
      'gu': 'શોપિંગ ઝોન નામ અને દુકાનોની સંખ્યા લખો!',
      'hi': 'शॉपिंग जोन का नाम और दुकानों की संख्या लिखें!',
      'en': 'Write shopping zone name and number of shops!',
    },
    'enter_wing_name_total_floors_and': {
      'gu': 'વિંગ નામ, કુલ માળ અને ફ્લેટ્સ/માળ દાખલ કરો!',
      'hi': 'विंग का नाम, कुल मंजिलें और फ्लैट/फर्श दर्ज करें!',
      'en': 'Enter Wing Name, Total Floors and Flats/Floors!',
    },
    'write_street_name_and_startend_house': {
      'gu': 'શેરી નામ અને શરૂઆત/અંતિમ ઘર નંબર સાચા લખો!',
      'hi': 'सड़क का नाम और आरंभ/अंत मकान नंबर सही ढंग से लिखें!',
      'en': 'Write street name and start/end house number correctly!',
    },
    'all_units_and_square_feet_sizes': {
      'gu': 'તમામ એકમો અને સ્ક્વેર ફીટ સાઈઝ આપમેળે સિસ્ટમમાં જોડાઈ જશે',
      'hi': 'सभी इकाइयां और वर्ग फुट आकार स्वचालित रूप से सिस्टम में जोड़ दिए जाएंगे',
      'en': 'All units and square feet sizes will automatically be added to the system',
    },
    'save_the_new_block_generate_units': {
      'gu': 'નવો બ્લોક સેવ કરો (Generate Units)',
      'hi': 'नया ब्लॉक सहेजें (इकाइयाँ उत्पन्न करें)',
      'en': 'Save the new block (Generate Units)',
    },
    'single_floor': {
      'gu': 'સિંગલ ફ્લોર (Single)',
      'hi': 'एकल मंजिल',
      'en': 'Single floor',
    },
    'floor_range': {
      'gu': 'ફ્લોર રેન્જ (Range)',
      'hi': 'फ़्लोर रेंज',
      'en': 'Floor Range',
    },
    'floor_code_name': {
      'gu': 'ફ્લોર કોડ / નામ *',
      'hi': 'फ़्लोर कोड/नाम*',
      'en': 'Floor Code / Name *',
    },
    'eg_g_1_2_b1': {
      'gu': 'દા.ત. G, 1, 2, B1',
      'hi': 'जैसे जी, 1, 2, बी1',
      'en': 'E.g. G, 1, 2, B1',
    },
    'shopoffice_number': {
      'gu': 'દુકાન/ઓફિસ સંખ્યા *',
      'hi': 'दुकान/कार्यालय नंबर*',
      'en': 'Shop/Office Number *',
    },
    'eg_20': {
      'gu': 'દા.ત. 20',
      'hi': 'जैसे 20',
      'en': 'E.g. 20',
    },
    'average_sqft': {
      'gu': 'સરેરાશ Sq.Ft',
      'hi': 'औसत वर्गफुट',
      'en': 'Average Sq.Ft',
    },
    'eg_350': {
      'gu': 'દા.ત. 350',
      'hi': 'जैसे 350',
      'en': 'E.g. 350',
    },
    'shop': {
      'gu': '🏪 દુકાન (Shop)',
      'hi': '🏪दुकान',
      'en': '🏪 Shop',
    },
    'office': {
      'gu': '💼 ઓફિસ (Office)',
      'hi': '💼कार्यालय',
      'en': '💼 Office',
    },
    'showroom': {
      'gu': '🏬 શો-રૂમ (Showroom)',
      'hi': 'शोरूम',
      'en': 'Showroom',
    },
    'godown': {
      'gu': '📦 ગોડાઉન (Godown)',
      'hi': '📦गोदाम',
      'en': '📦 Godown',
    },
    'unit_type': {
      'gu': 'એકમ પ્રકાર',
      'hi': 'इकाई प्रकार',
      'en': 'unit type',
    },
    'block_name_optional': {
      'gu': 'બ્લોક નામ (વૈકલ્પિક)',
      'hi': 'ब्लॉक नाम (वैकल्पिक)',
      'en': 'Block name (optional)',
    },
    'eg_corporate_floors': {
      'gu': 'દા.ત. Corporate Floors',
      'hi': 'जैसे कॉर्पोरेट फ़्लोर',
      'en': 'E.g. Corporate Floors',
    },
    'where_floor': {
      'gu': 'ક્યાંથી માળ *',
      'hi': 'मंजिल कहां*',
      'en': 'Where Floor *',
    },
    'eg_2': {
      'gu': 'દા.ત. 2',
      'hi': 'जैसे 2',
      'en': 'E.g. 2',
    },
    'until': {
      'gu': 'ક્યાં સુધી *',
      'hi': 'जब तक*',
      'en': 'until *',
    },
    'eg_10': {
      'gu': 'દા.ત. 10',
      'hi': 'जैसे 10',
      'en': 'E.g. 10',
    },
    'units_per_floor': {
      'gu': 'માળ દીઠ એકમો *',
      'hi': 'प्रति मंजिल इकाइयाँ *',
      'en': 'Units per Floor *',
    },
    'eg_8': {
      'gu': 'દા.ત. 8',
      'hi': 'जैसे 8',
      'en': 'E.g. 8',
    },
    'eg_500': {
      'gu': 'દા.ત. 500',
      'hi': 'जैसे 500',
      'en': 'E.g. 500',
    },
    'commercial_shops': {
      'gu': '🏬 કોમર્શિયલ શોપ્સ',
      'hi': '🏬वाणिज्यिक दुकानें',
      'en': '🏬 Commercial shops',
    },
    'residential_wing': {
      'gu': '🏢 રેસિડેન્શિયલ વિંગ',
      'hi': '🏢आवासीय विंग',
      'en': '🏢 Residential Wing',
    },
    'shopping_zone_floor': {
      'gu': 'શોપિંગ ઝોન / ફ્લોર *',
      'hi': 'शॉपिंग जोन/मंजिल*',
      'en': 'Shopping Zone / Floor *',
    },
    'eg_g': {
      'gu': 'દા.ત. G',
      'hi': 'जैसे जी',
      'en': 'E.g. G',
    },
    'number_of_shops': {
      'gu': 'દુકાનો સંખ્યા *',
      'hi': 'दुकानों की संख्या*',
      'en': 'Number of Shops *',
    },
    'eg_18': {
      'gu': 'દા.ત. 18',
      'hi': 'जैसे 18',
      'en': 'E.g. 18',
    },
    'wing_name': {
      'gu': 'વિંગ નામ *',
      'hi': 'विंग का नाम*',
      'en': 'Wing Name *',
    },
    'eg_a': {
      'gu': 'દા.ત. A',
      'hi': 'जैसे ए',
      'en': 'E.g. A',
    },
    'total_floors': {
      'gu': 'કુલ માળ *',
      'hi': 'कुल मंजिलें *',
      'en': 'Total Floors *',
    },
    'flats_per_floor': {
      'gu': 'માળ દીઠ ફ્લેટ્સ *',
      'hi': 'प्रति मंजिल फ्लैट*',
      'en': 'Flats per floor *',
    },
    'eg_4': {
      'gu': 'દા.ત. 4',
      'hi': 'जैसे 4',
      'en': 'E.g. 4',
    },
    'average_flat_size_sqft': {
      'gu': 'સરેરાશ ફ્લેટ સાઈઝ (Sq.Ft)',
      'hi': 'औसत फ़्लैट आकार (वर्ग फ़ुट)',
      'en': 'Average Flat Size (Sq.Ft)',
    },
    'eg_1000': {
      'gu': 'દા.ત. 1000',
      'hi': 'जैसे 1000',
      'en': 'E.g. 1000',
    },
    'eg_5': {
      'gu': 'દા.ત. 5',
      'hi': 'जैसे 5',
      'en': 'E.g. 5',
    },
    'flats_per_floor_2': {
      'gu': 'માળ દીઠ ફ્લેટ *',
      'hi': 'प्रति मंजिल फ्लैट*',
      'en': 'Flats per Floor *',
    },
    'street_number_name': {
      'gu': 'શેરી નંબર / નામ *',
      'hi': 'सड़क संख्या/नाम*',
      'en': 'Street Number / Name *',
    },
    'eg_1': {
      'gu': 'દા.ત. 1',
      'hi': 'जैसे 1',
      'en': 'E.g. 1',
    },
    'start_house_no': {
      'gu': 'શરૂઆત ઘર નં. *',
      'hi': 'प्रारंभ मकान नं. *',
      'en': 'Start house no. *',
    },
    'last_house_no': {
      'gu': 'છેલ્લો ઘર નં. *',
      'hi': 'अंतिम मकान नं. *',
      'en': 'Last house no. *',
    },
    'eg_25': {
      'gu': 'દા.ત. 25',
      'hi': 'जैसे 25',
      'en': 'E.g. 25',
    },
    'average_size_sqft': {
      'gu': 'સરેરાશ સાઈઝ (Sq.Ft)',
      'hi': 'औसत आकार (वर्ग फुट)',
      'en': 'Average Size (Sq.Ft)',
    },
    'eg_1200': {
      'gu': 'દા.ત. 1200',
      'hi': 'जैसे 1200',
      'en': 'E.g. 1200',
    },
    'please_enter_name_email_and_password': {
      'gu': 'કૃપા કરીને નામ, ઈમેલ અને પાસવર્ડ દાખલ કરો.',
      'hi': 'कृपया नाम, ईमेल और पासवर्ड दर्ज करें.',
      'en': 'Please enter name, email and password.',
    },
    'please_enter_a_valid_email_id': {
      'gu': 'કૃપા કરીને સાચું ઈમેલ આઈડી દાખલ કરો.',
      'hi': 'कृपया मान्य ईमेल पता दर्ज करें।',
      'en': 'Please enter a valid email id.',
    },
    'password_must_be_at_least_6': {
      'gu': 'પાસવર્ડ ઓછામાં ઓછો 6 અક્ષરનો હોવો જોઈએ.',
      'hi': 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए।',
      'en': 'Password must be at least 6 characters long.',
    },
    'please_select_block_and_flat_house': {
      'gu': 'કૃપા કરીને મેમ્બર માટે બ્લોક અને ફ્લેટ / ઘર નંબર પસંદ કરો.',
      'hi': 'कृपया सदस्य के लिए ब्लॉक और फ्लैट/मकान नंबर का चयन करें।',
      'en': 'Please select block and flat / house number for the member.',
    },
    'there_is_already_a_member_in': {
      'gu': 'ફ્લેટમાં પહેલેથી સભ્ય છે',
      'hi': 'फ्लैट में पहले से ही एक सदस्य मौजूद है',
      'en': 'There is already a member in the flat',
    },
    'yes_add': {
      'gu': 'હા, ઉમેરો',
      'hi': 'हाँ, जोड़ें',
      'en': 'Yes, add',
    },
    'subadmin': {
      'gu': 'સબ-એડમિન',
      'hi': 'उप-व्यवस्थापक',
      'en': 'Sub-admin',
    },
    'txt_1_select_user_role': {
      'gu': '૧. યુઝર રોલ પસંદ કરો',
      'hi': '1. उपयोगकर्ता भूमिका चुनें',
      'en': '1. Select User Role',
    },
    'flat_holder': {
      'gu': 'ફ્લેટ ધારક',
      'hi': 'फ्लैट धारक',
      'en': 'Flat holder',
    },
    'gate_staff': {
      'gu': 'ગેટ સ્ટાફ',
      'hi': 'गेट कर्मचारी',
      'en': 'Gate staff',
    },
    'txt_2_personal_details': {
      'gu': '૨. વ્યક્તિગત વિગતો',
      'hi': '2. व्यक्तिगत विवरण',
      'en': '2. Personal details',
    },
    'full_name': {
      'gu': 'પૂરું નામ (Full Name) *',
      'hi': 'पूरा नाम*',
      'en': 'Full Name *',
    },
    'eg_rameshbhai_patel': {
      'gu': 'દા.ત. રમેશભાઈ પટેલ',
      'hi': 'जैसे रमेशभाई पटेल',
      'en': 'E.g. Rameshbhai Patel',
    },
    'mobile_number': {
      'gu': 'મોબાઈલ નંબર (Mobile Number)',
      'hi': 'मोबाइल नंबर',
      'en': 'Mobile Number',
    },
    'eg_9876543210': {
      'gu': 'દા.ત. 9876543210',
      'hi': 'जैसे 9876543210',
      'en': 'E.g. 9876543210',
    },
    'email_id_email_login_id': {
      'gu': 'ઈમેલ આઈડી (Email / Login ID) *',
      'hi': 'ईमेल आईडी (ईमेल/लॉगिन आईडी)*',
      'en': 'Email ID (Email / Login ID) *',
    },
    'eg_usergmailcom': {
      'gu': 'દા.ત. user@gmail.com',
      'hi': 'जैसे user@gmail.com',
      'en': 'E.g. user@gmail.com',
    },
    'password_login_password': {
      'gu': 'પાસવર્ડ (Login Password) *',
      'hi': 'पासवर्ड (लॉगिन पासवर्ड) *',
      'en': 'Password (Login Password) *',
    },
    'at_least_6_characters': {
      'gu': 'ઓછામાં ઓછા 6 અક્ષર',
      'hi': 'कम से कम 6 अक्षर',
      'en': 'At least 6 characters',
    },
    'txt_3_details_of_block_flat_house': {
      'gu': '૩. બ્લોક & ફ્લેટ / ઘર નંબરની વિગતો',
      'hi': '3. ब्लॉक एवं फ्लैट/मकान संख्या का विवरण',
      'en': '3. Details of block & flat / house number',
    },
    'block_wing_floor': {
      'gu': 'બ્લોક / વિંગ / ફ્લોર *',
      'hi': 'ब्लॉक/विंग/फर्श*',
      'en': 'Block / Wing / Floor *',
    },
    'select_the_block': {
      'gu': 'બ્લોક પસંદ કરો',
      'hi': 'ब्लॉक का चयन करें',
      'en': 'Select the block',
    },
    'block_wing_name': {
      'gu': 'બ્લોક / વિંગ નામ (Block / Wing) *',
      'hi': 'ब्लॉक/विंग का नाम*',
      'en': 'Block / Wing Name *',
    },
    'eg_a_b_wing1': {
      'gu': 'દા.ત. A, B, વિંગ-1',
      'hi': 'जैसे ए, बी, विंग-1',
      'en': 'E.g. A, B, Wing-1',
    },
    'no_block_registered_yet_write_name': {
      'gu': 'હજુ કોઈ બ્લોક નોંધાયેલ નથી, નામ સીધું લખો.',
      'hi': 'अभी तक कोई ब्लॉक पंजीकृत नहीं है, सीधे नाम लिखें।',
      'en': 'No block registered yet, write name directly.',
    },
    'select_from_the_list_of_registered': {
      'gu': 'રજિસ્ટર્ડ ફ્લેટ લિસ્ટમાંથી પસંદ કરો:',
      'hi': 'पंजीकृत फ्लैटों की सूची से चयन करें:',
      'en': 'Select from the list of registered flats:',
    },
    'flat_unit_no': {
      'gu': 'ફ્લેટ / ઘર નંબર (Flat / Unit No.) *',
      'hi': 'फ़्लैट/यूनिट संख्या*',
      'en': 'Flat / Unit No. *',
    },
    'select_a_valid_flat_number': {
      'gu': 'માન્ય ફ્લેટ નંબર પસંદ કરો',
      'hi': 'एक वैध फ्लैट नंबर चुनें',
      'en': 'Select a valid flat number',
    },
    'empty': {
      'gu': 'ખાલી',
      'hi': 'खाली',
      'en': 'empty',
    },
    'please_select_block_wing_from_above': {
      'gu': 'કૃપા કરીને પહેલા ઉપરથી બ્લોક / વિંગ પસંદ કરો.',
      'hi': 'कृपया पहले ऊपर से ब्लॉक/विंग का चयन करें।',
      'en': 'Please select block / wing from above first.',
    },
    'there_are_no_flats_already_registered': {
      'gu': 'આ બ્લોકમાં અગાઉથી કોઈ ફ્લેટ ડેટાબેઝમાં નોંધાયેલ નથી.',
      'hi': 'इस ब्लॉक में डेटाबेस में पहले से कोई फ्लैट पंजीकृत नहीं है।',
      'en': 'There are no flats already registered in the database in this block.',
    },
    'enter_a_valid_flat_house_number': {
      'gu': 'માન્ય ફ્લેટ / ઘર નંબર દાખલ કરો (દા.ત. 101, A-101):',
      'hi': 'वैध फ़्लैट/घर का नंबर दर्ज करें (जैसे 101, ए-101):',
      'en': 'Enter a valid flat / house number (eg 101, A-101):',
    },
    'flat_house_no': {
      'gu': 'ફ્લેટ / ઘર નંબર *',
      'hi': 'फ़्लैट/मकान नं.*',
      'en': 'Flat / House No. *',
    },
    'eg_101': {
      'gu': 'દા.ત. 101',
      'hi': 'जैसे 101',
      'en': 'E.g. 101',
    },
    'register_a_user': {
      'gu': 'યુઝર રજીસ્ટર કરો',
      'hi': 'एक उपयोगकर्ता पंजीकृत करें',
      'en': 'Register a user',
    },
    'amenities_module_is_disabled': {
      'gu': 'એમેનિટીઝ મોડ્યુલ અક્ષમ (Disabled) છે',
      'hi': 'सुविधाएं मॉड्यूल अक्षम है',
      'en': 'Amenities module is disabled',
    },
    'if_your_society_does_not_have': {
      'gu': 'જો તમારી સોસાયટીમાં વાડી, ક્લબહાઉસ કે કોમન હોલ ન હોય, તો આ ફીચર બંધ રાખવાથી સભ્યો અને વોચમેનને એપમાં કોઈ વધારાની ખાલી સ્ક્રીન જોવા નહીં મળે.',
      'hi': 'यदि आपकी सोसायटी में वाडी, क्लब हाउस या कॉमन हॉल नहीं है, तो इस सुविधा को बंद करने से सदस्यों और चौकीदारों को ऐप में कोई अतिरिक्त खाली स्क्रीन देखने से रोका जा सकेगा।',
      'en': 'If your society does not have a wadi, clubhouse or common hall, turning this feature off will prevent members and watchmen from seeing any additional blank screens in the app.',
    },
    'bookings': {
      'gu': 'બુકિંગ્સ',
      'hi': 'बुकिंग',
      'en': 'Bookings',
    },
    'features_setup': {
      'gu': 'સુવિધાઓ (Setup)',
      'hi': 'सुविधाएँ (सेटअप)',
      'en': 'Features (Setup)',
    },
    'are_there_amenities_wadi_in_the': {
      'gu': 'સોસાયટીમાં એમેનિટીઝ / વાડી છે?',
      'hi': 'क्या सोसायटी में सुविधाएं/वाडी हैं?',
      'en': 'Are there amenities / Wadi in the society?',
    },
    'active_bookings_available_across_the_app': {
      'gu': 'સક્રિય • સમગ્ર એપમાં બુકિંગ ઉપલબ્ધ',
      'hi': 'सक्रिय • बुकिंग ऐप पर उपलब्ध है',
      'en': 'Active • Bookings available across the app',
    },
    'invisible_booking_module_is_hidden': {
      'gu': 'અદ્રશ્ય • બુકિંગ મોડ્યુલ છુપાયેલું છે',
      'hi': 'अदृश्य • बुकिंग मॉड्यूल छिपा हुआ है',
      'en': 'Invisible • Booking module is hidden',
    },
    'amenities_module_enabled_now_available_to': {
      'gu': '✅ એમેનિટીઝ મોડ્યુલ સક્ષમ થયું. હવે સભ્યો અને ગેટ પર ઉપલબ્ધ રહેશે.',
      'hi': '✅ सुविधाएं मॉड्यूल सक्षम। अब सदस्यों के लिए और गेट पर उपलब्ध है।',
      'en': '✅ Amenities module enabled. Now available to members and at the gate.',
    },
    'the_amenities_module_has_been_closed': {
      'gu': 'એમેનિટીઝ મોડ્યુલ બંધ કરવામાં આવ્યું છે.',
      'hi': 'सुविधाएं मॉड्यूल बंद कर दिया गया है.',
      'en': 'The amenities module has been closed.',
    },
    'no_booking_request_received_yet': {
      'gu': 'હજુ કોઈ બુકિંગ રિક્વેસ્ટ આવેલ નથી',
      'hi': 'अभी तक कोई बुकिंग अनुरोध प्राप्त नहीं हुआ',
      'en': 'No booking request received yet',
    },
    'when_society_members_book_slots_for': {
      'gu': 'જ્યારે સોસાયટીના સભ્યો વાડી, ક્લબહાઉસ કે ટેરેસ માટે સ્લોટ બુક કરશે ત્યારે તેમની મંજૂરી માટેની વિનંતી અહીં દર્શાવવામાં આવશે.',
      'hi': 'जब सोसायटी के सदस्य वाडी, क्लब हाउस या टेरेस के लिए स्लॉट बुक करते हैं तो उनका अनुमोदन अनुरोध यहां प्रदर्शित किया जाएगा।',
      'en': 'When society members book slots for Wadi, Clubhouse or Terrace their approval request will be displayed here.',
    },
    'wadi_hall': {
      'gu': 'વાડી / હોલ',
      'hi': 'वाडी/हॉल',
      'en': 'Wadi / Hall',
    },
    'clubhouse': {
      'gu': 'ક્લબહાઉસ',
      'hi': 'क्लब हाउस',
      'en': 'Clubhouse',
    },
    'terrace_garden': {
      'gu': 'ટેરેસ ગાર્ડન',
      'hi': 'छत वाला बगीचा',
      'en': 'Terrace garden',
    },
    'approved': {
      'gu': 'મંજૂર થયેલ (Approved)',
      'hi': 'स्वीकृत',
      'en': 'Approved',
    },
    'rejected': {
      'gu': 'નામંજૂર (Rejected)',
      'hi': 'अस्वीकृत',
      'en': 'Rejected',
    },
    'pending_approval': {
      'gu': 'પેન્ડિંગ મંજૂરી (Pending)',
      'hi': 'अनुमोदन लंबित',
      'en': 'Pending Approval',
    },
    'reject': {
      'gu': 'નામંજૂર (Reject)',
      'hi': 'अस्वीकार करें',
      'en': 'Reject',
    },
    'approve': {
      'gu': 'મંજૂર કરો (Approve)',
      'hi': 'स्वीकृत करें',
      'en': 'Approve',
    },
    'event_inspection_deposit_refund_note': {
      'gu': 'ઇવેન્ટ નિરીક્ષણ & ડિપોઝિટ રીફંડ નોંધ',
      'hi': 'घटना निरीक्षण एवं जमा वापसी नोट',
      'en': 'Event Inspection & Deposit Refund Note',
    },
    'want_to_approve_a_booking': {
      'gu': 'બુકિંગ મંજૂર કરવું છે?',
      'hi': 'क्या आप बुकिंग स्वीकृत करना चाहते हैं?',
      'en': 'Want to approve a booking?',
    },
    'want_to_decline_a_booking': {
      'gu': 'બુકિંગ નામંજૂર કરવું છે?',
      'hi': 'क्या आप बुकिंग अस्वीकार करना चाहते हैं?',
      'en': 'Want to decline a booking?',
    },
    'special_notice_optional': {
      'gu': 'ખાસ સૂચના (વૈકલ્પિક)',
      'hi': 'विशेष सूचना (वैकल्पिक)',
      'en': 'Special Notice (Optional)',
    },
    'reason_for_rejection': {
      'gu': 'નામંજૂર કરવાનું કારણ *',
      'hi': 'अस्वीकृति का कारण*',
      'en': 'Reason for Rejection *',
    },
    'approve_2': {
      'gu': 'મંજૂર કરો',
      'hi': 'स्वीकृत',
      'en': 'approve',
    },
    'reject_2': {
      'gu': 'નામંજૂર કરો',
      'hi': 'अस्वीकार करें',
      'en': 'Reject',
    },
    'no_damage_the_hall_is_clear': {
      'gu': 'કોઈ નુકસાન નથી, હોલ સાફ છે.',
      'hi': 'कोई क्षति नहीं, हॉल साफ़ है।',
      'en': 'No damage, the hall is clear.',
    },
    'post_event_inspection': {
      'gu': 'ઇવેન્ટ પછીનું નિરીક્ષણ (Inspection)',
      'hi': 'घटना के बाद निरीक्षण',
      'en': 'Post Event Inspection',
    },
    'deposit_status': {
      'gu': 'ડિપોઝિટ સ્ટેટસ:',
      'hi': 'जमा स्थिति:',
      'en': 'Deposit Status:',
    },
    'refunded': {
      'gu': 'રીફંડ (Refunded)',
      'hi': 'वापस कर दिया गया',
      'en': 'Refunded',
    },
    'deducted': {
      'gu': 'જપ્ત (Deducted)',
      'hi': 'कटौती की गई',
      'en': 'Deducted',
    },
    'inspection_note': {
      'gu': 'નિરીક્ષણ નોંધ (Inspection Note)',
      'hi': 'निरीक्षण नोट',
      'en': 'Inspection Note',
    },
    'save_2': {
      'gu': 'સેવ કરો',
      'hi': 'सहेजें',
      'en': 'Save',
    },
    'add_a_new_feature': {
      'gu': 'નવી સુવિધા ઉમેરો',
      'hi': 'एक नई सुविधा जोड़ें',
      'en': 'Add a new feature',
    },
    'no_feature_added': {
      'gu': 'કોઈ સુવિધા ઉમેરેલ નથી',
      'hi': 'कोई सुविधा नहीं जोड़ी गई',
      'en': 'No feature added',
    },
    'add_here_the_facilities_available_in': {
      'gu': 'સોસાયટીમાં ઉપલબ્ધ વાડી, પાર્ટી પ્લોટ, ક્લબહાઉસ કે ટેરેસ જેવી સુવિધાઓ અહીં ઉમેરો.',
      'hi': 'यहां सोसायटी में उपलब्ध सुविधाओं जैसे वाडी, पार्टी प्लॉट, क्लब हाउस या छत को जोड़ें।',
      'en': 'Add here the facilities available in the society like wadi, party plot, clubhouse or terrace.',
    },
    'add_default_features_wadi_hall': {
      'gu': 'ડિફૉલ્ટ સુવિધાઓ ઉમેરો (વાડી & હોલ)',
      'hi': 'डिफ़ॉल्ट सुविधाएँ जोड़ें (वाडी और हॉल)',
      'en': 'Add Default Features (Wadi & Hall)',
    },
    'community_hall_wadi_community_hall': {
      'gu': 'કોમ્યુનિટી હોલ / વાડી (Community Hall)',
      'hi': 'सामुदायिक भवन/वाडी (सामुदायिक भवन)',
      'en': 'Community Hall / Wadi (Community Hall)',
    },
    'a_large_hall_for_weddings_engagements': {
      'gu': 'લગ્ન, સગાઈ, બર્થડે પાર્ટી કે સામાજિક પ્રસંગો માટે મોટો હોલ.',
      'hi': 'शादियों, सगाई, जन्मदिन पार्टियों या सामाजिक कार्यक्रमों के लिए एक बड़ा हॉल।',
      'en': 'A large hall for weddings, engagements, birthday parties or social events.',
    },
    'full_day': {
      'gu': 'આખો દિવસ (Full Day)',
      'hi': 'पूरा दिन',
      'en': 'Full Day',
    },
    'morning_day_9_am_4_pm': {
      'gu': 'સવાર (Day: 9 AM - 4 PM)',
      'hi': 'सुबह (दिन: सुबह 9 बजे से शाम 4 बजे तक)',
      'en': 'Morning (Day: 9 AM - 4 PM)',
    },
    'evening_5_pm_11_pm': {
      'gu': 'સાંજ (Evening: 5 PM - 11 PM)',
      'hi': 'शाम: 5 बजे से रात 11 बजे तक',
      'en': 'Evening: 5 PM - 11 PM',
    },
    'djloudspeaker_off_after_10pm_cleaning_will': {
      'gu': 'રાત્રે ૧૦ વાગ્યા પછી ડીજે/લાઉડસ્પીકર બંધ. સાફ-સફાઈ સભ્યની રહેશે.',
      'hi': 'रात 10 बजे के बाद डीजे/लाउडस्पीकर बंद कर दें। सफाई की जिम्मेदारी सदस्य की होगी।',
      'en': 'DJ/loudspeaker off after 10pm. Cleaning will be the responsibility of the member.',
    },
    'loudspeaker_off_after_10_pm': {
      'gu': 'રાત્રે ૧૦ વાગ્યા પછી લાઉડસ્પીકર બંધ.',
      'hi': 'रात 10 बजे के बाद लाउडस्पीकर बंद कर दें।',
      'en': 'Loudspeaker off after 10 pm.',
    },
    'add_new_amenities': {
      'gu': 'નવી એમેનિટી ઉમેરો',
      'hi': 'नई सुविधाएं जोड़ें',
      'en': 'Add new amenities',
    },
    'name_of_facility_eg_clubhouse_wadi': {
      'gu': 'સુવિધાનું નામ (દા.ત. ક્લબહાઉસ, વાડી, ટેરેસ) *',
      'hi': 'सुविधा का नाम (जैसे क्लब हाउस, वाडी, टेरेस) *',
      'en': 'Name of Facility (eg Clubhouse, Wadi, Terrace) *',
    },
    'capacity_guests': {
      'gu': 'ક્ષમતા (મહેમાનો)',
      'hi': 'क्षमता (मेहमान)',
      'en': 'Capacity (Guests)',
    },
    'paid_facility_rent_deposit_required': {
      'gu': 'પેઇડ સુવિધા (ભાડું / ડિપોઝિટ લાગશે?)',
      'hi': 'सशुल्क सुविधा (किराया/जमा आवश्यक है?)',
      'en': 'Paid facility (rent / deposit required?)',
    },
    'fare': {
      'gu': 'ભાડું (₹)',
      'hi': 'किराया (₹)',
      'en': 'Fare (₹)',
    },
    'security_deposit_refundable': {
      'gu': 'સિક્યોરિટી ડિપોઝિટ (₹ - રીફંડેબલ)',
      'hi': 'सुरक्षा जमा (₹ - वापसी योग्य)',
      'en': 'Security Deposit (₹ - Refundable)',
    },
    'explanation': {
      'gu': 'સમજૂતી',
      'hi': 'स्पष्टीकरण',
      'en': 'Explanation',
    },
    'terms_and_conditions': {
      'gu': 'નિયમો અને શરતો',
      'hi': 'नियम एवं शर्तें',
      'en': 'Terms and conditions',
    },
    'add': {
      'gu': 'ઉમેરો',
      'hi': 'जोड़ें',
      'en': 'Add',
    },
    'common': {
      'gu': 'સામાન્ય',
      'hi': 'सामान्य',
      'en': 'common',
    },
    'society_notification': {
      'gu': 'સોસાયટી સૂચના',
      'hi': 'सोसायटी अधिसूचना',
      'en': 'Society Notification',
    },
    'water': {
      'gu': 'પાણી',
      'hi': 'पानी',
      'en': 'water',
    },
    'water_supply_update': {
      'gu': 'પાણી સપ્લાય અપડેટ',
      'hi': 'जल आपूर्ति अद्यतन',
      'en': 'Water supply update',
    },
    'electricity': {
      'gu': 'વીજળી',
      'hi': 'बिजली',
      'en': 'Electricity',
    },
    'light_power_cut_notification': {
      'gu': 'લાઈટ / પાવર કટ સૂચના',
      'hi': 'लाइट/बिजली कटौती अधिसूचना',
      'en': 'Light / Power Cut Notification',
    },
    'meeting': {
      'gu': 'મીટિંગ',
      'hi': 'बैठक',
      'en': 'meeting',
    },
    'society_general_meeting': {
      'gu': 'સોસાયટી સામાન્ય સભા',
      'hi': 'सोसायटी की आम बैठक',
      'en': 'Society General Meeting',
    },
    'emergency': {
      'gu': 'ઇમરજન્સી',
      'hi': 'आपातकाल',
      'en': 'Emergency',
    },
    'urgent_safety_notice': {
      'gu': 'તાકીદની સુરક્ષા સૂચના',
      'hi': 'तत्काल सुरक्षा सूचना',
      'en': 'Urgent Safety Notice',
    },
    'society_general_notice': {
      'gu': 'સોસાયટી સામાન્ય સૂચના',
      'hi': 'सोसायटी सामान्य सूचना',
      'en': 'Society General Notice',
    },
    'add_a_new_message_category': {
      'gu': 'નવી મેસેજ કેટેગરી ઉમેરો',
      'hi': 'एक नई संदेश श्रेणी जोड़ें',
      'en': 'Add a new message category',
    },
    'category_name': {
      'gu': 'કેટેગરી નામ *',
      'hi': 'श्रेणी का नाम *',
      'en': 'Category Name *',
    },
    'eg_lift_security_parking_etc': {
      'gu': 'દા.ત. લિફ્ટ, સિક્યોરિટી, પાર્કિંગ, વગેરે',
      'hi': 'जैसे लिफ्ट, सुरक्षा, पार्किंग, आदि',
      'en': 'E.g. Lift, Security, Parking, etc',
    },
    'default_title_optional': {
      'gu': 'ડિફૉલ્ટ શીર્ષક (વૈકલ્પિક)',
      'hi': 'डिफ़ॉल्ट शीर्षक (वैकल्पिक)',
      'en': 'Default title (optional)',
    },
    'eg_notice_of_lift_maintenance_required': {
      'gu': 'દા.ત. લિફ્ટ મેઇન્ટેનન્સ જરૂરી સૂચના',
      'hi': 'जैसे लिफ्ट रखरखाव की सूचना आवश्यक',
      'en': 'E.g. Notice of lift maintenance required',
    },
    'please_enter_both_a_title_and': {
      'gu': 'કૃપા કરીને શીર્ષક અને સંદેશ બંને દાખલ કરો.',
      'hi': 'कृपया शीर्षक और संदेश दोनों दर्ज करें।',
      'en': 'Please enter both a title and a message.',
    },
    'instant_broadcast': {
      'gu': 'ઈન્સ્ટન્ટ બ્રોડકાસ્ટ',
      'hi': 'त्वरित प्रसारण',
      'en': 'Instant broadcast',
    },
    'society_broadcast': {
      'gu': 'સોસાયટી બ્રોડકાસ્ટ',
      'hi': 'समाज प्रसारण',
      'en': 'Society Broadcast',
    },
    'direct_alert': {
      'gu': 'ડાયરેક્ટ એલર્ટ',
      'hi': 'प्रत्यक्ष चेतावनी',
      'en': 'Direct Alert',
    },
    'a_push_notification_with_immediate_sound': {
      'gu': 'તમામ સભ્યોના મોબાઇલ પર તાત્કાલિક સાઉન્ડ સાથે પુશ નોટિસ પહોંચશે.',
      'hi': 'तत्काल ध्वनि के साथ एक पुश सूचना सभी सदस्यों के मोबाइल पर पहुंच जाएगी।',
      'en': 'A push notification with immediate sound will reach all members\' mobiles.',
    },
    'recipient_all_members_broadcasting': {
      'gu': 'પ્રાપ્તકર્તા: તમામ સભ્યો (Broadcasting)',
      'hi': 'प्राप्तकर्ता: सभी सदस्य (प्रसारण)',
      'en': 'Recipient: All Members (Broadcasting)',
    },
    'this_notification_will_ring_instantly_on': {
      'gu': 'આ સૂચના તમામ એપ યુઝર્સના ફોન પર તરત વાગશે',
      'hi': 'यह नोटिफिकेशन सभी ऐप यूजर्स के फोन पर तुरंत बज जाएगा',
      'en': 'This notification will ring instantly on the phones of all app users',
    },
    'a_push_alert_will_go_to': {
      'gu': 'આ સભ્યના મોબાઈલ પર પુશ એલર્ટ જશે',
      'hi': 'इस सदस्य के मोबाइल पर एक पुश अलर्ट जाएगा',
      'en': 'A push alert will go to this member\'s mobile',
    },
    'target_audience_2': {
      'gu': 'લક્ષ્ય પરિસર / વિંગ (Target Audience):',
      'hi': 'लक्षित दर्शक:',
      'en': 'Target Audience:',
    },
    'select_the_topic_of_notification': {
      'gu': 'સૂચનાનો વિષય પસંદ કરો:',
      'hi': 'अधिसूचना का विषय चुनें:',
      'en': 'Select the topic of notification:',
    },
    'new_category': {
      'gu': '+ નવી કેટેગરી',
      'hi': '+ नई श्रेणी',
      'en': '+ New category',
    },
    'title_of_notification': {
      'gu': 'સૂચનાનું શીર્ષક (Title) *',
      'hi': 'अधिसूचना का शीर्षक*',
      'en': 'Title of Notification *',
    },
    'eg_tomorrow_morning_the_water_will': {
      'gu': 'દા.ત. આવતીકાલે સવારે પાણી 7 વાગે આવશે',
      'hi': 'जैसे कल सुबह 7 बजे पानी आएगा',
      'en': 'E.g. Tomorrow morning the water will come at 7 o\'clock',
    },
    'full_message_message_details': {
      'gu': 'સંપૂર્ણ સંદેશ / વિગત (Message Details) *',
      'hi': 'पूर्ण संदेश/संदेश विवरण*',
      'en': 'Full Message / Message Details *',
    },
    'write_detailed_information': {
      'gu': 'વિગતવાર માહિતી લખો...',
      'hi': 'विस्तृत जानकारी लिखें...',
      'en': 'Write detailed information...',
    },
    'on_mobile_it_will_look_like': {
      'gu': 'મોબાઈલ પર આ રીતે દેખાશે:',
      'hi': 'मोबाइल पर यह इस तरह दिखेगा:',
      'en': 'On mobile it will look like this:',
    },
    'right_now': {
      'gu': 'હમણાં',
      'hi': 'अभी',
      'en': 'right now',
    },
    'title_of_notification_2': {
      'gu': 'સૂચનાનું શીર્ષક',
      'hi': 'अधिसूचना का शीर्षक',
      'en': 'Title of Notification',
    },
    'your_message_will_appear_here': {
      'gu': 'અહીં તમારો સંદેશ દેખાશે...',
      'hi': 'आपका संदेश यहां दिखाई देगा...',
      'en': 'Your message will appear here...',
    },
    'send_an_instant_push_notification': {
      'gu': 'તુરંત પુશ સૂચના મોકલો',
      'hi': 'तत्काल पुश सूचना भेजें',
      'en': 'Send an instant push notification',
    },
    'sq_ft_wise_or': {
      'gu': '(ચોરસ ફૂટ મુજબ) અથવા',
      'hi': '(वर्ग फुट अनुसार) या',
      'en': '(sq. ft. wise) or',
    },
    'diwali_decoration_security_contribution': {
      'gu': 'દિવાળી ડેકોરેશન / સુરક્ષા ફાળો',
      'hi': 'दिवाली सजावट/सुरक्षा योगदान',
      'en': 'Diwali Decoration / Security Contribution',
    },
    'society_festival_development_contribution': {
      'gu': 'સોસાયટી ઉત્સવ / વિકાસ ફાળો',
      'hi': 'समाज उत्सव/विकास योगदान',
      'en': 'Society Festival / Development Contribution',
    },
    'ganesh_mahotsav_navratri_contribution': {
      'gu': 'ગણેશ મહોત્સવ / નવરાત્રિ ફાળો',
      'hi': 'गणेश महोत्सव/नवरात्रि योगदान',
      'en': 'Ganesh Mahotsav / Navratri contribution',
    },
    'shop_2': {
      'gu': 'દુકાન',
      'hi': 'दुकान',
      'en': 'shop',
    },
    'building': {
      'gu': 'મકાન',
      'hi': 'इमारत',
      'en': 'Building',
    },
    'unit': {
      'gu': 'એકમ',
      'hi': 'इकाई',
      'en': 'unit',
    },
    'flat': {
      'gu': 'ફ્લેટ',
      'hi': 'समतल',
      'en': 'Flat',
    },
    'shops': {
      'gu': 'દુકાનો',
      'hi': 'दुकानें',
      'en': 'shops',
    },
    'houses': {
      'gu': 'મકાનો',
      'hi': 'मकान',
      'en': 'houses',
    },
    'units': {
      'gu': 'એકમો',
      'hi': 'इकाइयाँ',
      'en': 'units',
    },
    'flats': {
      'gu': 'ફ્લેટ્સ',
      'hi': 'फ़्लैट',
      'en': 'Flats',
    },
    'shop_maintenance': {
      'gu': 'શોપ મેન્ટેનન્સ',
      'hi': 'दुकान का रखरखाव',
      'en': 'Shop Maintenance',
    },
    'society_maintenance': {
      'gu': 'સોસાયટી મેન્ટેનન્સ',
      'hi': 'सोसायटी रखरखाव',
      'en': 'Society Maintenance',
    },
    'please_enter_valid_square_feet_sqft': {
      'gu': 'કૃપા કરીને માન્ય ચોરસ ફૂટ (Sq.Ft) દર દાખલ કરો.',
      'hi': 'कृपया वैध वर्ग फुट (वर्ग फुट) दर दर्ज करें।',
      'en': 'Please enter valid Square Feet (Sq.Ft) rate.',
    },
    'please_enter_valid_amount_for_both': {
      'gu': 'કૃપા કરીને દુકાન અને ફ્લેટ બંને માટે માન્ય રકમ દાખલ કરો.',
      'hi': 'कृपया दुकान और फ्लैट दोनों के लिए वैध राशि दर्ज करें।',
      'en': 'Please enter valid amount for both shop and flat.',
    },
    'please_enter_a_valid_amount': {
      'gu': 'કૃપા કરીને માન્ય રકમ દાખલ કરો.',
      'hi': 'कृपया एक वैध राशि दर्ज करें.',
      'en': 'Please enter a valid amount.',
    },
    'please_enter_the_title_of_the': {
      'gu': 'કૃપા કરીને બિલનું શીર્ષક લખો.',
      'hi': 'कृपया बिल का शीर्षक दर्ज करें.',
      'en': 'Please enter the title of the bill.',
    },
    'bulk_bill_successful': {
      'gu': 'બલ્ક બિલ સફળ!',
      'hi': 'थोक बिल सफल!',
      'en': 'Bulk bill successful!',
    },
    'see_maintenance_account': {
      'gu': 'મેન્ટેનન્સ હિસાબ જુઓ',
      'hi': 'रखरखाव खाता देखें',
      'en': 'See Maintenance Account',
    },
    'shopping_mall_billing_desk': {
      'gu': 'શોપિંગ મોલ બિલિંગ ડેસ્ક',
      'hi': 'शॉपिंग मॉल बिलिंग डेस्क',
      'en': 'Shopping Mall Billing Desk',
    },
    'mixed_complex_billing_desk': {
      'gu': 'મિક્સ્ડ કોમ્પ્લેક્સ બિલિંગ ડેસ્ક',
      'hi': 'मिश्रित कॉम्प्लेक्स बिलिंग डेस्क',
      'en': 'Mixed Complex Billing Desk',
    },
    'society_bungalow_billing_desk': {
      'gu': 'સોસાયટી / બંગલો બિલિંગ ડેસ્ક',
      'hi': 'सोसायटी/बंगला बिलिंग डेस्क',
      'en': 'Society / Bungalow Billing Desk',
    },
    'residential_flat_billing_desk': {
      'gu': 'રેસિડેન્શિયલ ફ્લેટ બિલિંગ ડેસ્ક',
      'hi': 'आवासीय फ्लैट बिलिंग डेस्क',
      'en': 'Residential Flat Billing Desk',
    },
    'area_sqft_rate_for_each_shop': {
      'gu': 'દરેક દુકાન / ઓફિસ માટે એરિયા (Sq.Ft) દર & ૧૮% GST ઇન્વોઇસિંગ',
      'hi': 'प्रत्येक दुकान/कार्यालय के लिए क्षेत्र (वर्ग फीट) दर और 18% जीएसटी चालान',
      'en': 'Area (Sq.Ft) rate for each shop / office & 18% GST invoicing',
    },
    'dual_split_rate_billing_engine_for': {
      'gu': 'દુકાનો અને ફ્લેટ્સ માટે ડ્યુઅલ સ્પ્લિટ રેટ બિલિંગ એન્જિન',
      'hi': 'दुकानों और फ्लैटों के लिए दोहरी विभाजन दर बिलिंग इंजन',
      'en': 'Dual split rate billing engine for shops and flats',
    },
    'street_and_plot_wise_bungalow_society': {
      'gu': 'શેરી અને પ્લોટ વાઇઝ બંગલો સોસાયટી મેન્ટેનન્સ બિલિંગ',
      'hi': 'स्ट्रीट और प्लॉट वाइज बंगला सोसायटी रखरखाव बिलिंग',
      'en': 'Street and Plot Wise Bungalow Society Maintenance Billing',
    },
    'automated_monthly_billing_for_all_flats': {
      'gu': 'સોસાયટી અને ટાવરના તમામ ફ્લેટ્સ માટે ઓટોમેટેડ માસિક બિલિંગ',
      'hi': 'सोसायटी और टावर के सभी फ्लैटों के लिए स्वचालित मासिक बिलिंग',
      'en': 'Automated monthly billing for all flats in the society and tower',
    },
    'txt_1_premises_details_and_scope': {
      'gu': '૧. પરિસર વિગતો અને સ્કોપ',
      'hi': '1. परिसर विवरण और दायरा',
      'en': '1. Premises Details and Scope',
    },
    'commercial_billing_based_on_carpet_area': {
      'gu': 'દરેક શોપ/ઓફિસ માટે કાર્પેટ એરિયા (Sq.Ft) આધારિત કોમર્શિયલ બિલિંગ',
      'hi': 'प्रत्येक दुकान/कार्यालय के लिए कारपेट एरिया (वर्ग फीट) के आधार पर वाणिज्यिक बिलिंग',
      'en': 'Commercial billing based on carpet area (Sq.Ft) for each shop/office',
    },
    'commercial_rate_for_shops_and_residential': {
      'gu': 'શોપ્સ માટે કોમર્શિયલ દર અને ફ્લેટ્સ માટે રેસિડેન્શિયલ દર',
      'hi': 'दुकानों के लिए वाणिज्यिक दर और फ्लैटों के लिए आवासीय दर',
      'en': 'Commercial rate for shops and residential rate for flats',
    },
    'street_no_as_per_bungalow_row': {
      'gu': 'શેરી નં. મુજબ બંગલા / રો-હાઉસ સોસાયટી બિલિંગ',
      'hi': 'गली नं. बंगला/रो हाउस सोसायटी बिलिंग के अनुसार',
      'en': 'Street no. As per bungalow / row house society billing',
    },
    'regular_billing_for_all_flats_in': {
      'gu': 'ટાવર અને વિંગ્સના તમામ ફ્લેટ્સ માટે નિયમિત બિલિંગ',
      'hi': 'टावर और विंग्स में सभी फ्लैटों के लिए नियमित बिलिंग',
      'en': 'Regular billing for all flats in Tower and Wings',
    },
    'total_units': {
      'gu': 'કુલ એકમો',
      'hi': 'कुल इकाइयाँ',
      'en': 'total units',
    },
    'total_area': {
      'gu': 'કુલ એરિયા',
      'hi': 'कुल क्षेत्रफल',
      'en': 'Total Area',
    },
    'billing_target_who_is_billed_for': {
      'gu': 'બિલિંગ લક્ષ્ય (કોના માટે બિલ બનાવવું છે?):',
      'hi': 'बिलिंग लक्ष्य (किसके लिए बिल किया जाता है?):',
      'en': 'Billing target (who is billed for?):',
    },
    'quarterly_maintenance': {
      'gu': 'ત્રિમાસિક મેન્ટેનન્સ',
      'hi': 'त्रैमासिक रखरखाव',
      'en': 'Quarterly Maintenance',
    },
    'annual_commercial_maintenance': {
      'gu': 'વાર્ષિક કોમર્શિયલ મેન્ટેનન્સ',
      'hi': 'वार्षिक वाणिज्यिक रखरखाव',
      'en': 'Annual Commercial Maintenance',
    },
    'annual_maintenance': {
      'gu': 'વાર્ષિક મેન્ટેનન્સ',
      'hi': 'वार्षिक रखरखाव',
      'en': 'Annual Maintenance',
    },
    'txt_2_billing_cycle_and_month': {
      'gu': '૨. બિલિંગ ચક્ર અને મહિનો',
      'hi': '2. बिलिंग चक्र और महीना',
      'en': '2. Billing cycle and month',
    },
    'title_of_bill': {
      'gu': 'બિલનું શીર્ષક (Title)',
      'hi': 'विधेयक का शीर्षक',
      'en': 'Title of Bill',
    },
    'txt_3_commercial_rate_calculation': {
      'gu': '૩. કોમર્શિયલ દર ગણતરી',
      'hi': '3. वाणिज्यिक दर गणना',
      'en': '3. Commercial rate calculation',
    },
    'square_feet_sqft_rate': {
      'gu': 'ચોરસ ફૂટ (Sq.Ft) દર',
      'hi': 'वर्ग फ़ुट (वर्ग फ़ुट) दर',
      'en': 'Square Feet (Sq.Ft) Rate',
    },
    'shop_area_wise': {
      'gu': 'દુકાન એરિયા મુજબ',
      'hi': 'क्षेत्रफल के अनुसार खरीदारी करें',
      'en': 'Shop area wise',
    },
    'fixed_shop_rate': {
      'gu': 'ફિક્સ શોપ દર',
      'hi': 'दुकान का रेट तय',
      'en': 'Fixed shop rate',
    },
    'the_same_amount_for_each': {
      'gu': 'દરેક માટે સમાન રકમ',
      'hi': 'प्रत्येक के लिए समान राशि',
      'en': 'The same amount for each',
    },
    'per_square_feet_sqft_monthly_rate': {
      'gu': 'પ્રતિ ચોરસ ફૂટ (Sq.Ft) માસિક દર',
      'hi': 'प्रति वर्ग फ़ुट (वर्ग फ़ुट) मासिक दर',
      'en': 'Per Square Feet (Sq.Ft) Monthly Rate',
    },
    'live_calculation_example_400_sqft_shop': {
      'gu': 'લાઇવ ગણતરી ઉદાહરણ (400 Sq.Ft દુકાન):',
      'hi': 'लाइव गणना उदाहरण (400 वर्ग फुट दुकान):',
      'en': 'Live Calculation Example (400 Sq.Ft Shop):',
    },
    'regular_amount_per_shop_office': {
      'gu': 'નિયમિત રકમ (પ્રતિ દુકાન / ઓફિસ)',
      'hi': 'नियमित राशि (प्रति दुकान/कार्यालय)',
      'en': 'Regular Amount (Per Shop / Office)',
    },
    'txt_3_split_rate_calculation': {
      'gu': '૩. સ્પ્લિટ રેટ ગણતરી',
      'hi': '3. विभाजन दर गणना',
      'en': '3. Split rate calculation',
    },
    'eg_2500': {
      'gu': 'દા.ત. 2500',
      'hi': 'जैसे 2500',
      'en': 'E.g. 2500',
    },
    'residential_flat_rate_per_flat': {
      'gu': 'રેસિડેન્શિયલ ફ્લેટ દર (પ્રતિ ફ્લેટ)',
      'hi': 'आवासीय फ्लैट दर (प्रति फ्लैट)',
      'en': 'Residential Flat Rate (Per Flat)',
    },
    'eg_1500': {
      'gu': 'દા.ત. 1500',
      'hi': 'जैसे 1500',
      'en': 'E.g. 1500',
    },
    'txt_3_flat_maintenance_amount': {
      'gu': '૩. ફ્લેટ મેન્ટેનન્સ રકમ',
      'hi': '3. फ्लैट रखरखाव राशि',
      'en': '3. Flat maintenance amount',
    },
    'regular_amount_per_flat': {
      'gu': 'નિયમિત રકમ (પ્રતિ ફ્લેટ)',
      'hi': 'नियमित राशि (प्रति फ्लैट)',
      'en': 'Regular Amount (per Flat)',
    },
    'txt_3_society_maintenance_amount': {
      'gu': '૩. સોસાયટી મેન્ટેનન્સ રકમ',
      'hi': '3. सोसायटी भरण-पोषण राशि',
      'en': '3. Society Maintenance Amount',
    },
    'regular_amount_per_house_plot': {
      'gu': 'નિયમિત રકમ (પ્રતિ મકાન / પ્લોટ)',
      'hi': 'नियमित राशि (प्रति मकान/प्लॉट)',
      'en': 'Regular Amount (Per House / Plot)',
    },
    'add_18_gst_tax_to_invoice': {
      'gu': '૧૮% GST ટેક્સ ઇનવોઇસ ઉમેરો',
      'hi': 'इनवॉइस में 18% जीएसटी टैक्स जोड़ें',
      'en': 'Add 18% GST tax to invoice',
    },
    'txt_9_cgst_9_sgst_for_commercial': {
      'gu': 'કોમર્શિયલ શોપ્સ માટે 9% CGST + 9% SGST (ફ્લેટ્સ કરમુક્ત)',
      'hi': 'वाणिज्यिक दुकानों के लिए 9% सीजीएसटी + 9% एसजीएसटी (फ्लैट कर मुक्त)',
      'en': '9% CGST + 9% SGST for commercial shops (flats tax free)',
    },
    'txt_9_cgst_9_sgst_for_shops': {
      'gu': 'દુકાનો / ઑફિસો માટે 9% CGST + 9% SGST',
      'hi': 'दुकानों/कार्यालयों के लिए 9% सीजीएसटी + 9% एसजीएसटी',
      'en': '9% CGST + 9% SGST for shops / offices',
    },
    'society_mall_gstin_no': {
      'gu': 'સોસાયટી / મોલ GSTIN નંબર',
      'hi': 'सोसायटी/मॉल जीएसटीआईएन नं',
      'en': 'SOCIETY / MALL GSTIN NO',
    },
    'eg_24aaaaa0000a1z5': {
      'gu': 'દા.ત. 24AAAAA0000A1Z5',
      'hi': 'जैसे 24AAAAA0000A1Z5',
      'en': 'E.g. 24AAAAA0000A1Z5',
    },
    'txt_4_due_date': {
      'gu': '૪. છેલ્લી તારીખ (Due Date)',
      'hi': '4. नियत तिथि',
      'en': '4. Due Date',
    },
    'the_deadline_has_passed': {
      'gu': 'મુદત વીતી ગઈ છે',
      'hi': 'समय सीमा बीत चुकी है',
      'en': 'The deadline has passed',
    },
    'tap_to_change_the_date': {
      'gu': 'તારીખ બદલવા માટે ટેપ કરો',
      'hi': 'तारीख बदलने के लिए टैप करें',
      'en': 'Tap to change the date',
    },
    'txt_7_days': {
      'gu': '+૭ દિવસ',
      'hi': '+7 दिन',
      'en': '+7 days',
    },
    'txt_10_days': {
      'gu': '+૧૦ દિવસ',
      'hi': '+10 दिन',
      'en': '+10 days',
    },
    'txt_15_days': {
      'gu': '+૧૫ દિવસ',
      'hi': '+15 दिन',
      'en': '+15 days',
    },
    'end_of_month': {
      'gu': 'મહિનાનો અંત',
      'hi': 'महीने का अंत',
      'en': 'end of month',
    },
    'txt_5_special_security_decoration_contribution': {
      'gu': '૫. વિશેષ સુરક્ષા / ડેકોરેશન ફાળો',
      'hi': '5. विशेष सुरक्षा/सजावट योगदान',
      'en': '5. Special Security / Decoration Contribution',
    },
    'txt_5_add_a_festivalspecial_contribution': {
      'gu': '૫. તહેવાર / વિશેષ ફાળો ઉમેરો',
      'hi': '5. कोई उत्सव/विशेष योगदान जोड़ें',
      'en': '5. Add a festival/special contribution',
    },
    'to_add_festivalspecial_contribution_separately_to': {
      'gu': 'મેન્ટેનન્સ રસીદમાં ઉત્સવ/વિશેષ ફાળો અલગથી ઉમેરવા માટે',
      'hi': 'रख-रखाव रसीद में त्यौहार/विशेष अंशदान अलग से जोड़ने हेतु',
      'en': 'To add festival/special contribution separately to maintenance receipt',
    },
    'name_of_contribution_event': {
      'gu': 'ફાળો / પ્રસંગનું નામ',
      'hi': 'योगदान/घटना का नाम',
      'en': 'Name of Contribution / Event',
    },
    'ganesh_festival_contribution': {
      'gu': 'ગણેશ મહોત્સવ ફાળો',
      'hi': 'गणेश उत्सव योगदान',
      'en': 'Ganesh festival contribution',
    },
    'diwali_lighting_contribution': {
      'gu': 'દિવાળી લાઈટિંગ ફાળો',
      'hi': 'दिवाली प्रकाश योगदान',
      'en': 'Diwali lighting contribution',
    },
    'digital_invoice_preview': {
      'gu': 'ડિજિટલ ઇનવોઇસ પ્રીવ્યૂ',
      'hi': 'डिजिटल चालान पूर्वावलोकन',
      'en': 'Digital Invoice Preview',
    },
    'receipt_based_on_sqft': {
      'gu': 'Sq.Ft બેઝ્ડ રસીદ',
      'hi': 'वर्ग फीट के आधार पर रसीद',
      'en': 'Receipt based on Sq.Ft',
    },
    'shop_fix_receipt': {
      'gu': 'શોપ ફિક્સ રસીદ',
      'hi': 'दुकान फिक्स रसीद',
      'en': 'Shop fix receipt',
    },
    'hybrid_split_receipt': {
      'gu': 'હાઇબ્રિડ સ્પ્લિટ રસીદ',
      'hi': 'हाइब्रिड स्प्लिट रसीद',
      'en': 'Hybrid Split Receipt',
    },
    'monthly_digital_receipt': {
      'gu': 'માસિક ડિજિટલ રસીદ',
      'hi': 'मासिक डिजिटल रसीद',
      'en': 'Monthly digital receipt',
    },
    'regular_monthly_maintenance': {
      'gu': 'નિયમિત માસિક મેન્ટેનન્સ:',
      'hi': 'नियमित मासिक रखरखाव:',
      'en': 'Regular monthly maintenance:',
    },
    'txt_18_gst_9_cgst_9_sgst': {
      'gu': '૧૮% GST (9% CGST + 9% SGST):',
      'hi': '18% जीएसटी (9% सीजीएसटी + 9% एसजीएसटी):',
      'en': '18% GST (9% CGST + 9% SGST):',
    },
    'no_outstanding_complaints': {
      'gu': 'કોઈ બાકી ફરિયાદ નથી!',
      'hi': 'कोई बकाया शिकायत नहीं!',
      'en': 'No outstanding complaints!',
    },
    'no_complaints_have_been_registered_yet': {
      'gu': 'હજી સુધી કોઈ ફરિયાદ નોંધાયેલ નથી.',
      'hi': 'अभी तक कोई शिकायत दर्ज नहीं की गई है.',
      'en': 'No complaints have been registered yet.',
    },
    'all_questions_are_resolved_everything_is': {
      'gu': 'બધા પ્રશ્નો ઉકેલાઈ ગયા છે. બધું સરસ ચાલે છે!',
      'hi': 'सभी प्रश्न हल हो गए हैं. सब कुछ बढ़िया चल रहा है!',
      'en': 'All questions are resolved. Everything is going great!',
    },
    'when_a_member_lodges_a_complaint': {
      'gu': 'જ્યારે કોઈ સભ્ય ફરિયાદ નોંધાવશે ત્યારે અહીં દેખાશે.',
      'hi': 'जब कोई सदस्य शिकायत दर्ज कराएगा तो वह यहां दिखाई देगी।',
      'en': 'When a member lodges a complaint it will appear here.',
    },
    'resolved': {
      'gu': 'ઉકેલાઈ ગઈ',
      'hi': 'समाधान हो गया',
      'en': 'resolved',
    },
    'pending': {
      'gu': 'બાકી (Pending)',
      'hi': 'लंबित',
      'en': 'Pending',
    },
    'zoom_in': {
      'gu': 'ઝૂમ કરો',
      'hi': 'ज़ूम इन करें',
      'en': 'Zoom in',
    },
    'complaint_marked_as_resolved': {
      'gu': 'ફરિયાદ ઉકેલાઈ ગઈ તરીકે નોંધાઈ ગઈ!',
      'hi': 'शिकायत को समाधान के रूप में चिह्नित किया गया!',
      'en': 'Complaint marked as resolved!',
    },
    'mark_as_solved': {
      'gu': 'ઉકેલાઈ તરીકે માર્ક કરો',
      'hi': 'हल के रूप में चिह्नित करें',
      'en': 'Mark as solved',
    },
    'admin_control_panel': {
      'gu': 'એડમિન કંટ્રોલ પેનલ',
      'hi': 'व्यवस्थापक नियंत्रण कक्ष',
      'en': 'Admin Control Panel',
    },
    'grievance_redressal_centre': {
      'gu': 'ફરિયાદ નિવારણ સેન્ટર',
      'hi': 'शिकायत निवारण केंद्र',
      'en': 'Grievance Redressal Centre',
    },
    'complaints_alerts': {
      'gu': 'ફરિયાદો & એલર્ટ્સ',
      'hi': 'शिकायतें एवं चेतावनियाँ',
      'en': 'Complaints & Alerts',
    },
    'admin_panel': {
      'gu': 'એડમિન પેનલ',
      'hi': 'व्यवस्थापक पैनल',
      'en': 'Admin panel',
    },
    'smart_security_active': {
      'gu': 'સ્માર્ટ સિક્યોરિટી • સક્રિય',
      'hi': 'स्मार्ट सुरक्षा • सक्रिय',
      'en': 'Smart Security • Active',
    },
    'smart_society_command_hub': {
      'gu': 'સ્માર્ટ સોસાયટી કમાન્ડ હબ',
      'hi': 'स्मार्ट सोसायटी कमांड हब',
      'en': 'Smart Society Command Hub',
    },
    'gate_visitors_security_cover_maintenance_and': {
      'gu': 'ગેટ વિઝિટર્સ, સિક્યોરિટી કવચ, મેન્ટેનન્સ અને ડિજિટલ પરિપત્ર',
      'hi': 'गेट आगंतुक, सुरक्षा कवर, रखरखाव और डिजिटल परिसंचरण',
      'en': 'Gate visitors, security cover, maintenance and digital circulation',
    },
    'new_notice': {
      'gu': 'નવી નોટિસ',
      'hi': 'नई सूचना',
      'en': 'New notice',
    },
    'maintenance_portal': {
      'gu': 'મેન્ટેનન્સ પોર્ટલ',
      'hi': 'रखरखाव पोर्टल',
      'en': 'Maintenance Portal',
    },
    'emergency_help': {
      'gu': 'ઈમરજન્સી હેલ્પ',
      'hi': 'आपातकालीन सहायता',
      'en': 'Emergency help',
    },
    'society_security_arrangements_are_normal_no': {
      'gu': 'સોસાયટી સુરક્ષા વ્યવસ્થા સામાન્ય છે • કોઈ પેન્ડિંગ ફરિયાદ નથી',
      'hi': 'सोसायटी की सुरक्षा व्यवस्था सामान्य है • कोई शिकायत लंबित नहीं है',
      'en': 'Society security arrangements are normal • No pending complaints',
    },
    'tap_here_for_instant_check_and': {
      'gu': 'તુરંત તપાસ અને નિરાકરણ માટે અહીં ટેપ કરો',
      'hi': 'तत्काल जांच और समाधान के लिए यहां टैप करें',
      'en': 'Tap here for instant check and resolution',
    },
    'family_directory': {
      'gu': 'પરિવાર ડિરેક્ટરી',
      'hi': 'पारिवारिक निर्देशिका',
      'en': 'Family Directory',
    },
    'watchman_staff_pin': {
      'gu': 'વોચમેન સ્ટાફ & PIN',
      'hi': 'चौकीदार कर्मचारी और पिन',
      'en': 'WATCHMAN STAFF & PIN',
    },
    'structure_map': {
      'gu': 'સ્ટ્રક્ચર નકશો',
      'hi': 'संरचना मानचित्र',
      'en': 'Structure map',
    },
    'get_live_traffic': {
      'gu': 'ગેટ લાઈવ ટ્રાફિક',
      'hi': 'लाइव ट्रैफ़िक प्राप्त करें',
      'en': 'Get Live Traffic',
    },
    'maintenance_portal_qr_payment': {
      'gu': 'મેન્ટેનન્સ પોર્ટલ & QR પેમેન્ટ',
      'hi': 'रखरखाव पोर्टल और क्यूआर भुगतान',
      'en': 'Maintenance Portal & QR Payment',
    },
    'upi_1tap': {
      'gu': 'UPI ૧-ટેપ',
      'hi': 'यूपीआई 1-टैप करें',
      'en': 'UPI 1-Tap',
    },
    'monthly_billing_society_upi_qr_scan': {
      'gu': 'માસિક બિલિંગ, સોસાયટી UPI QR સ્કેન અને ઑનલાઇન કલેક્શન',
      'hi': 'मासिक बिलिंग, सोसायटी यूपीआई क्यूआर स्कैन और ऑनलाइन संग्रह',
      'en': 'Monthly Billing, Society UPI QR Scan and Online Collection',
    },
    'billing_desk': {
      'gu': 'બિલિંગ ડેસ્ક',
      'hi': 'बिलिंग डेस्क',
      'en': 'Billing Desk',
    },
    'bankupi_setting': {
      'gu': 'બેંક/UPI સેટિંગ',
      'hi': 'बैंक/UPI सेटिंग',
      'en': 'Bank/UPI setting',
    },
    'society_accounts_expenditure_ledger_fund': {
      'gu': 'સોસાયટી હિસાબ & ખર્ચ (Ledger & Fund)',
      'hi': 'सोसायटी खाते एवं व्यय (बही एवं निधि)',
      'en': 'Society Accounts & Expenditure (Ledger & Fund)',
    },
    'live_get_activity': {
      'gu': 'લાઈવ ગેટ એક્ટિવિટી',
      'hi': 'लाइव गतिविधि प्राप्त करें',
      'en': 'Live get activity',
    },
    'txt_24x7_live': {
      'gu': '૨૪x૭ લાઈવ',
      'hi': '24x7 लाइव',
      'en': '24x7 Live',
    },
    'view_the_report': {
      'gu': 'રિપોર્ટ જુઓ',
      'hi': 'रिपोर्ट देखें',
      'en': 'View the report',
    },
    'gate_protection_is_active_normal': {
      'gu': 'ગેટ સુરક્ષા સક્રિય & સામાન્ય છે',
      'hi': 'गेट सुरक्षा सक्रिय एवं सामान्य है',
      'en': 'Gate protection is active & normal',
    },
    'nowadays_all_the_security_at_the': {
      'gu': 'આજના દિવસમાં સોસાયટી ગેટ પર તમામ સુરક્ષા સામાન્ય છે. કોઈ પેન્ડિંગ કે શંકાસ્પદ મુલાકાતી નથી.',
      'hi': 'आजकल सोसायटी गेट पर सारी सुरक्षा सामान्य है। कोई लंबित या संदिग्ध आगंतुक नहीं।',
      'en': 'Nowadays all the security at the society gate is normal. No pending or suspicious visitors.',
    },
    'no_visitor_entries_were_found_according': {
      'gu': 'પસંદ કરેલ ફિલ્ટર મુજબ કોઈ મુલાકાતીની એન્ટ્રી મળી નથી.',
      'hi': 'चयनित फ़िल्टर के अनुसार कोई विज़िटर प्रविष्टियाँ नहीं मिलीं।',
      'en': 'No visitor entries were found according to the selected filter.',
    },
    'visitor_register': {
      'gu': 'મુલાકાતી રજીસ્ટર',
      'hi': 'आगंतुक रजिस्टर',
      'en': 'Visitor Register',
    },
    'watchmen_manage': {
      'gu': 'વોચમેન મેનેજ',
      'hi': 'चौकीदार संभालते हैं',
      'en': 'Watchmen manage',
    },
    'interview': {
      'gu': 'મુલાકાત',
      'hi': 'साक्षात्कार',
      'en': 'interview',
    },
    'society': {
      'gu': 'સોસાયટી',
      'hi': 'समाज',
      'en': 'Society',
    },
    'rejected_2': {
      'gu': 'નકારેલ',
      'hi': 'अस्वीकृत',
      'en': 'Rejected',
    },
    'at_the_gate': {
      'gu': 'ગેટ પર',
      'hi': 'गेट पर',
      'en': 'at the gate',
    },
    'parcel': {
      'gu': 'પાર્સલ',
      'hi': 'पार्सल',
      'en': 'parcel',
    },
    'delivery': {
      'gu': 'ડિલિવરી',
      'hi': 'डिलिवरी',
      'en': 'Delivery',
    },
    'taxi': {
      'gu': 'ટેક્સી',
      'hi': 'टैक्सी',
      'en': 'Taxi',
    },
    'rickshaw': {
      'gu': 'રીક્ષા',
      'hi': 'रिक्शा',
      'en': 'Rickshaw',
    },
    'working': {
      'gu': 'કામવાળા',
      'hi': 'काम कर रहे हैं',
      'en': 'working',
    },
    'repairing': {
      'gu': 'રીપેરિંગ',
      'hi': 'मरम्मत',
      'en': 'Repairing',
    },
    'is_in_approved': {
      'gu': 'અંદર છે (Approved)',
      'hi': 'में है (स्वीकृत)',
      'en': 'is in (Approved)',
    },
    'rejected_3': {
      'gu': 'નકારેલ (Rejected)',
      'hi': 'अस्वीकृत',
      'en': 'Rejected',
    },
    'checked_out': {
      'gu': 'બહાર ગયા (Checked Out)',
      'hi': 'चेक आउट किया गया',
      'en': 'Checked Out',
    },
    'at_the_gate_pending': {
      'gu': 'ગેટ પર (Pending)',
      'hi': 'गेट पर (लंबित)',
      'en': 'At the gate (Pending)',
    },
    'purpose_of_visit': {
      'gu': 'મુલાકાત હેતુ:',
      'hi': 'यात्रा का उद्देश्य:',
      'en': 'Purpose of Visit:',
    },
    'mobile_number_2': {
      'gu': 'મોબાઇલ નંબર:',
      'hi': 'मोबाइल नंबर:',
      'en': 'Mobile Number:',
    },
    'vehicle_number_2': {
      'gu': 'વાહન નંબર:',
      'hi': 'वाहन संख्या:',
      'en': 'Vehicle Number:',
    },
    'entry_time_2': {
      'gu': 'પ્રવેશ સમય:',
      'hi': 'प्रवेश समय:',
      'en': 'Entry Time:',
    },
    'exited': {
      'gu': 'બહાર નીકળ્યા:',
      'hi': 'बाहर निकलें:',
      'en': 'Exited:',
    },
    'mark_gone_out': {
      'gu': 'બહાર ગયા માર્ક કરો',
      'hi': 'मार्क बाहर चला गया',
      'en': 'Mark gone out',
    },
    'delete_entry': {
      'gu': 'એન્ટ્રી ડિલીટ',
      'hi': 'प्रविष्टि हटाएँ',
      'en': 'Delete entry',
    },
    'delete_visitor_entry': {
      'gu': 'મુલાકાતી એન્ટ્રી ડિલીટ',
      'hi': 'विज़िटर प्रविष्टि हटाएँ',
      'en': 'Delete visitor entry',
    },
    'yes_delete': {
      'gu': 'હા, ડિલીટ કરો',
      'hi': 'हाँ, हटाएँ',
      'en': 'Yes, delete',
    },
    'entry_deleted_successfully': {
      'gu': 'એન્ટ્રી સફળતાપૂર્વક ડિલીટ થઈ.',
      'hi': 'प्रविष्टि सफलतापूर्वक हटा दी गई.',
      'en': 'Entry deleted successfully.',
    },
    'control_panel_management': {
      'gu': 'કંટ્રોલ પેનલ & મેનેજમેન્ટ',
      'hi': 'नियंत्रण कक्ष एवं प्रबंधन',
      'en': 'Control Panel & Management',
    },
    'all_2': {
      'gu': 'બધા (All)',
      'hi': 'सब',
      'en': 'All',
    },
    'security_gate': {
      'gu': '🛡️ સુરક્ષા & ગેટ',
      'hi': '🛡️ सुरक्षा एवं द्वार',
      'en': '🛡️ Security & Gate',
    },
    'communication_notification': {
      'gu': '📢 સંચાર & સૂચના',
      'hi': '📢 संचार एवं अधिसूचना',
      'en': '📢 Communication & Notification',
    },
    'administration_setup': {
      'gu': '🏢 વહીવટ & સેટઅપ',
      'hi': '🏢 प्रशासन एवं सेटअप',
      'en': '🏢 Administration & Setup',
    },
    'architecture_block_layout': {
      'gu': 'આર્કિટેક્ચર & બ્લોક ગોઠવણી',
      'hi': 'वास्तुकला एवं ब्लॉक लेआउट',
      'en': 'Architecture & Block Layout',
    },
    'member_signature_form_pdf': {
      'gu': 'સભ્ય સહી પત્રક (PDF)',
      'hi': 'सदस्य हस्ताक्षर प्रपत्र (पीडीएफ)',
      'en': 'Member Signature Form (PDF)',
    },
    'resolutionreason_signature_list': {
      'gu': 'ઠરાવ/કારણ & સહી લિસ્ટ',
      'hi': 'संकल्प/कारण एवं हस्ताक्षर सूची',
      'en': 'Resolution/Reason & Signature List',
    },
    'add_new_blockhouse': {
      'gu': 'નવા બ્લોક/ઘર એડ કરો',
      'hi': 'नया ब्लॉक/घर जोड़ें',
      'en': 'Add new block/house',
    },
    'member_staff_registration': {
      'gu': 'મેમ્બર & સ્ટાફ નોંધણી',
      'hi': 'सदस्य एवं कर्मचारी पंजीकरण',
      'en': 'Member & Staff Registration',
    },
    'immediate_notice_to_all': {
      'gu': 'તમામને તુરંત સૂચના',
      'hi': 'सभी को तत्काल सूचना',
      'en': 'Immediate notice to all',
    },
    'notice_board_post': {
      'gu': 'નોટિસ બોર્ડ પોસ્ટ',
      'hi': 'नोटिस बोर्ड पोस्ट',
      'en': 'Notice board post',
    },
    'digital_circular_publish': {
      'gu': 'ડિજિટલ પરિપત્ર પબ્લિશ',
      'hi': 'डिजिटल परिपत्र प्रकाशन',
      'en': 'Digital Circular Publish',
    },
    'member_problem_resolution': {
      'gu': 'મેમ્બર સમસ્યા & સમાધાન',
      'hi': 'सदस्य समस्या एवं समाधान',
      'en': 'Member Problem & Resolution',
    },
    'digital_voting_polls': {
      'gu': 'ડિજિટલ વોટિંગ & પોલ',
      'hi': 'डिजिटल वोटिंग और मतदान',
      'en': 'Digital Voting & Polls',
    },
    'visitor_entry_details': {
      'gu': 'મુલાકાતી એન્ટ્રી વિગત',
      'hi': 'आगंतुक प्रवेश विवरण',
      'en': 'Visitor Entry Details',
    },
    'duty_status_pin': {
      'gu': 'ડ્યુટી સ્ટેટસ & પિન',
      'hi': 'ड्यूटी स्थिति एवं पिन',
      'en': 'Duty Status & Pin',
    },
    'emergency_helpline': {
      'gu': 'ઈમરજન્સી હેલ્પલાઇન',
      'hi': 'आपातकालीन हेल्पलाइन',
      'en': 'Emergency Helpline',
    },
    'police_108_fire_plumber': {
      'gu': 'પોલીસ, ૧૦૮, ફાયર, પ્લમ્બર',
      'hi': 'पुलिस, 108, फायर, प्लम्बर',
      'en': 'Police, 108, Fire, Plumber',
    },
    'watchman_qr_scan_report': {
      'gu': 'વોચમેન QR સ્કેન રિપોર્ટ',
      'hi': 'वॉचमैन क्यूआर स्कैन रिपोर्ट',
      'en': 'Watchman QR Scan Report',
    },
    'bankupi_settings': {
      'gu': 'બેંક/UPI સેટિંગ્સ',
      'hi': 'बैंक/यूपीआई सेटिंग्स',
      'en': 'Bank/UPI Settings',
    },
    'society_collection_qr': {
      'gu': 'સોસાયટી કલેક્શન QR',
      'hi': 'सोसायटी संग्रह QR',
      'en': 'Society Collection QR',
    },
    'society_map': {
      'gu': 'સોસાયટી નકશો',
      'hi': 'समाज का नक्शा',
      'en': 'Society map',
    },
    'flats_visual_preview': {
      'gu': 'ફ્લેટ્સ વિઝ્યુઅલ પ્રિવ્યુ',
      'hi': 'फ़्लैट दृश्य पूर्वावलोकन',
      'en': 'Flats Visual Preview',
    },
    'generate_control_slots': {
      'gu': 'સ્લોટ્સ જનરેટ & કંટ્રોલ',
      'hi': 'स्लॉट उत्पन्न एवं नियंत्रित करें',
      'en': 'Generate & Control Slots',
    },
    'wadi_clubhouse_setup': {
      'gu': 'વાડી, ક્લબહાઉસ સેટઅપ',
      'hi': 'वाडी, क्लब हाउस सेटअप',
      'en': 'Wadi, clubhouse setup',
    },
    'visitor_analysis': {
      'gu': 'મુલાકાતી વિશ્લેષણ',
      'hi': 'आगंतुक विश्लेषण',
      'en': 'Visitor analysis',
    },
    'gate_traffic_entry_statistics': {
      'gu': 'ગેટ ટ્રાફિક & એન્ટ્રી આંકડા',
      'hi': 'गेट यातायात और प्रवेश आँकड़े',
      'en': 'Gate traffic & entry statistics',
    },
    'month': {
      'gu': 'મહિનો',
      'hi': 'महीना',
      'en': 'month',
    },
    'type': {
      'gu': 'પ્રકાર',
      'hi': 'प्रकार',
      'en': 'type',
    },
    'wing': {
      'gu': 'વિંગ (Wing)',
      'hi': 'विंग',
      'en': 'Wing',
    },
    'street': {
      'gu': 'શેરી (Street)',
      'hi': 'सड़क',
      'en': 'Street',
    },
    'remaining': {
      'gu': 'બાકી',
      'hi': 'शेष',
      'en': 'remaining',
    },
    'blocks_with_the_most_visitors': {
      'gu': 'સૌથી વધુ વિઝિટર્સ ધરાવતા બ્લોક્સ',
      'hi': 'सर्वाधिक विज़िटर वाले ब्लॉक',
      'en': 'Blocks with the most visitors',
    },
    'no_members_have_been_added_yet': {
      'gu': 'હજુ સુધી કોઈ મેમ્બર્સ ઉમેરાયા નથી',
      'hi': 'अभी तक कोई सदस्य नहीं जोड़ा गया है',
      'en': 'No members have been added yet',
    },
    'register_the_flat_owners_and_tenants': {
      'gu': 'સોસાયટીના ફ્લેટ માલિકો અને ભાડૂતોની નોંધણી કરો.',
      'hi': 'सोसायटी के फ्लैट मालिकों और किरायेदारों का पंजीकरण करें।',
      'en': 'Register the flat owners and tenants of the society.',
    },
    'add_new_member': {
      'gu': 'નવા મેમ્બર ઉમેરો',
      'hi': 'नया सदस्य जोड़ें',
      'en': 'Add new member',
    },
    'no_contact': {
      'gu': 'કોઈ સંપર્ક નથી',
      'hi': 'कोई संपर्क नहीं',
      'en': 'No contact',
    },
    'assign_the_post_of_president': {
      'gu': 'પ્રમુખ પદ સોંપો',
      'hi': 'अध्यक्ष का पद सौंपें',
      'en': 'Assign the post of president',
    },
    'send_a_notification': {
      'gu': 'સૂચના મોકલો',
      'hi': 'एक सूचना भेजें',
      'en': 'Send a notification',
    },
    'delegation_of_admin_authority': {
      'gu': 'એડમિન સત્તા સોંપણી',
      'hi': 'प्रशासन प्राधिकारी का प्रतिनिधिमंडल',
      'en': 'Delegation of admin authority',
    },
    'yes_delegate_authority': {
      'gu': 'હા, સત્તા સોંપો',
      'hi': 'हाँ, प्रतिनिधि प्राधिकारी',
      'en': 'Yes, delegate authority',
    },
    'ownership_has_successfully_changed': {
      'gu': 'માલિકી સફળતાપૂર્વક બદલાઈ ગઈ છે!',
      'hi': 'स्वामित्व सफलतापूर्वक बदल गया है!',
      'en': 'Ownership has successfully changed!',
    },
    'please_enter_both_service_name_and': {
      'gu': 'કૃપા કરીને સેવાનું નામ અને નંબર બંને દાખલ કરો.',
      'hi': 'कृपया सेवा का नाम और नंबर दोनों दर्ज करें।',
      'en': 'Please enter both service name and number.',
    },
    'txt_24x7_immediate_services': {
      'gu': '૨૪x૭ તાત્કાલિક સેવાઓ',
      'hi': '24x7 तत्काल सेवाएँ',
      'en': '24x7 Immediate Services',
    },
    'emergency_helpline_2': {
      'gu': 'ઇમરજન્સી હેલ્પલાઇન',
      'hi': 'आपातकालीन हेल्पलाइन',
      'en': 'Emergency Helpline',
    },
    'all_members_and_watchmen_will_be': {
      'gu': 'તમામ સભ્યો અને વોચમેન આ નંબરો પર ૧-ટેપથી કૉલ કરી શકશે.',
      'hi': 'सभी सदस्य और चौकीदार 1-टैप से इन नंबरों पर कॉल कर सकेंगे।',
      'en': 'All members and watchmen will be able to call these numbers with 1-tap.',
    },
    'quick_presets_add_with_1tap': {
      'gu': 'ઝડપી પ્રીસેટ્સ (૧-ટેપથી ઉમેરો):',
      'hi': 'त्वरित प्रीसेट (1-टैप से जोड़ें):',
      'en': 'Quick Presets (Add with 1-tap):',
    },
    'add_a_new_emergency_contact': {
      'gu': 'નવો ઈમરજન્સી સંપર્ક ઉમેરો:',
      'hi': 'एक नया आपातकालीन संपर्क जोड़ें:',
      'en': 'Add a new emergency contact:',
    },
    'name_of_service_person': {
      'gu': 'સેવા / વ્યક્તિનું નામ *',
      'hi': 'सेवा/व्यक्ति का नाम*',
      'en': 'Name of Service / Person *',
    },
    'eg_surat_fire_control_dr_patel': {
      'gu': 'દા.ત. સુરત ફાયર કંટ્રોલ, ડૉ. પટેલ',
      'hi': 'जैसे सूरत फायर कंट्रोल, डॉ. पटेल',
      'en': 'E.g. Surat Fire Control, Dr. Patel',
    },
    'contact_number_phone_number': {
      'gu': 'સંપર્ક નંબર (Phone Number) *',
      'hi': 'संपर्क नंबर (फोन नंबर) *',
      'en': 'Contact Number (Phone Number) *',
    },
    'eg_101_or_9876543210': {
      'gu': 'દા.ત. 101 અથવા 9876543210',
      'hi': 'जैसे 101 या 9876543210',
      'en': 'E.g. 101 or 9876543210',
    },
    'save_the_contact': {
      'gu': 'સંપર્ક સેવ કરો',
      'hi': 'संपर्क सहेजें',
      'en': 'Save the contact',
    },
    'current_emergency_helpline_list': {
      'gu': 'હાલની ઈમરજન્સી હેલ્પલાઇન લિસ્ટ:',
      'hi': 'वर्तमान आपातकालीन हेल्पलाइन सूची:',
      'en': 'Current Emergency Helpline List:',
    },
    'no_emergency_numbers_have_been_added': {
      'gu': 'હજુ સુધી કોઈ ઈમરજન્સી નંબર ઉમેરાયો નથી.\\nઉપરના પ્રીસેટ પર ટેપ કરીને નંબર ઉમેરો.',
      'hi': 'अभी तक कोई आपातकालीन नंबर नहीं जोड़ा गया है।\\nउपरोक्त प्रीसेट पर टैप करके एक नंबर जोड़ें।',
      'en': 'No emergency numbers have been added yet.\\nAdd a number by tapping on the preset above.',
    },
    'call': {
      'gu': 'કૉલ',
      'hi': 'बुलाओ',
      'en': 'Call',
    },
    'no_bill_available_for_this_month': {
      'gu': 'આ મહિના માટે કોઈ બિલ ઉપલબ્ધ નથી.',
      'hi': 'इस माह का कोई बिल उपलब्ध नहीं है.',
      'en': 'No bill available for this month.',
    },
    'monthly_maintenance': {
      'gu': 'માસિક મેન્ટેનન્સ',
      'hi': 'मासिक रखरखाव',
      'en': 'Monthly Maintenance',
    },
    'error_loading_qr_code': {
      'gu': 'QR કોડ લોડ કરવામાં ભૂલ આવી',
      'hi': 'QR कोड लोड करने में त्रुटि',
      'en': 'Error loading QR code',
    },
    'society_upi_id_is_not_set': {
      'gu': 'સોસાયટી UPI ID સેટ કરેલ નથી',
      'hi': 'सोसायटी UPI आईडी सेट नहीं है',
      'en': 'Society UPI ID is not set',
    },
    'enter_upi_id_below_to_view': {
      'gu': 'QR જોવા માટે નીચે UPI ID લખી સેવ કરો',
      'hi': 'QR देखने और सेव करने के लिए नीचे UPI आईडी दर्ज करें',
      'en': 'Enter UPI ID below to view QR and save',
    },
    'members_can_scan_this_qr_from': {
      'gu': 'મેમ્બર તેમના મોબાઈલની કોઈપણ UPI એપ\\n(Google Pay, PhonePe, Paytm, BHIM)\\nથી આ QR સ્કેન કરી શકે છે.',
      'hi': 'सदस्य इस QR को अपने मोबाइल पर किसी भी UPI ऐप\\n(Google Pay, PhonePe, Paytm, BHIM)\\n से स्कैन कर सकते हैं।',
      'en': 'Members can scan this QR from any UPI app\\n(Google Pay, PhonePe, Paytm, BHIM)\\n on their mobile.',
    },
    'upi_id_copied': {
      'gu': 'UPI ID કૉપી થઈ ગયો!',
      'hi': 'UPI आईडी कॉपी की गई!',
      'en': 'UPI ID copied!',
    },
    'set_society_upi_id': {
      'gu': 'સોસાયટી UPI ID સેટ કરો:',
      'hi': 'सोसाइटी UPI आईडी सेट करें:',
      'en': 'Set Society UPI ID:',
    },
    'change_upi_id': {
      'gu': 'UPI ID બદલો:',
      'hi': 'UPI आईडी बदलें:',
      'en': 'Change UPI ID:',
    },
    'eg_yournamebank_like_okhdfcbank_sbi': {
      'gu': 'દા.ત. yourname@bank (જેમ કે @okhdfcbank, @sbi)',
      'hi': 'जैसे आपका नाम@बैंक (जैसे @okhdfcbank, @sbi)',
      'en': 'E.g. yourname@bank (like @okhdfcbank, @sbi)',
    },
    'enter_the_correct_upi_id_eg': {
      'gu': 'સાચો UPI ID દાખલ કરો (દા.ત. yourname@bank)',
      'hi': 'सही UPI आईडी दर्ज करें (जैसे आपका नाम@बैंक)',
      'en': 'Enter the correct UPI ID (eg yourname@bank)',
    },
    'society_upi_id_saved_permanently': {
      'gu': 'સોસાયટી UPI ID કાયમી સેવ થઈ ગયો!',
      'hi': 'सोसाइटी UPI आईडी स्थायी रूप से सहेजी गई!',
      'en': 'Society UPI ID Saved Permanently!',
    },
    'save_update_qr': {
      'gu': 'સેવ & QR અપડેટ કરો',
      'hi': 'QR सहेजें और अपडेट करें',
      'en': 'Save & Update QR',
    },
    'click_on_the_following_link_to': {
      'gu': 'ઓનલાઇન UPI થી ચૂકવવા નીચેની લિંક પર ક્લિક કરો:\\n',
      'hi': 'UPI से ऑनलाइन भुगतान करने के लिए निम्नलिखित लिंक पर क्लिक करें:\\n',
      'en': 'Click on the following link to pay online with UPI:\\n',
    },
    'society_management': {
      'gu': '- સોસાયટી મેનેજમેન્ટ',
      'hi': '- सोसायटी प्रबंधन',
      'en': '- Society Management',
    },
    'payment_received': {
      'gu': 'પેમેન્ટ મળ્યું',
      'hi': 'भुगतान प्राप्त हुआ',
      'en': 'Payment received',
    },
    'payment_mode_3': {
      'gu': 'ચુકવણીનો પ્રકાર (Payment Mode):',
      'hi': 'भुगतान का प्रकार:',
      'en': 'Payment Mode:',
    },
    'upi_qr_scan': {
      'gu': 'UPI (QR સ્કેન)',
      'hi': 'यूपीआई (क्यूआर स्कैन)',
      'en': 'UPI (QR Scan)',
    },
    'qr_code_for_member_to_scan': {
      'gu': 'મેમ્બરને સ્કેન કરાવવા માટે QR કોડ:',
      'hi': 'सदस्य को स्कैन करने के लिए क्यूआर कोड:',
      'en': 'QR code for member to scan:',
    },
    'show_payment_qr_code_show_qr': {
      'gu': 'પેમેન્ટ QR કોડ બતાવો (Show QR)',
      'hi': 'भुगतान क्यूआर कोड दिखाएं (क्यूआर दिखाएं)',
      'en': 'Show Payment QR Code (Show QR)',
    },
    'utr_transaction_id_optional': {
      'gu': 'UTR / ટ્રાન્ઝેક્શન આઈડી (વૈકલ્પિક)',
      'hi': 'यूटीआर/लेनदेन आईडी (वैकल्पिक)',
      'en': 'UTR / Transaction ID (Optional)',
    },
    'check_no': {
      'gu': 'ચેક નંબર (Cheque No.) *',
      'hi': 'चेक नंबर *',
      'en': 'Check No. *',
    },
    'note_optional': {
      'gu': 'નોંધ (વૈકલ્પિક)',
      'hi': 'नोट (वैकल्पिक)',
      'en': 'Note (optional)',
    },
    'entering_the_check_number_is_required': {
      'gu': 'ચેક નંબર દાખલ કરવો જરૂરી છે',
      'hi': 'चेक नंबर दर्ज करना आवश्यक है',
      'en': 'Entering the check number is required',
    },
    'payment_accepted_and_receipt': {
      'gu': 'પેમેન્ટ સ્વીકારાઈ ગયું અને રસીદ બની ગઈ!',
      'hi': 'भुगतान स्वीकृत और रसीद!',
      'en': 'Payment Accepted and Receipt!',
    },
    'mark_paid': {
      'gu': 'પેઇડ માર્ક કરો',
      'hi': 'मार्क पेड',
      'en': 'Mark Paid',
    },
    'verify_upi_payment': {
      'gu': 'UPI પેમેન્ટ વેરિફાય કરો',
      'hi': 'UPI भुगतान सत्यापित करें',
      'en': 'Verify UPI payment',
    },
    'utr_transaction_no_entered_by_member': {
      'gu': 'સભ્ય દ્વારા દાખલ કરેલ UTR / ટ્રાન્ઝેક્શન નં:',
      'hi': 'सदस्य द्वारा दर्ज यूटीआर/लेनदेन संख्या:',
      'en': 'UTR / Transaction No. Entered by Member:',
    },
    'utr_not_entered': {
      'gu': 'UTR દાખલ નથી થયો',
      'hi': 'यूटीआर दर्ज नहीं किया गया',
      'en': 'UTR not entered',
    },
    'upi_payment_approved_successfully': {
      'gu': 'UPI પેમેન્ટ સફળતાપૂર્વક મંજૂર કરવામાં આવ્યું!',
      'hi': 'UPI भुगतान सफलतापूर्वक स्वीकृत!',
      'en': 'UPI Payment Approved Successfully!',
    },
    'approve_3': {
      'gu': 'એપ્રૂવ કરો (Approve)',
      'hi': 'स्वीकृत करें',
      'en': 'Approve',
    },
    'digital_receipt': {
      'gu': 'ડિજિટલ રસીદ',
      'hi': 'डिजिटल रसीद',
      'en': 'Digital receipt',
    },
    'bill': {
      'gu': 'બિલ',
      'hi': 'बिल',
      'en': 'Bill',
    },
    'flat_no': {
      'gu': 'ફ્લેટ નં',
      'hi': 'फ़्लैट नं',
      'en': 'Flat no',
    },
    'member': {
      'gu': 'સભ્ય',
      'hi': 'सदस्य',
      'en': 'member',
    },
    'mode_of_payment': {
      'gu': 'ચુકવણી રીત',
      'hi': 'भुगतान का तरीका',
      'en': 'Mode of payment',
    },
    'utr_no': {
      'gu': 'UTR નં',
      'hi': 'यूटीआर नं',
      'en': 'UTR NO',
    },
    'check_no_2': {
      'gu': 'ચેક નં',
      'hi': 'चेक नं',
      'en': 'Check no',
    },
    'view_the_pdf': {
      'gu': 'PDF જુઓ',
      'hi': 'पीडीएफ देखें',
      'en': 'View the PDF',
    },
    'pdf_download': {
      'gu': 'PDF ડાઉનલોડ',
      'hi': 'पीडीएफ डाउनलोड',
      'en': 'PDF download',
    },
    'owner': {
      'gu': 'માલિક (Owner)',
      'hi': 'मालिक',
      'en': 'Owner',
    },
    'tenant': {
      'gu': 'ભાડુઆત (Tenant)',
      'hi': 'किरायेदार',
      'en': 'Tenant',
    },
    'flat_owner': {
      'gu': 'ફ્લેટ માલિક (Owner)',
      'hi': 'फ्लैट मालिक',
      'en': 'Flat Owner',
    },
    'flats_2': {
      'gu': '^ફ્લેટ\\s+',
      'hi': '^फ्लैट\\s+',
      'en': '^Flat\\s+',
    },
    'member_profile_details': {
      'gu': 'સભ્ય પ્રોફાઇલ & વિગતો',
      'hi': 'सदस्य प्रोफ़ाइल और विवरण',
      'en': 'Member Profile & Details',
    },
    'paid': {
      'gu': 'ચૂકવેલ (Paid)',
      'hi': 'भुगतान किया गया',
      'en': 'Paid',
    },
    'amount_paid': {
      'gu': 'ચૂકવેલ રકમ',
      'hi': 'भुगतान की गई राशि',
      'en': 'amount paid',
    },
    'view_download_official_pdf_receipt': {
      'gu': 'સત્તાવાર PDF રસીદ જુઓ / ડાઉનલોડ',
      'hi': 'आधिकारिक पीडीएफ रसीद देखें/डाउनलोड करें',
      'en': 'View / Download Official PDF Receipt',
    },
    'under_review': {
      'gu': 'ચકાસણી હેઠળ (Review)',
      'hi': 'समीक्षाधीन',
      'en': 'Under Review',
    },
    'pending_online_payment_approval': {
      'gu': 'ઓનલાઇન ચુકવણી મંજૂરી બાકી',
      'hi': 'ऑनलाइन भुगतान अनुमोदन लंबित',
      'en': 'Pending online payment approval',
    },
    'total_amount': {
      'gu': 'કુલ રકમ',
      'hi': 'कुल राशि',
      'en': 'total amount',
    },
    'payment_pending': {
      'gu': 'ચુકવણી બાકી (Pending)',
      'hi': 'भुगतान लंबित है',
      'en': 'Payment Pending',
    },
    'amount_due': {
      'gu': 'બાકી રકમ',
      'hi': 'देय राशि',
      'en': 'amount due',
    },
    'not_registered': {
      'gu': 'નોંધાયેલ નથી',
      'hi': 'पंजीकृत नहीं है',
      'en': 'Not registered',
    },
    'copy_the_number': {
      'gu': 'નંબર કૉપિ કરો',
      'hi': 'नंबर कॉपी करें',
      'en': 'Copy the number',
    },
    'mobile_number_copied_to_clipboard': {
      'gu': 'મોબાઇલ નંબર ક્લિપબોર્ડમાં કૉપિ થયો',
      'hi': 'मोबाइल नंबर क्लिपबोर्ड पर कॉपी किया गया',
      'en': 'Mobile number copied to clipboard',
    },
    'email_address': {
      'gu': 'ઇમેઇલ એડ્રેસ',
      'hi': 'ईमेल पता',
      'en': 'email address',
    },
    'copy_the_email': {
      'gu': 'ઇમેઇલ કૉપિ કરો',
      'hi': 'ईमेल कॉपी करें',
      'en': 'Copy the email',
    },
    'email_address_copied_to_clipboard': {
      'gu': 'ઇમેઇલ એડ્રેસ ક્લિપબોર્ડમાં કૉપિ થયું',
      'hi': 'ईमेल पता क्लिपबोर्ड पर कॉपी किया गया',
      'en': 'Email address copied to clipboard',
    },
    'make_a_call': {
      'gu': 'કૉલ કરો',
      'hi': 'कॉल करो',
      'en': 'make a call',
    },
    'whatsapp_reminder': {
      'gu': 'વોટ્સએપ રીમાઇન્ડર',
      'hi': 'व्हाट्सएप अनुस्मारक',
      'en': 'WhatsApp Reminder',
    },
    'send_message': {
      'gu': 'મેસેજ મોકલો',
      'hi': 'संदेश भेजें',
      'en': 'send message',
    },
    'receipt_detail': {
      'gu': 'રસીદ વિગત',
      'hi': 'रसीद विवरण',
      'en': 'Receipt Detail',
    },
    'verify': {
      'gu': 'વેરિફાય કરો',
      'hi': 'सत्यापित करें',
      'en': 'Verify',
    },
    'accept_cash': {
      'gu': 'રોકડ સ્વીકારો',
      'hi': 'नकद स्वीकार करें',
      'en': 'Accept cash',
    },
    'firebase_security_permission_error': {
      'gu': 'ફાયરબેઝ સિક્યોરિટી પરમિશન એરર',
      'hi': 'फायरबेस सुरक्षा अनुमति त्रुटि',
      'en': 'Firebase Security Permission Error',
    },
    'to_resolve_this_error_publish_permission': {
      'gu': 'આ એરર ઉકેલવા Firebase Console -> Firestore Database -> Rules માં પરમિશન Publish કરો.',
      'hi': 'इस त्रुटि को हल करने के लिए फ़ायरबेस कंसोल -> फ़ायरस्टोर डेटाबेस -> नियमों में अनुमति प्रकाशित करें।',
      'en': 'To resolve this error Publish permission in Firebase Console -> Firestore Database -> Rules.',
    },
    'month_2': {
      'gu': 'મહિનો:',
      'hi': 'महीना:',
      'en': 'Month:',
    },
    'total_deposit': {
      'gu': 'કુલ જમા',
      'hi': 'कुल जमा',
      'en': 'total deposit',
    },
    'total_outstanding': {
      'gu': 'કુલ બાકી',
      'hi': 'कुल बकाया',
      'en': 'total outstanding',
    },
    'upi_verify': {
      'gu': 'UPI વેરિફાય',
      'hi': 'यूपीआई सत्यापित करें',
      'en': 'UPI Verify',
    },
    'pending_verification': {
      'gu': 'ચકાસણી પેન્ડિંગ',
      'hi': 'सत्यापन लंबित है',
      'en': 'Pending verification',
    },
    'there_are_no_bills_in_this': {
      'gu': 'આ ફિલ્ટરમાં કોઈ બિલ નથી.',
      'hi': 'इस फ़िल्टर में कोई बिल नहीं हैं.',
      'en': 'There are no bills in this filter.',
    },
    'generate_the_bill': {
      'gu': 'બિલ જનરેટ કરો',
      'hi': 'बिल जनरेट करें',
      'en': 'Generate the bill',
    },
    'upi_verification': {
      'gu': 'UPI ચકાસણી',
      'hi': 'यूपीआई सत्यापन',
      'en': 'UPI verification',
    },
    'the_deadline_has_passed_2': {
      'gu': 'મુદત વીતી ગઈ',
      'hi': 'समय सीमा बीत चुकी है',
      'en': 'The deadline has passed',
    },
    'receipt': {
      'gu': 'રસીદ (Receipt)',
      'hi': 'रसीद',
      'en': 'Receipt',
    },
    'qr_pay': {
      'gu': 'QR પે',
      'hi': 'क्यूआर भुगतान',
      'en': 'QR Pay',
    },
    'verify_2': {
      'gu': 'વેરિફાય',
      'hi': 'सत्यापित करें',
      'en': 'verify',
    },
    'general_assembly_resolution_approved': {
      'gu': 'સામાન્ય સભા ઠરાવ મંજૂરી',
      'hi': 'सामान्य सभा के प्रस्ताव को मंजूरी',
      'en': 'General Assembly resolution approved',
    },
    'formatdatetimenow01': {
      'gu': ').format(DateTime.now())}/૦૧',
      'hi': '.format(DateTime.now())}/01',
      'en': ').format(DateTime.now())}/01',
    },
    'therefore_we_all_the_members_of': {
      'gu': 'આથી અમે નીચે સહી કરનાર સોસાયટીના તમામ સભ્યો ઉપરોક્ત વિષય/ઠરાવ સાથે સંપૂર્ણ સંમત છીએ અને અમારી સ્વેચ્છાએ નીચે સહી કરીએ છીએ.',
      'hi': 'इसलिए हम अधोहस्ताक्षरी सोसायटी के सभी सदस्य उपरोक्त विषय/संकल्प से पूरी तरह सहमत हैं और स्वेच्छा से नीचे हस्ताक्षर करते हैं।',
      'en': 'Therefore we all the members of the undersigned Society fully agree with the above subject/resolution and voluntarily sign below.',
    },
    'lift_modernization_repairing_approval': {
      'gu': 'લિફ્ટ મોડર્નાઇઝેશન / રીપેરીંગ મંજૂરી',
      'hi': 'लिफ्ट आधुनिकीकरण/मरम्मत को मंजूरी',
      'en': 'Lift modernization / repairing approval',
    },
    'hence_we_all_the_members_unanimously': {
      'gu': 'આથી સોસાયટીની લિફ્ટ રીપેરીંગ/AMC રીન્યુઅલ અને મોડર્નાઇઝેશનના ખર્ચ બાબતે અમે તમામ સભ્યો સર્વાનુમતે સંમતિ આપીએ છીએ.',
      'hi': 'इसलिए हम सभी सदस्य लिफ्ट की मरम्मत/एएमसी नवीनीकरण और सोसायटी के आधुनिकीकरण की लागत पर एकमत हैं।',
      'en': 'Hence we all the members unanimously agree on the cost of lift repairing/AMC renewal and modernization of the society.',
    },
    'general_meeting_agm_resolution_approved': {
      'gu': 'સામાન્ય સભા (AGM) ઠરાવ મંજૂરી',
      'hi': 'आम बैठक (एजीएम) के प्रस्ताव को मंजूरी दी गई',
      'en': 'General Meeting (AGM) resolution approved',
    },
    'hence_we_all_the_members_ratify': {
      'gu': 'આથી સોસાયટીની સામાન્ય વાર્ષિક સભામાં પસાર કરાયેલ ઉપરોક્ત ઠરાવને અમે તમામ સભ્યો બહાલી આપીએ છીએ.',
      'hi': 'अतः हम सभी सदस्य सोसायटी की सामान्य वार्षिक बैठक में पारित उपरोक्त प्रस्ताव का अनुमोदन करते हैं।',
      'en': 'Hence we all the members ratify the above resolution passed in the General Annual Meeting of the Society.',
    },
    'cctv_camera_installation_consent': {
      'gu': 'સીસીટીવી કેમેરા ઇન્સ્ટોલેશન સંમતિ',
      'hi': 'सीसीटीवी कैमरा स्थापना की सहमति',
      'en': 'CCTV Camera Installation Consent',
    },
    'hence_we_the_members_agree_to': {
      'gu': 'આથી સોસાયટી પરિસરની સુરક્ષા માટે નવા સીસીટીવી કેમેરા સિસ્ટમ ઇન્સ્ટોલ કરવા બાબતે અમે સભ્યો સંમતિ આપીએ છીએ.',
      'hi': 'इसलिए हम सदस्य सोसायटी परिसर की सुरक्षा के लिए नया सीसीटीवी कैमरा सिस्टम लगाने पर सहमत हैं।',
      'en': 'Hence we the members agree to install new CCTV camera system for the security of the society premises.',
    },
    'society_redevelopment_consent_form': {
      'gu': 'સોસાયટી રિડેવલપમેન્ટ સંમતિ પત્રક',
      'hi': 'सोसायटी पुनर्विकास सहमति प्रपत्र',
      'en': 'Society Redevelopment Consent Form',
    },
    'hence_we_members_agree_to_the': {
      'gu': 'આથી સોસાયટીના રિડેવલપમેન્ટ પ્રક્રિયા અને કમિટી દ્વારા આગળની કાર્યવાહી હાથ ધરવા બાબતે અમે સભ્યો સંમતિ આપીએ છીએ.',
      'hi': 'इसलिए हम सदस्य सोसायटी की पुनर्विकास प्रक्रिया और समिति द्वारा की जाने वाली आगे की कार्रवाई से सहमत हैं।',
      'en': 'Hence we members agree to the redevelopment process of the society and further action to be taken by the committee.',
    },
    'society_colorwork_waterproofing_approved': {
      'gu': 'સોસાયટી કલરકામ & વોટરપ્રૂફિંગ મંજૂરી',
      'hi': 'सोसायटी कलरवर्क और वॉटरप्रूफिंग स्वीकृत',
      'en': 'Society Colorwork & Waterproofing Approved',
    },
    'we_the_members_hereby_consent_to': {
      'gu': 'આથી સોસાયટીની બિલ્ડિંગના બાહ્ય કલરકામ અને ટેરેસ વોટરપ્રૂફિંગ કાર્ય હાથ ધરવા માટે અમે સભ્યો સંમતિ આપીએ છીએ.',
      'hi': 'हम सदस्य सोसायटी की इमारत की बाहरी पेंटिंग और छत पर वॉटरप्रूफिंग करने के लिए सहमति देते हैं।',
      'en': 'We the members hereby consent to carry out external painting work and terrace waterproofing of the building of the society.',
    },
    'solar_rooftop_panel_plant_installation': {
      'gu': 'સોલાર રૂફટોપ પેનલ પ્લાન્ટ ઇન્સ્ટોલેશન',
      'hi': 'सोलर रूफटॉप पैनल प्लांट स्थापना',
      'en': 'Solar Rooftop Panel Plant Installation',
    },
    'hence_we_members_agree_for_installation': {
      'gu': 'આથી કોમન લાઈટિંગ અને લિફ્ટ માટે સોલાર રૂફટોપ સિસ્ટમ બેસાડવા તથા સબસિડી પ્રક્રિયા માટે અમે સભ્યો સંમતિ આપીએ છીએ.',
      'hi': 'इसलिए, हम सदस्य सौर छत प्रणाली की स्थापना और सामान्य प्रकाश व्यवस्था और लिफ्ट के लिए सब्सिडी प्रक्रिया के लिए सहमत हैं।',
      'en': 'Hence, we members agree for installation of solar rooftop system and subsidy process for common lighting and lift.',
    },
    'security_consent_to_new_gate_pass': {
      'gu': 'સિક્યોરિટી & નવા ગેટ પાસ નિયમો સંમતિ',
      'hi': 'नए गेट पास नियमों के लिए सुरक्षा एवं सहमति',
      'en': 'Security & Consent to New Gate Pass Rules',
    },
    'we_the_members_therefore_agree_to': {
      'gu': 'આથી સોસાયટીમાં મુલાકાતીઓ (વિઝિટર્સ) અને વાહનો માટેના નવા સુરક્ષા નિયમોનું પાલન કરવા બાબતે અમે સભ્યો સંમતિ આપીએ છીએ.',
      'hi': 'इसलिए हम सदस्य सोसायटी में आगंतुकों और वाहनों के लिए नए सुरक्षा नियमों का पालन करने के लिए सहमत हैं।',
      'en': 'We the members therefore agree to follow the new security rules for visitors and vehicles in the society.',
    },
    'special_maintenance_contribution_approval_form': {
      'gu': 'વિશેષ મેન્ટેનન્સ / ફાળો મંજૂરી પત્રક',
      'hi': 'विशेष रखरखाव/अंशदान अनुमोदन प्रपत्र',
      'en': 'Special Maintenance / Contribution Approval Form',
    },
    'therefore_we_members_agree_to_deposit': {
      'gu': 'આથી ઉપરોક્ત કામગીરી પેટે નક્કી કરેલ વિશેષ ફાળો નિયત સમયમાં જમા કરાવવા બાબતે અમે સભ્યો સંમતિ આપીએ છીએ.',
      'hi': 'अतः हम सदस्य उपरोक्त कार्यवाही के अन्तर्गत निर्धारित विशेष अंशदान निर्धारित समयावधि में जमा कराने हेतु सहमत हैं।',
      'en': 'Therefore, we members agree to deposit the special contribution determined under the above operation within the stipulated time.',
    },
    'empty_unit': {
      'gu': '— (ખાલી એકમ) —',
      'hi': '— (खाली इकाई) —',
      'en': '— (empty unit) —',
    },
    'no_members_or_flats_found_in': {
      'gu': 'પસંદ કરેલ વિંગમાં કોઈ સભ્યો કે ફ્લેટ્સ મળ્યા નથી!',
      'hi': 'चयनित विंग में कोई सदस्य या फ्लैट नहीं मिला!',
      'en': 'No members or flats found in the selected wing!',
    },
    'refresh_data': {
      'gu': 'રીફ્રેશ ડેટા',
      'hi': 'डेटा ताज़ा करें',
      'en': 'Refresh data',
    },
    'loading_society_members_and_flats': {
      'gu': 'સોસાયટી સભ્યો અને ફ્લેટ્સ લોડ થઈ રહ્યા છે...',
      'hi': 'सोसायटी के सदस्यों और फ्लैटों को लोड किया जा रहा है...',
      'en': 'Loading society members and flats...',
    },
    'official_member_signature_register': {
      'gu': 'સત્તાવાર સભ્ય સહી & સંમતિ રજીસ્ટર (Official Member Signature Register)',
      'hi': 'आधिकारिक सदस्य हस्ताक्षर रजिस्टर',
      'en': 'Official Member Signature Register',
    },
    'txt_1_purpose_of_signature': {
      'gu': '૧. સહી લેવાનું કારણ / ઠરાવ વિષય (Purpose)',
      'hi': '1. हस्ताक्षर का उद्देश्य',
      'en': '1. Purpose of signature',
    },
    'name_of_subject_purpose': {
      'gu': 'વિષય / હેતુનું નામ *',
      'hi': 'विषय का नाम/उद्देश्य*',
      'en': 'Name of Subject / Purpose *',
    },
    'eg_lift_repairing_approval_agm_resolution': {
      'gu': 'દા.ત. લિફ્ટ રીપેરીંગ મંજૂરી / AGM ઠરાવ',
      'hi': 'जैसे लिफ्ट मरम्मत अनुमोदन/एजीएम समाधान',
      'en': 'E.g. Lift repairing approval / AGM resolution',
    },
    'common_reasons_used_frequently_onetap_select': {
      'gu': 'વારંવાર વપરાતા સામાન્ય કારણો (વન-ટેપ સિલેક્ટ):',
      'hi': 'अक्सर उपयोग किए जाने वाले सामान्य कारण (वन-टैप सेलेक्ट):',
      'en': 'Common reasons used frequently (One-Tap Select):',
    },
    'txt_2_sheet_settings_wing_selection': {
      'gu': '૨. પત્રક સેટિંગ્સ & વિંગ પસંદગી',
      'hi': '2. शीट सेटिंग्स और विंग चयन',
      'en': '2. Sheet Settings & Wing Selection',
    },
    'resolution_reference_no': {
      'gu': 'ઠરાવ / સંદર્ભ નં.',
      'hi': 'संकल्प/संदर्भ क्रमांक.',
      'en': 'Resolution / Reference no.',
    },
    'eg_202601': {
      'gu': 'દા.ત. ૨૦૨૬/૦૧',
      'hi': 'जैसे 2026/01',
      'en': 'E.g. 2026/01',
    },
    'select_wing_block': {
      'gu': 'વિંગ / બ્લોક પસંદ કરો:',
      'hi': 'विंग/ब्लॉक चुनें:',
      'en': 'Select Wing / Block:',
    },
    'all_units': {
      'gu': 'તમામ એકમો (All)',
      'hi': 'सभी इकाइयाँ',
      'en': 'All units',
    },
    'declaration_text': {
      'gu': 'જાહેરનામું / સંમતિ નોંધ (Declaration Text)',
      'hi': 'घोषणा पाठ',
      'en': 'Declaration Text',
    },
    'conditions_of_consent_printed_on_the': {
      'gu': 'સહી પત્રક ઉપર છપાતી સંમતિની શરતો...',
      'hi': 'हस्ताक्षर पत्रक पर मुद्रित सहमति की शर्तें...',
      'en': 'Conditions of consent printed on the signature sheet...',
    },
    'also_display_unoccupied_units': {
      'gu': 'ખાલી એકમો (Unoccupied) પણ દર્શાવો',
      'hi': 'खाली इकाइयों को भी प्रदर्शित करें',
      'en': 'Also display unoccupied units',
    },
    'including_vacant_units_to_keep_all': {
      'gu': 'તમામ ફ્લેટ ક્રમબદ્ધ રહે તે માટે ખાલી એકમો સહિત',
      'hi': 'सभी फ्लैटों को व्यवस्थित रखने के लिए रिक्त इकाइयों को शामिल करना',
      'en': 'Including vacant units to keep all flats in order',
    },
    'include_a_consentcomment_box_column': {
      'gu': 'સંમતિ / મંતવ્ય બોક્સ કોલમ સમાવો',
      'hi': 'एक सहमति/टिप्पणी बॉक्स कॉलम शामिल करें',
      'en': 'Include a consent/comment box column',
    },
    'member_may_mark_agreement_with_signature': {
      'gu': 'સભ્ય સહી સાથે [✓] સંમત માર્કિંગ કરી શકે',
      'hi': 'सदस्य हस्ताक्षर के साथ समझौते को [✓] चिह्नित कर सकते हैं',
      'en': 'Member may mark [✓] agreement with signature',
    },
    'include_the_mobile_number_column': {
      'gu': 'મોબાઈલ નંબર કોલમ સમાવો',
      'hi': 'मोबाइल नंबर कॉलम शामिल करें',
      'en': 'Include the Mobile Number column',
    },
    'phone_number_for_member_verification': {
      'gu': 'સભ્યના વેરિફિકેશન માટે ફોન નંબર',
      'hi': 'सदस्य सत्यापन के लिए फ़ोन नंबर',
      'en': 'Phone number for member verification',
    },
    'all_the_wings': {
      'gu': 'બધી વિંગ્સ',
      'hi': 'सारे पंख',
      'en': 'All the wings',
    },
    'pdf_preview_export_preview_pdf': {
      'gu': '📄 પીડીએફ પ્રિવ્યૂ & એક્સપોર્ટ (Preview PDF)',
      'hi': '📄 पीडीएफ पूर्वावलोकन और निर्यात (पूर्वावलोकन पीडीएफ)',
      'en': '📄 PDF Preview & Export (Preview PDF)',
    },
    'print': {
      'gu': 'પ્રિન્ટ (Print)',
      'hi': 'प्रिंट करें',
      'en': 'Print',
    },
    'share_whatsapp': {
      'gu': 'શેર (WhatsApp)',
      'hi': 'साझा करें (व्हाट्सएप)',
      'en': 'Share (WhatsApp)',
    },
    'member_signature_sheet_preview': {
      'gu': 'સભ્ય સહી પત્રક પ્રિવ્યૂ',
      'hi': 'सदस्य हस्ताक्षर पत्रक पूर्वावलोकन',
      'en': 'Member Signature Sheet Preview',
    },
    'print_2': {
      'gu': 'પ્રિન્ટ કરો',
      'hi': 'प्रिंट करें',
      'en': 'Print',
    },
    'generating_signature_sheet_pdf': {
      'gu': 'સહી પત્રક PDF જનરેટ થઈ રહ્યું છે...',
      'hi': 'हस्ताक्षर पत्र पीडीएफ तैयार किया जा रहा है...',
      'en': 'Generating signature sheet PDF...',
    },
    'please_select_a_wing_or_enter': {
      'gu': 'કૃપા કરીને વિંગ સિલેક્ટ કરો અથવા નામ દાખલ કરો!',
      'hi': 'कृपया एक विंग चुनें या एक नाम दर्ज करें!',
      'en': 'Please select a wing or enter a name!',
    },
    'common_plot': {
      'gu': 'કોમન પ્લોટ',
      'hi': 'सामान्य कथानक',
      'en': 'Common Plot',
    },
    'delete_a_slot': {
      'gu': 'સ્લોટ ડિલીટ કરવો છે?',
      'hi': 'एक स्लॉट हटाएँ?',
      'en': 'Delete a slot?',
    },
    'autogenerator_allotment_and_slot_status': {
      'gu': 'ઓટો-જનરેટર, એલોટમેન્ટ અને સ્લોટ સ્ટેટસ',
      'hi': 'ऑटो-जनरेटर, आवंटन और स्लॉट स्थिति',
      'en': 'Auto-Generator, Allotment and Slot Status',
    },
    'no_common_plot_slots_have_been': {
      'gu': 'હજુ સુધી કોઈ કોમન પ્લોટ સ્લોટ્સ બનાવવામાં આવ્યા નથી.\\n(શેરી સોસાયટીમાં દરેક સભ્ય ઘર આગળ પાર્ક કરે છે).',
      'hi': 'अभी तक कोई सामान्य प्लॉट स्लॉट नहीं बनाया गया है।\\n(एक सड़क सोसायटी में प्रत्येक सदस्य घर के सामने पार्क करता है)।',
      'en': 'No common plot slots have been created yet.\\n(In a street society every member parks in front of the house).',
    },
    'no_wings_slots_have_been_created': {
      'gu': 'હજુ સુધી કોઈ વિંગ્સ સ્લોટ્સ બનાવવામાં આવ્યા નથી.\\nઉપરના બટનથી સ્લોટ્સ જનરેટ કરો.',
      'hi': 'अभी तक कोई विंग स्लॉट नहीं बनाया गया है।\\nऊपर दिए गए बटन से स्लॉट जेनरेट करें।',
      'en': 'No wings slots have been created yet.\\nGenerate slots with the button above.',
    },
    'street_rowhouse_society': {
      'gu': 'શેરી / રો-હાઉસ સોસાયટી',
      'hi': 'स्ट्रीट/रो-हाउस सोसायटी',
      'en': 'Street / Row-house Society',
    },
    'highrise_apartment_wings': {
      'gu': 'હાઇરાઇઝ એપાર્ટમેન્ટ વિંગ્સ',
      'hi': 'हाईराइज अपार्टमेंट विंग्स',
      'en': 'Highrise apartment wings',
    },
    'admin_control': {
      'gu': '👑 એડમિન કંટ્રોલ',
      'hi': '👑 व्यवस्थापक नियंत्रण',
      'en': '👑 Admin control',
    },
    'society_parking_control_centre': {
      'gu': 'સોસાયટી પાર્કિંગ કંટ્રોલ સેન્ટર',
      'hi': 'सोसायटी पार्किंग नियंत्रण केंद्र',
      'en': 'Society Parking Control Centre',
    },
    'total_slots': {
      'gu': 'કુલ સ્લોટ્સ',
      'hi': 'कुल स्लॉट',
      'en': 'Total slots',
    },
    'booked': {
      'gu': 'બુક થયેલ',
      'hi': 'बुक किया गया',
      'en': 'booked',
    },
    'available': {
      'gu': 'ઉપલબ્ધ',
      'hi': 'उपलब्ध',
      'en': 'Available',
    },
    'wing_wise_slots_autogenerator': {
      'gu': 'વિંગ વાઇઝ સ્લોટ્સ ઓટો-જનરેટર',
      'hi': 'विंग वाइज स्लॉट ऑटो-जनरेटर',
      'en': 'Wing Wise Slots Auto-Generator',
    },
    'set_the_number_of_4wheeler_2wheeler': {
      'gu': 'દરેક વિંગ માટે ૪-વ્હીલર, ૨-વ્હીલર અને EV સ્લોટ્સની સંખ્યા સેટ કરી ડેટાબેઝમાં સેવ કરો:',
      'hi': 'प्रत्येक विंग के लिए 4-व्हीलर, 2-व्हीलर और ईवी स्लॉट की संख्या निर्धारित करें और डेटाबेस में सहेजें:',
      'en': 'Set the number of 4-wheeler, 2-wheeler and EV slots for each wing and save in the database:',
    },
    'all_wings': {
      'gu': '⭐ તમામ વિંગ્સ (All)',
      'hi': '⭐ सभी पंख',
      'en': '⭐ All Wings',
    },
    'wing_name_eg_s1_or_a': {
      'gu': 'વિંગનું નામ (દા.ત. S-1 અથવા A)',
      'hi': 'विंग का नाम (जैसे S-1 या A)',
      'en': 'Wing name (eg S-1 or A)',
    },
    'eg_s1': {
      'gu': 'દા.ત. S-1',
      'hi': 'जैसे एस-1',
      'en': 'E.g. S-1',
    },
    'parking_level_floor': {
      'gu': 'પાર્કિંગ લેવલ / ફ્લોર:',
      'hi': 'पार्किंग स्तर/तल:',
      'en': 'Parking Level / Floor:',
    },
    'ground_stilt': {
      'gu': 'ગ્રાઉન્ડ / સ્ટીલ્ટ',
      'hi': 'ग्राउंड/स्टिल्ट',
      'en': 'Ground / Stilt',
    },
    'basement_1_b1': {
      'gu': 'બેઝમેન્ટ - ૧ (B1)',
      'hi': 'बेसमेंट - 1 (बी1)',
      'en': 'Basement - 1 (B1)',
    },
    'basement_2_b2': {
      'gu': 'બેઝમેન્ટ - ૨ (B2)',
      'hi': 'बेसमेंट - 2 (बी2)',
      'en': 'Basement - 2 (B2)',
    },
    'basement_3_b3': {
      'gu': 'બેઝમેન્ટ - ૩ (B3)',
      'hi': 'बेसमेंट - 3 (बी3)',
      'en': 'Basement - 3 (B3)',
    },
    'open_surface': {
      'gu': 'ઓપન / સપાટી',
      'hi': 'खुला/सतह',
      'en': 'Open / surface',
    },
    'commercial_loading_bay': {
      'gu': 'કોમર્શિયલ લોડિંગ બે',
      'hi': 'वाणिज्यिक लोडिंग बे',
      'en': 'Commercial loading bay',
    },
    'txt_4wheeler_car': {
      'gu': '૪-વ્હીલર (કાર)',
      'hi': '4-पहिया (कार)',
      'en': '4-wheeler (car)',
    },
    'txt_2wheeler_bike': {
      'gu': '૨-વ્હીલર (બાઇક)',
      'hi': '2-व्हीलर (बाइक)',
      'en': '2-wheeler (bike)',
    },
    'ev_slots': {
      'gu': 'EV સ્લોટ્સ',
      'hi': 'ईवी स्लॉट',
      'en': 'EV slots',
    },
    'generating': {
      'gu': 'જનરેટ થઈ રહ્યું છે...',
      'hi': 'उत्पन्न हो रहा है...',
      'en': 'Generating...',
    },
    'txt_1click_generate_save_slots': {
      'gu': '૧-ક્લિક સ્લોટ્સ જનરેટ & સેવ કરો',
      'hi': '1-स्लॉट जेनरेट और सेव करें पर क्लिक करें',
      'en': '1-Click Generate & Save Slots',
    },
    'sherry_common_plot_wadi_slots_setup': {
      'gu': 'શેરી કોમન પ્લોટ & વાડી સ્લોટ્સ સેટઅપ',
      'hi': 'शेरी कॉमन प्लॉट और वाडी स्लॉट सेटअप',
      'en': 'Sherry Common Plot & Wadi Slots Setup',
    },
    'every_member_in_the_street_society': {
      'gu': 'શેરી સોસાયટીમાં દરેક સભ્ય ઘર આંગણે પાર્ક કરે છે. જો કોમન પ્લોટ કે વાડીમાં વધારાનું પાર્કિંગ મંજૂર કરવું હોય તો જ સ્લોટ્સ બનાવો:',
      'hi': 'स्ट्रीट सोसायटी का प्रत्येक सदस्य घर के सामने पार्क करता है। यदि सामान्य भूखंड या वाडी में अतिरिक्त पार्किंग की अनुमति दी जानी है तो ही स्लॉट बनाएं:',
      'en': 'Every member in the street society parks in front of the house. Create slots only if additional parking is to be allowed in the common plot or wadi:',
    },
    'common_plot_slots_cp': {
      'gu': 'કોમન પ્લોટ સ્લોટ્સ (CP)',
      'hi': 'सामान्य प्लॉट स्लॉट (सीपी)',
      'en': 'Common Plot Slots (CP)',
    },
    'wadi_parking_slots': {
      'gu': 'વાડી પાર્કિંગ સ્લોટ્સ',
      'hi': 'वाडी पार्किंग स्लॉट',
      'en': 'Wadi parking slots',
    },
    'saving': {
      'gu': 'સેવ થઈ રહ્યું છે...',
      'hi': 'सहेजा जा रहा है...',
      'en': 'Saving...',
    },
    'save_common_plot_slots': {
      'gu': 'કોમન પ્લોટ સ્લોટ્સ સેવ કરો',
      'hi': 'सामान्य प्लॉट स्लॉट सहेजें',
      'en': 'Save common plot slots',
    },
    'custom_slots_eg_cpvip_guestp1': {
      'gu': 'કસ્ટમ સ્લોટ દા.ત. CP-VIP, GUEST-P1',
      'hi': 'कस्टम स्लॉट उदा. सीपी-वीआईपी, अतिथि-पी1',
      'en': 'Custom slots e.g. CP-VIP, GUEST-P1',
    },
    'custom_slots_eg_basement01_vip01': {
      'gu': 'કસ્ટમ સ્લોટ દા.ત. BASEMENT-01, VIP-01',
      'hi': 'कस्टम स्लॉट उदा. बेसमेंट-01, वीआईपी-01',
      'en': 'Custom slots e.g. BASEMENT-01, VIP-01',
    },
    'book': {
      'gu': 'બુક',
      'hi': 'किताब',
      'en': 'book',
    },
    'common_2': {
      'gu': 'કોમન',
      'hi': 'सामान्य',
      'en': 'Common',
    },
    'wadi': {
      'gu': 'વાડી',
      'hi': 'वाडी',
      'en': 'wadi',
    },
    'available_blank': {
      'gu': 'ઉપલબ્ધ (ખાલી)',
      'hi': 'उपलब्ध (रिक्त)',
      'en': 'available (blank)',
    },
    'audit_report_log': {
      'gu': 'ઓડિટ રિપોર્ટ લોગ',
      'hi': 'ऑडिट रिपोर्ट लॉग',
      'en': 'Audit report log',
    },
    'checkpoints_qr_codes': {
      'gu': 'ચેકપોઇન્ટ્સ & QR કોડ',
      'hi': 'चेकप्वाइंट और क्यूआर कोड',
      'en': 'Checkpoints & QR Codes',
    },
    'society_id_not_found_please_login': {
      'gu': 'સોસાયટી ઓળખ મળી નથી. કૃપા કરીને ફરી લૉગિન કરો.',
      'hi': 'सोसाइटी आईडी नहीं मिली. कृपया फिर भाग लें।',
      'en': 'Society ID not found. Please login again.',
    },
    'loading_audit': {
      'gu': 'ઓડિટ લોડ થઈ રહ્યું છે...',
      'hi': 'ऑडिट लोड हो रहा है...',
      'en': 'Loading audit...',
    },
    'security_compliance_score': {
      'gu': 'સુરક્ષા કમ્પ્લાયન્સ સ્કોર',
      'hi': 'सुरक्षा अनुपालन स्कोर',
      'en': 'Security Compliance Score',
    },
    'full_round': {
      'gu': 'પૂર્ણ રાઉન્ડ',
      'hi': 'पूरा दौर',
      'en': 'Full round',
    },
    'reported_problems': {
      'gu': 'નોંધાયેલ સમસ્યાઓ',
      'hi': 'समस्याओं की सूचना दी',
      'en': 'reported problems',
    },
    'round_history': {
      'gu': 'રાઉન્ડ હિસ્ટ્રી:',
      'hi': 'गोल इतिहास:',
      'en': 'Round History:',
    },
    'yesterday': {
      'gu': 'ગઈકાલે',
      'hi': 'कल',
      'en': 'yesterday',
    },
    'no_patrol_rounds_found': {
      'gu': 'કોઈ પેટ્રોલિંગ રાઉન્ડ મળ્યા નથી',
      'hi': 'कोई गश्ती दल नहीं मिला',
      'en': 'No patrol rounds found',
    },
    'watch_live_here_when_the_round': {
      'gu': 'વોચમેન એપમાંથી રાઉન્ડ શરૂ કરશે ત્યારે અહીં લાઈવ જોવા મળશે.',
      'hi': 'चौकीदार ऐप से राउंड शुरू होने पर यहां लाइव देखें।',
      'en': 'Watch live here when the round starts from the watchman app.',
    },
    'completed_successfully': {
      'gu': 'સફળતાપૂર્વક પૂર્ણ',
      'hi': 'सफलतापूर्वक पूरा हुआ',
      'en': 'Completed successfully',
    },
    'the_round_continues': {
      'gu': 'રાઉન્ડ ચાલુ છે',
      'hi': 'दौर जारी है',
      'en': 'The round continues',
    },
    'incomplete_missing': {
      'gu': 'અધૂરો / છૂટી ગયેલ',
      'hi': 'अपूर्ण/अनुपलब्ध',
      'en': 'Incomplete / Missing',
    },
    'there_is_a_reported_problem_see': {
      'gu': 'નોંધાયેલ સમસ્યા છે (વિગત જુઓ)',
      'hi': 'एक समस्या बताई गई है (विवरण देखें)',
      'en': 'There is a reported problem (see details)',
    },
    'checkpoint_scan_timeline': {
      'gu': 'ચેકપોઇન્ટ સ્કેન ટાઇમલાઇન:',
      'hi': 'चेकप्वाइंट स्कैन टाइमलाइन:',
      'en': 'Checkpoint Scan Timeline:',
    },
    'no_checkpoints_have_been_scanned_yet': {
      'gu': 'હજુ સુધી કોઈ ચેકપોઇન્ટ સ્કેન થયો નથી.',
      'hi': 'अभी तक किसी भी चेकपॉइंट को स्कैन नहीं किया गया है.',
      'en': 'No checkpoints have been scanned yet.',
    },
    'print_the_qr_code_of_the': {
      'gu': 'ચેકપોઇન્ટના QR કોડ પ્રિન્ટ કરીને સંબંધિત જગ્યાએ ચોંટાડો',
      'hi': 'चेकपॉइंट का क्यूआर कोड प्रिंट करें और संबंधित स्थान पर पेस्ट करें',
      'en': 'Print the QR code of the checkpoint and paste it at the relevant place',
    },
    'add_new': {
      'gu': 'નવો ઉમેરો',
      'hi': 'नया जोड़ें',
      'en': 'Add new',
    },
    'no_checkpoints_have_been_added_yet': {
      'gu': 'હજુ કોઈ ચેકપોઇન્ટ ઉમેરેલ નથી',
      'hi': 'अभी तक कोई चेकपॉइंट नहीं जोड़ा गया है',
      'en': 'No checkpoints have been added yet',
    },
    'add_places_like_gate_terrace_basement': {
      'gu': 'વોચમેન નાઈટ પેટ્રોલિંગ માટે સોસાયટીના ગેટ, ટેરેસ, બેઝમેન્ટ જેવા સ્થળો ઉમેરો અને QR સ્ટીકર પ્રિન્ટ કરો.',
      'hi': 'सोसायटी के गेट, छत, बेसमेंट जैसी जगहों को जोड़ें और चौकीदार की रात्रि गश्त के लिए क्यूआर स्टिकर प्रिंट करें।',
      'en': 'Add places like gate, terrace, basement of society and print QR sticker for watchman night patrol.',
    },
    'add_first_checkpoint': {
      'gu': '+ પ્રથમ ચેકપોઇન્ટ ઉમેરો',
      'hi': '+ पहला चेकपॉइंट जोड़ें',
      'en': '+ Add first checkpoint',
    },
    'view_print_qr_code': {
      'gu': 'QR કોડ જુઓ / પ્રિન્ટ',
      'hi': 'क्यूआर कोड देखें/प्रिंट करें',
      'en': 'View / Print QR Code',
    },
    'main_entrance': {
      'gu': 'મુખ્ય પ્રવેશ દ્વાર',
      'hi': 'मुख्य प्रवेश द्वार',
      'en': 'Main entrance',
    },
    'ground_floor_opposite_gate': {
      'gu': 'ગ્રાઉન્ડ ફ્લોર - ગેટ સામે',
      'hi': 'ग्राउंड फ्लोर - गेट के सामने',
      'en': 'Ground Floor - Opposite Gate',
    },
    'wing_a_terrace_entry': {
      'gu': 'વિંગ A ટેરેસ એન્ટ્રી',
      'hi': 'विंग ए टैरेस एंट्री',
      'en': 'Wing A Terrace Entry',
    },
    'top_floor_terrace_door': {
      'gu': 'ટોપ ફ્લોર - ટેરેસ ડોર',
      'hi': 'सबसे ऊपरी मंजिल - छत वाला दरवाजा',
      'en': 'Top Floor - Terrace Door',
    },
    'wing_b_terrace_entry': {
      'gu': 'વિંગ B ટેરેસ એન્ટ્રી',
      'hi': 'विंग बी टेरेस एंट्री',
      'en': 'Wing B Terrace Entry',
    },
    'basement_b1_parking': {
      'gu': 'બેઝમેન્ટ B1 પાર્કિંગ',
      'hi': 'बेसमेंट बी1 पार्किंग',
      'en': 'Basement B1 Parking',
    },
    'basement_pillar_no_near_5': {
      'gu': 'બેઝમેન્ટ - પિલર નં. ૫ પાસે',
      'hi': 'तहखाना - स्तम्भ नं. 5 के पास',
      'en': 'Basement - Pillar no. Near 5',
    },
    'generator_electric_room': {
      'gu': 'જનરેટર / ઇલેક્ટ્રિક રૂમ',
      'hi': 'जेनरेटर/इलेक्ट्रिक कक्ष',
      'en': 'Generator / Electric Room',
    },
    'ground_level_utility_block': {
      'gu': 'ગ્રાઉન્ડ લેવલ - યુટિલિટી બ્લોક',
      'hi': 'ग्राउंड लेवल - यूटिलिटी ब्लॉक',
      'en': 'Ground Level - Utility Block',
    },
    'rear_garden_play_area': {
      'gu': 'પાછળનો ગાર્ડન / પ્લે એરિયા',
      'hi': 'पिछला बगीचा/खेल क्षेत्र',
      'en': 'Rear garden / play area',
    },
    'rear_boundary_wall': {
      'gu': 'પાછળની બાઉન્ડ્રી વોલ',
      'hi': 'पीछे की चारदीवारी',
      'en': 'Rear boundary wall',
    },
    'add_a_new_security_checkpoint': {
      'gu': 'નવો સુરક્ષા ચેકપોઇન્ટ ઉમેરો',
      'hi': 'एक नया सुरक्षा चेकपॉइंट जोड़ें',
      'en': 'Add a new security checkpoint',
    },
    'a_qr_sticker_will_be_generated': {
      'gu': 'વોચમેન સ્કેન કરવા માટે QR સ્ટીકર જનરેટ થશે',
      'hi': 'चौकीदार को स्कैन करने के लिए एक क्यूआर स्टिकर उत्पन्न किया जाएगा',
      'en': 'A QR sticker will be generated for the watchman to scan',
    },
    'checkpoint_code_sequence': {
      'gu': 'ચેકપોઇન્ટ કોડ & ક્રમ *',
      'hi': 'चेकपॉइंट कोड और अनुक्रम *',
      'en': 'Checkpoint Code & Sequence *',
    },
    'eg_cp01_cp02': {
      'gu': 'દા.ત. CP01, CP02',
      'hi': 'जैसे CP01, CP02',
      'en': 'E.g. CP01, CP02',
    },
    'checkpoint_name': {
      'gu': 'ચેકપોઇન્ટનું નામ *',
      'hi': 'चेकपॉइंट का नाम *',
      'en': 'Checkpoint Name *',
    },
    'eg_main_gate': {
      'gu': 'દા.ત. મુખ્ય પ્રવેશ દ્વાર (Main Gate)',
      'hi': 'जैसे मुख्य द्वार',
      'en': 'E.g. Main Gate',
    },
    'quick_pick': {
      'gu': 'ઝડપી પસંદગી:',
      'hi': 'त्वरित चयन:',
      'en': 'Quick Pick:',
    },
    'specific_location_description': {
      'gu': 'ચોક્કસ સ્થળ વર્ણન *',
      'hi': 'विशिष्ट स्थान विवरण *',
      'en': 'Specific Location Description *',
    },
    'eg_ground_floor_opposite_security_cabin': {
      'gu': 'દા.ત. ગ્રાઉન્ડ ફ્લોર - સિક્યોરિટી કેબિન સામે',
      'hi': 'जैसे भूतल - सुरक्षा केबिन के सामने',
      'en': 'E.g. Ground Floor - Opposite Security Cabin',
    },
    'safety_notice_note_to_guard_optional': {
      'gu': 'સુરક્ષા સૂચના / ગાર્ડ માટે નોંધ (વૈકલ્પિક)',
      'hi': 'सुरक्षा सूचना/गार्ड को नोट (वैकल्पिक)',
      'en': 'Safety Notice / Note to Guard (Optional)',
    },
    'eg_specially_checking_that_the_lock': {
      'gu': 'દા.ત. રાત્રે તાળું અને લાઈટ ચાલુ છે તે ખાસ ચકાસવું...',
      'hi': 'जैसे विशेष रूप से यह जांचना कि रात में ताला और लाइटें जल रही हों...',
      'en': 'E.g. Specially checking that the lock and lights are on at night...',
    },
    'please_enter_name_and_place': {
      'gu': 'કૃપા કરીને નામ અને સ્થળ દાખલ કરો.',
      'hi': 'कृपया नाम और स्थान दर्ज करें.',
      'en': 'Please enter name and place.',
    },
    'checkpoint_added_successfully': {
      'gu': 'ચેકપોઇન્ટ સફળતાપૂર્વક ઉમેરાઈ ગયો! 🎉',
      'hi': 'चेकप्वाइंट सफलतापूर्वक जोड़ा गया! 🎉',
      'en': 'Checkpoint added successfully! 🎉',
    },
    'save_the_checkpoint_and_get_the': {
      'gu': 'ચેકપોઇન્ટ સાચવો અને QR મેળવો',
      'hi': 'चेकपॉइंट सहेजें और क्यूआर प्राप्त करें',
      'en': 'Save the checkpoint and get the QR',
    },
    'night_patrol_system_manual': {
      'gu': 'નાઈટ પેટ્રોલિંગ સિસ્ટમ માર્ગદર્શિકા',
      'hi': 'रात्रि गश्ती प्रणाली मैनुअल',
      'en': 'Night Patrol System Manual',
    },
    'audit_rules_for_security_guard_and': {
      'gu': 'સુરક્ષા ગાર્ડ અને કમિટી માટે ઓડિટ નિયમો',
      'hi': 'सुरक्षा गार्ड और समिति के लिए ऑडिट नियम',
      'en': 'Audit Rules for Security Guard and Committee',
    },
    'txt_1': {
      'gu': '૧',
      'hi': '1',
      'en': '1',
    },
    'add_checkpoints': {
      'gu': 'ચેકપોઇન્ટ્સ ઉમેરો (Add Checkpoints)',
      'hi': 'चेकप्वाइंट जोड़ें',
      'en': 'Add Checkpoints',
    },
    'add_the_main_security_places_of': {
      'gu': 'સોસાયટીના મુખ્ય સુરક્ષા સ્થળો જેમ કે મુખ્ય ગેટ, ટેરેસ, બેઝમેન્ટ પાર્કિંગ, પંપ રૂમ ઉમેરો.',
      'hi': 'सोसायटी के मुख्य सुरक्षा स्थानों जैसे मुख्य द्वार, छत, बेसमेंट पार्किंग, पंप रूम को जोड़ें।',
      'en': 'Add the main security places of the society like main gate, terrace, basement parking, pump room.',
    },
    'txt_2': {
      'gu': '૨',
      'hi': '2',
      'en': '2',
    },
    'print_and_apply_the_qr_sticker': {
      'gu': 'QR સ્ટીકર પ્રિન્ટ કરી લગાવો',
      'hi': 'क्यूआर स्टिकर प्रिंट करें और लगाएं',
      'en': 'Print and apply the QR sticker',
    },
    'view_print_qr_code_of_each': {
      'gu': 'દરેક ચેકપોઇન્ટનું "QR કોડ જુઓ / પ્રિન્ટ" કરી તે સંબંધિત સ્થળની દિવાલ પર વોટરપ્રૂફ સ્ટીકર લગાવો.',
      'hi': 'प्रत्येक चेकपॉइंट का "क्यूआर कोड देखें/प्रिंट करें" और संबंधित स्थान की दीवार पर एक वाटरप्रूफ स्टिकर चिपकाएं।',
      'en': '"View / Print QR Code" of each checkpoint and affix a waterproof sticker on the wall of the respective location.',
    },
    'txt_3': {
      'gu': '૩',
      'hi': '3',
      'en': '3',
    },
    'watchmen_night_patrol_and_scan': {
      'gu': 'વોચમેન રાત્રિ પેટ્રોલિંગ અને સ્કેન',
      'hi': 'चौकीदार रात्रि गश्त और स्कैनिंग करते हैं',
      'en': 'Watchmen night patrol and scan',
    },
    'the_watchman_will_complete_the_round': {
      'gu': 'વોચમેન રાત્રે ૧૧:૦૦ PM થી સવારે ૬:૦૦ AM દરમિયાન એપથી ટોર્ચ અને કેમેરા વડે QR સ્કેન કરી રાઉન્ડ પૂર્ણ કરશે.',
      'hi': 'चौकीदार रात 11:00 बजे से सुबह 6:00 बजे के बीच ऐप से क्यूआर को टॉर्च और कैमरे से स्कैन करके राउंड पूरा करेगा.',
      'en': 'The watchman will complete the round by scanning the QR with torch and camera from the app between 11:00 PM to 6:00 AM.',
    },
    'txt_4': {
      'gu': '૪',
      'hi': '4',
      'en': '4',
    },
    'morning_live_audit_and_certification': {
      'gu': 'સવારે લાઈવ ઓડિટ અને પ્રમાણપત્ર',
      'hi': 'मॉर्निंग लाइव ऑडिट और प्रमाणन',
      'en': 'Morning live audit and certification',
    },
    'committee_will_be_able_to_see': {
      'gu': 'કમિટી સમય અને સ્થળ સાથે ૧૦૦% સુરક્ષા રિપોર્ટ જોઈ શકશે અને સભ્યોને પણ સુરક્ષાની ખાતરી મળશે.',
      'hi': 'समिति समय और स्थान के साथ 100 प्रतिशत सुरक्षा रिपोर्ट देख सकेगी और सदस्यों को सुरक्षा का आश्वासन भी मिलेगा।',
      'en': 'Committee will be able to see 100% security report with time and place and members will also get security assurance.',
    },
    'got_it_close': {
      'gu': 'સમજાયું (Close)',
      'hi': 'समझ गया (बंद करें)',
      'en': 'Got it (Close)',
    },
    'my_building_guard': {
      'gu': 'માય બિલ્ડિંગ ગાર્ડ',
      'hi': 'मेरा बिल्डिंग गार्ड',
      'en': 'My building guard',
    },
    'security_patrol_sticker': {
      'gu': 'સુરક્ષા પેટ્રોલિંગ સ્ટીકર',
      'hi': 'सुरक्षा गश्ती स्टीकर',
      'en': 'Security patrol sticker',
    },
    'for_security_guards_scan_here_during': {
      'gu': 'સુરક્ષા ગાર્ડ માટે: પેટ્રોલિંગ દરમિયાન અહીં સ્કેન કરો',
      'hi': 'सुरक्षा गार्डों के लिए: गश्त के दौरान यहां स्कैन करें',
      'en': 'For Security Guards: Scan here during patrol',
    },
    'share_qr_details': {
      'gu': 'QR વિગત શેર કરો',
      'hi': 'QR विवरण साझा करें',
      'en': 'Share QR details',
    },
    'delete_a_checkpoint': {
      'gu': 'ચેકપોઇન્ટ કાઢી નાખવો છે?',
      'hi': 'चेकपॉइंट हटाएं?',
      'en': 'Delete a checkpoint?',
    },
    'there_are_no_active_polls_running': {
      'gu': 'હજુ કોઈ સક્રિય પોલ ચાલુ નથી',
      'hi': 'अभी तक कोई सक्रिय मतदान नहीं चल रहा है',
      'en': 'There are no active polls running yet',
    },
    'there_is_no_completed_poll': {
      'gu': 'કોઈ પૂર્ણ થયેલો પોલ નથી',
      'hi': 'कोई पूर्ण मतदान नहीं हुआ है',
      'en': 'There is no completed poll',
    },
    'start_a_poll_to_get_digital': {
      'gu': 'સોસાયટી કલરકામ, સુરક્ષા કે આયોજન જેવા મહત્વના વિષયો પર સભ્યો પાસેથી ડિજિટલ અભિપ્રાય મેળવવા પોલ શરૂ કરો.',
      'hi': 'समाज के रंग-रोगन, सुरक्षा या योजना जैसे महत्वपूर्ण विषयों पर सदस्यों से डिजिटल राय प्राप्त करने के लिए एक सर्वेक्षण शुरू करें।',
      'en': 'Start a poll to get digital opinions from members on important topics like society colorwork, security or planning.',
    },
    'previously_completed_polls_and_committee_decisions': {
      'gu': 'અગાઉ પૂર્ણ થયેલા પોલ અને કમિટીના નિર્ણયો અહીં સંગ્રહિત થશે.',
      'hi': 'पहले पूर्ण किए गए मतदान और समिति के निर्णय यहां संग्रहीत किए जाएंगे।',
      'en': 'Previously completed polls and committee decisions will be stored here.',
    },
    'admin_polling_control': {
      'gu': 'એડમિન પોલિંગ કંટ્રોલ',
      'hi': 'व्यवस्थापक मतदान नियंत्रण',
      'en': 'Admin Polling Control',
    },
    'society_digital_polling_decision': {
      'gu': 'સોસાયટી ડિજિટલ પોલિંગ & નિર્ણય',
      'hi': 'सोसायटी डिजिटल मतदान एवं निर्णय',
      'en': 'Society Digital Polling & Decision',
    },
    'no_active_polls_are_running': {
      'gu': 'કોઈ સક્રિય પોલ ચાલુ નથી',
      'hi': 'कोई सक्रिय पोल नहीं चल रहा है',
      'en': 'No active polls are running',
    },
    'voting_complete': {
      'gu': 'મતદાન પૂર્ણ',
      'hi': 'वोटिंग पूरी',
      'en': 'Voting complete',
    },
    'the_final_hours': {
      'gu': 'અંતિમ ઘડીઓ',
      'hi': 'अंतिम घंटे',
      'en': 'The final hours',
    },
    'ongoing_voting': {
      'gu': 'ચાલુ મતદાન',
      'hi': 'जारी है वोटिंग',
      'en': 'Ongoing voting',
    },
    'completed_closed': {
      'gu': 'પૂર્ણ / બંધ',
      'hi': 'पूर्ण/बंद',
      'en': 'Completed / Closed',
    },
    'secret_vote': {
      'gu': 'ગુપ્ત મત',
      'hi': 'गुप्त मतदान',
      'en': 'secret vote',
    },
    'live_result': {
      'gu': 'લાઈવ પરિણામ:',
      'hi': 'लाइव परिणाम:',
      'en': 'Live Result:',
    },
    'voting_process_is_going_on': {
      'gu': 'મતદાન પ્રક્રિયા ચાલુ છે',
      'hi': 'वोटिंग प्रक्रिया जारी है',
      'en': 'Voting process is going on',
    },
    'voting_is_complete': {
      'gu': 'મતદાન પૂર્ણ થયેલ છે',
      'hi': 'मतदान पूरा हो गया है',
      'en': 'Voting is complete',
    },
    'voting_closed': {
      'gu': 'મતદાન બંધ',
      'hi': 'वोटिंग बंद',
      'en': 'Voting closed',
    },
    'delete_the_poll': {
      'gu': 'પોલ ડીલીટ કરો',
      'hi': 'जनमत संग्रह हटाएं',
      'en': 'Delete the poll',
    },
    'yes_agree': {
      'gu': 'હા, સંમત છીએ (Yes)',
      'hi': 'हाँ, सहमत हूँ',
      'en': 'Yes, agree',
    },
    'no_not_needed_now_no': {
      'gu': 'ના, અત્યારે જરૂર નથી (No)',
      'hi': 'नहीं, अभी जरूरत नहीं (नहीं)',
      'en': 'No, not needed now (No)',
    },
    'create_a_new_decision_poll': {
      'gu': 'નવો નિર્ણય પોલ બનાવો',
      'hi': 'एक नया निर्णय जनमत तैयार करें',
      'en': 'Create a new decision poll',
    },
    'transparent_decision_by_digital_voting_of': {
      'gu': 'સભ્યોના ડિજિટલ મતદાન દ્વારા પારદર્શક નિર્ણય',
      'hi': 'सदस्यों की डिजिटल वोटिंग से पारदर्शी निर्णय',
      'en': 'Transparent decision by digital voting of members',
    },
    'poll_question_main_topic': {
      'gu': 'પોલ પ્રશ્ન / મુખ્ય વિષય *',
      'hi': 'मतदान प्रश्न / मुख्य विषय *',
      'en': 'Poll Question / Main Topic *',
    },
    'eg_society_doing_paintwork_and_waterproofing': {
      'gu': 'દા.ત. સોસાયટી કલરકામ અને વોટરપ્રૂફિંગ કરાવવું?',
      'hi': 'जैसे सोसायटी पेंटवर्क और वॉटरप्रूफिंग कर रही है?',
      'en': 'E.g. Society doing paintwork and waterproofing?',
    },
    'detail_explanation_optional': {
      'gu': 'વિગત / સમજૂતી (વૈકલ્પિક)',
      'hi': 'विवरण/स्पष्टीकरण (वैकल्पिक)',
      'en': 'Detail / Explanation (Optional)',
    },
    'enter_the_estimated_cost_agenda_or': {
      'gu': 'અંદાજિત ખર્ચ, એજન્ડા કે કોટેશનની વિગત લખો...',
      'hi': 'अनुमानित लागत, एजेंडा या कोटेशन विवरण दर्ज करें...',
      'en': 'Enter the estimated cost, agenda or quotation details...',
    },
    'voting_options': {
      'gu': 'મતદાન વિકલ્પો (Options) *',
      'hi': 'मतदान विकल्प*',
      'en': 'Voting Options *',
    },
    'add_option_2': {
      'gu': 'વિકલ્પ ઉમેરો',
      'hi': 'विकल्प जोड़ें',
      'en': 'Add option',
    },
    'who_is_it_applicable_to_target': {
      'gu': 'કોના માટે લાગુ છે? (Target Scope)',
      'hi': 'यह किस पर लागू होता है? (लक्ष्य दायरा)',
      'en': 'Who is it applicable to? (Target Scope)',
    },
    'all_society_2': {
      'gu': 'સમગ્ર સોસાયટી (All Society)',
      'hi': 'सर्व समाज',
      'en': 'All Society',
    },
    'voting_closing_date_time': {
      'gu': 'મતદાન સમાપ્તિ તારીખ & સમય *',
      'hi': 'मतदान समाप्ति तिथि एवं समय*',
      'en': 'Voting Closing Date & Time *',
    },
    'ddmmyyyy_1159_pm': {
      'gu': 'dd/MM/yyyy (સાંજે ૧૧:૫૯)',
      'hi': 'dd/MM/yyyy (रात 11:59 बजे)',
      'en': 'dd/MM/yyyy (11:59 PM)',
    },
    'anonymous_voting': {
      'gu': 'ગુપ્ત મતદાન (Anonymous Voting)',
      'hi': 'अनाम मतदान',
      'en': 'Anonymous Voting',
    },
    'the_name_of_the_voters_will': {
      'gu': 'મતદારોનું નામ જાહેર નહીં થાય, માત્ર ટકાવારી દેખાશે',
      'hi': 'मतदाताओं का नाम उजागर नहीं किया जाएगा, केवल प्रतिशत देखा जाएगा',
      'en': 'The name of the voters will not be revealed, only the percentage will be visible',
    },
    'please_write_a_poll_subject': {
      'gu': 'કૃપા કરીને પોલ વિષય લખો.',
      'hi': 'कृपया एक सर्वेक्षण विषय लिखें.',
      'en': 'Please write a poll subject.',
    },
    'at_least_2_options_must_be': {
      'gu': 'ઓછામાં ઓછા ૨ વિકલ્પો લખવા જરૂરી છે.',
      'hi': 'कम से कम 2 विकल्प अवश्य लिखें।',
      'en': 'At least 2 options must be written.',
    },
    'decision_poll_started_successfully': {
      'gu': 'નિર્ણય પોલ સફળતાપૂર્વક શરૂ થયો! 🗳️',
      'hi': 'निर्णय सर्वेक्षण सफलतापूर्वक प्रारंभ हुआ! 🗳️',
      'en': 'Decision poll started successfully! 🗳️',
    },
    'publish_poll_2': {
      'gu': 'મતદાન શરૂ કરો (Publish Poll)',
      'hi': 'पोल प्रकाशित करें',
      'en': 'Publish Poll',
    },
    'stop_voting': {
      'gu': 'મતદાન બંધ કરવું છે?',
      'hi': 'वोट देना बंद करो?',
      'en': 'Stop voting?',
    },
    'do_you_want_to_close_this': {
      'gu': 'શું આપ આ પોલનું મતદાન અત્યારે બંધ કરીને આખરી નિર્ણય જાહેર કરવા માંગો છો?',
      'hi': 'क्या आप अब इस पोल को बंद करना चाहते हैं और अंतिम निर्णय की घोषणा करना चाहते हैं?',
      'en': 'Do you want to close this poll now and announce the final decision?',
    },
    'final_resolution_decision_note_optional': {
      'gu': 'આખરી ઠરાવ / નિર્ણય નોંધ (વૈકલ્પિક)',
      'hi': 'अंतिम संकल्प/निर्णय नोट (वैकल्पिक)',
      'en': 'Final Resolution / Decision Note (Optional)',
    },
    'eg_72_majority_approved_color_work': {
      'gu': 'દા.ત. ૭૨% બહુમતીથી કલરકામ મંજૂર થયું.',
      'hi': 'जैसे 72% बहुमत ने रंग कार्य को मंजूरी दी।',
      'en': 'E.g. 72% majority approved color work.',
    },
    'the_poll_has_been_closed': {
      'gu': 'પોલ બંધ કરવામાં આવ્યો છે.',
      'hi': 'मतदान बंद कर दिया गया है.',
      'en': 'The poll has been closed.',
    },
    'yes_turn_it_off': {
      'gu': 'હા, બંધ કરો',
      'hi': 'हां, इसे बंद कर दें',
      'en': 'Yes, turn it off',
    },
    'list_of_voting_members': {
      'gu': 'મતદાન કરનાર સભ્યોનું લિસ્ટ',
      'hi': 'मतदान करने वाले सदस्यों की सूची',
      'en': 'List of voting members',
    },
    'no_vote_yet': {
      'gu': 'હજુ કોઈ મત પડ્યો નથી.',
      'hi': 'अभी तक कोई वोट नहीं.',
      'en': 'No vote yet.',
    },
    'unknown_option': {
      'gu': 'અજ્ઞાત વિકલ્પ',
      'hi': 'अज्ञात विकल्प',
      'en': 'Unknown option',
    },
    'want_to_delete_a_poll': {
      'gu': 'પોલ ડીલીટ કરવો છે?',
      'hi': 'क्या आप कोई पोल हटाना चाहते हैं?',
      'en': 'Want to delete a poll?',
    },
    'this_poll_and_all_of_its': {
      'gu': 'આ પોલ અને તેનો تمام મતદાન રેકોર્ડ કાયમ માટે દૂર થઈ જશે.',
      'hi': 'यह मतदान और इसके सभी मतदान रिकॉर्ड हमेशा के लिए हटा दिए जाएंगे।',
      'en': 'This poll and all of its voting records will be deleted forever.',
    },
    'delete_2': {
      'gu': 'ડીલીટ કરો',
      'hi': 'हटाएँ',
      'en': 'Delete',
    },
    'the_poll_was_deleted': {
      'gu': 'પોલ ડીલીટ કરવામાં આવ્યો.',
      'hi': 'जनमत संग्रह हटा दिया गया.',
      'en': 'The poll was deleted.',
    },
    'general_notice': {
      'gu': 'સામાન્ય સૂચના',
      'hi': 'सामान्य सूचना',
      'en': 'General notice',
    },
    'water_supply_time': {
      'gu': 'પાણી પુરવઠા સમય',
      'hi': 'जल आपूर्ति का समय',
      'en': 'Water supply time',
    },
    'light': {
      'gu': 'લાઈટ',
      'hi': 'रोशनी',
      'en': 'Light',
    },
    'electricity_generator': {
      'gu': 'વીજળી / જનરેટર',
      'hi': 'बिजली/जनरेटर',
      'en': 'Electricity / Generator',
    },
    'annual_monthly_meeting': {
      'gu': 'વાર્ષિક / માસિક મીટિંગ',
      'hi': 'वार्षिक/मासिक बैठक',
      'en': 'Annual / Monthly Meeting',
    },
    'festival': {
      'gu': 'ઉત્સવ',
      'hi': 'त्योहार',
      'en': 'festival',
    },
    'festival_event_planning': {
      'gu': 'તહેવાર / ઇવેન્ટ આયોજન',
      'hi': 'महोत्सव/कार्यक्रम योजना',
      'en': 'Festival / event planning',
    },
    'cleaning': {
      'gu': 'સફાઈ',
      'hi': 'सफ़ाई',
      'en': 'Cleaning',
    },
    'society_cleanliness_campaign': {
      'gu': 'સોસાયટી સ્વચ્છતા અભિયાન',
      'hi': 'समाज स्वच्छता अभियान',
      'en': 'Society Cleanliness Campaign',
    },
    'add_new_notice_category': {
      'gu': 'નવી નોટિસ કેટેગરી ઉમેરો',
      'hi': 'नई सूचना श्रेणी जोड़ें',
      'en': 'Add new notice category',
    },
    'eg_lifts_security_rules_etc': {
      'gu': 'દા.ત. લિફ્ટ, સિક્યોરિટી, નિયમો, વગેરે',
      'hi': 'जैसे लिफ्ट, सुरक्षा, नियम, आदि',
      'en': 'E.g. Lifts, security, rules, etc',
    },
    'eg_circular_regarding_lift_service_matters': {
      'gu': 'દા.ત. લિફ્ટ સર્વિસ બાબત જરૂરી પરિપત્ર',
      'hi': 'जैसे लिफ्ट सेवा मामलों के संबंध में परिपत्र',
      'en': 'E.g. Circular regarding lift service matters',
    },
    'please_fill_in_both_title_and': {
      'gu': 'કૃપા કરીને શીર્ષક અને વિગત બંને ભરો.',
      'hi': 'कृपया शीर्षक और विवरण दोनों भरें।',
      'en': 'Please fill in both title and description.',
    },
    'successfully_published_on_the_notice_board': {
      'gu': 'નોટિસ બોર્ડ પર સફળતાપૂર્વક પબ્લિશ થઈ ગઈ!',
      'hi': 'नोटिस बोर्ड पर सफलतापूर्वक प्रकाशित!',
      'en': 'Successfully published on the notice board!',
    },
    'notice_type_category': {
      'gu': 'નોટિસ પ્રકાર / કેટેગરી:',
      'hi': 'नोटिस प्रकार/श्रेणी:',
      'en': 'Notice Type / Category:',
    },
    'title_of_notice': {
      'gu': 'નોટિસનું શીર્ષક (Title) *',
      'hi': 'नोटिस का शीर्षक*',
      'en': 'Title of Notice *',
    },
    'eg_society_general_annual_meeting': {
      'gu': 'દા.ત. સોસાયટી સામાન્ય વાર્ષિક સભા',
      'hi': 'जैसे सोसायटी की सामान्य वार्षिक बैठक',
      'en': 'E.g. Society General Annual Meeting',
    },
    'full_details_of_notice_notice_content': {
      'gu': 'નોટિસની સંપૂર્ણ વિગતો (Notice Content) *',
      'hi': 'नोटिस का पूरा विवरण (नोटिस सामग्री) *',
      'en': 'Full Details of Notice (Notice Content) *',
    },
    'write_the_date_time_agenda_or': {
      'gu': 'તારીખ, સમય, એજન્ડા અથવા નિયમો લખો...',
      'hi': 'दिनांक, समय, एजेंडा या नियम लिखें...',
      'en': 'Write the date, time, agenda or rules...',
    },
    'urgent_notice': {
      'gu': 'તાત્કાલિક / અર્જન્ટ નોટિસ (Urgent)',
      'hi': 'अत्यावश्यक सूचना',
      'en': 'Urgent Notice',
    },
    'will_be_highlighted_with_a_red': {
      'gu': 'લાલ રંગના એલર્ટ બેજ સાથે હાઇલાઇટ થશે',
      'hi': 'रेड अलर्ट बैज के साथ हाइलाइट किया जाएगा',
      'en': 'will be highlighted with a red alert badge',
    },
    'pin_to_top': {
      'gu': 'ટોચ પર પિન કરો (Pin to Top)',
      'hi': 'शीर्ष पर पिन करें',
      'en': 'Pin to Top',
    },
    'the_notice_will_appear_at_the': {
      'gu': 'નોટિસ બોર્ડમાં સૌથી ઉપર દેખાશે',
      'hi': 'नोटिस बोर्ड के शीर्ष पर दिखाई देगा',
      'en': 'The notice will appear at the top of the board',
    },
    'send_instant_push_notifications_to_everyone': {
      'gu': 'તમામને તુરંત પુશ નોટિફિકેશન મોકલો',
      'hi': 'सभी को त्वरित पुश सूचनाएँ भेजें',
      'en': 'Send instant push notifications to everyone',
    },
    'as_soon_as_the_notice_is': {
      'gu': 'નોટિસ પબ્લિશ થતા જ બધા સભ્યોના ફોનમાં એલર્ટ વાગશે',
      'hi': 'नोटिस प्रकाशित होते ही सभी सदस्यों के फोन पर अलर्ट बजेगा',
      'en': 'As soon as the notice is published, an alert will ring on the phone of all the members',
    },
    'notice_board_preview': {
      'gu': 'નોટિસ બોર્ડ પ્રિવ્યુ:',
      'hi': 'नोटिस बोर्ड पूर्वावलोकन:',
      'en': 'Notice Board Preview:',
    },
    'urgent_notice_2': {
      'gu': '🔴 અર્જન્ટ નોટિસ',
      'hi': '🔴 अति आवश्यक सूचना',
      'en': '🔴 Urgent notice',
    },
    'pinned': {
      'gu': '📌 પિન કરેલ',
      'hi': '📌 पिन किया गया',
      'en': '📌 Pinned',
    },
    'title_of_notice_2': {
      'gu': 'નોટિસનું શીર્ષક',
      'hi': 'नोटिस का शीर्षक',
      'en': 'Title of Notice',
    },
    'notice_details_will_appear_here': {
      'gu': 'અહીં નોટિસની વિગતો દેખાશે...',
      'hi': 'सूचना विवरण यहां दिखाई देगा…',
      'en': 'Notice details will appear here…',
    },
    'publish_notice': {
      'gu': 'નોટિસ પબ્લિશ કરો',
      'hi': 'नोटिस प्रकाशित करें',
      'en': 'Publish notice',
    },
    'my_society_2': {
      'gu': 'માય સોસાયટી (My Society)',
      'hi': 'मेरा समाज',
      'en': 'My Society',
    },
    'premises_setup_guide': {
      'gu': 'પરિસર સેટઅપ માર્ગદર્શિકા',
      'hi': 'परिसर सेटअप गाइड',
      'en': 'Premises Setup Guide',
    },
    'how_to_set_up_all_cases': {
      'gu': 'તમામ કેસો અને વિવિધ માળનું સચોટ સેટઅપ કેવી રીતે કરવું?',
      'hi': 'सभी मामलों और अलग-अलग मंजिलों को सही ढंग से कैसे स्थापित करें?',
      'en': 'How to set up all cases and different floors accurately?',
    },
    'txt_1_shopping_mall_commercial_complex_commercial': {
      'gu': '૧. શોપિંગ મોલ / કોમર્શિયલ સંકુલ (Commercial)',
      'hi': '1. शॉपिंग मॉल / वाणिज्यिक परिसर (वाणिज्यिक)',
      'en': '1. Shopping Mall / Commercial Complex (Commercial)',
    },
    'if_there_are_10_floors_of': {
      'gu': 'જો ૧૦ માળનું શોપિંગ હોય અને દરેક માળે અલગ-અલગ દુકાનો હોય:',
      'hi': 'यदि शॉपिंग की 10 मंजिलें हैं और प्रत्येक मंजिल पर अलग-अलग दुकानें हैं:',
      'en': 'If there are 10 floors of shopping and each floor has different shops:',
    },
    'ground_floor_select_single_floor_and': {
      'gu': '🔹 ગ્રાઉન્ડ ફ્લોર: \'સિંગલ ફ્લોર\' પસંદ કરી \'G\' અને \'20\' લખો ➜ \'G-01\' થી \'G-20\' આપમેળે બની જશે.',
      'hi': '🔹 ग्राउंड फ्लोर: \'सिंगल फ्लोर\' चुनें और \'जी\' और \'20\' टाइप करें ➜ \'जी-01\' से \'जी-20\' अपने आप बन जाएगा।',
      'en': '🔹 Ground Floor: Select \'Single Floor\' and type \'G\' and \'20\' ➜ \'G-01\' to \'G-20\' will automatically become.',
    },
    'txt_1st_floor_enter_1_and_15': {
      'gu': '🔹 પહેલો માળ: \'સિંગલ ફ્લોર\' માં \'1\' અને \'15\' લખો ➜ \'101\' થી \'115\' બની જશે.',
      'hi': '🔹 पहली मंजिल: \'एकल मंजिल\' में \'1\' और \'15\' दर्ज करें ➜ \'101\' \'115\' बन जाएगा।',
      'en': '🔹 1st Floor: Enter \'1\' and \'15\' in \'Single Floor\' ➜ \'101\' will become \'115\'.',
    },
    'txt_2_to_10_floors_select_multistorey': {
      'gu': '🔹 ૨ થી ૧૦ માળ: \'બહુમાળી રેન્જ\' પસંદ કરી \'2\' થી \'10\' અને માળ દીઠ \'8\' લખો ➜ \'201\' થી \'1008\' (કુલ ૭૨ ઓફિસો) બની જશે.',
      'hi': '🔹 2 से 10 मंजिलें: \'बहुमंजिला रेंज\' चुनें और \'2\' से \'10\' और \'8\' प्रति मंजिल दर्ज करें ➜ \'201\' से \'1008\' (कुल 72 कार्यालय)',
      'en': '🔹 2 to 10 floors: Select \'Multi-storey range\' and enter \'2\' to \'10\' and \'8\' per floor ➜ \'201\' to \'1008\' (Total 72 offices)',
    },
    'txt_2_mixed_project_shop_flats': {
      'gu': '૨. મિક્સ્ડ પ્રોજેક્ટ (દુકાન + ફ્લેટ્સ)',
      'hi': '2. मिश्रित परियोजना (दुकान + फ्लैट)',
      'en': '2. Mixed Project (Shop + Flats)',
    },
    'having_shops_on_the_ground_and': {
      'gu': 'ગ્રાઉન્ડ પર દુકાનો અને ઉપર રેસિડેન્શિયલ ટાવર હોય:',
      'hi': 'जमीन पर दुकानें और ऊपर आवासीय टावर होना:',
      'en': 'Having shops on the ground and residential towers above:',
    },
    'first_select_commercial_shops_and_type': {
      'gu': '🔹 પ્રથમ \'🏬 કોમર્શિયલ શોપ્સ\' પસંદ કરી \'G\' અને \'18\' લખી નીચેની દુકાનો એડ કરો (SHOP-01 થી SHOP-18).',
      'hi': '🔹 सबसे पहले \'🏬 वाणिज्यिक दुकानें\' चुनें और \'जी\' और \'18\' टाइप करें और निम्नलिखित दुकानों को जोड़ें (SHOP-01 से SHOP-18)।',
      'en': '🔹 First select \'🏬 Commercial Shops\' and type \'G\' and \'18\' and add the following shops (SHOP-01 to SHOP-18).',
    },
    'then_select_residential_wing_and_write': {
      'gu': '🔹 ત્યારબાદ \'🏢 રેસિડેન્શિયલ વિંગ\' પસંદ કરી \'A\' અને ૧૦ માળ, ૪ ફ્લેટ લખી \'વિંગ A\' એડ કરો.',
      'hi': '🔹 फिर \'🏢 रेजिडेंशियल विंग\' चुनें और \'ए\' लिखें और 10 मंजिल, 4 फ्लैट और \'विंग ए\' जोड़ें।',
      'en': '🔹 Then select \'🏢 Residential Wing\' and write \'A\' and 10 floors, 4 flats and add \'Wing A\'.',
    },
    'you_can_also_add_wing_b': {
      'gu': '🔹 આ જ રીતે \'વિંગ B\' પણ એડ કરી શકો છો. બંનેનો હિસાબ અને બિલ અલગ રહેશે.',
      'hi': '🔹आप इसी प्रकार \'विंग बी\' भी जोड़ सकते हैं। खाते और बिल दोनों अलग-अलग होंगे।',
      'en': '🔹 You can also add \'Wing B\' in the same way. Both accounts and bills will be separate.',
    },
    'txt_3_general_apartment_wing': {
      'gu': '૩. સામાન્ય એપાર્ટમેન્ટ (Wing)',
      'hi': '3. सामान्य अपार्टमेंट (विंग)',
      'en': '3. General Apartment (Wing)',
    },
    'for_a_typical_multistorey_flat_project': {
      'gu': 'સામાન્ય બહુમાળી ફ્લેટ પ્રોજેક્ટ માટે:',
      'hi': 'एक विशिष्ट बहुमंजिला फ्लैट परियोजना के लिए:',
      'en': 'For a typical multi-storey flat project:',
    },
    'add_wing_name_a_total_floors': {
      'gu': '🔹 વિંગ નામ \'A\', કુલ માળ \'5\' અને માળ દીઠ \'4\' લખી એડ કરો ➜ \'101\' થી \'504\' આપમેળે બની જશે.',
      'hi': '🔹 विंग का नाम \'ए\' जोड़ें, कुल मंजिल \'5\' और प्रति मंजिल \'4\' ➜ \'101\' से \'504\' अपने आप हो जाएगा।',
      'en': '🔹 Add wing name \'A\', total floors \'5\' and per floor \'4\' ➜ \'101\' to \'504\' will become automatically.',
    },
    'txt_4_rowhouse_society_street': {
      'gu': '૪. રો-હાઉસ / સોસાયટી (Street)',
      'hi': '4. रो-हाउस/सोसाइटी (स्ट्रीट)',
      'en': '4. Row-house / Society (Street)',
    },
    'for_street_and_bungalow_society': {
      'gu': 'શેરી અને બંગલાની સોસાયટી માટે:',
      'hi': 'स्ट्रीट और बंगला सोसायटी के लिए:',
      'en': 'For Street and Bungalow Society:',
    },
    'add_street_1_first_house_1': {
      'gu': '🔹 શેરી \'૧\', પ્રથમ ઘર \'૧\' અને છેલ્લો ઘર \'૨૫\' લખી એડ કરો ➜ ઘર નં. ૧ થી ૨૫ બની જશે.',
      'hi': '🔹 गली \'1\', पहला मकान \'1\' और आखिरी मकान \'25\' जोड़ें ➜ मकान नं. 1 से 25 हो जायेंगे.',
      'en': '🔹 Add street \'1\', first house \'1\' and last house \'25\' ➜ House no. 1 to 25 will become.',
    },
    'txt_5_square_feet_sqft_and_maintenance': {
      'gu': '૫. સ્ક્વેર ફીટ (Sq.Ft) અને મેન્ટેનન્સ બિલિંગ',
      'hi': '5. वर्ग फुट (वर्ग फुट) और रखरखाव बिलिंग',
      'en': '5. Square Feet (Sq.Ft) and Maintenance Billing',
    },
    'why_is_it_necessary_to_write': {
      'gu': 'દુકાન કે ફ્લેટની સરેરાશ સાઈઝ લખવી શા માટે જરૂરી છે?',
      'hi': 'दुकान या फ्लैट का औसत साइज लिखना क्यों जरूरी है?',
      'en': 'Why is it necessary to write average size of shop or flat?',
    },
    'small_shop_200_sqft_and_large': {
      'gu': '🔹 કોમર્શિયલ સંકુલમાં નાની દુકાન (૨૦૦ ચો.ફૂટ) અને મોટા શો-રૂમ (૧૨૦૦ ચો.ફૂટ) નું બિલ સ્ક્વેર ફીટના દર મુજબ આપમેળે સાચું ગણાશે જેથી કોઈ વિવાદ ન થાય.',
      'hi': '🔹व्यावसायिक कॉम्प्लेक्स में छोटी दुकान (200 वर्गफीट) एवं बड़े शोरूम (1200 वर्गफीट) का बिल स्वतः ही वर्गफीट दर के अनुसार हो जाएगा ताकि कोई विवाद न हो।',
      'en': '🔹 Small shop (200 sq.ft) and large showroom (1200 sq.ft) in commercial complexes will automatically be billed as per square feet rate so that there is no dispute.',
    },
    'even_after_setup_specific_size_of': {
      'gu': '🔹 સેટઅપ પછી પણ એડમિન પેનલમાંથી કોઈપણ દુકાનની ચોક્કસ સાઈઝ બદલી શકાય છે.',
      'hi': '🔹 सेटअप के बाद भी एडमिन पैनल से किसी भी दुकान का विशिष्ट साइज बदला जा सकता है।',
      'en': '🔹 Even after setup, specific size of any shop can be changed from admin panel.',
    },
    'got_it_continue_setup': {
      'gu': 'સમજાઈ ગયું, સેટઅપ ચાલુ રાખો',
      'hi': 'समझ गया, सेटअप जारी रखें',
      'en': 'Got it, continue setup',
    },
    'please_enter_floor_code_and_valid': {
      'gu': 'કૃપા કરીને ફ્લોર કોડ અને દુકાનોની માન્ય સંખ્યા લખો!',
      'hi': 'कृपया फ़्लोर कोड और दुकानों की वैध संख्या दर्ज करें!',
      'en': 'Please enter floor code and valid number of shops!',
    },
    'offices': {
      'gu': 'ઓફિસો',
      'hi': 'कार्यालय',
      'en': 'offices',
    },
    'this_is_already_on_the_block': {
      'gu': 'આ બ્લોક લિસ્ટમાં પહેલેથી છે!',
      'hi': 'यह पहले से ही ब्लॉक सूची में है!',
      'en': 'This is already on the block list!',
    },
    'write_the_floor_name_and_number': {
      'gu': 'દુકાનોનું ફ્લોર નામ અને સંખ્યા લખો!',
      'hi': 'मंजिल का नाम और दुकानों की संख्या लिखें!',
      'en': 'Write the floor name and number of shops!',
    },
    'commercial_shops_added': {
      'gu': 'કોમર્શિયલ શોપ્સ ઉમેરાઈ!',
      'hi': 'वाणिज्यिक दुकानें जोड़ी गईं!',
      'en': 'Commercial Shops Added!',
    },
    'write_the_name_of_the_society': {
      'gu': 'સોસાયટીનું નામ લખો!',
      'hi': 'समाज का नाम लिखो!',
      'en': 'Write the name of the society!',
    },
    'add_at_least_one_block_or': {
      'gu': 'ઓછામાં ઓછો એક બ્લોક અથવા ફ્લોર ઉમેરો!',
      'hi': 'कम से कम एक ब्लॉक या फर्श जोड़ें!',
      'en': 'Add at least one block or floor!',
    },
    'logout_sign_out': {
      'gu': 'લૉગઆઉટ (Sign Out)',
      'hi': 'लॉगआउट (साइन आउट)',
      'en': 'Logout (Sign Out)',
    },
    'universal_space_engine': {
      'gu': '✨ સર્વસમાવેશી પરિસર એન્જિન (Universal Space Engine)',
      'hi': '✨ यूनिवर्सल स्पेस इंजन',
      'en': '✨ Universal Space Engine',
    },
    'smart_society_mall_setup': {
      'gu': 'સ્માર્ટ સોસાયટી & મોલ સેટઅપ',
      'hi': 'स्मार्ट सोसायटी एवं मॉल सेटअप',
      'en': 'Smart Society & Mall Setup',
    },
    'accurate_setup_of_separate_shops_or': {
      'gu': 'દરેક માળે અલગ-અલગ દુકાનો કે મિક્સ્ડ પ્રોજેક્ટનું સચોટ સેટઅપ',
      'hi': 'प्रत्येक मंजिल पर अलग-अलग दुकानों या मिश्रित परियोजनाओं की सटीक स्थापना',
      'en': 'Accurate setup of separate shops or mixed projects on each floor',
    },
    'txt_1_enter_the_premises_name': {
      'gu': '૧. પરિસરનું નામ દાખલ કરો',
      'hi': '1. परिसर का नाम दर्ज करें',
      'en': '1. Enter the premises name',
    },
    'eg_ratnam_shopping_center_shivalik_hub': {
      'gu': 'દા.ત. રત્નમ શોપિંગ સેન્ટર / શિવાલિક હબ / શાંતિવન રેસિડેન્સી',
      'hi': 'जैसे रत्नम शॉपिंग सेंटर / शिवालिक हब / शांतिवन रेजीडेंसी',
      'en': 'E.g. Ratnam Shopping Center / Shivalik Hub / Shantivan Residency',
    },
    'shopping_mall_market': {
      'gu': 'શોપિંગ મોલ / માર્કેટ',
      'hi': 'शॉपिंग मॉल/बाजार',
      'en': 'Shopping Mall / Market',
    },
    'shops_offices_showrooms_godowns': {
      'gu': 'દુકાનો, ઓફિસો, શો-રૂમ, ગોડાઉન',
      'hi': 'दुकानें, कार्यालय, शोरूम, गोदाम',
      'en': 'Shops, offices, showrooms, godowns',
    },
    'mixed_project': {
      'gu': 'મિક્સ્ડ પ્રોજેક્ટ',
      'hi': 'मिश्रित परियोजना',
      'en': 'Mixed project',
    },
    'ground_shops_residential_tower': {
      'gu': 'ગ્રાઉન્ડ શોપ્સ + રેસિડેન્શિયલ ટાવર',
      'hi': 'ग्राउंड दुकानें + आवासीय टॉवर',
      'en': 'Ground Shops + Residential Tower',
    },
    'hybrid_space': {
      'gu': 'હાઇબ્રિડ સ્પેસ',
      'hi': 'हाइब्रिड स्पेस',
      'en': 'Hybrid space',
    },
    'apartment_towers': {
      'gu': 'એપાર્ટમેન્ટ ટાવર્સ',
      'hi': 'अपार्टमेंट टावर्स',
      'en': 'Apartment towers',
    },
    'wing_a_b_multistorey_flats': {
      'gu': 'વિંગ A, B... બહુમાળી ફ્લેટ્સ',
      'hi': 'विंग ए, बी... बहुमंजिला फ्लैट',
      'en': 'Wing A, B... multi-storey flats',
    },
    'flats_towers': {
      'gu': 'ફ્લેટ્સ / ટાવર',
      'hi': 'फ़्लैट/टावर',
      'en': 'Flats / Towers',
    },
    'rowhouse_society': {
      'gu': 'રો-હાઉસ / સોસાયટી',
      'hi': 'रो-हाउस/सोसायटी',
      'en': 'Row-house / Society',
    },
    'street_no_1_2_bungalow_tenement': {
      'gu': 'શેરી નં. ૧, ૨... બંગલા / ટેનામેન્ટ',
      'hi': 'गली नं. 1, 2...बंगला/किराया',
      'en': 'Street no. 1, 2... Bungalow / Tenement',
    },
    'street_layout': {
      'gu': 'શેરી લેઆઉટ',
      'hi': 'सड़क लेआउट',
      'en': 'Street layout',
    },
    'txt_2_select_the_type_of_premises': {
      'gu': '૨. પરિસરનો પ્રકાર પસંદ કરો',
      'hi': '2. परिसर का प्रकार चुनें',
      'en': '2. Select the type of premises',
    },
    'is_locked': {
      'gu': 'લૉક થયેલ છે',
      'hi': 'बंद है',
      'en': 'is locked',
    },
    'the_architecture_type_is_permanently_locked': {
      'gu': 'આર્કિટેક્ચર પ્રકાર કાયમી લૉક છે',
      'hi': 'आर्किटेक्चर प्रकार स्थायी रूप से लॉक है',
      'en': 'The architecture type is permanently locked',
    },
    'important_planning_rule_permanent_architecture_rule': {
      'gu': 'મહત્વનો પ્લાનિંગ નિયમ (Permanent Architecture Rule)',
      'hi': 'महत्वपूर्ण नियोजन नियम (स्थायी वास्तु नियम)',
      'en': 'Important Planning Rule (Permanent Architecture Rule)',
    },
    'the_architecture_for_this_society_has': {
      'gu': 'આ સોસાયટી માટે આર્કિટેક્ચર નક્કી થઈ ગયું છે. એકવાર એકમો જનરેટ થયા પછી મુખ્ય પ્રકાર બદલી શકાતો નથી. જોકે તમે આ જ પ્રકાર હેઠળ નીચેના ફોર્મથી નવા ફ્લોર, શેરી કે બ્લોક ઉમેરી શકો છો.',
      'hi': 'इस समाज की रूपरेखा तय हो चुकी है. एक बार इकाइयाँ उत्पन्न होने के बाद मूल प्रकार को नहीं बदला जा सकता है। हालाँकि आप नीचे दिए गए फॉर्म का उपयोग करके उसी प्रकार के तहत एक नई मंजिल, सड़क या ब्लॉक जोड़ सकते हैं।',
      'en': 'The architecture for this society has been decided. The core type cannot be changed once the entities are generated. However you can add a new floor, street or block under the same type using the form below.',
    },
    'once_units_are_generated_by_selecting': {
      'gu': 'એકવાર આર્કિટેક્ચર પસંદ કરીને એકમો જનરેટ થઈ ગયા પછી તેનો મુખ્ય પ્રકાર (જેમ કે Wing, Street, Commercial) બદલી શકાશે નહીં. જોકે તમે પસંદ કરેલા પ્રકાર હેઠળ નવા ફ્લોર, શેરી, વિંગ કે બ્લોક ગમે ત્યારે વધારી શકશો.',
      'hi': 'एक बार आर्किटेक्चर का चयन करके इकाइयाँ तैयार कर ली जाती हैं, तो उनके मुख्य प्रकार (जैसे विंग, स्ट्रीट, कमर्शियल) को नहीं बदला जा सकता है। हालाँकि आप चयनित प्रकार के अंतर्गत किसी भी समय एक नई मंजिल, सड़क, विंग या ब्लॉक जोड़ सकते हैं।',
      'en': 'Once units are generated by selecting an architecture, their main type (eg Wing, Street, Commercial) cannot be changed. However you can add a new floor, street, wing or block anytime under the selected type.',
    },
    'locked': {
      'gu': 'લૉક',
      'hi': 'बंद',
      'en': 'locked',
    },
    'the_architecture_type_is_locked': {
      'gu': 'આર્કિટેક્ચર પ્રકાર લૉક થયેલ છે',
      'hi': 'आर्किटेक्चर प्रकार लॉक है',
      'en': 'The architecture type is locked',
    },
    'understood': {
      'gu': 'સમજાઈ ગયું (Understood)',
      'hi': 'समझ गया',
      'en': 'Understood',
    },
    'showroom_2': {
      'gu': 'શો-રૂમ',
      'hi': 'शो-रूम',
      'en': 'Show-room',
    },
    'godown_2': {
      'gu': 'ગોડાઉન',
      'hi': 'गोदाम',
      'en': 'Godown',
    },
    'txt_3_floor_shops_configuration': {
      'gu': '૩. ફ્લોર & દુકાનો કોન્ફિગરેશન',
      'hi': '3. फर्श और दुकानों का विन्यास',
      'en': '3. Floor & Shops Configuration',
    },
    'guide': {
      'gu': 'ગાઈડ',
      'hi': 'मार्गदर्शक',
      'en': 'Guide',
    },
    'single_floor_g_1': {
      'gu': 'સિંગલ ફ્લોર (G, 1...)',
      'hi': 'एकल तल (जी, 1...)',
      'en': 'Single Floor (G, 1...)',
    },
    'multistorey_range_2_to_10': {
      'gu': 'બહુમાળી રેન્જ (2 થી 10)',
      'hi': 'बहुमंजिला रेंज (2 से 10)',
      'en': 'Multi-storey range (2 to 10)',
    },
    'floor_code': {
      'gu': 'ફ્લોર કોડ *',
      'hi': 'फ़्लोर कोड*',
      'en': 'Floor Code *',
    },
    'shop_number': {
      'gu': 'દુકાન સંખ્યા *',
      'hi': 'दुकान नंबर*',
      'en': 'Shop Number *',
    },
    'fast_floor': {
      'gu': 'ઝડપી ફ્લોર:',
      'hi': 'तेज़ मंजिल:',
      'en': 'Fast floor:',
    },
    'showroom_3': {
      'gu': '🏬 શો-રૂમ',
      'hi': '🏬शो-रूम',
      'en': '🏬 Show-room',
    },
    'godown_3': {
      'gu': '📦 ગોડાઉન',
      'hi': '📦गोदाम',
      'en': '📦 Godown',
    },
    'average_size': {
      'gu': 'સરેરાશ સાઈઝ',
      'hi': 'औसत आकार',
      'en': 'Average size',
    },
    'block_name_optional_2': {
      'gu': 'બ્લોકનું નામ (વૈકલ્પિક)',
      'hi': 'ब्लॉक नाम (वैकल्पिक)',
      'en': 'Block name (optional)',
    },
    'eg_tower1_or_offices': {
      'gu': 'દા.ત. Tower-1 અથવા Offices',
      'hi': 'जैसे टावर-1 या कार्यालय',
      'en': 'E.g. Tower-1 or Offices',
    },
    'add_this_floor': {
      'gu': '+ આ ફ્લોર ઉમેરો',
      'hi': '+ इस मंजिल को जोड़ें',
      'en': '+ Add this floor',
    },
    'add_this_floor_range': {
      'gu': '+ આ ફ્લોર રેન્જ ઉમેરો',
      'hi': '+ इस फ़्लोर रेंज को जोड़ें',
      'en': '+ Add this floor range',
    },
    'txt_3_choose_a_mixed_unit': {
      'gu': '૩. મિક્સ્ડ એકમ પસંદ કરો',
      'hi': '3. एक मिश्रित इकाई चुनें',
      'en': '3. Choose a mixed unit',
    },
    'shopping_zone_floor_code': {
      'gu': 'શોપિંગ ઝોન / ફ્લોર કોડ *',
      'hi': 'शॉपिंग जोन/फ्लोर कोड*',
      'en': 'Shopping Zone / Floor Code *',
    },
    'eg_g_or_frontshops': {
      'gu': 'દા.ત. G અથવા FRONT-SHOPS',
      'hi': 'जैसे जी या सामने की दुकानें',
      'en': 'E.g. G or FRONT-SHOPS',
    },
    'number_of_shops_2': {
      'gu': 'દુકાનોની સંખ્યા *',
      'hi': 'दुकानों की संख्या*',
      'en': 'Number of Shops *',
    },
    'residential_wing_name': {
      'gu': 'રેસિડેન્શિયલ વિંગ નામ *',
      'hi': 'आवासीय विंग का नाम *',
      'en': 'Residential Wing Name *',
    },
    'eg_a_b_or_c': {
      'gu': 'દા.ત. A, B અથવા C',
      'hi': 'जैसे ए, बी या सी',
      'en': 'E.g. A, B or C',
    },
    'add_commercial_shops': {
      'gu': '+ કોમર્શિયલ શોપ્સ ઉમેરો',
      'hi': '+ व्यावसायिक दुकानें जोड़ें',
      'en': '+ Add commercial shops',
    },
    'add_residential_wing': {
      'gu': '+ રેસિડેન્શિયલ વિંગ ઉમેરો',
      'hi': '+ आवासीय विंग जोड़ें',
      'en': '+ Add residential wing',
    },
    'txt_3_wing_and_flat_details': {
      'gu': '૩. વિંગ અને ફ્લેટ વિગતો',
      'hi': '3. पंख और सपाट विवरण',
      'en': '3. Wing and flat details',
    },
    'add_wing_to_list': {
      'gu': '+ લિસ્ટમાં વિંગ ઉમેરો',
      'hi': '+ सूची में विंग जोड़ें',
      'en': '+ Add wing to list',
    },
    'the_street': {
      'gu': 'શેરી',
      'hi': 'सड़क',
      'en': 'the street',
    },
    'txt_3_street_and_building_details': {
      'gu': '૩. શેરી અને મકાન વિગતો',
      'hi': '3. सड़क और भवन का विवरण',
      'en': '3. Street and building details',
    },
    'eg_1_or_ratnadeep': {
      'gu': 'દા.ત. 1 અથવા રત્નદીપ',
      'hi': 'जैसे 1 या रत्नदीप',
      'en': 'E.g. 1 or Ratnadeep',
    },
    'average_plot_building_size_sqft': {
      'gu': 'સરેરાશ પ્લોટ / મકાન સાઈઝ (Sq.Ft)',
      'hi': 'औसत प्लॉट/भवन का आकार (वर्ग फीट)',
      'en': 'Average Plot / Building Size (Sq.Ft)',
    },
    'add_street_to_list': {
      'gu': '+ લિસ્ટમાં શેરી ઉમેરો',
      'hi': '+ सूची में सड़क जोड़ें',
      'en': '+ Add street to list',
    },
    'no_blocks_or_floors_added': {
      'gu': 'કોઈ બ્લોક કે ફ્લોર ઉમેરેલ નથી',
      'hi': 'कोई ब्लॉक या फर्श नहीं जोड़ा गया',
      'en': 'No blocks or floors added',
    },
    'fill_the_floor_details_from_above': {
      'gu': 'ઉપરના ફોર્મમાંથી ફ્લોર વિગત ભરી \'+ આ ફ્લોર ઉમેરો\' દબાવો.',
      'hi': 'उपरोक्त फॉर्म से फर्श का विवरण भरें और \'+इस मंजिल को जोड़ें\' दबाएँ।',
      'en': 'Fill the floor details from above form and press \'+ Add this floor\'.',
    },
    'added_blocks_space_blueprint': {
      'gu': 'ઉમેરેલા બ્લોક્સ & સ્પેસ બ્લુપ્રિન્ટ',
      'hi': 'जोड़े गए ब्लॉक और स्पेस ब्लूप्रिंट',
      'en': 'Added Blocks & Space Blueprint',
    },
    'units_available': {
      'gu': 'એકમો ઉપલબ્ધ',
      'hi': 'इकाइयाँ उपलब्ध हैं',
      'en': 'units available',
    },
    'view_architecture_preview_full_preview': {
      'gu': 'આર્કિટેક્ચર પ્રિવ્યુ જુઓ (Full Preview)',
      'hi': 'आर्किटेक्चर पूर्वावलोकन देखें (पूर्ण पूर्वावलोकन)',
      'en': 'View Architecture Preview (Full Preview)',
    },
    'society_president_chairman': {
      'gu': 'સોસાયટી પ્રમુખ / ચેરમેન',
      'hi': 'सोसायटी अध्यक्ष/अध्यक्ष',
      'en': 'Society President / Chairman',
    },
    'society_bank_digital_signature_settings_saved': {
      'gu': 'સોસાયટી બેંક & ડિજિટલ સહી સેટિંગ્સ સફળતાપૂર્વક સાચવવામાં આવ્યા!',
      'hi': 'सोसाइटी बैंक और डिजिटल हस्ताक्षर सेटिंग्स सफलतापूर्वक सहेजी गईं!',
      'en': 'Society Bank & Digital Signature Settings Saved Successfully!',
    },
    'entering_society_upi_id_is_mandatory': {
      'gu': 'સોસાયટી UPI ID દાખલ કરવો ફરજિયાત છે',
      'hi': 'सोसायटी में प्रवेश के लिए यूपीआई आईडी अनिवार्य है',
      'en': 'Entering society UPI ID is mandatory',
    },
    'upi_id_should_not_contain_spaces': {
      'gu': 'UPI ID માં સ્પેસ (ખાલી જગ્યા) ન હોવી જોઈએ',
      'hi': 'UPI आईडी में रिक्त स्थान नहीं होना चाहिए',
      'en': 'UPI ID should not contain spaces',
    },
    'enter_correct_upi_id_eg_yournamebank': {
      'gu': 'સાચો UPI ID દાખલ કરો (દા.ત. yourname@bank જેમ કે @okhdfcbank, @sbi, @paytm)',
      'hi': 'सही UPI आईडी दर्ज करें (उदाहरण के लिए आपका नाम@बैंक जैसे @okhdfcbank, @sbi, @paytm)',
      'en': 'Enter correct UPI ID (eg yourname@bank like @okhdfcbank, @sbi, @paytm)',
    },
    'invalid_upi_id_must_be_only': {
      'gu': 'અમાન્ય UPI ID (માત્ર ૧ વાર @ હોવું જોઈએ)',
      'hi': 'अमान्य UPI आईडी (केवल 1 बार @ होना चाहिए)',
      'en': 'Invalid UPI ID (must be @ only 1 time)',
    },
    'upi_id_name_is_too_short': {
      'gu': 'UPI ID નું નામ બહુ નાનું છે (ઓછામાં ઓછા ૨ અક્ષર)',
      'hi': 'UPI आईडी नाम बहुत छोटा है (न्यूनतम 2 अक्षर)',
      'en': 'UPI ID name is too short (minimum 2 characters)',
    },
    'followed_by_bank_handle_eg_sbi': {
      'gu': '@ પછી બેંક હેન્ડલ લખો (દા.ત. @sbi, @paytm, @okhdfcbank)',
      'hi': '@ के बाद बैंक हैंडल (जैसे @sbi, @paytm, @okhdfcbank)',
      'en': '@ followed by bank handle (eg @sbi, @paytm, @okhdfcbank)',
    },
    'this_is_the_email_id_type': {
      'gu': '⚠️ આ ઈમેલ ID છે! બેંક UPI ID લખો (દા.ત. @okhdfcbank, @sbi, @paytm)',
      'hi': '⚠️ यह ईमेल आईडी है! बैंक UPI आईडी टाइप करें (जैसे @okhdfcbank, @sbi, @paytm)',
      'en': '⚠️ This is the email ID! Type the bank UPI ID (eg @okhdfcbank, @sbi, @paytm)',
    },
    'invalid_upi_id_format_remove_inappropriate': {
      'gu': 'અમાન્ય UPI ID ફોર્મેટ. અયોગ્ય ચિહ્નો હટાવો.',
      'hi': 'अमान्य UPI आईडी प्रारूप. अनुचित चिह्न हटाएँ.',
      'en': 'Invalid UPI ID format. Remove inappropriate marks.',
    },
    'test_vpa_in_upi_app': {
      'gu': 'UPI એપમાં ચકાસો (Test VPA)',
      'hi': 'यूपीआई ऐप में वीपीए का परीक्षण करें',
      'en': 'Test VPA in UPI App',
    },
    'verify_the_bank_name_in_the': {
      'gu': 'UPI એપમાં બેંક નામ ચકાસો',
      'hi': 'UPI ऐप में बैंक का नाम सत्यापित करें',
      'en': 'Verify the bank name in the UPI app',
    },
    'the_upi_id_has_been_copied': {
      'gu': 'UPI ID ક્લિપબોર્ડમાં કૉપી થઈ ગયો છે',
      'hi': 'UPI आईडी को क्लिपबोर्ड पर कॉपी कर दिया गया है',
      'en': 'The UPI ID has been copied to the clipboard',
    },
    'copy': {
      'gu': 'કૉપી કરો',
      'hi': 'प्रतिलिपि',
      'en': 'Copy',
    },
    'how_to_see_real_name_registered': {
      'gu': '💡 બેંકમાં રજીસ્ટર્ડ સાચું નામ કેવી રીતે જોવું? (૧૦૦% ફ્રી)',
      'hi': '💡बैंक में रजिस्टर्ड असली नाम कैसे देखें? (100% निःशुल्क)',
      'en': '💡 How to see real name registered in bank? (100% Free)',
    },
    'txt_1_clicking_open_upi_app_below': {
      'gu': '૧. નીચે "UPI એપ ખોલો" દબાવતા Google Pay / PhonePe ખુલશે.\\n',
      'hi': '1. नीचे "ओपन यूपीआई ऐप" पर क्लिक करने पर Google Pay/PhonePe खुल जाएगा।\\n',
      'en': '1. Clicking "Open UPI App" below will open Google Pay / PhonePe.\\n',
    },
    'txt_2_paste_this_copied_id_in': {
      'gu': '૨. એપમાં "Pay UPI ID" અથવા Search બારમાં આ કૉપી કરેલ ID Paste કરો.\\n',
      'hi': '2. इस कॉपी की गई आईडी को "पे यूपीआई आईडी" या ऐप में सर्च बार में पेस्ट करें।\\n',
      'en': '2. Paste this copied ID in "Pay UPI ID" or Search bar in the app.\\n',
    },
    'txt_3_npci_bank_server_will_directly': {
      'gu': '૩. NPCI બેંક સર્વર સીધું જ રજીસ્ટર્ડ બેંક ખાતાધારકનું સાચું નામ (Verified Name) બતાવશે.\\n',
      'hi': '3. एनपीसीआई बैंक सर्वर सीधे पंजीकृत बैंक खाताधारक का सत्यापित नाम दिखाएगा।\\n',
      'en': '3. NPCI Bank server will directly show the Verified Name of the registered bank account holder.\\n',
    },
    'txt_4_no_need_to_pay_after': {
      'gu': '૪. નામ ચકાસ્યા પછી પેમેન્ટ કરવાની જરૂર નથી — સીધા પાછા આવી અહીં સેવ કરી લો.',
      'hi': '4. नाम सत्यापन के बाद भुगतान करने की कोई आवश्यकता नहीं है - बस वापस आएं और यहां सहेजें।',
      'en': '4. No need to pay after name verification — just come back and save here.',
    },
    'open_the_upi_app': {
      'gu': 'UPI એપ ખોલો',
      'hi': 'यूपीआई ऐप खोलें',
      'en': 'Open the UPI app',
    },
    'could_not_open_any_upi_app': {
      'gu': 'તમારા ફોનમાં કોઈ UPI એપ (GPay/PhonePe/Paytm) ખૂલી શકી નહીં. નીચે રહેલા QR કોડને બીજા ફોનથી સ્કેન કરીને પણ ચકાસી શકો છો.',
      'hi': 'आपके फ़ोन पर कोई भी UPI ऐप (GPay/PhonePe/Paytm) नहीं खुल सका। आप नीचे दिए गए क्यूआर कोड को दूसरे फोन से स्कैन करके भी जांच सकते हैं।',
      'en': 'Could not open any UPI app (GPay/PhonePe/Paytm) on your phone. You can also check by scanning the below QR code with another phone.',
    },
    'authorized_bank_account': {
      'gu': '🏦 અધિકૃત બેંક ખાતું',
      'hi': '🏦 अधिकृत बैंक खाता',
      'en': '🏦 Authorized bank account',
    },
    'name_of_society_account_holder': {
      'gu': 'સોસાયટી ખાતાધારકનું નામ',
      'hi': 'सोसायटी खाताधारक का नाम',
      'en': 'Name of Society Account Holder',
    },
    'month_3': {
      'gu': '} / મહિનો',
      'hi': '}/माह',
      'en': '} / month',
    },
    'last_date': {
      'gu': 'છેલ્લી તારીખ',
      'hi': 'अंतिम तिथि',
      'en': 'last date',
    },
    'bank_upi_details': {
      'gu': 'બેંક & UPI વિગતો',
      'hi': 'बैंक और यूपीआई विवरण',
      'en': 'Bank & UPI details',
    },
    'members_will_deposit_maintenance_directly_on': {
      'gu': 'મેમ્બર્સ આ UPI ID પર સીધું મેન્ટેનન્સ જમા કરશે',
      'hi': 'सदस्य सीधे इस यूपीआई आईडी पर रखरखाव जमा करेंगे',
      'en': 'Members will deposit maintenance directly on this UPI ID',
    },
    'society_upi_id_vpa': {
      'gu': 'સોસાયટી UPI ID (VPA) *',
      'hi': 'सोसाइटी यूपीआई आईडी (वीपीए) *',
      'en': 'Society UPI ID (VPA) *',
    },
    'eg_yournamebank_like_okhdfcbank_sbi_paytm': {
      'gu': 'દા.ત. yourname@bank (જેમ કે @okhdfcbank, @sbi, @paytm)',
      'hi': 'जैसे आपका नाम@बैंक (जैसे @okhdfcbank, @sbi, @paytm)',
      'en': 'E.g. yourname@bank (like @okhdfcbank, @sbi, @paytm)',
    },
    'example_format_societynamebank_secretarypaytm_nameokhdfcbank': {
      'gu': 'ઉદાહરણ ફોર્મેટ: societyname@bank, secretary@paytm, name@okhdfcbank',
      'hi': 'उदाहरण प्रारूप: सोसायटीनाम@बैंक, सचिव@पेटीएम, नाम@ओखडीएफसीबैंक',
      'en': 'Example format: societyname@bank, secretary@paytm, name@okhdfcbank',
    },
    'verify_account_in_upi_app_test': {
      'gu': 'UPI એપમાં ખાતું ચકાસો (Test VPA)',
      'hi': 'UPI ऐप में खाता सत्यापित करें (परीक्षण VPA)',
      'en': 'Verify Account in UPI App (Test VPA)',
    },
    'verify_account_in_upi_app_test_2': {
      'gu': 'UPI એપમાં ખાતું ચકાસો (Test VPA — ૧૦૦% ફ્રી)',
      'hi': 'यूपीआई ऐप में खाता सत्यापित करें (परीक्षण वीपीए - 100% निःशुल्क)',
      'en': 'Verify Account in UPI App (Test VPA — 100% Free)',
    },
    'payee_name': {
      'gu': 'ખાતાધારકનું નામ (Payee Name)',
      'hi': 'भुगतानकर्ता का नाम',
      'en': 'Payee Name',
    },
    'eg_name_of_society_name_of': {
      'gu': 'દા.ત. સોસાયટીનું નામ / ખાતાધારકનું નામ',
      'hi': 'जैसे सोसायटी का नाम/खाताधारक का नाम',
      'en': 'E.g. Name of Society / Name of Account Holder',
    },
    'default_monthly_amount': {
      'gu': 'ડિફૉલ્ટ માસિક રકમ',
      'hi': 'डिफ़ॉल्ट मासिक राशि',
      'en': 'Default monthly amount',
    },
    'last_date_day': {
      'gu': 'છેલ્લી તારીખ (Day)',
      'hi': 'अंतिम तिथि (दिन)',
      'en': 'Last Date (Day)',
    },
    'live_upi_qr_verification': {
      'gu': 'લાઈવ UPI QR ચકાસણી',
      'hi': 'लाइव यूपीआई क्यूआर सत्यापन',
      'en': 'Live UPI QR Verification',
    },
    'this_qr_code_will_automatically_appear': {
      'gu': 'આ QR કોડ દરેક મેમ્બરના મેન્ટેનન્સ પેજ પર ઓટોમેટિક દેખાશે જેથી સીધું પેમેન્ટ કરી શકાય.',
      'hi': 'यह क्यूआर कोड सीधे भुगतान के लिए प्रत्येक सदस्य के रखरखाव पृष्ठ पर स्वचालित रूप से दिखाई देगा।',
      'en': 'This QR code will automatically appear on each member\'s maintenance page for direct payment.',
    },
    'official_digital_signature_stamp': {
      'gu': 'અધિકૃત ડિજિટલ સહી & સ્ટેમ્પ',
      'hi': 'आधिकारिक डिजिटल हस्ताक्षर एवं मोहर',
      'en': 'Official Digital Signature & Stamp',
    },
    'this_original_signature_and_seal_will': {
      'gu': 'PDF મેન્ટેનન્સ રસીદ પર આ અસલ સહી અને સીલ છપાશે',
      'hi': 'यह मूल हस्ताक्षर और मुहर पीडीएफ रखरखाव रसीद पर मुद्रित की जाएगी',
      'en': 'This original signature and seal will be printed on the PDF Maintenance Receipt',
    },
    'full_name_of_authorized_person': {
      'gu': 'અધિકૃત વ્યક્તિનું પૂરું નામ',
      'hi': 'अधिकृत व्यक्ति का पूरा नाम',
      'en': 'Full name of authorized person',
    },
    'eg_mr_hiteshbhai_patel': {
      'gu': 'દા.ત. શ્રી હિતેશભાઈ પટેલ',
      'hi': 'जैसे श्री हितेशभाई पटेल',
      'en': 'E.g. Mr. Hiteshbhai Patel',
    },
    'designation_desigration': {
      'gu': 'હોદ્દો / ડેઝિગ્રેશન',
      'hi': 'पदनाम/पदनाम',
      'en': 'Designation / Desigration',
    },
    'eg_society_president_chairman': {
      'gu': 'દા.ત. સોસાયટી પ્રમુખ / ચેરમેન',
      'hi': 'जैसे सोसायटी अध्यक्ष/अध्यक्ष',
      'en': 'E.g. Society President / Chairman',
    },
    'signature_is_set_active': {
      'gu': 'સહી સેટ થયેલી છે (Active)',
      'hi': 'हस्ताक्षर सेट है (सक्रिय)',
      'en': 'Signature is set (Active)',
    },
    'remove_signature': {
      'gu': 'સહી હટાવો',
      'hi': 'हस्ताक्षर हटाएँ',
      'en': 'Remove signature',
    },
    'no_signature_added_yet': {
      'gu': 'હજુ સુધી કોઈ સહી ઉમેરેલ નથી',
      'hi': 'अभी तक कोई हस्ताक्षर नहीं जोड़ा गया',
      'en': 'No signature added yet',
    },
    'redraw_the_signature': {
      'gu': 'સહી ફરી દોરો',
      'hi': 'हस्ताक्षर दोबारा बनाएं',
      'en': 'Redraw the signature',
    },
    'draw_a_signature': {
      'gu': 'સહી દોરો',
      'hi': 'एक हस्ताक्षर बनाएं',
      'en': 'Draw a signature',
    },
    'change_photo': {
      'gu': 'ફોટો બદલો',
      'hi': 'फ़ोटो बदलें',
      'en': 'Change photo',
    },
    'upload_photo': {
      'gu': 'ફોટો અપલોડ',
      'hi': 'फोटो अपलोड करें',
      'en': 'Upload photo',
    },
    'saving_2': {
      'gu': 'સાચવી રહ્યા છીએ...',
      'hi': 'सहेजा जा रहा है...',
      'en': 'Saving...',
    },
    'save_settings': {
      'gu': 'સેટિંગ્સ સાચવો (Save Settings)',
      'hi': 'सेटिंग्स सहेजें',
      'en': 'Save Settings',
    },
    'draw_an_authorized_signature_signature': {
      'gu': 'અધિકૃત સહી દોરો (Signature)',
      'hi': 'एक अधिकृत हस्ताक्षर बनाएं (हस्ताक्षर)',
      'en': 'Draw an authorized signature (Signature)',
    },
    'draw_your_signature_in_the_box': {
      'gu': 'બોક્સમાં તમારી સહી આંગળીથી દોરો',
      'hi': 'अपनी उंगली से बॉक्स में अपना हस्ताक्षर बनाएं',
      'en': 'Draw your signature in the box with your finger',
    },
    'sign_here': {
      'gu': '✕ સહી અહીં કરો (Sign here)',
      'hi': '✕ यहां साइन करें',
      'en': '✕ Sign here',
    },
    'clean_up': {
      'gu': 'સાફ કરો',
      'hi': 'साफ़ करो',
      'en': 'Clean up',
    },
    'save_the_signature': {
      'gu': 'સહી સાચવો',
      'hi': 'हस्ताक्षर सहेजें',
      'en': 'Save the signature',
    },
    'please_write_an_appeal_message_or': {
      'gu': 'કૃપા કરીને અપીલ સંદેશો અથવા સ્પષ્ટતા લખો.',
      'hi': 'कृपया एक अपील संदेश या स्पष्टीकरण लिखें।',
      'en': 'Please write an appeal message or explanation.',
    },
    'admin': {
      'gu': 'એડમિન',
      'hi': 'व्यवस्थापक',
      'en': 'Admin',
    },
    'appeal_request_has_been_successfully_sent': {
      'gu': 'અપીલ વિનંતી સફળતાપૂર્વક સુપર એડમિનને મોકલાઈ ગઈ છે.',
      'hi': 'अपील अनुरोध सुपर एडमिन को सफलतापूर्वक भेज दिया गया है।',
      'en': 'Appeal request has been successfully sent to Super Admin.',
    },
    'impact_on_society_as_a_whole': {
      'gu': 'સમગ્ર સોસાયટી પર અસર:',
      'hi': 'समग्र रूप से समाज पर प्रभाव:',
      'en': 'Impact on society as a whole:',
    },
    'due_to_this_suspension_access_to': {
      'gu': 'આ સ્થગિતીકરણને કારણે તમારી સોસાયટીના તમામ સબ-એડમિન, સભ્યો (Members) અને વોચમેન (Watchmen) માટે પણ એપનું એક્સેસ બંધ છે.',
      'hi': 'इस निलंबन के कारण, आपकी सोसायटी के सभी उप-व्यवस्थापकों, सदस्यों और चौकीदारों के लिए ऐप तक पहुंच भी बंद है।',
      'en': 'Due to this suspension, access to the app is also closed for all sub-admins, members and watchmen of your society.',
    },
    'approved_resolved': {
      'gu': 'મંજૂર / ઉકેલાયેલ',
      'hi': 'स्वीकृत/समाधान',
      'en': 'Approved / Resolved',
    },
    'rejected_rejected': {
      'gu': 'અસ્વીકૃત / નકારેલ',
      'hi': 'अस्वीकृत/अस्वीकृत',
      'en': 'Rejected / Rejected',
    },
    'super_admin_under_review': {
      'gu': 'સુપર એડમિન સમીક્ષા હેઠળ',
      'hi': 'सुपर एडमिन समीक्षाधीन',
      'en': 'Super admin under review',
    },
    'latest_appeal_status': {
      'gu': 'તાજેતરની અપીલ સ્થિતિ',
      'hi': 'नवीनतम अपील स्थिति',
      'en': 'Latest appeal status',
    },
    'your_appeal_details': {
      'gu': 'તમારી અપીલ વિગત:',
      'hi': 'आपकी अपील का विवरण:',
      'en': 'Your appeal details:',
    },
    'super_admins_official_reply': {
      'gu': 'સુપર એડમિનનો સત્તાવાર પ્રત્યુત્તર:',
      'hi': 'सुपर एडमिन का आधिकारिक उत्तर:',
      'en': 'Super Admin\'s official reply:',
    },
    'write_a_new_appeal': {
      'gu': 'નવી અપીલ લખો',
      'hi': 'एक नई अपील लिखें',
      'en': 'Write a new appeal',
    },
    'reconsideration_appeal_form': {
      'gu': 'પુનઃવિચારણા અપીલ ફોર્મ',
      'hi': 'पुनर्विचार अपील प्रपत्र',
      'en': 'Reconsideration Appeal Form',
    },
    'send_the_necessary_details_or_clarifications': {
      'gu': 'સોસાયટી ફરીથી સક્રિય કરવા માટે જરૂરી વિગત કે સ્પષ્ટતા સુપર એડમિનને મોકલો:',
      'hi': 'सोसायटी को पुनः सक्रिय करने के लिए सुपर एडमिन को आवश्यक विवरण या स्पष्टीकरण भेजें:',
      'en': 'Send the necessary details or clarifications to the Super Admin to reactivate the society:',
    },
    'eg_our_societys_annual_renewal_payment': {
      'gu': 'દા.ત. અમારી સોસાયટીનું વાર્ષિક રિન્યુઅલ પેમેન્ટ થઈ ગયું છે, કૃપા કરીને એકાઉન્ટ પુનઃસક્રિય કરશો...',
      'hi': 'जैसे हमारी सोसायटी का वार्षिक नवीनीकरण भुगतान हो गया है, कृपया खाता पुनः सक्रिय करें...',
      'en': 'E.g. Our society\'s annual renewal payment is done, please reactivate the account...',
    },
    'sending': {
      'gu': 'મોકલાઈ રહ્યું છે...',
      'hi': 'भेजा जा रहा है...',
      'en': 'Sending...',
    },
    'send_appeal_to_super_admin': {
      'gu': 'સુપર એડમિનને અપીલ મોકલો',
      'hi': 'सुपर एडमिन को अपील भेजें',
      'en': 'Send appeal to super admin',
    },
    'exit_the_app_logout': {
      'gu': 'એપમાંથી બહાર નીકળો (લૉગઆઉટ)',
      'hi': 'ऐप से बाहर निकलें (लॉगआउट करें)',
      'en': 'Exit the app (Logout)',
    },
    'delete_user': {
      'gu': 'યુઝર ડિલીટ કરવો છે?',
      'hi': 'उपयोगकर्ता हटाएं?',
      'en': 'Delete user?',
    },
    'search_by_name_phone_wing_or': {
      'gu': 'નામ, ફોન, વિંગ અથવા ફ્લેટ નંબરથી શોધો...',
      'hi': 'नाम, फ़ोन, विंग या फ़्लैट नंबर से खोजें...',
      'en': 'Search by name, phone, wing or flat number...',
    },
    'no_users_found': {
      'gu': 'કોઈ યુઝર મળ્યા નથી',
      'hi': 'कोई उपयोगकर्ता नहीं मिला',
      'en': 'No users found',
    },
    'there_are_no_results_matching_your': {
      'gu': 'તમારા સર્ચ સાથે મેળ ખાતું કોઈ પરિણામ નથી.',
      'hi': 'आपकी खोज से मेल खाता कोई परिणाम नहीं है.',
      'en': 'There are no results matching your search.',
    },
    'there_are_no_registrations_in_this': {
      'gu': 'આ કેટેગરીમાં હજી કોઈ નોંધણી થયેલ નથી.',
      'hi': 'इस श्रेणी में अभी तक कोई पंजीकरण नहीं हुआ है।',
      'en': 'There are no registrations in this category yet.',
    },
    'new_user': {
      'gu': 'નવો યુઝર',
      'hi': 'नए उपयोगकर्ता',
      'en': 'New user',
    },
    'anonymous': {
      'gu': 'અનામી',
      'hi': 'गुमनाम',
      'en': 'anonymous',
    },
    'mobile_number_not_registered': {
      'gu': 'મોબાઇલ નંબર નોંધાયેલ નથી',
      'hi': 'मोबाइल नंबर पंजीकृत नहीं है',
      'en': 'Mobile number not registered',
    },
    'gate_watchman': {
      'gu': 'ગેટ વોચમેન',
      'hi': 'गेट का चौकीदार',
      'en': 'Gate watchman',
    },
    'society_member': {
      'gu': 'સોસાયટી મેમ્બર',
      'hi': 'सोसायटी सदस्य',
      'en': 'Society Member',
    },
    'member_details': {
      'gu': 'સભ્યની વિગતો',
      'hi': 'सदस्य विवरण',
      'en': 'Member details',
    },
    'block_flat_no': {
      'gu': 'બ્લોક & ફ્લેટ નંબર',
      'hi': 'ब्लॉक एवं फ्लैट नं',
      'en': 'Block & Flat No',
    },
    'no_flat_assign': {
      'gu': 'કોઈ ફ્લેટ એસાઇન નથી',
      'hi': 'कोई फ्लैट असाइनमेंट नहीं',
      'en': 'No flat assign',
    },
    'date_of_registration': {
      'gu': 'રજીસ્ટ્રેશન તારીખ',
      'hi': 'पंजीकरण की तिथि',
      'en': 'Date of Registration',
    },
    'account_status': {
      'gu': 'એકાઉન્ટ સ્ટેટસ',
      'hi': 'खाता स्थिति',
      'en': 'Account status',
    },
    'active_verified': {
      'gu': 'સક્રિય (Active & Verified)',
      'hi': 'सक्रिय एवं सत्यापित',
      'en': 'Active & Verified',
    },
    'user_id': {
      'gu': 'યુઝર આઈડી',
      'hi': 'उपयोगकर्ता आईडी',
      'en': 'User ID',
    },
    'delete_3': {
      'gu': 'ડિલીટ કરો',
      'hi': 'हटाएँ',
      'en': 'Delete',
    },
    'copy_2': {
      'gu': 'કૉપિ કરો',
      'hi': 'प्रतिलिपि',
      'en': 'Copy',
    },
    'id_copied': {
      'gu': 'આઈડી કૉપિ થઈ ગયું!',
      'hi': 'आईडी कॉपी की गई!',
      'en': 'ID copied!',
    },
    'reset_filters': {
      'gu': 'ફિલ્ટર્સ રીસેટ કરો',
      'hi': 'फ़िल्टर रीसेट करें',
      'en': 'Reset filters',
    },
    'date_filter': {
      'gu': 'તારીખ ફિલ્ટર',
      'hi': 'दिनांक फ़िल्टर',
      'en': 'Date filter',
    },
    'grocery': {
      'gu': 'ગ્રોસરી',
      'hi': 'किराना',
      'en': 'grocery',
    },
    'to_eat': {
      'gu': 'ખાવાનું',
      'hi': 'खाने के लिए',
      'en': 'to eat',
    },
    'courier': {
      'gu': 'કુરિયર',
      'hi': 'कूरियर',
      'en': 'Courier',
    },
    'cab': {
      'gu': 'કેબ',
      'hi': 'कैब',
      'en': 'Cab',
    },
    'service': {
      'gu': 'સર્વિસ',
      'hi': 'सेवा',
      'en': 'Service',
    },
    'repair': {
      'gu': 'રિપેર',
      'hi': 'मरम्मत',
      'en': 'Repair',
    },
    'technician': {
      'gu': 'ટેકનિશિયન',
      'hi': 'तकनीशियन',
      'en': 'technician',
    },
    'the_guest': {
      'gu': 'મહેમાન',
      'hi': 'अतिथि',
      'en': 'the guest',
    },
    'a_friend': {
      'gu': 'મિત્ર',
      'hi': 'एक दोस्त',
      'en': 'a friend',
    },
    'search_name_phone_vehicle_or_flat': {
      'gu': 'નામ, ફોન, વાહન અથવા ફ્લેટ નંબર શોધો...',
      'hi': 'नाम, फ़ोन, वाहन या फ़्लैट नंबर खोजें...',
      'en': 'Search name, phone, vehicle or flat number...',
    },
    'all_the_time': {
      'gu': '📅 બધા સમય',
      'hi': '📅हर समय',
      'en': '📅 All the time',
    },
    'today': {
      'gu': '⚡ આજે',
      'hi': '⚡ आज',
      'en': '⚡ Today',
    },
    'yesterday_2': {
      'gu': '⏮️ ગઈકાલે',
      'hi': '⏮️ कल',
      'en': '⏮️ yesterday',
    },
    'this_week': {
      'gu': '📆 આ સપ્તાહ',
      'hi': '📆इस सप्ताह',
      'en': '📆 This week',
    },
    'this_month': {
      'gu': '🗓️ આ મહિનો',
      'hi': '🗓️इस महीने',
      'en': '🗓️ This month',
    },
    'all_purpose': {
      'gu': '✨ બધા હેતુ',
      'hi': '✨ सर्व प्रयोजन',
      'en': '✨ All purpose',
    },
    'food_grocery': {
      'gu': '🍔 ફૂડ & ગ્રોસરી',
      'hi': '🍔 भोजन और किराना',
      'en': '🍔 Food & Grocery',
    },
    'parcel_courier': {
      'gu': '📦 પાર્સલ & કુરિયર',
      'hi': '📦 पार्सल एवं कूरियर',
      'en': '📦 Parcel & Courier',
    },
    'cab_ride': {
      'gu': '🚕 કેબ & રાઈડ',
      'hi': '🚕 कैब और सवारी',
      'en': '🚕 Cab & Ride',
    },
    'service_repair': {
      'gu': '🔧 સર્વિસ & રિપેર',
      'hi': '🔧 सेवा एवं मरम्मत',
      'en': '🔧 Service & Repair',
    },
    'guest': {
      'gu': '👥 મહેમાન (Guest)',
      'hi': '👥अतिथि',
      'en': '👥 Guest',
    },
    'all_blocks': {
      'gu': 'બધા બ્લોક્સ',
      'hi': 'सभी ब्लॉक',
      'en': 'All blocks',
    },
    'visitor_statistics': {
      'gu': 'મુલાકાતી આંકડા',
      'hi': 'आगंतुक आँकड़े',
      'en': 'Visitor statistics',
    },
    'select_a_date': {
      'gu': '🔍 તારીખ પસંદ કરો',
      'hi': '🔍 एक तारीख चुनें',
      'en': '🔍 Select a date',
    },
    'the_filter_is_active': {
      'gu': 'ફિલ્ટર સક્રિય છે',
      'hi': 'फ़िल्टर सक्रिय है',
      'en': 'The filter is active',
    },
    'clear_all': {
      'gu': 'બધા સાફ કરો',
      'hi': 'सब साफ़ करें',
      'en': 'Clear all',
    },
    'no_visitors_were_found_according_to': {
      'gu': 'આ ફિલ્ટર્સ મુજબ કોઈ વિઝિટર મળ્યા નથી',
      'hi': 'इन फ़िल्टर के अनुसार कोई विज़िटर नहीं मिला',
      'en': 'No visitors were found according to these filters',
    },
    'there_are_no_visitors_in_this': {
      'gu': 'આ કેટેગરીમાં કોઈ વિઝિટર નથી',
      'hi': 'इस श्रेणी में कोई विज़िटर नहीं हैं',
      'en': 'There are no visitors in this category',
    },
    'change_the_filter_or_clear_all': {
      'gu': 'ફિલ્ટર બદલો અથવા બધા ફિલ્ટર્સ સાફ કરો',
      'hi': 'फ़िल्टर बदलें या सभी फ़िल्टर साफ़ करें',
      'en': 'Change the filter or clear all filters',
    },
    'clear_all_filters': {
      'gu': 'બધા ફિલ્ટર્સ સાફ કરો',
      'hi': 'सभी फ़िल्टर साफ़ करें',
      'en': 'Clear all filters',
    },
    'time_not_recorded': {
      'gu': 'સમય નોંધાયેલ નથી',
      'hi': 'समय दर्ज नहीं किया गया',
      'en': 'Time not recorded',
    },
    'pending_2': {
      'gu': 'પેન્ડિંગ (Pending)',
      'hi': 'लंबित',
      'en': 'Pending',
    },
    'recorded_as_the_visitor_went_out': {
      'gu': 'મુલાકાતી બહાર ગયા તરીકે નોંધાયા.',
      'hi': 'आगंतुक के बाहर जाते ही रिकॉर्ड किया गया।',
      'en': 'Recorded as the visitor went out.',
    },
    'mark_the_exit': {
      'gu': 'એક્ઝિટ માર્ક કરો',
      'hi': 'निकास को चिह्नित करें',
      'en': 'Mark the exit',
    },
    'change_password': {
      'gu': 'પાસવર્ડ બદલો',
      'hi': 'पासवर्ड बदलें',
      'en': 'Change password',
    },
    'new_password': {
      'gu': 'નવો પાસવર્ડ *',
      'hi': 'नया पासवर्ड*',
      'en': 'New Password *',
    },
    'password_must_be_longer_than_6': {
      'gu': 'પાસવર્ડ 6 અક્ષરથી મોટો હોવો જોઈએ.',
      'hi': 'पासवर्ड 6 अक्षरों से अधिक लंबा होना चाहिए.',
      'en': 'Password must be longer than 6 characters.',
    },
    'watchman_password_reset_request_has_been': {
      'gu': 'વોચમેન પાસવર્ડ રીસેટ રિક્વેસ્ટ મોકલાઈ ગઈ છે.',
      'hi': 'वॉचमैन पासवर्ड रीसेट अनुरोध भेज दिया गया है।',
      'en': 'Watchman password reset request has been sent.',
    },
    'change': {
      'gu': 'બદલો',
      'hi': 'परिवर्तन',
      'en': 'change',
    },
    'main_gate_security_team': {
      'gu': 'મુખ્ય ગેટ સિક્યોરિટી ટીમ',
      'hi': 'मुख्य द्वार सुरक्षा दल',
      'en': 'Main Gate Security Team',
    },
    'there_are_no_watchmen_registered_yet': {
      'gu': 'હજુ સુધી કોઈ વોચમેન નોંધાયેલ નથી.',
      'hi': 'अभी तक कोई चौकीदार पंजीकृत नहीं है।',
      'en': 'There are no watchmen registered yet.',
    },
    'add_a_new_watchman_from_the': {
      'gu': 'નીચેના બટનથી નવો વોચમેન ઉમેરો.',
      'hi': 'नीचे दिए गए बटन से एक नया चौकीदार जोड़ें।',
      'en': 'Add a new watchman from the button below.',
    },
    'anonymous_guard': {
      'gu': 'અનામી ગાર્ડ',
      'hi': 'गुमनाम गार्ड',
      'en': 'Anonymous guard',
    },
    'on_duty': {
      'gu': '🟢 ફરજ પર',
      'hi': '🟢ड्यूटी पर',
      'en': '🟢 On duty',
    },
    'on_holiday': {
      'gu': '⚪ રજા પર',
      'hi': '⚪छुट्टी पर',
      'en': '⚪ On holiday',
    },
    'make_a_call_2': {
      'gu': 'કોલ કરો',
      'hi': 'कॉल करो',
      'en': 'make a call',
    },
    'view_signature_sheet': {
      'gu': 'સહી પત્રક જુઓ (Signature Sheet)',
      'hi': 'हस्ताक्षर पत्र देखें',
      'en': 'View Signature Sheet',
    },
    'occupant': {
      'gu': 'કબજેદાર',
      'hi': 'कब्ज़ा करने वाला',
      'en': 'Occupant',
    },
    'empty_available': {
      'gu': 'ખાલી (ઉપલબ્ધ)',
      'hi': 'खाली (उपलब्ध)',
      'en': 'empty (available)',
    },
    'tap_any_unit_for_details': {
      'gu': '💡 વિગતો માટે કોઈપણ એકમ પર ટૅપ કરો',
      'hi': 'विवरण के लिए किसी भी इकाई पर टैप करें',
      'en': '💡 Tap any unit for details',
    },
    'find_the_unit_number_eg_g01': {
      'gu': 'એકમ નંબર શોધો (દા.ત. G-01, 102, Shop 4)...',
      'hi': 'इकाई संख्या ज्ञात करें (जैसे जी-01, 102, दुकान 4)...',
      'en': 'Find the unit number (eg G-01, 102, Shop 4)...',
    },
    'no_architecture_data_available': {
      'gu': 'કોઈ આર્કિટેક્ચર ડેટા ઉપલબ્ધ નથી.',
      'hi': 'कोई आर्किटेक्चर डेटा उपलब्ध नहीं है.',
      'en': 'No architecture data available.',
    },
    'block': {
      'gu': 'બ્લોક',
      'hi': 'ब्लॉक',
      'en': 'Block',
    },
    'there_are_no_units_according_to': {
      'gu': 'પસંદ કરેલા ફિલ્ટર મુજબ કોઈ એકમ નથી.',
      'hi': 'चयनित फ़िल्टर के अनुसार कोई इकाइयाँ नहीं हैं।',
      'en': 'There are no units according to the selected filter.',
    },
    'ground_floor_floor_0': {
      'gu': 'ગ્રાઉન્ડ ફ્લોર (Floor 0)',
      'hi': 'भूतल (तल 0)',
      'en': 'Ground Floor (Floor 0)',
    },
    'active': {
      'gu': 'સક્રિય',
      'hi': 'सक्रिय',
      'en': 'Active',
    },
    'occupant_2': {
      'gu': '🟢 કબજેદાર',
      'hi': '🟢कब्जाधारी',
      'en': '🟢 Occupant',
    },
    'empty_2': {
      'gu': '⚪ ખાલી',
      'hi': '⚪खाली',
      'en': '⚪ Empty',
    },
    'area': {
      'gu': 'ક્ષેત્રફળ (Area)',
      'hi': 'क्षेत्र',
      'en': 'Area',
    },
    'floor_level': {
      'gu': 'માળ લેવલ (Floor)',
      'hi': 'फर्श का स्तर',
      'en': 'Floor Level',
    },
    'ground_0': {
      'gu': 'ગ્રાઉન્ડ (0)',
      'hi': 'ज़मीन (0)',
      'en': 'ground (0)',
    },
    'unit_type_2': {
      'gu': 'એકમ શ્રેણી (Type)',
      'hi': 'इकाई प्रकार',
      'en': 'Unit Type',
    },
    'block_floor': {
      'gu': 'બ્લોક / ફ્લોર',
      'hi': 'ब्लॉक/मंजिल',
      'en': 'Block / Floor',
    },
    'resident_info': {
      'gu': 'કબજેદાર / સભ્ય વિગતો (Resident Info)',
      'hi': 'निवासी जानकारी',
      'en': 'Resident Info',
    },
    'unknown_member': {
      'gu': 'અજાણ્યો સભ્ય',
      'hi': 'अज्ञात सदस्य',
      'en': 'unknown member',
    },
    'subadmin_committee_member': {
      'gu': 'સબ-એડમિન / કમિટી મેમ્બર',
      'hi': 'उप-व्यवस्थापक/समिति सदस्य',
      'en': 'Sub-Admin / Committee Member',
    },
    'registered_member_shopkeeper': {
      'gu': 'નોંધાયેલ સભ્ય / દુકાનદાર',
      'hi': 'पंजीकृत सदस्य/दुकानदार',
      'en': 'Registered Member / Shopkeeper',
    },
    'whatsapp': {
      'gu': 'વોટ્સએપ',
      'hi': 'व्हाट्सएप',
      'en': 'WhatsApp',
    },
    'no_member_alloted_vacant': {
      'gu': 'કોઈ સભ્ય ફાળવેલ નથી (Vacant)',
      'hi': 'कोई सदस्य आवंटित नहीं (रिक्त)',
      'en': 'No Member Alloted (Vacant)',
    },
    'this_unit_is_currently_vacant_you': {
      'gu': 'આ એકમ હાલમાં ખાલી છે. તમે સીધા જ નવા સભ્યને એલોટ કરી શકો છો.',
      'hi': 'यह इकाई फिलहाल खाली है. आप सीधे एक नया सदस्य आवंटित कर सकते हैं।',
      'en': 'This unit is currently vacant. You can directly allocate a new member.',
    },
    'add_member_to_this_unit': {
      'gu': 'આ યુનિટમાં સભ્ય ઉમેરો (Add Member)',
      'hi': 'इस इकाई में सदस्य जोड़ें',
      'en': 'Add Member to this Unit',
    },
    'shop_3': {
      'gu': 'દુકાન (Shop)',
      'hi': 'दुकान',
      'en': 'Shop',
    },
    'retail_shop': {
      'gu': 'રીટેલ શોપ',
      'hi': 'खुदरा दुकान',
      'en': 'Retail shop',
    },
    'showroom_4': {
      'gu': 'શોરૂમ (Showroom)',
      'hi': 'शोरूम',
      'en': 'Showroom',
    },
    'showroom_5': {
      'gu': 'શોરૂમ',
      'hi': 'शोरूम',
      'en': 'Showroom',
    },
    'office_corporate': {
      'gu': 'ઓફિસ (Corporate)',
      'hi': 'कार्यालय (कॉर्पोरेट)',
      'en': 'Office (Corporate)',
    },
    'office_2': {
      'gu': 'ઓફિસ',
      'hi': 'कार्यालय',
      'en': 'Office',
    },
    'bungalow_rowhouse': {
      'gu': 'બંગલો / રો-હાઉસ',
      'hi': 'बंगला/रो-हाउस',
      'en': 'Bungalow / Row-house',
    },
    'bungalow': {
      'gu': 'બંગલો',
      'hi': 'बंगला',
      'en': 'bungalow',
    },
    'godown_warehouse': {
      'gu': 'ગોડાઉન / વેરહાઉસ',
      'hi': 'गोदाम/गोदाम',
      'en': 'Godown / Warehouse',
    },
    'apartment': {
      'gu': 'ફ્લેટ (Apartment)',
      'hi': 'अपार्टमेंट',
      'en': 'Apartment',
    },
    'commercial_premises_units': {
      'gu': 'કોમર્શિયલ પરિસર એકમો',
      'hi': 'वाणिज्यिक परिसर इकाइयाँ',
      'en': 'Commercial premises units',
    },
    'shops_and_office_units_set_up': {
      'gu': 'એડમિન દ્વારા સેટઅપ કરેલ શોપ્સ અને ઓફિસ યુનિટ્સ',
      'hi': 'व्यवस्थापक द्वारा स्थापित दुकानें और कार्यालय इकाइयाँ',
      'en': 'Shops and office units set up by admin',
    },
    'mixed_complex_units': {
      'gu': 'મિક્સ્ડ સંકુલ એકમો',
      'hi': 'मिश्रित जटिल इकाइयाँ',
      'en': 'Mixed complex units',
    },
    'shops_and_residential_flats_set_up': {
      'gu': 'એડમિન દ્વારા સેટઅપ કરેલ શોપ્સ અને રેસિડેન્શિયલ ફ્લેટ્સ',
      'hi': 'प्रशासन द्वारा स्थापित दुकानें और आवासीय फ्लैट',
      'en': 'Shops and Residential Flats set up by Admin',
    },
    'society_street_and_rowhouse': {
      'gu': 'સોસાયટી શેરી અને રો-હાઉસ',
      'hi': 'सोसायटी स्ट्रीट और रो-हाउस',
      'en': 'Society Street and Row-House',
    },
    'bungalow_and_plot_units_set_up': {
      'gu': 'એડમિન દ્વારા સેટઅપ કરેલ બંગલો અને પ્લોટ એકમો',
      'hi': 'व्यवस्थापक द्वारा स्थापित बंगला और प्लॉट इकाइयाँ',
      'en': 'Bungalow and plot units set up by admin',
    },
    'society_wings_and_flats': {
      'gu': 'સોસાયટી વિંગ્સ અને ફ્લેટ્સ',
      'hi': 'सोसायटी विंग्स और फ्लैट्स',
      'en': 'Society Wings and Flats',
    },
    'wings_and_apartments_set_up_by': {
      'gu': 'એડમિન દ્વારા સેટઅપ કરેલ વિંગ્સ અને એપાર્ટમેન્ટ્સ',
      'hi': 'व्यवस्थापक द्वारा स्थापित विंग और अपार्टमेंट',
      'en': 'Wings and apartments set up by admin',
    },
    'invalid_credentials_emailmobile_or_password_is': {
      'gu': 'અમાન્ય ક્રેડેન્શિયલ્સ: ઈમેલ/મોબાઇલ અથવા પાસવર્ડ ખોટો છે. કૃપા કરીને તપાસો અથવા એડમિનનો સંપર્ક કરો.',
      'hi': 'अमान्य क्रेडेंशियल: ईमेल/मोबाइल या पासवर्ड गलत है। कृपया जाँचें या व्यवस्थापक से संपर्क करें।',
      'en': 'Invalid Credentials: Email/Mobile or Password is incorrect. Please check or contact admin.',
    },
    'the_email_address_is_invalid_please': {
      'gu': 'ઈમેલ એડ્રેસ અમાન્ય છે. કૃપા કરીને સાચો ઈમેલ દાખલ કરો.',
      'hi': 'ईमेल पता अमान्य है। कृपया एक मान्य ईमेल दर्ज करें।',
      'en': 'The email address is invalid. Please enter a valid email.',
    },
    'this_account_is_disabled_contact_the': {
      'gu': 'આ એકાઉન્ટ નિષ્ક્રિય (ડીસેબલ) કરેલું છે. સોસાયટી એડમિનનો સંપર્ક કરો.',
      'hi': 'यह खाता अक्षम है. सोसायटी व्यवस्थापक से संपर्क करें.',
      'en': 'This account is disabled. Contact the Society Admin.',
    },
    'there_have_been_many_unsuccessful_attempts': {
      'gu': 'ઘણી બધી અસફળ કોશિશો થઈ છે. થોડી મિનિટો પછી ફરી પ્રયાસ કરો.',
      'hi': 'कई असफल प्रयास हुए हैं. कुछ मिनटों के बाद पुनः प्रयास करें.',
      'en': 'There have been many unsuccessful attempts. Try again after a few minutes.',
    },
    'account_access_policy': {
      'gu': 'એકાઉન્ટ એક્સેસ નીતિ',
      'hi': 'खाता पहुंच नीति',
      'en': 'Account Access Policy',
    },
    'manual_registration_is_prohibited_for_security': {
      'gu': 'સુરક્ષા માટે જાતે રજીસ્ટ્રેશન પ્રતિબંધિત છે',
      'hi': 'सुरक्षा कारणों से मैन्युअल पंजीकरण निषिद्ध है',
      'en': 'Manual registration is prohibited for security reasons',
    },
    'no_member_or_admin_can_directly': {
      'gu': 'Building Guard એપમાં કોઈ સભ્ય કે એડમિન સીધા જાતે એકાઉન્ટ બનાવી શકતા નથી. ફક્ત અધિકૃત એડમિન જ નવું એકાઉન્ટ બનાવીને લૉગિન વિગતો આપી શકે છે.',
      'hi': 'बिल्डिंग गार्ड ऐप में कोई भी सदस्य या एडमिन सीधे अकाउंट नहीं बना सकता है। केवल अधिकृत व्यवस्थापक ही नया खाता बनाकर लॉगिन विवरण प्रदान कर सकता है।',
      'en': 'No member or admin can directly create account in Building Guard app. Only authorized admin can provide login details by creating a new account.',
    },
    'txt_1_society_admin_chairman_president': {
      'gu': '૧. સોસાયટી એડમિન (ચેરમેન / પ્રમુખ)',
      'hi': '1. सोसायटी एडमिन (अध्यक्ष/अध्यक्ष)',
      'en': '1. Society Admin (Chairman / President)',
    },
    'the_main_admin_account_of_the': {
      'gu': 'નવી સોસાયટીના મુખ્ય એડમિનનું એકાઉન્ટ પ્લેટફોર્મના \'સુપર એડમિન\' દ્વારા બનાવવામાં આવે છે અને તેમને સુરક્ષિત લૉગિન ક્રેડેન્શિયલ્સ આપવામાં આવે છે.',
      'hi': 'नई सोसाइटी का मुख्य व्यवस्थापक खाता प्लेटफ़ॉर्म के \'सुपर एडमिन\' द्वारा बनाया गया है और सुरक्षित लॉगिन क्रेडेंशियल दिया गया है।',
      'en': 'The main admin account of the new society is created by the \'Super Admin\' of the platform and given secure login credentials.',
    },
    'txt_2_society_member_resident': {
      'gu': '૨. સોસાયટી મેમ્બર / રહીશ',
      'hi': '2. सोसायटी सदस्य/निवासी',
      'en': '2. Society Member / Resident',
    },
    'the_account_for_your_flathouse_is': {
      'gu': 'તમારા ફ્લેટ/ઘર માટેનું એકાઉન્ટ તમારી સોસાયટીના એડમિન (ચેરમેન) દ્વારા ડેશબોર્ડમાંથી ઉમેરવામાં આવે છે અને તમને લૉગિન ઈમેલ/મોબાઈલ અને પાસવર્ડ આપવામાં આવે છે.',
      'hi': 'आपके फ्लैट/घर का खाता आपकी सोसायटी के व्यवस्थापक (अध्यक्ष) द्वारा डैशबोर्ड से जोड़ा जाता है और आपको एक लॉगिन ईमेल/मोबाइल और पासवर्ड दिया जाता है।',
      'en': 'The account for your flat/house is added from the dashboard by the admin (chairman) of your society and you are given a login email/mobile and password.',
    },
    'txt_3_subadmin_and_watchmen_guards': {
      'gu': '૩. સબ-એડમિન અને વોચમેન (ગાર્ડ)',
      'hi': '3. उप-प्रशासन और चौकीदार (गार्ड)',
      'en': '3. Sub-Admin and Watchmen (Guards)',
    },
    'accounts_of_committee_members_wing_admins': {
      'gu': 'કમિટી મેમ્બર, વિંગ એડમિન તથા સિક્યોરિટી ગાર્ડ્સનું એકાઉન્ટ પણ સોસાયટી એડમિન દ્વારા તેમના એડમિન પેનલમાંથી તૈયાર કરવામાં આવે છે.',
      'hi': 'समिति के सदस्यों, विंग प्रशासकों और सुरक्षा गार्डों के खाते भी सोसायटी प्रशासकों द्वारा उनके व्यवस्थापक पैनल से तैयार किए जाते हैं।',
      'en': 'Accounts of committee members, wing admins and security guards are also prepared by society admins from their admin panel.',
    },
    'got_it_close_2': {
      'gu': 'સમજાઈ ગયું (Close)',
      'hi': 'समझ गया (बंद करें)',
      'en': 'Got it (Close)',
    },
    'password_reset': {
      'gu': 'પાસવર્ડ રીસેટ',
      'hi': 'पासवर्ड रीसेट',
      'en': 'Password reset',
    },
    'enter_your_registered_email_we_will': {
      'gu': 'તમારો રજીસ્ટર્ડ ઇમેઇલ દાખલ કરો. અમે તમને પાસવર્ડ રીસેટ કરવાની લિંક મોકલીશું.',
      'hi': 'अपना पंजीकृत ईमेल दर्ज करें. हम आपको एक पासवर्ड रीसेट लिंक भेजेंगे.',
      'en': 'Enter your registered email. We will send you a password reset link.',
    },
    'email': {
      'gu': 'ઇમેઇલ',
      'hi': 'ईमेल',
      'en': 'email',
    },
    'a_password_reset_link_has_been': {
      'gu': 'પાસવર્ડ રીસેટ લિંક તમારા ઇમેઇલ પર મોકલવામાં આવી છે.',
      'hi': 'आपके ईमेल पर एक पासवर्ड रीसेट लिंक भेजा गया है।',
      'en': 'A password reset link has been sent to your email.',
    },
    'send_link': {
      'gu': 'લિંક મોકલો',
      'hi': 'लिंक भेजें',
      'en': 'send link',
    },
    'please_enter_name_email_and_password_2': {
      'gu': 'કૃપા કરીને નામ, ઇમેઇલ અને પાસવર્ડ ભરો.',
      'hi': 'कृपया नाम, ईमेल और पासवर्ड दर्ज करें.',
      'en': 'Please enter name, email and password.',
    },
    'please_enter_a_valid_email_address': {
      'gu': 'કૃપા કરીને માન્ય ઇમેઇલ એડ્રેસ લખો.',
      'hi': 'कृपया एक मान्य ईमेल पता प्रविष्ट करें।',
      'en': 'Please enter a valid email address.',
    },
    'password_should_be_at_least_6': {
      'gu': 'પાસવર્ડ ઓછામાં ઓછો ૬ અક્ષરનો હોવો જોઈએ.',
      'hi': 'पासवर्ड कम से कम 6 अक्षर लंबा होना चाहिए.',
      'en': 'Password should be at least 6 characters long.',
    },
    'it_is_mandatory_to_enter_society': {
      'gu': 'નવી સોસાયટી માટે સોસાયટી કોડ લખવો ફરજિયાત છે.',
      'hi': 'नई सोसायटी के लिए सोसायटी कोड दर्ज करना अनिवार्य है।',
      'en': 'It is mandatory to enter society code for new society.',
    },
    'society_and_admin_account_created_successfully': {
      'gu': 'સોસાયટી અને એડમિન એકાઉન્ટ સફળતાપૂર્વક બની ગયું! હવે લૉગિન કરો.',
      'hi': 'सोसाइटी और एडमिन खाता सफलतापूर्वक बनाया गया! अभी लॉगिन करें।',
      'en': 'Society and admin account created successfully! Login now.',
    },
    'registration_successful_now_login_to_your': {
      'gu': 'રજીસ્ટ્રેશન સફળ! હવે તમારા એકાઉન્ટમાં લૉગિન કરો.',
      'hi': 'सफल पंजीकरण! अब अपने अकाउंट में लॉगइन करें.',
      'en': 'Registration successful! Now login to your account.',
    },
    'registration_guide_help': {
      'gu': 'રજીસ્ટ્રેશન માર્ગદર્શિકા (Help)',
      'hi': 'पंजीकरण गाइड (सहायता)',
      'en': 'Registration Guide (Help)',
    },
    'residency_member_registration': {
      'gu': 'રહીશ / સભ્ય રજીસ્ટ્રેશન',
      'hi': 'निवास/सदस्य पंजीकरण',
      'en': 'Residency / Member Registration',
    },
    'enter_the_society_code_obtained_from': {
      'gu': 'તમારા ચેરમેન કે સેક્રેટરી પાસેથી મેળવેલ સોસાયટી કોડ દાખલ કરો. તમારો વિંગ (દા.ત. A) અને ફ્લેટ/દુકાન નંબર (દા.ત. 101, G-02) લખીને રજીસ્ટર કરો.',
      'hi': 'अपने अध्यक्ष या सचिव से प्राप्त सोसायटी कोड दर्ज करें। अपना विंग (जैसे ए) और फ्लैट/दुकान नंबर (जैसे 101, जी-02) लिखकर रजिस्टर करें।',
      'en': 'Enter the society code obtained from your chairman or secretary. Register by writing your wing (eg A) and flat/shop number (eg 101, G-02).',
    },
    'new_society_chairman_builder': {
      'gu': 'નવી સોસાયટી (ચેરમેન / બિલ્ડર)',
      'hi': 'नई सोसायटी (अध्यक्ष/निर्माता)',
      'en': 'New Society (Chairman / Builder)',
    },
    'register_here_to_set_up_a': {
      'gu': 'નવી સોસાયટી, રેસીડેન્સી કે શોપિંગ મોલનું સેટઅપ કરવા અહીંથી રજીસ્ટર કરો. તમારી સોસાયટી માટે અંગ્રેજીમાં યુનિક કોડ (દા.ત. shiv-residency) પસંદ કરો. લૉગિન કર્યા પછી એડમિન સેટઅપ વિઝાર્ડમાં વિંગ અને દુકાનો ઉમેરી શકશો.',
      'hi': 'नई सोसायटी, रेजीडेंसी या शॉपिंग मॉल स्थापित करने के लिए यहां पंजीकरण करें। अपनी सोसायटी के लिए अंग्रेजी में एक अद्वितीय कोड (जैसे शिव-रेजीडेंसी) चुनें। लॉगिन करने के बाद आप एडमिन सेटअप विज़ार्ड में विंग्स और शॉप्स जोड़ सकते हैं।',
      'en': 'Register here to set up a new society, residency or shopping mall. Select a unique code (eg shiv-residency) in English for your society. After login you can add wings and shops in admin setup wizard.',
    },
    'watchman_security_guard_account': {
      'gu': 'વોચમેન / સિક્યુરિટી ગાર્ડ એકાઉન્ટ',
      'hi': 'चौकीदार/सुरक्षा गार्ड खाता',
      'en': 'Watchman / Security Guard Account',
    },
    'for_security_reasons_the_watchman_account': {
      'gu': 'સુરક્ષાના કારણોસર વોચમેનનું એકાઉન્ટ બહારથી રજીસ્ટર થઈ શકતું નથી. માત્ર ચેરમેન પોતાના એડમિન ડેશબોર્ડના \'સ્ટાફ મેનેજમેન્ટ\'માંથી જ વોચમેનનું ખાતું બનાવી શકે છે.',
      'hi': 'सुरक्षा कारणों से वॉचमैन खाता बाहरी रूप से पंजीकृत नहीं किया जा सकता है। केवल चेयरमैन ही अपने एडमिन डैशबोर्ड में \'स्टाफ मैनेजमेंट\' से वॉचमैन अकाउंट बना सकते हैं।',
      'en': 'For security reasons the Watchman account cannot be registered externally. Only the Chairman can create a Watchman account from \'Staff Management\' in his admin dashboard.',
    },
    'understood_2': {
      'gu': 'સમજાઈ ગયું',
      'hi': 'समझ गया',
      'en': 'Understood',
    },
    'smart_society_and_premises_portal': {
      'gu': '✨ સ્માર્ટ સોસાયટી એન્ડ પ્રિમાઇસીસ પોર્ટલ',
      'hi': '✨ स्मार्ट सोसायटी और परिसर पोर्टल',
      'en': '✨ Smart Society and Premises Portal',
    },
    'create_a_new_account': {
      'gu': 'નવું એકાઉન્ટ બનાવો',
      'hi': 'एक नया खाता बनाएं',
      'en': 'Create a new account',
    },
    'log_in_as_a_resident_tenant': {
      'gu': 'રહીશ, ભાડુઆત કે દુકાનદાર તરીકે પ્રવેશ મેળવો',
      'hi': 'एक निवासी, किरायेदार या दुकानदार के रूप में लॉग इन करें',
      'en': 'Log in as a resident, tenant or shopkeeper',
    },
    'set_up_a_new_society_mall': {
      'gu': 'નવી સોસાયટી, મોલ કે બંગલો પ્રોજેક્ટ સેટઅપ કરો',
      'hi': 'एक नई सोसायटी, मॉल या बंगला परियोजना स्थापित करें',
      'en': 'Set up a new society, mall or bungalow project',
    },
    'txt_1_select_your_account_type': {
      'gu': '૧. તમારું એકાઉન્ટ પ્રકાર પસંદ કરો:',
      'hi': '1. अपना खाता प्रकार चुनें:',
      'en': '1. Select your account type:',
    },
    'resident_member': {
      'gu': 'રહીશ / સભ્ય',
      'hi': 'निवासी/सदस्य',
      'en': 'Resident / Member',
    },
    'flat_bungalow_or_shopkeeper': {
      'gu': 'ફ્લેટ, બંગલો કે દુકાનદાર',
      'hi': 'फ्लैट, बंगला या दुकानदार',
      'en': 'Flat, bungalow or shopkeeper',
    },
    'new_society': {
      'gu': 'નવી સોસાયટી',
      'hi': 'नया समाज',
      'en': 'New Society',
    },
    'chairman_admin_setup': {
      'gu': 'ચેરમેન / એડમિન સેટઅપ',
      'hi': 'अध्यक्ष/व्यवस्थापक सेटअप',
      'en': 'Chairman / Admin setup',
    },
    'all_the_families_or_shopkeepers_living': {
      'gu': 'સોસાયટીમાં રહેતા તમામ પરિવારો કે દુકાનદારો અહીંથી સીધા જોડાઈ શકે છે.',
      'hi': 'सोसायटी में रहने वाले सभी परिवार या दुकानदार यहां से सीधे जुड़ सकते हैं।',
      'en': 'All the families or shopkeepers living in the society can connect directly from here.',
    },
    'chairman_secretary_can_setup_from_here': {
      'gu': 'નવી સોસાયટી શરૂ કરવા ચેરમેન / સેક્રેટરી અહીંથી સેટઅપ કરી શકે છે.',
      'hi': 'अध्यक्ष/सचिव यहां से नई सोसायटी शुरू करने के लिए सेटअप कर सकते हैं।',
      'en': 'Chairman / Secretary can setup from here to start a new society.',
    },
    'personal_profile_information': {
      'gu': 'વ્યક્તિગત પ્રોફાઇલ માહિતી',
      'hi': 'व्यक्तिगत प्रोफ़ाइल जानकारी',
      'en': 'Personal Profile Information',
    },
    'full_name_2': {
      'gu': 'પૂરું નામ *',
      'hi': 'पूरा नाम*',
      'en': 'Full Name *',
    },
    'name_of_chairman_admin': {
      'gu': 'ચેરમેન / એડમિનનું નામ *',
      'hi': 'अध्यक्ष/प्रशासक का नाम *',
      'en': 'Name of Chairman / Admin *',
    },
    'mobile_number_contact': {
      'gu': 'મોબાઇલ નંબર (કોન્ટેક્ટ)',
      'hi': 'मोबाइल नंबर (संपर्क)',
      'en': 'Mobile Number (Contact)',
    },
    'email_address_2': {
      'gu': 'ઇમેઇલ એડ્રેસ *',
      'hi': 'ईमेल पता*',
      'en': 'Email Address *',
    },
    'eg_rameshexamplecom': {
      'gu': 'દા.ત. ramesh@example.com',
      'hi': 'जैसे ramesh@example.com',
      'en': 'E.g. ramesh@example.com',
    },
    'password_at_least_6_characters': {
      'gu': 'પાસવર્ડ (ઓછામાં ઓછા ૬ અક્ષર) *',
      'hi': 'पासवर्ड (कम से कम 6 अक्षर) *',
      'en': 'Password (at least 6 characters) *',
    },
    'society_and_unit_details': {
      'gu': 'સોસાયટી અને યુનિટ વિગતો',
      'hi': 'सोसायटी और इकाई विवरण',
      'en': 'Society and Unit Details',
    },
    'a_new_society_configuration': {
      'gu': 'નવી સોસાયટી કોન્ફિગરેશન',
      'hi': 'एक नया समाज विन्यास',
      'en': 'A New Society Configuration',
    },
    'name_of_society': {
      'gu': 'સોસાયટીનું નામ *',
      'hi': 'सोसायटी का नाम*',
      'en': 'Name of Society *',
    },
    'eg_shiv_residency_ratnam_mall': {
      'gu': 'દા.ત. શિવ રેસીડેન્સી / રત્નમ મોલ',
      'hi': 'जैसे शिव रेजीडेंसी/रत्नम मॉल',
      'en': 'E.g. Shiv Residency / Ratnam Mall',
    },
    'new_society_code_in_english': {
      'gu': 'નવો સોસાયટી કોડ (અંગ્રેજીમાં) *',
      'hi': 'नया सोसायटी कोड (अंग्रेजी में) *',
      'en': 'New Society Code (in English) *',
    },
    'eg_shivresidency': {
      'gu': 'દા.ત. shiv-residency',
      'hi': 'जैसे शिव-रेजीडेंसी',
      'en': 'E.g. shiv-residency',
    },
    'other_members_will_join_using_this': {
      'gu': 'અન્ય સભ્યો આ કોડ વાપરીને જોડાશે.',
      'hi': 'अन्य सदस्य इस कोड का उपयोग करके शामिल होंगे।',
      'en': 'Other members will join using this code.',
    },
    'society_code': {
      'gu': 'સોસાયટી કોડ (Society Code)',
      'hi': 'सोसायटी कोड',
      'en': 'Society Code',
    },
    'if_left_blank_it_will_be': {
      'gu': 'ખાલી રાખશો તો default society ગણાશે.',
      'hi': 'यदि इसे खाली छोड़ दिया जाए तो इसे डिफॉल्ट सोसायटी माना जाएगा।',
      'en': 'If left blank it will be considered default society.',
    },
    'wing_street': {
      'gu': 'વિંગ / શેરી',
      'hi': 'विंग/स्ट्रीट',
      'en': 'Wing / Street',
    },
    'eg_a_street_1': {
      'gu': 'દા.ત. A, શેરી 1',
      'hi': 'जैसे ए, स्ट्रीट 1',
      'en': 'E.g. A, Street 1',
    },
    'flat_shop_no': {
      'gu': 'ફ્લેટ / દુકાન નં.',
      'hi': 'फ़्लैट/दुकान नं.',
      'en': 'Flat / Shop no.',
    },
    'eg_101_g01': {
      'gu': 'દા.ત. 101, G-01',
      'hi': 'जैसे 101, जी-01',
      'en': 'E.g. 101, G-01',
    },
    'security_rule_watchman_guard_account_can': {
      'gu': 'સુરક્ષા નિયમ: વોચમેન / ગાર્ડનું ખાતું માત્ર એડમિન ડેશબોર્ડના સ્ટાફ વિભાગમાંથી જ બની શકે છે.',
      'hi': 'सुरक्षा नियम: वॉचमैन/गार्ड खाता केवल एडमिन डैशबोर्ड के स्टाफ सेक्शन से बनाया जा सकता है।',
      'en': 'Security Rule: Watchman / Guard account can be created only from staff section of admin dashboard.',
    },
    'register_a_new_society': {
      'gu': 'નવી સોસાયટી રજીસ્ટર કરો',
      'hi': 'एक नई सोसायटी पंजीकृत करें',
      'en': 'Register a new society',
    },
    'register_as_a_member': {
      'gu': 'મેમ્બર તરીકે રજીસ્ટર કરો',
      'hi': 'सदस्य के रूप में पंजीकरण करें',
      'en': 'Register as a member',
    },
    'already_have_an_account': {
      'gu': 'પહેલેથી એકાઉન્ટ છે?',
      'hi': 'क्या आपके पास पहले से ही एक खाता है?',
      'en': 'Already have an account?',
    },
    'distribution_of_major_expenses_where_money': {
      'gu': 'મુખ્ય ખર્ચાઓની વહેંચણી (Where Money Goes)',
      'hi': 'प्रमुख खर्चों का वितरण (पैसा कहाँ जाता है)',
      'en': 'Distribution of Major Expenses (Where Money Goes)',
    },
    'no_expenses_recorded': {
      'gu': 'કોઈ ખર્ચ નોંધાયેલ નથી',
      'hi': 'कोई खर्च दर्ज नहीं किया गया',
      'en': 'No expenses recorded',
    },
    'the_date_wise_passbook_of_all': {
      'gu': 'સોસાયટીની તમામ આવક અને ખર્ચની તારીખવાર પાસબુક અહીં પારદર્શક રીતે દેખાશે.',
      'hi': 'सोसायटी की समस्त आय-व्यय की तिथिवार पासबुक यहां पारदर्शी रूप से दिखाई देगी।',
      'en': 'The date wise passbook of all income and expenditure of the society will be transparently visible here.',
    },
    'no_amenities_available_at_this_time': {
      'gu': 'અત્યારે કોઈ એમેનિટી ઉપલબ્ધ નથી.',
      'hi': 'इस समय कोई सुविधाएं उपलब्ध नहीं हैं.',
      'en': 'No amenities available at this time.',
    },
    'free': {
      'gu': 'મફત (Free)',
      'hi': 'निःशुल्क',
      'en': 'Free',
    },
    'book_date_slot': {
      'gu': 'તારીખ & સ્લોટ બુક કરો',
      'hi': 'बुक करने की तारीख और स्लॉट',
      'en': 'Book date & slot',
    },
    'select_booking_date': {
      'gu': 'બુકિંગ તારીખ પસંદ કરો:',
      'hi': 'बुकिंग तिथि चुनें:',
      'en': 'Select Booking Date:',
    },
    'select_timeslot': {
      'gu': 'સમય / સ્લોટ પસંદ કરો:',
      'hi': 'समय/स्लॉट चुनें:',
      'en': 'Select time/slot:',
    },
    'occasion_purpose': {
      'gu': 'પ્રસંગ / હેતુ *',
      'hi': 'अवसर/उद्देश्य*',
      'en': 'Occasion / Purpose *',
    },
    'eg_engagement_birthday_party_family_gettogether': {
      'gu': 'દા.ત. સગાઈ, બર્થડે પાર્ટી, પારિવારિક ગેટ-ટુગેધર',
      'hi': 'जैसे सगाई, जन्मदिन की पार्टी, पारिवारिक मिलन समारोह',
      'en': 'E.g. Engagement, birthday party, family get-together',
    },
    'estimated_number_of_guests': {
      'gu': 'અંદાજિત મહેમાનોની સંખ્યા',
      'hi': 'अतिथियों की अनुमानित संख्या',
      'en': 'Estimated number of guests',
    },
    'rent_security_deposit': {
      'gu': 'ભાડું + સિક્યોરિટી ડિપોઝિટ:',
      'hi': 'किराया + सुरक्षा जमा:',
      'en': 'Rent + Security Deposit:',
    },
    'please_write_the_occasionpurpose': {
      'gu': 'કૃપા કરીને પ્રસંગ/હેતુ લખો.',
      'hi': 'कृपया अवसर/उद्देश्य लिखें।',
      'en': 'Please write the occasion/purpose.',
    },
    'booking_request_has_been_successfully_sent': {
      'gu': '✅ બુકિંગ રિક્વેસ્ટ એડમિનને સફળતાપૂર્વક મોકલાઈ ગઈ છે.',
      'hi': '✅ बुकिंग अनुरोध सफलतापूर्वक व्यवस्थापक को भेज दिया गया है।',
      'en': '✅ Booking request has been successfully sent to admin.',
    },
    'submit_a_request': {
      'gu': 'રિક્વેસ્ટ સબમિટ કરો',
      'hi': 'एक अनुरोध सबमिट करें',
      'en': 'Submit a request',
    },
    'no_facility_has_been_booked_yet': {
      'gu': 'આપે હજુ સુધી કોઈ સુવિધા બુક કરેલ નથી.',
      'hi': 'अभी तक कोई सुविधा बुक नहीं की गई है.',
      'en': 'No facility has been booked yet.',
    },
    'under_review_2': {
      'gu': 'ચકાસણી હેઠળ (Under Review)',
      'hi': 'समीक्षाधीन',
      'en': 'Under Review',
    },
    'guest_gate_entry_passcode_event_gate': {
      'gu': 'મહેમાન ગેટ એન્ટ્રી પાસકોડ (Event Gate Pass):',
      'hi': 'अतिथि गेट प्रवेश पासकोड (इवेंट गेट पास):',
      'en': 'Guest Gate Entry Passcode (Event Gate Pass):',
    },
    'share_passcode_to_guests_on_whatsapp': {
      'gu': 'WhatsApp પર મહેમાનોને પાસકોડ શેર કરો',
      'hi': 'व्हाट्सएप पर मेहमानों को पासकोड साझा करें',
      'en': 'Share passcode to guests on WhatsApp',
    },
    'water_supply': {
      'gu': 'પાણી પુરવઠો',
      'hi': 'जल आपूर्ति',
      'en': 'Water supply',
    },
    'light_electricity': {
      'gu': 'લાઈટ / વીજળી',
      'hi': 'प्रकाश/बिजली',
      'en': 'Light / Electricity',
    },
    'the_elevator_problem': {
      'gu': 'લિફ્ટ સમસ્યા',
      'hi': 'लिफ्ट की समस्या',
      'en': 'The elevator problem',
    },
    'cleaning_garbage': {
      'gu': 'સફાઈ / કચરો',
      'hi': 'सफ़ाई/कचरा',
      'en': 'Cleaning / Garbage',
    },
    'parking_dispute': {
      'gu': 'પાર્કિંગ વિવાદ',
      'hi': 'पार्किंग विवाद',
      'en': 'Parking dispute',
    },
    'security': {
      'gu': 'સિક્યોરિટી',
      'hi': 'सुरक्षा',
      'en': 'Security',
    },
    'another_general': {
      'gu': 'અન્ય સામાન્ય',
      'hi': 'एक और जनरल',
      'en': 'Another general',
    },
    'complaint_successfully_registered': {
      'gu': 'ફરિયાદ સફળતાપૂર્વક નોંધાઈ ગઈ છે!',
      'hi': 'शिकायत सफलतापूर्वक पंजीकृत!',
      'en': 'Complaint successfully registered!',
    },
    'society_support_desk': {
      'gu': 'સોસાયટી સપોર્ટ ડેસ્ક',
      'hi': 'सोसायटी सहायता डेस्क',
      'en': 'Society Support Desk',
    },
    'report_a_problem_or_complaint': {
      'gu': 'સમસ્યા કે ફરિયાદ નોંધો',
      'hi': 'किसी समस्या या शिकायत की रिपोर्ट करें',
      'en': 'Report a problem or complaint',
    },
    'immediate_resolution_will_be_done_by': {
      'gu': 'કમિટી અને એડમિન દ્વારા ત્વરિત નિરાકરણ કરવામાં આવશે.',
      'hi': 'समिति एवं व्यवस्थापक द्वारा तत्काल समाधान किया जायेगा।',
      'en': 'Immediate resolution will be done by committee and admin.',
    },
    'select_the_problem_type': {
      'gu': 'સમસ્યાનો પ્રકાર પસંદ કરો:',
      'hi': 'समस्या का प्रकार चुनें:',
      'en': 'Select the problem type:',
    },
    'subject_short_description': {
      'gu': 'વિષય / ટૂંકી વિગત *',
      'hi': 'विषय/संक्षिप्त विवरण *',
      'en': 'Subject / Short Description *',
    },
    'eg_3rd_floor_light_off_slot': {
      'gu': 'દા.ત. ૩જા માળે લાઈટ બંધ છે / સ્લોટ સમસ્યા',
      'hi': 'जैसे तीसरी मंजिल की लाइट बंद/स्लॉट की समस्या',
      'en': 'E.g. 3rd floor light off / slot problem',
    },
    'please_write_a_subject': {
      'gu': 'કૃપા કરીને વિષય લખો',
      'hi': 'कृपया एक विषय लिखें',
      'en': 'Please write a subject',
    },
    'full_description': {
      'gu': 'સંપૂર્ણ વિગત (Description)',
      'hi': 'पूर्ण विवरण',
      'en': 'Full Description',
    },
    'write_about_the_problem_in_detail': {
      'gu': 'સમસ્યા વિશે વિગતવાર લખો જેથી કમિટી સરળતાથી ઝડપી ઉકેલ લાવી શકે...',
      'hi': 'समस्या के बारे में विस्तार से लिखें ताकि समिति आसानी से त्वरित समाधान निकाल सके...',
      'en': 'Write about the problem in detail so that the committee can easily come up with a quick solution...',
    },
    'complaint_is_being_sent': {
      'gu': 'ફરિયાદ મોકલાઈ રહી છે...',
      'hi': 'शिकायत भेजी जा रही है...',
      'en': 'Complaint is being sent...',
    },
    'submit_a_complaint': {
      'gu': 'ફરિયાદ સબમિટ કરો',
      'hi': 'शिकायत दर्ज करें',
      'en': 'Submit a complaint',
    },
    'photo_of_the_problem_optional': {
      'gu': 'સમસ્યાનો ફોટો (વૈકલ્પિક)',
      'hi': 'समस्या का फोटो (वैकल्पिक)',
      'en': 'Photo of the problem (optional)',
    },
    'txt_1_photo_selected': {
      'gu': '૧ ફોટો પસંદ થયો',
      'hi': '1 फ़ोटो चयनित',
      'en': '1 photo selected',
    },
    'take_with_camera': {
      'gu': 'કેમેરાથી લો',
      'hi': 'कैमरे से लें',
      'en': 'Take with camera',
    },
    'choose_from_gallery': {
      'gu': 'ગેલેરીમાંથી પસંદ',
      'hi': 'गैलरी से चुनें',
      'en': 'Choose from gallery',
    },
    'urgent': {
      'gu': 'તાત્કાલિક ધ્યાન જરૂરી (Urgent)',
      'hi': 'अत्यावश्यक',
      'en': 'Urgent',
    },
    'if_there_is_water_leakage_main': {
      'gu': 'જો પાણી લીકેજ, મેઈન લાઈન કે લિફ્ટ બ્રેકડાઉન હોય તો ચાલુ કરો.',
      'hi': 'यदि पानी का रिसाव हो, मुख्य लाइन हो या लिफ्ट खराब हो तो चालू करें।',
      'en': 'If there is water leakage, main line or lift breakdown, turn on.',
    },
    'my_earlier_complaints': {
      'gu': 'મારી અગાઉની ફરિયાદો',
      'hi': 'मेरी पहले की शिकायतें',
      'en': 'My earlier complaints',
    },
    'realtime_status': {
      'gu': 'રીયલટાઇમ સ્ટેટસ',
      'hi': 'वास्तविक समय स्थिति',
      'en': 'Realtime status',
    },
    'resolved_2': {
      'gu': 'ઉકેલાઈ ગયેલ',
      'hi': 'समाधान हो गया',
      'en': 'resolved',
    },
    'work_is_in_progress': {
      'gu': 'કામ ચાલુ છે',
      'hi': 'कार्य प्रगति पर है',
      'en': 'Work is in progress',
    },
    'see_photo': {
      'gu': 'ફોટો જુઓ',
      'hi': 'फोटो देखें',
      'en': 'See photo',
    },
    'no_pending_complaints': {
      'gu': 'કોઈ પેન્ડિંગ ફરિયાદ નથી!',
      'hi': 'कोई लंबित शिकायत नहीं!',
      'en': 'No pending complaints!',
    },
    'your_society_is_peaceful_and_wellorderednif': {
      'gu': 'તમારી સોસાયટી શાંતિપૂર્ણ અને સુવ્યવસ્થિત છે.\\nજો કોઈ પ્રશ્ન જણાય તો ઉપરથી સરળતાથી નોંધાવો.',
      'hi': 'आपका समाज शांतिपूर्ण और सुव्यवस्थित है।\\nयदि आपके कोई प्रश्न हैं, तो बस ऊपर से पंजीकरण करें।',
      'en': 'Your society is peaceful and well-ordered.\\nIf you have any query, simply register from above.',
    },
    'maid': {
      'gu': 'કામવાળા (Maid)',
      'hi': 'नौकरानी',
      'en': 'Maid',
    },
    'driver': {
      'gu': 'ડ્રાઈવર (Driver)',
      'hi': 'चालक',
      'en': 'Driver',
    },
    'cook': {
      'gu': 'રસોઈયા (Cook)',
      'hi': 'पकाना',
      'en': 'Cook',
    },
    'gardener': {
      'gu': 'માળી (Gardener)',
      'hi': 'माली',
      'en': 'gardener',
    },
    'tutor': {
      'gu': 'ટ્યુટર (Tutor)',
      'hi': 'शिक्षक',
      'en': 'Tutor',
    },
    'another_helper': {
      'gu': 'અન્ય હેલ્પર',
      'hi': 'एक और सहायक',
      'en': 'Another helper',
    },
    'staff_added_successfully': {
      'gu': 'સ્ટાફ સફળતાપૂર્વક ઉમેરાઈ ગયો.',
      'hi': 'स्टाफ़ सफलतापूर्वक जोड़ा गया.',
      'en': 'Staff added successfully.',
    },
    'add_new_staff_helpers': {
      'gu': 'નવા સ્ટાફ / હેલ્પર ઉમેરો',
      'hi': 'नए कर्मचारी/सहायक जोड़ें',
      'en': 'Add new staff / helpers',
    },
    'function_role': {
      'gu': 'કામગીરી / ભૂમિકા:',
      'hi': 'कार्य/भूमिका:',
      'en': 'Function / Role:',
    },
    'staff_name': {
      'gu': 'સ્ટાફનું નામ *',
      'hi': 'स्टाफ का नाम*',
      'en': 'Staff Name *',
    },
    'eg_minaben': {
      'gu': 'દા.ત. મીનાબેન',
      'hi': 'जैसे मीनाबेन',
      'en': 'E.g. Minaben',
    },
    'enter_name': {
      'gu': 'નામ દાખલ કરો',
      'hi': 'नाम दर्ज करें',
      'en': 'Enter name',
    },
    'mobile_number_3': {
      'gu': 'મોબાઈલ નંબર *',
      'hi': 'मोबाइल नंबर*',
      'en': 'Mobile Number *',
    },
    'txt_10_digit_number': {
      'gu': '૧૦ આંકડાનો નંબર',
      'hi': '10 अंकों की संख्या',
      'en': '10 digit number',
    },
    'enter_a_valid_10_digit_number': {
      'gu': 'સાચો ૧૦ અંકનો નંબર દાખલ કરો',
      'hi': 'एक वैध 10 अंकीय संख्या दर्ज करें',
      'en': 'Enter a valid 10 digit number',
    },
    'adding': {
      'gu': 'ઉમેરાઈ રહ્યું છે...',
      'hi': 'जोड़ा जा रहा है...',
      'en': 'Adding...',
    },
    'save_the_staff': {
      'gu': 'સ્ટાફ સાચવો',
      'hi': 'Save the staff',
      'en': 'Save the staff',
    },
    'no_staff_registered_yet': {
      'gu': 'હજુ કોઈ સ્ટાફ નોંધાયેલ નથી!',
      'hi': 'No staff registered yet!',
      'en': 'No staff registered yet!',
    },
    'add_a_worker_or_driver_by': {
      'gu': 'ઉપરના બટન પર ક્લિક કરીને કામવાળા કે ડ્રાઈવર ઉમેરો, જેથી તેઓને ગેટ પર ડિજિટલ સિક્યોરિટી પાસ મળે.',
      'hi': 'ऊपर दिए गए बटन पर क्लिक करके किसी कर्मचारी या ड्राइवर को जोड़ें, ताकि उन्हें गेट पर डिजिटल सुरक्षा पास मिल सके।',
      'en': 'Add a worker or driver by clicking the button above, so that they get a digital security pass at the gate.',
    },
    'helper': {
      'gu': 'હેલ્પર',
      'hi': 'सहायक',
      'en': 'Helper',
    },
    'delete_the_staff': {
      'gu': 'સ્ટાફ કાઢી નાખો',
      'hi': 'Delete the staff',
      'en': 'Delete the staff',
    },
    'daily_staff_helpers': {
      'gu': 'ડેઇલી સ્ટાફ & હેલ્પર્સ',
      'hi': 'Daily Staff & Helpers',
      'en': 'Daily Staff & Helpers',
    },
    'permanent_staff_management': {
      'gu': 'કાયમી સ્ટાફ મેનેજમેન્ટ',
      'hi': 'स्थायी कर्मचारी प्रबंधन',
      'en': 'Permanent Staff Management',
    },
    'workers_drivers_or_cooks_can_easily': {
      'gu': 'કામવાળા, ડ્રાઈવર કે રસોઈયા ગેટ પર સરળતાથી પ્રવેશી શકે અને ડિજિટલ સિક્યોરિટી પાસ વેરિફાય થાય.',
      'hi': 'कर्मचारी, ड्राइवर या रसोइया आसानी से गेट पर प्रवेश कर सकते हैं और डिजिटल सुरक्षा पास सत्यापित करा सकते हैं।',
      'en': 'Workers, drivers or cooks can easily enter at the gate and get digital security pass verified.',
    },
    'digital_democracy': {
      'gu': 'ડિજિટલ લોકશાહી',
      'hi': 'डिजिटल लोकतंत्र',
      'en': 'Digital Democracy',
    },
    'new_poll_available': {
      'gu': 'નવો નિર્ણય મતદાન માટે ઉપલબ્ધ છે',
      'hi': 'नया निर्णय मतदान के लिए उपलब्ध है',
      'en': 'new decision available for voting',
    },
    'new_polls_available': {
      'gu': 'નવા નિર્ણયો મતદાન માટે ઉપલબ્ધ છે',
      'hi': 'नए निर्णय मतदान के लिए उपलब्ध हैं',
      'en': 'new decisions available for voting',
    },
    'namaste': {
      'gu': 'નમસ્તે',
      'hi': 'नमस्ते',
      'en': 'Namaste',
    },
    'resident': {
      'gu': 'રહેવાસી',
      'hi': 'निवासी',
      'en': 'Resident',
    },
    'flat_label': {
      'gu': 'ફ્લેટ',
      'hi': 'फ्लैट',
      'en': 'Flat',
    },
    'verified_society_member': {
      'gu': 'સોસાયટી માન્ય સભ્ય',
      'hi': 'सोसायटी मान्य सदस्य',
      'en': 'Verified Society Member',
    },
    'days_label': {
      'gu': 'દિવસ',
      'hi': 'दिन',
      'en': 'days',
    },
    'hours_label': {
      'gu': 'કલાક',
      'hi': 'घंटे',
      'en': 'hours',
    },
    'total_label': {
      'gu': 'કુલ',
      'hi': 'कुल',
      'en': 'Total',
    },
    'votes_label': {
      'gu': 'મત',
      'hi': 'वोट',
      'en': 'votes',
    },
    'deadline_label': {
      'gu': 'અંતિમ',
      'hi': 'अंतिम',
      'en': 'Deadline',
    },
    'paid_to_label': {
      'gu': 'ચૂકવ્યા',
      'hi': 'भुगतान किया गया',
      'en': 'Paid to',
    },
    'passbook_entries_label': {
      'gu': 'પાસબુક એન્ટ્રીઓ',
      'hi': 'पासबुक प्रविष्टियां',
      'en': 'Passbook entries',
    },
    'amenities_tab_label': {
      'gu': 'સુવિધાઓ',
      'hi': 'सुविधाएं',
      'en': 'Amenities',
    },
    'my_bookings_tab_label': {
      'gu': 'મારાં બુકિંગ્સ',
      'hi': 'मेरी बुकिंग्स',
      'en': 'My Bookings',
    },
    'amenities_hero_title': {
      'gu': 'સુવિધા & હોલ બુકિંગ કેન્દ્ર',
      'hi': 'सुविधा व हॉल बुकिंग केंद्र',
      'en': 'Amenities & Hall Booking Hub',
    },
    'amenities_hero_subtitle': {
      'gu': 'વાડી, ક્લબહાઉસ, ટેરેસ કે પાર્ટી પ્લોટ બુકિંગ સુવિધા',
      'hi': 'वाडी, क्लब हाउस, छत या पार्टी प्लॉट बुकिंग सुविधा',
      'en': 'Book clubhouse, hall, terrace or party plot easily',
    },
    'available_amenities_count': {
      'gu': 'ઉપલબ્ધ સુવિધાઓ',
      'hi': 'उपलब्ध सुविधाएं',
      'en': 'Available Amenities',
    },
    'capacity_label': {
      'gu': 'ક્ષમતા',
      'hi': 'क्षमता',
      'en': 'Capacity',
    },
    'refundable_deposit_label': {
      'gu': 'રીફંડેબલ ડિપોઝિટ',
      'hi': 'रिफंडेबल सिक्योरिटी',
      'en': 'Refundable Deposit',
    },
    'free_badge': {
      'gu': 'મફત (Free)',
      'hi': 'मुफ़्त (Free)',
      'en': 'Free',
    },
    'per_day_badge': {
      'gu': 'દિવસ',
      'hi': 'दिन',
      'en': 'day',
    },
    'book_now_btn': {
      'gu': 'તારીખ & સ્લોટ બુક કરો',
      'hi': 'तारीख व स्लॉट बुक करें',
      'en': 'Book Date & Slot',
    },
    'under_review_badge': {
      'gu': 'ચકાસણી હેઠળ',
      'hi': 'समीक्षाधीन',
      'en': 'Under Review',
    },
    'approved_badge': {
      'gu': 'મંજૂર થયેલ',
      'hi': 'स्वीकृत',
      'en': 'Approved',
    },
    'rejected_badge': {
      'gu': 'નામંજૂર',
      'hi': 'अस्वीकृत',
      'en': 'Rejected',
    },
    'society_services_suspended_title': {
      'gu': 'સોસાયટી સેવાઓ અસ્થાયી સ્થગિત છે',
      'hi': 'सोसायटी सेवाएं अस्थायी रूप से स्थगित हैं',
      'en': 'Society services are temporarily suspended',
    },
    'society_suspended_msg_prefix': {
      'gu': 'તમારી સોસાયટી',
      'hi': 'आपकी सोसायटी',
      'en': 'Your society',
    },
    'society_suspended_msg_suffix': {
      'gu': 'ની એપ સેવાઓ સુપર એડમિન દ્વારા અસ્થાયી રૂપે નિષ્ક્રિય (Inactive) કરવામાં આવી છે.',
      'hi': 'की ऐप सेवाएं सुपर एडमिन द्वारा अस्थायी रूप से निष्क्रिय कर दी गई हैं।',
      'en': 'app services have been temporarily deactivated by Super Admin.',
    },
    'contact_admin_notice': {
      'gu': 'સેવાઓ ફરી શરૂ કરવા માટે અથવા વધુ વિગત માટે તમારી સોસાયટીના મુખ્ય એડમિન / પ્રમુખશ્રીનો સંપર્ક કરો.',
      'hi': 'सेवाएं पुनः प्रारंभ करने या अधिक जानकारी के लिए अपनी सोसायटी के मुख्य एडमिन / अध्यक्ष से संपर्क करें।',
      'en': 'To restore services or for more details, please contact your society admin / president.',
    },
    'call_society_admin': {
      'gu': 'સોસાયટી એડમિનને કૉલ કરો',
      'hi': 'सोसायटी एडमिन को कॉल करें',
      'en': 'Call Society Admin',
    },
    'check_status_refresh': {
      'gu': 'સ્ટેટસ તપાસો (રીફ્રેશ)',
      'hi': 'स्थिति जांचें (रिफ्रेश)',
      'en': 'Check Status (Refresh)',
    },
    'complexes_label': {
      'gu': 'સંકુલ',
      'hi': 'परिसर',
      'en': 'Complexes',
    },
    'all_premises_label': {
      'gu': 'બધા પરિસરો',
      'hi': 'सभी परिसर',
      'en': 'All Premises',
    },
    'admins_label': {
      'gu': 'એડમિન',
      'hi': 'व्यवस्थापक',
      'en': 'Admins',
    },
    'visitors_label': {
      'gu': 'વિઝિટર',
      'hi': 'आगंतुक',
      'en': 'Visitors',
    },
    'guards_on_duty_label': {
      'gu': 'ગાર્ડ્સ ઓન-ડ્યુટી',
      'hi': 'ड्यूटी पर तैनात गार्ड',
      'en': 'Guards on duty',
    },
    'approve_visitor_btn': {
      'gu': 'મંજૂર કરો',
      'hi': 'मंजूर करें',
      'en': 'Approve',
    },
    'deny_visitor_btn': {
      'gu': 'નામંજૂર કરો',
      'hi': 'अस्वीकार करें',
      'en': 'Deny',
    },
    'visitor_approved_success': {
      'gu': 'મુલાકાતીને પ્રવેશ મંજૂરી અપાઈ.',
      'hi': 'आगंतुक को प्रवेश की अनुमति दी गई।',
      'en': 'Visitor entry has been approved.',
    },
    'visitor_denied_success': {
      'gu': 'મુલાકાતી પ્રવેશ નકારવામાં આવ્યો.',
      'hi': 'आगंतुक का प्रवेश अस्वीकार कर दिया गया।',
      'en': 'Visitor entry has been denied.',
    },
    'visitor_status_approved': {
      'gu': 'પ્રવેશ મંજૂર થયેલ છે',
      'hi': 'प्रवेश स्वीकृत है',
      'en': 'Entry Approved',
    },
    'visitor_status_rejected': {
      'gu': 'પ્રવેશ નકારવામાં આવ્યો છે',
      'hi': 'प्रवेश अस्वीकृत है',
      'en': 'Entry Denied',
    },
    'super_admin_notifications_title': {
      'gu': 'સુપર એડમિન નોટિફિકેશન કેન્દ્ર',
      'hi': 'सुपर एडमिन अधिसूचना केंद्र',
      'en': 'Super Admin Notification Hub',
    },
    'no_admin_notifications_yet': {
      'gu': 'હાલ કોઈ નવી એડમિન નોટિફિકેશન કે અપીલ નથી.',
      'hi': 'फिलहाल कोई नई एडमिन अधिसूचना या अपील नहीं है।',
      'en': 'No admin notifications or appeals yet.',
    },
    'your_voice_in_society_decisions': {
      'gu': 'સોસાયટી નિર્ણયોમાં આપનો અવાજ',
      'hi': 'समाज के निर्णयों में आपकी आवाज़',
      'en': 'Your voice in society decisions',
    },
    'there_are_currently_no_active_polls': {
      'gu': 'હાલ કોઈ સક્રિય મતદાન બાકી નથી',
      'hi': 'वर्तमान में कोई सक्रिय मतदान नहीं बचा है',
      'en': 'There are currently no active polls left',
    },
    'there_are_no_new_polls_currently': {
      'gu': 'અત્યારે કોઈ નવું મતદાન ચાલુ નથી.',
      'hi': 'वर्तमान में कोई नया चुनाव नहीं चल रहा है।',
      'en': 'There are no new polls currently running.',
    },
    'no_previous_decisions_recorded': {
      'gu': 'કોઈ અગાઉના નિર્ણયો નોંધાયેલા નથી.',
      'hi': 'कोई पिछला निर्णय दर्ज नहीं किया गया.',
      'en': 'No previous decisions recorded.',
    },
    'whenever_a_new_decision_is_taken': {
      'gu': 'જ્યારે પણ કમિટી તરફથી સોસાયટીના ખર્ચ, સુવિધા કે નિયમો અંગે નવો નિર્ણય લેવાશે ત્યારે આપ અહીંથી મત આપી શકશો.',
      'hi': 'जब भी समिति द्वारा सोसायटी के खर्चों, सुविधाओं या नियमों के संबंध में कोई नया निर्णय लिया जाता है तो आप यहां से वोट कर सकते हैं।',
      'en': 'Whenever a new decision is taken by the committee regarding the expenses, facilities or rules of the society, you can vote from here.',
    },
    'all_completed_polls_and_passed_resolutions': {
      'gu': 'સમાપ્ત થયેલા તમામ પોલ અને પસાર થયેલા ઠરાવો અહીં સંગ્રહિત થશે.',
      'hi': 'सभी पूर्ण मतदान और पारित प्रस्ताव यहां संग्रहीत किए जाएंगे।',
      'en': 'All completed polls and passed resolutions will be stored here.',
    },
    'your_vote_has_been_successfully_registered': {
      'gu': '🎉 આપનો મત સફળતાપૂર્વક નોંધાઈ ગયો છે! આભાર.',
      'hi': '🎉आपका वोट सफलतापूर्वक पंजीकृत हो गया है! धन्यवाद',
      'en': '🎉 Your vote has been successfully registered! thank you',
    },
    'voted': {
      'gu': 'આપે મત આપી દીધો છે',
      'hi': 'मतदान किया',
      'en': 'Voted',
    },
    'voting_is_pending': {
      'gu': 'મતદાન બાકી છે',
      'hi': 'Voting is pending',
      'en': 'Voting is pending',
    },
    'voting_is_complete_2': {
      'gu': 'મતદાન પૂર્ણ થયું',
      'hi': 'मतदान पूरा हो गया है',
      'en': 'Voting is complete',
    },
    'poll_result': {
      'gu': 'મતદાન પરિણામ:',
      'hi': 'मतदान परिणाम:',
      'en': 'Poll Result:',
    },
    'your_opinion': {
      'gu': 'આપનો મત',
      'hi': 'आपकी राय',
      'en': 'your opinion',
    },
    'society_official_resolution': {
      'gu': 'સોસાયટી સત્તાવાર ઠરાવ:',
      'hi': 'सोसायटी का आधिकारिक संकल्प:',
      'en': 'Society Official Resolution:',
    },
    'select_your_option': {
      'gu': 'આપનો વિકલ્પ પસંદ કરો:',
      'hi': 'अपना विकल्प चुनें:',
      'en': 'Select your option:',
    },
    'txt_1_vote_per_flat': {
      'gu': '(૧ મત પ્રતિ ફ્લેટ)',
      'hi': '(1 vote per flat)',
      'en': '(1 vote per flat)',
    },
    'registering_votes': {
      'gu': 'મત નોંધાઈ રહ્યો છે...',
      'hi': 'Registering votes...',
      'en': 'Registering votes...',
    },
    'select_the_first_option': {
      'gu': 'પહેલાં વિકલ્પ પસંદ કરો',
      'hi': 'Select the first option',
      'en': 'Select the first option',
    },
    'submit_vote': {
      'gu': 'મત આપો (Submit Vote)',
      'hi': 'Submit Vote',
      'en': 'Submit Vote',
    },
    'digital_security_entry': {
      'gu': '✨ ડિજિટલ સિક્યોરિટી એન્ટ્રી',
      'hi': '✨ डिजिटल सुरक्षा प्रविष्टि',
      'en': '✨ Digital security entry',
    },
    'vip_gate_entry_qr_pass': {
      'gu': 'VIP ગેટ એન્ટ્રી QR પાસ',
      'hi': 'VIP Gate Entry QR Pass',
      'en': 'VIP Gate Entry QR Pass',
    },
    'send_qr_pass_to_guest_directly': {
      'gu': 'વોચમેન પૂછપરછ વગર મહેમાનને સીધા આવવા માટે QR પાસ મોકલો.',
      'hi': 'चौकीदार से पूछताछ के बिना सीधे अतिथि को क्यूआर पास भेजें।',
      'en': 'Send QR pass to guest directly without watchman inquiry.',
    },
    'guest_details': {
      'gu': 'મહેમાનની વિગતો',
      'hi': 'Guest details',
      'en': 'Guest details',
    },
    'guest_name': {
      'gu': 'મહેમાનનું નામ *',
      'hi': 'Guest Name *',
      'en': 'Guest Name *',
    },
    'eg_rahul_shah': {
      'gu': 'દા.ત. રાહુલ શાહ',
      'hi': 'जैसे राहुल शाह',
      'en': 'E.g. Rahul Shah',
    },
    'please_enter_a_name': {
      'gu': 'કૃપા કરીને નામ દાખલ કરો',
      'hi': 'Please enter a name',
      'en': 'Please enter a name',
    },
    'select_purpose_of_visit': {
      'gu': 'આવવાનો હેતુ પસંદ કરો:',
      'hi': 'Select purpose of visit:',
      'en': 'Select purpose of visit:',
    },
    'generating_pass': {
      'gu': 'પાસ જનરેટ થઈ રહ્યો છે...',
      'hi': 'Generating pass...',
      'en': 'Generating pass...',
    },
    'approve_get_qr_pass': {
      'gu': 'મંજૂર કરો & QR પાસ મેળવો',
      'hi': 'Approve & Get QR Pass',
      'en': 'Approve & Get QR Pass',
    },
    'qr_pass_is_ready': {
      'gu': 'QR પાસ તૈયાર છે!',
      'hi': 'QR Pass is ready!',
      'en': 'QR Pass is ready!',
    },
    'share_this_pass_with_the_guest': {
      'gu': 'આ પાસ મહેમાન સાથે WhatsApp પર શેર કરો.',
      'hi': 'इस पास को अतिथि के साथ व्हाट्सएप पर साझा करें।',
      'en': 'Share this pass with the guest on WhatsApp.',
    },
    'smart_society_pass': {
      'gu': '🛡️ સ્માર્ટ સોસાયટી પાસ',
      'hi': '🛡️ स्मार्ट सोसायटी पास',
      'en': '🛡️ Smart Society Pass',
    },
    'watchman_will_provide_direct_entry_without': {
      'gu': 'વોચમેન આ QR સ્કેન કરીને વગર કોઈ રોકટોક સીધી એન્ટ્રી આપશે.',
      'hi': 'इस क्यूआर को स्कैन कर चौकीदार बिना किसी परेशानी के सीधे प्रवेश देगा।',
      'en': 'Watchman will provide direct entry without any hassle by scanning this QR.',
    },
    'whatsapp_share': {
      'gu': 'WhatsApp શેર',
      'hi': 'व्हाट्सएप शेयर',
      'en': 'WhatsApp share',
    },
    'create_a_new_pass': {
      'gu': 'નવો પાસ બનાવો',
      'hi': 'एक नया पास बनाएं',
      'en': 'Create a new pass',
    },
    'recently_generated_passes': {
      'gu': 'તાજેતરમાં જનરેટ કરેલા પાસ',
      'hi': 'हाल ही में जनरेट किए गए पास',
      'en': 'Recently generated passes',
    },
    'no_preapproval_pass_has_been_created': {
      'gu': 'હજુ સુધી કોઈ પૂર્વ-મંજૂરી પાસ બનાવેલ નથી.',
      'hi': 'अभी तक कोई प्री-अप्रूवल पास नहीं बनाया गया है.',
      'en': 'No pre-approval pass has been created yet.',
    },
    'anonymous_guest': {
      'gu': 'અનામી મહેમાન',
      'hi': 'अनाम अतिथि',
      'en': 'Anonymous guest',
    },
    'pending_entry': {
      'gu': 'પેન્ડિંગ એન્ટ્રી',
      'hi': 'लंबित प्रविष्टि',
      'en': 'Pending entry',
    },
    'came_in': {
      'gu': 'અંદર આવ્યા',
      'hi': 'अंदर आया',
      'en': 'came in',
    },
    'immediate_security_assistance_alert': {
      'gu': 'તાત્કાલિક સુરક્ષા સહાયતા એલર્ટ',
      'hi': 'तत्काल सुरक्षा सहायता अलर्ट',
      'en': 'Immediate security assistance alert',
    },
    'immediate_alert_push_notification_with_siren': {
      'gu': 'એડમિન અને સોસાયટી ગેટ વોચમેનને સાયરન સાથે તાત્કાલિક એલર્ટ પુશ નોટિફિકેશન જશે.',
      'hi': 'सायरन के साथ तत्काल अलर्ट पुश नोटिफिकेशन एडमिन और सोसायटी गेट के चौकीदारों के पास चला जाएगा।',
      'en': 'Immediate alert push notification with siren will go to admin and society gate watchmen.',
    },
    'problem_or_detail_optional': {
      'gu': 'સમસ્યા અથવા વિગત (વૈકલ્પિક)',
      'hi': 'समस्या या विवरण (वैकल्पिक)',
      'en': 'Problem or Detail (Optional)',
    },
    'eg_bad_health_lift_problem_security': {
      'gu': 'દા.ત. તબિયત ખરાબ છે, લિફ્ટ સમસ્યા, સુરક્ષા...',
      'hi': 'जैसे ख़राब स्वास्थ्य, लिफ्ट की समस्या, सुरक्षा...',
      'en': 'E.g. Bad health, lift problem, security...',
    },
    'yes_send_an_sos': {
      'gu': 'હા, SOS મોકલો',
      'hi': 'हां, एक एसओएस भेजें',
      'en': 'Yes, send an SOS',
    },
    'member_emergency': {
      'gu': '🚨 મેમ્બર ઇમરજન્સી',
      'hi': '🚨सदस्य आपातकाल',
      'en': '🚨 Member Emergency',
    },
    'member_emergency_gate': {
      'gu': '🚨 મેમ્બર ઇમરજન્સી (ગેટ)',
      'hi': '🚨 सदस्य आपातकाल (गेट)',
      'en': '🚨 Member Emergency (Gate)',
    },
    'help_notification_successfully_sent_to_admin': {
      'gu': 'મદદની સૂચના એડમિન અને ગેટને સફળતાપૂર્વક મોકલાઈ.',
      'hi': 'सहायता सूचना सफलतापूर्वक व्यवस्थापक और गेट को भेजी गई।',
      'en': 'Help notification successfully sent to admin and gate.',
    },
    'member_portal_2': {
      'gu': 'મેમ્બર પોર્ટલ',
      'hi': 'सदस्य पोर्टल',
      'en': 'Member Portal',
    },
    'society_recognized_member': {
      'gu': 'સોસાયટી માન્ય સભ્ય',
      'hi': 'समाज द्वारा मान्यता प्राप्त सदस्य',
      'en': 'Society recognized member',
    },
    'live_gate': {
      'gu': 'લાઈવ ગેટ',
      'hi': 'लाइव गेट',
      'en': 'Live Gate',
    },
    'waiting': {
      'gu': 'પ્રતીક્ષા',
      'hi': 'इंतज़ार कर रहा हूँ',
      'en': 'waiting',
    },
    'approved_2': {
      'gu': 'મંજૂર કરેલ',
      'hi': 'स्वीकृत',
      'en': 'Approved',
    },
    'valid_visitor': {
      'gu': 'માન્ય મુલાકાતી',
      'hi': 'वैध आगंतुक',
      'en': 'Valid visitor',
    },
    'dispatched': {
      'gu': 'રવાના થયેલ',
      'hi': 'भेजा गया',
      'en': 'dispatched',
    },
    'amenities_wadi_booking': {
      'gu': 'એમેનિટીઝ & વાડી બુકિંગ',
      'hi': 'सुविधाएं एवं वाडी बुकिंग',
      'en': 'Amenities & Wadi Booking',
    },
    'book_a_wadi_clubhouse_or_terrace': {
      'gu': 'વાડી, ક્લબહાઉસ કે ટેરેસ સ્લોટ બુક કરો અને ગેટ પાસ મેળવો',
      'hi': 'वाडी, क्लब हाउस या टैरेस स्लॉट बुक करें और गेट पास प्राप्त करें',
      'en': 'Book a wadi, clubhouse or terrace slot and get a gate pass',
    },
    'night_security_audit_night_patrol': {
      'gu': 'રાત્રિ સુરક્ષા ઓડિટ (Night Patrol)',
      'hi': 'रात्रि सुरक्षा लेखापरीक्षा (रात्रि गश्ती)',
      'en': 'Night Security Audit (Night Patrol)',
    },
    'report': {
      'gu': 'રિપોર્ટ',
      'hi': 'रिपोर्ट करें',
      'en': 'Report',
    },
    'society_security_certificate': {
      'gu': 'સોસાયટી સુરક્ષા પ્રમાણપત્ર',
      'hi': 'सोसायटी सुरक्षा प्रमाणपत्र',
      'en': 'Society Security Certificate',
    },
    'watchman_24x7_night_patrol_audit_status': {
      'gu': 'વોચમેન ૨૪x૭ રાત્રિ પેટ્રોલિંગ ઓડિટ સ્ટેટસ',
      'hi': 'चौकीदार 24x7 रात्रि गश्त ऑडिट स्थिति',
      'en': 'Watchman 24x7 night patrol audit status',
    },
    'security_compliance': {
      'gu': 'સુરક્ષા કમ્પ્લાયન્સ:',
      'hi': 'सुरक्षा अनुपालन:',
      'en': 'Security Compliance:',
    },
    'night_patrol_round': {
      'gu': 'રાત્રિ પેટ્રોલિંગ રાઉન્ડ:',
      'hi': 'रात्रि गश्ती दौर:',
      'en': 'Night Patrol Round:',
    },
    'last_round': {
      'gu': 'છેલ્લો રાઉન્ડ:',
      'hi': 'अंतिम दौर:',
      'en': 'Last Round:',
    },
    'the_main_gate_terrace_basement_parking': {
      'gu': 'મુખ્ય ગેટ, ટેરેસ, બેઝમેન્ટ પાર્કિંગ & પંપ રૂમ સુરક્ષિત રીતે તપાસવામાં આવ્યા છે.',
      'hi': 'मुख्य द्वार, छत, बेसमेंट पार्किंग और पंप रूम की सुरक्षित रूप से जांच की गई है।',
      'en': 'The main gate, terrace, basement parking & pump room are securely checked.',
    },
    'all_the_time_2': {
      'gu': 'બધો સમય',
      'hi': 'हर समय',
      'en': 'all the time',
    },
    'status_filter': {
      'gu': 'સ્થિતિ ફિલ્ટર',
      'hi': 'स्थिति फ़िल्टर',
      'en': 'Status filter',
    },
    'all_visitors_today': {
      'gu': 'આજના તમામ મુલાકાતીઓ',
      'hi': 'आज सभी आगंतुक',
      'en': 'All visitors today',
    },
    'last_7_days': {
      'gu': 'છેલ્લા ૭ દિવસ',
      'hi': 'पिछले 7 दिन',
      'en': 'Last 7 days',
    },
    'detail_of_last_one_week': {
      'gu': 'છેલ્લા એક અઠવાડિયાની વિગત',
      'hi': 'पिछले एक सप्ताह का विवरण',
      'en': 'Detail of last one week',
    },
    'last_30_days': {
      'gu': 'છેલ્લા ૩૦ દિવસ',
      'hi': 'पिछले 30 दिन',
      'en': 'Last 30 days',
    },
    'visits_of_the_current_month': {
      'gu': 'ચાલુ માસની મુલાકાતો',
      'hi': 'चालू माह के दौरे',
      'en': 'Visits of the current month',
    },
    'all_historical_records': {
      'gu': 'તમામ ઐતિહાસિક રેકોર્ડ્સ',
      'hi': 'सभी ऐतिहासिक अभिलेख',
      'en': 'All historical records',
    },
    'select_time_range': {
      'gu': 'સમયગાળો પસંદ કરો (Time Range)',
      'hi': 'समय सीमा चुनें',
      'en': 'Select Time Range',
    },
    'no_visitors_left': {
      'gu': 'કોઈ મુલાકાતી બાકી નથી',
      'hi': 'कोई आगंतुक नहीं बचा',
      'en': 'No visitors left',
    },
    'there_is_no_entry_at_the': {
      'gu': 'સોસાયટી ગેટ પર કોઈ એન્ટ્રી નથી',
      'hi': 'सोसायटी के गेट पर नो एंट्री है',
      'en': 'There is no entry at the society gate',
    },
    'all_entries_for_your_flat_are': {
      'gu': 'તમારા ફ્લેટ માટે તમામ એન્ટ્રી સુરક્ષિત અને અપ-ટૂ-ડેટ છે.',
      'hi': 'आपके फ्लैट की सभी प्रविष्टियाँ सुरक्षित और अद्यतन हैं।',
      'en': 'All entries for your flat are secure and up-to-date.',
    },
    'society_gate_has_not_received_any': {
      'gu': 'પસંદ કરેલ સમયગાળામાં સોસાયટી ગેટ પર કોઈ મુલાકાતી મળ્યા નથી.',
      'hi': 'सोसायटी गेट पर चयनित अवधि में कोई भी आगंतुक नहीं आया है।',
      'en': 'Society Gate has not received any visitors in the selected period.',
    },
    'awaits_approval_at_gate_action_required': {
      'gu': 'ગેટ પર મંજૂરીની રાહ જુએ છે (Action Required)',
      'hi': 'गेट पर अनुमोदन की प्रतीक्षा है (कार्रवाई आवश्यक)',
      'en': 'Awaits approval at gate (Action Required)',
    },
    'anonymous_visitor': {
      'gu': 'અનામી મુલાકાતી',
      'hi': 'अनाम आगंतुक',
      'en': 'Anonymous visitor',
    },
    'access_granted': {
      'gu': 'પ્રવેશ મંજૂર',
      'hi': 'प्रवेश दिया गया',
      'en': 'Access granted',
    },
    'refuse': {
      'gu': 'નકારો',
      'hi': 'मना करो',
      'en': 'refuse',
    },
    'society_circular_notice': {
      'gu': 'સોસાયટી પરિપત્ર / નોટિસ',
      'hi': 'सोसायटी परिपत्र/सूचना',
      'en': 'Society Circular / Notice',
    },
    'society_important_notice': {
      'gu': 'સોસાયટી મહત્વની સૂચના',
      'hi': 'समाज महत्वपूर्ण सूचना',
      'en': 'Society Important Notice',
    },
    'fresh_update': {
      'gu': 'તાજી અપડેટ',
      'hi': 'ताज़ा अपडेट',
      'en': 'Fresh update',
    },
    'car_suv': {
      'gu': 'કાર / SUV',
      'hi': 'कार/एसयूवी',
      'en': 'Car / SUV',
    },
    'txt_2wheeler_bikescooter': {
      'gu': '૨-વ્હીલર (બાઇક/સ્કૂટર)',
      'hi': '2-पहिया (बाइक/स्कूटर)',
      'en': '2-Wheeler (Bike/Scooter)',
    },
    'bike_scooter': {
      'gu': 'બાઇક / સ્કૂટર',
      'hi': 'बाइक/स्कूटर',
      'en': 'Bike / Scooter',
    },
    'electric_vehicle_ev': {
      'gu': 'ઇલેક્ટ્રિક વાહન (EV)',
      'hi': 'इलेक्ट्रिक वाहन (ईवी)',
      'en': 'Electric Vehicle (EV)',
    },
    'electric_ev': {
      'gu': 'ઇલેક્ટ્રિક EV',
      'hi': 'इलेक्ट्रिक ईवी',
      'en': 'Electric EV',
    },
    'commercial_other': {
      'gu': 'કોમર્શિયલ / અન્ય',
      'hi': 'वाणिज्यिक/अन्य',
      'en': 'Commercial / Other',
    },
    'invalid_vehicle_number_plate': {
      'gu': 'અમાન્ય વાહન નંબર પ્લેટ!',
      'hi': 'अवैध वाहन नंबर प्लेट!',
      'en': 'Invalid vehicle number plate!',
    },
    'the_vehicle_is_already_registered': {
      'gu': 'વાહન પહેલેથી નોંધાયેલ છે',
      'hi': 'वाहन पहले से ही पंजीकृत है',
      'en': 'The vehicle is already registered',
    },
    'vehicle_registered_successfully': {
      'gu': 'વાહન સફળતાપૂર્વક નોંધાઈ ગયું.',
      'hi': 'वाहन सफलतापूर्वक पंजीकृत हो गया.',
      'en': 'Vehicle registered successfully.',
    },
    'the_slot_is_already_booked': {
      'gu': 'સ્લોટ પહેલેથી બુક છે!',
      'hi': 'स्लॉट पहले ही बुक हो चुका है!',
      'en': 'The slot is already booked!',
    },
    'please_select_another_empty_green_slot': {
      'gu': 'કૃપા કરીને અન્ય ખાલી (લીલો) સ્લોટ પસંદ કરો.',
      'hi': 'कृपया एक अन्य खाली (हरा) स्लॉट चुनें।',
      'en': 'Please select another empty (green) slot.',
    },
    'choose_another_slot': {
      'gu': 'અન્ય સ્લોટ પસંદ કરો',
      'hi': 'दूसरा स्लॉट चुनें',
      'en': 'Choose another slot',
    },
    'want_to_scrap_a_vehicle': {
      'gu': 'વાહન કાઢી નાખવું છે?',
      'hi': 'क्या आप किसी वाहन को स्क्रैप करना चाहते हैं?',
      'en': 'Want to scrap a vehicle?',
    },
    'will_be_emptied_and_available_to': {
      'gu': '} ખાલી થઈ જશે અને અન્ય સભ્યો માટે ઉપલબ્ધ બનશે.',
      'hi': '} खाली कर दिया जाएगा और अन्य सदस्यों के लिए उपलब्ध होगा।',
      'en': '} will be emptied and available to other members.',
    },
    'wadi_2': {
      'gu': 'વાડી-',
      'hi': 'वाडी-',
      'en': 'wadi-',
    },
    'street_society_automated_secure_parking_at': {
      'gu': 'શેરી સોસાયટી: ઘર આંગણે આપોઆપ સુરક્ષિત પાર્કિંગ',
      'hi': 'स्ट्रीट सोसाइटी: दरवाजे पर स्वचालित सुरक्षित पार्किंग',
      'en': 'Street Society: Automated secure parking at doorstep',
    },
    'vehicle_type': {
      'gu': 'વાહનનો પ્રકાર:',
      'hi': 'वाहन का प्रकार:',
      'en': 'Vehicle Type:',
    },
    'electric': {
      'gu': 'ઇલેક્ટ્રિક',
      'hi': 'बिजली',
      'en': 'Electric',
    },
    'vehicle_number_plate': {
      'gu': 'વાહન નંબર પ્લેટ *',
      'hi': 'वाहन नंबर प्लेट*',
      'en': 'Vehicle Number Plate *',
    },
    'eg_gj_01_ab_1234': {
      'gu': 'દા.ત. GJ 01 AB 1234',
      'hi': 'जैसे जीजे 01 एबी 1234',
      'en': 'E.g. GJ 01 AB 1234',
    },
    'format_gj_01_ab_1234_or': {
      'gu': 'ફોર્મેટ: GJ 01 AB 1234 અથવા 22 BH 1234 AA',
      'hi': 'प्रारूप: जीजे 01 एबी 1234 या 22 बीएच 1234 एए',
      'en': 'Format: GJ 01 AB 1234 or 22 BH 1234 AA',
    },
    'you_have_already_added_a_vehicle': {
      'gu': 'આ નંબર પ્લેટવાળું વાહન તમે પહેલેથી જ ઉમેરેલું છે!',
      'hi': 'आपने पहले ही इस नंबर प्लेट के साथ एक वाहन जोड़ लिया है!',
      'en': 'You have already added a vehicle with this number plate!',
    },
    'vehicle_model_company': {
      'gu': 'વાહન મોડેલ / કંપની',
      'hi': 'वाहन मॉडल/कंपनी',
      'en': 'Vehicle Model / Company',
    },
    'eg_swift_activa_nexon_ev': {
      'gu': 'દા.ત. Swift / Activa / Nexon EV',
      'hi': 'जैसे स्विफ्ट/एक्टिवा/नेक्सॉन ईवी',
      'en': 'E.g. Swift / Activa / Nexon EV',
    },
    'society_parking_arrangement': {
      'gu': 'સોસાયટી પાર્કિંગ વ્યવસ્થા:',
      'hi': 'सोसायटी पार्किंग व्यवस्था:',
      'en': 'Society Parking Arrangement:',
    },
    'home_front_parking': {
      'gu': 'ઘર આંગણે પાર્કિંગ (Home Front)',
      'hi': 'होम फ्रंट पार्किंग',
      'en': 'Home Front Parking',
    },
    'street_society_no_need_to_select': {
      'gu': '✓ શેરી સોસાયટી: કોઈ સ્લોટ નંબર પસંદ કરવાની જરૂર નથી.',
      'hi': '✓ स्ट्रीट सोसाइटी: किसी भी स्लॉट नंबर का चयन करने की आवश्यकता नहीं है।',
      'en': '✓ Street Society: No need to select any slot number.',
    },
    'society_common_plot_wadi_slot': {
      'gu': 'સોસાયટી કોમન પ્લોટ / વાડી સ્લોટ',
      'hi': 'सोसायटी कॉमन प्लॉट/वाडी स्लॉट',
      'en': 'Society Common Plot / Wadi Slot',
    },
    'a_slot_is_secured_in_the': {
      'gu': 'સોસાયટી કોમન પ્લોટમાં સ્લોટ સુરક્ષિત છે.',
      'hi': 'सोसायटी के कॉमन प्लॉट में एक स्लॉट सुरक्षित है।',
      'en': 'A slot is secured in the society common plot.',
    },
    'keep_at_home': {
      'gu': 'ઘર આંગણે રાખો',
      'hi': 'घर पर रखो',
      'en': 'Keep at home',
    },
    'select_a_slot': {
      'gu': 'સ્લોટ પસંદ કરો',
      'hi': 'एक स्लॉट चुनें',
      'en': 'Select a slot',
    },
    'choose_from_real_slots_created_by': {
      'gu': 'એડમિન દ્વારા બનાવેલા રીઅલ સ્લોટ્સમાંથી પસંદ કરો',
      'hi': 'व्यवस्थापक द्वारा बनाए गए वास्तविक स्लॉट में से चुनें',
      'en': 'Choose from real slots created by admin',
    },
    'registering': {
      'gu': 'નોંધાઈ રહ્યું છે...',
      'hi': 'पंजीकरण हो रहा है...',
      'en': 'Registering...',
    },
    'save_vehicle_slot': {
      'gu': 'વાહન & સ્લોટ સાચવો',
      'hi': 'वाहन और स्लॉट सहेजें',
      'en': 'Save vehicle & slot',
    },
    'get_security_active': {
      'gu': 'ગેટ સિક્યોરિટી એક્ટિવ',
      'hi': 'सुरक्षा सक्रिय करें',
      'en': 'Get Security Active',
    },
    'smart_society_parking_guard': {
      'gu': 'સ્માર્ટ સોસાયટી પાર્કિંગ ગાર્ડ',
      'hi': 'स्मार्ट सोसायटी पार्किंग गार्ड',
      'en': 'Smart Society Parking Guard',
    },
    'no_vehicle_registered_yet': {
      'gu': 'હજુ કોઈ વાહન નોંધાયેલ નથી',
      'hi': 'अभी तक कोई वाहन पंजीकृत नहीं है',
      'en': 'No vehicle registered yet',
    },
    'save_your_carbike_and_allocated_parking': {
      'gu': 'ઉપરના "+ નવું વાહન ઉમેરો" પર ક્લિક કરી તમારી કાર/બાઇક અને ફાળવેલ પાર્કિંગ સ્લોટ સાચવો.',
      'hi': 'ऊपर "+नया वाहन जोड़ें" पर क्लिक करके अपनी कार/बाइक और आवंटित पार्किंग स्लॉट को सहेजें।',
      'en': 'Save your car/bike and allocated parking slot by clicking on "+ Add New Vehicle" above.',
    },
    'txt_1_slot_1_vehicle': {
      'gu': '૧ સ્લોટ = ૧ વાહન',
      'hi': '1 स्लॉट = 1 वाहन',
      'en': '1 slot = 1 vehicle',
    },
    'car': {
      'gu': 'કાર',
      'hi': 'कार',
      'en': 'car',
    },
    'click_to_copy_the_number': {
      'gu': 'નંબર કોપી કરવા માટે ક્લિક કરો',
      'hi': 'नंबर कॉपी करने के लिए क्लिक करें',
      'en': 'Click to copy the number',
    },
    'remove_the_vehicle': {
      'gu': 'વાહન કાઢી નાખો',
      'hi': 'वाहन हटाओ',
      'en': 'Remove the vehicle',
    },
    'no_slots_allocated': {
      'gu': 'કોઈ સ્લોટ ફાળવેલ નથી',
      'hi': 'कोई स्लॉट आवंटित नहीं किया गया',
      'en': 'No slots allocated',
    },
    'secure_lock': {
      'gu': 'સુરક્ષિત લૉક',
      'hi': 'सुरक्षित ताला',
      'en': 'Secure lock',
    },
    'change_the_slot': {
      'gu': 'સ્લોટ બદલો',
      'hi': 'स्लॉट बदलें',
      'en': 'Change the slot',
    },
    'having_problems_with_slots_other_vehicle': {
      'gu': 'સ્લોટમાં સમસ્યા છે? (અન્ય વાહન / ફરિયાદ)',
      'hi': 'स्लॉट के साथ समस्या आ रही है? (अन्य वाहन/शिकायत)',
      'en': 'Having problems with slots? (Other Vehicle / Complaint)',
    },
    'please_write_the_vehicle_number_plate': {
      'gu': 'કૃપા કરીને વાહન નંબર પ્લેટ લખો!',
      'hi': 'कृपया वाहन का नंबर प्लेट अवश्य लिखें!',
      'en': 'Please write the vehicle number plate!',
    },
    'parking_slot_vacate_request': {
      'gu': '🚨 પાર્કિંગ સ્લોટ ખાલી કરવાની વિનંતી',
      'hi': '🚨पार्किंग स्लॉट खाली करने का अनुरोध',
      'en': '🚨 Parking slot vacate request',
    },
    'unauthorized_vehicle_parking_alert': {
      'gu': '🚨 અનધિકૃત વાહન પાર્કિંગ એલર્ટ',
      'hi': '🚨 अनधिकृत वाहन पार्किंग चेतावनी',
      'en': '🚨 Unauthorized vehicle parking alert',
    },
    'solving_the_parking_slot_problem': {
      'gu': 'પાર્કિંગ સ્લોટ સમસ્યા નિવારણ',
      'hi': 'पार्किंग स्लॉट की समस्या का समाधान',
      'en': 'Solving the parking slot problem',
    },
    'another_vehicle_is_parked_in_my': {
      'gu': 'મારા સ્લોટમાં અન્ય વાહન પાર્ક છે',
      'hi': 'मेरे स्लॉट में एक और गाड़ी खड़ी है',
      'en': 'Another vehicle is parked in my slot',
    },
    'check_by_entering_wrongly_parked_vehicle': {
      'gu': 'ખોટી જગ્યાએ પાર્ક થયેલ વાહન નંબર દાખલ કરી તપાસ કરો:',
      'hi': 'गलत पार्क किए गए वाहन नंबर दर्ज करके जांचें:',
      'en': 'Check by entering wrongly parked vehicle number:',
    },
    'check_out': {
      'gu': 'તપાસ કરો',
      'hi': 'जाँच करें',
      'en': 'check out',
    },
    'send_a_vehicle_removal_alert_to': {
      'gu': 'માલિકને ગાડી હટાવવાનું એલર્ટ મોકલો',
      'hi': 'मालिक को वाहन हटाने की चेतावनी भेजें',
      'en': 'Send a vehicle removal alert to the owner',
    },
    'this_notification_will_go_directly_to': {
      'gu': 'આ નોટિફિકેશન સીધું વાહન માલિકને જશે (એડમિનને નહીં, જેથી આપસી સમજણથી તાત્કાલિક ગાડી હટી શકે).',
      'hi': 'यह नोटिफिकेशन सीधे वाहन मालिक के पास जाएगा (एडमिन के पास नहीं, ताकि आपसी समझ से वाहन तुरंत हटाया जा सके)।',
      'en': 'This notification will go directly to the vehicle owner (not to the admin, so that the vehicle can be removed immediately by mutual understanding).',
    },
    'this_vehicle_does_not_belong_to': {
      'gu': 'આ વાહન સોસાયટીના કોઈ સભ્યનું નથી (વિઝિટર/મહેમાનનું હોઈ શકે છે).',
      'hi': 'यह वाहन सोसायटी के किसी भी सदस्य का नहीं है (आगंतुक/अतिथि का हो सकता है)।',
      'en': 'This vehicle does not belong to any member of the society (may belong to a visitor/guest).',
    },
    'inform_security_watchman_immediately': {
      'gu': 'સિક્યોરિટી / વૉચમેનને તાત્કાલિક જાણ કરો',
      'hi': 'तुरंत सुरक्षा/चौकीदार को सूचित करें',
      'en': 'Inform security / watchman immediately',
    },
    'parking_complaint': {
      'gu': 'પાર્કિંગ ફરિયાદ',
      'hi': 'पार्किंग की शिकायत',
      'en': 'Parking complaint',
    },
    'the_whole_society_gate': {
      'gu': 'આખી સોસાયટી ગેટ',
      'hi': 'पूरी सोसायटी का गेट',
      'en': 'The whole society gate',
    },
    'all_the_time_3': {
      'gu': 'બધા સમય',
      'hi': 'हर समय',
      'en': 'all the time',
    },
    'there_are_no_entries_in_the': {
      'gu': 'પસંદ કરેલ ફિલ્ટર અથવા સમયગાળામાં કોઈ એન્ટ્રી નથી.',
      'hi': 'चयनित फ़िल्टर या अवधि में कोई प्रविष्टियाँ नहीं हैं।',
      'en': 'There are no entries in the selected filter or period.',
    },
    'to_resume_services_or_for_more': {
      'gu': 'સેવાઓ ફરી શરૂ કરવા માટે અથવા વધુ વિગત માટે તમારી સોસાયટીના મુખ્ય એડમિન / પ્રમુખશ્રીનો સંપર્ક કરો.',
      'hi': 'सेवाओं को फिर से शुरू करने या अधिक जानकारी के लिए अपनी सोसायटी के मुख्य व्यवस्थापक/अध्यक्ष से संपर्क करें।',
      'en': 'To resume services or for more details contact your society\'s Chief Admin / President.',
    },
    'start_a_new_patrol_round': {
      'gu': 'નવો પેટ્રોલિંગ રાઉન્ડ શરૂ કરો',
      'hi': 'एक नया गश्ती दौर शुरू करें',
      'en': 'Start a new patrol round',
    },
    'checkpoints_havent_been_added_yet_by': {
      'gu': 'સોસાયટી એડમિન દ્વારા હજુ ચેકપોઇન્ટ્સ ઉમેરેલ નથી!',
      'hi': 'सोसाइटी एडमिन द्वारा अभी तक चेकप्वाइंट नहीं जोड़े गए हैं!',
      'en': 'Checkpoints haven\'t been added yet by society admin!',
    },
    'start_a_patrol_round': {
      'gu': 'પેટ્રોલિંગ રાઉન્ડ શરૂ કરો',
      'hi': 'गश्त का दौर शुरू करें',
      'en': 'Start a patrol round',
    },
    'round_1_1100_pm_1230_am': {
      'gu': 'રાઉન્ડ ૧ (૧૧:૦૦ PM - ૧૨:૩૦ AM)',
      'hi': 'राउंड 1 (11:00 अपराह्न - 12:30 पूर्वाह्न)',
      'en': 'Round 1 (11:00 PM - 12:30 AM)',
    },
    'round_2_0100_am_0230_am': {
      'gu': 'રાઉન્ડ ૨ (૦૧:૦૦ AM - ૦૨:૩૦ AM)',
      'hi': 'राउंड 2 (01:00 पूर्वाह्न - 02:30 पूर्वाह्न)',
      'en': 'Round 2 (01:00 AM - 02:30 AM)',
    },
    'round_3_0300_am_0430_am': {
      'gu': 'રાઉન્ડ ૩ (૦૩:૦૦ AM - ૦૪:૩૦ AM)',
      'hi': 'राउंड 3 (03:00 पूर्वाह्न - 04:30 पूर्वाह्न)',
      'en': 'Round 3 (03:00 AM - 04:30 AM)',
    },
    'round_4_0500_am_0630_am': {
      'gu': 'રાઉન્ડ ૪ (૦૫:૦૦ AM - ૦૬:૩૦ AM)',
      'hi': 'राउंड 4 (05:00 पूर्वाह्न - 06:30 पूर्वाह्न)',
      'en': 'Round 4 (05:00 AM - 06:30 AM)',
    },
    'select_a_round': {
      'gu': 'રાઉન્ડ પસંદ કરો:',
      'hi': 'एक राउंड चुनें:',
      'en': 'Select a round:',
    },
    'get_started': {
      'gu': 'શરૂ કરો',
      'hi': 'आरंभ करें',
      'en': 'get started',
    },
    'txt_100_complete': {
      'gu': '૧૦૦% પૂર્ણ',
      'hi': '100% पूर्ण',
      'en': '100% complete',
    },
    'in_progress': {
      'gu': 'પ્રગતિમાં',
      'hi': 'प्रगति पर है',
      'en': 'in progress',
    },
    'list_of_patrol_checkpoints': {
      'gu': 'પેટ્રોલિંગ ચેકપોઇન્ટ્સ યાદી:',
      'hi': 'गश्ती चौकियों की सूची:',
      'en': 'List of Patrol Checkpoints:',
    },
    'scan_the_qr': {
      'gu': 'QR સ્કેન કરો',
      'hi': 'क्यूआर स्कैन करें',
      'en': 'Scan the QR',
    },
    'complete': {
      'gu': 'પૂર્ણ કરો ✅',
      'hi': 'पूर्ण ✅',
      'en': 'Complete ✅',
    },
    'finish': {
      'gu': 'સમાપ્ત',
      'hi': 'ख़त्म करो',
      'en': 'finish',
    },
    'have_to_complete_a_patrol_round': {
      'gu': 'પેટ્રોલિંગ રાઉન્ડ પૂર્ણ કરવો છે?',
      'hi': 'एक गश्ती दौर पूरा करना है?',
      'en': 'Have to complete a patrol round?',
    },
    'all_checkpoints_have_been_scanned_successfully': {
      'gu': 'બધા ચેકપોઇન્ટ્સ સફળતાપૂર્વક સ્કેન થઈ ગયા છે. રાઉન્ડ પૂર્ણ કરવો છે?',
      'hi': 'सभी चौकियों को सफलतापूर्वक स्कैन कर लिया गया है। राउंड पूरा करें?',
      'en': 'All checkpoints have been scanned successfully. Complete the round?',
    },
    'no_carry_on': {
      'gu': 'ના, ચાલુ રાખો',
      'hi': 'नहीं, आगे बढ़ो',
      'en': 'No, carry on',
    },
    'patrol_round_successfully_completed': {
      'gu': 'પેટ્રોલિંગ રાઉન્ડ સફળતાપૂર્વક પૂર્ણ થયો! 🎉',
      'hi': 'गश्ती दौर सफलतापूर्वक पूरा हुआ! 🎉',
      'en': 'Patrol round successfully completed! 🎉',
    },
    'yes_complete': {
      'gu': 'હા, પૂર્ણ કરો',
      'hi': 'हाँ, पूर्ण',
      'en': 'Yes, complete',
    },
    'checkpoint_inspection': {
      'gu': 'ચેકપોઇન્ટ નિરીક્ષણ',
      'hi': 'चेकपॉइंट निरीक्षण',
      'en': 'Checkpoint inspection',
    },
    'is_everything_safe_and_normal_at': {
      'gu': 'શું આ ચેકપોઇન્ટ પર બધું સલામત અને સામાન્ય છે?',
      'hi': 'क्या इस चौकी पर सब कुछ सुरक्षित और सामान्य है?',
      'en': 'Is everything safe and normal at this checkpoint?',
    },
    'any_problems_notes_optional': {
      'gu': 'કોઈ સમસ્યા / નોંધ? (વૈકલ્પિક)',
      'hi': 'कोई समस्या/नोट? (वैकल्पिक)',
      'en': 'Any problems / notes? (optional)',
    },
    'eg_the_light_is_off_the': {
      'gu': 'દા.ત. લાઈટ બંધ છે, દરવાજો ખુલ્લો હતો...',
      'hi': 'जैसे लाइट बंद है, दरवाज़ा खुला था...',
      'en': 'E.g. The light is off, the door was open...',
    },
    'everything_is_fine': {
      'gu': 'બધું બરાબર છે ✅',
      'hi': 'सब कुछ ठीक है',
      'en': 'Everything is fine',
    },
    'save_with_a_note': {
      'gu': 'નોંધ સાથે સાચવો',
      'hi': 'एक नोट के साथ सहेजें',
      'en': 'Save with a note',
    },
    'checkpoint_qr_scanner': {
      'gu': 'ચેકપોઇન્ટ QR સ્કેનર',
      'hi': 'चेकप्वाइंट क्यूआर स्कैनर',
      'en': 'Checkpoint QR Scanner',
    },
    'hold_the_camera_in_front_of': {
      'gu': 'દિવાલ પર લગાવેલ QR કોડ સામે કેમેરા રાખો',
      'hi': 'कैमरे को दीवार पर लगे क्यूआर कोड के सामने रखें',
      'en': 'Hold the camera in front of the QR code on the wall',
    },
    'all_society_3': {
      'gu': 'આખી સોસાયટી (All Society)',
      'hi': 'सर्व समाज',
      'en': 'All Society',
    },
    'cab_taxi': {
      'gu': 'કેબ / ટેક્સી',
      'hi': 'कैब/टैक्सी',
      'en': 'Cab / Taxi',
    },
    'service_repair_2': {
      'gu': 'સર્વિસ / રિપેર',
      'hi': 'सेवा/मरम्मत',
      'en': 'Service / Repair',
    },
    'guest_2': {
      'gu': 'મહેમાન (Guest)',
      'hi': 'अतिथि',
      'en': 'Guest',
    },
    'goods_tempo': {
      'gu': 'માલ-સામાન / ટેમ્પો',
      'hi': 'माल/टेम्पो',
      'en': 'Goods / Tempo',
    },
    'traders_shop_staff': {
      'gu': 'વેપારી / શોપ સ્ટાફ',
      'hi': 'व्यापारी/दुकान कर्मचारी',
      'en': 'Traders / Shop Staff',
    },
    'new_visitor_type_partner': {
      'gu': 'નવો વિઝિટર પ્રકાર / પાર્ટનર',
      'hi': 'नये आगंतुक प्रकार/साझीदार',
      'en': 'New visitor type / partner',
    },
    'name_of_partner_or_visitor': {
      'gu': 'પાર્ટનર અથવા વિઝિટરનું નામ *',
      'hi': 'भागीदार या आगंतुक का नाम *',
      'en': 'Name of Partner or Visitor *',
    },
    'eg_jiomart_milkman_gas_service': {
      'gu': 'દા.ત. JioMart, દૂધવાળા, ગેસ સર્વિસ',
      'hi': 'जैसे JioMart, दूधवाला, गैस सेवा',
      'en': 'E.g. JioMart, milkman, gas service',
    },
    'label_purpose': {
      'gu': 'લેબલ / હેતુ (Purpose)',
      'hi': 'लेबल/उद्देश्य',
      'en': 'Label / Purpose',
    },
    'eg_jiomart_delivery': {
      'gu': 'દા.ત. JioMart Delivery',
      'hi': 'जैसे जिओ मार्ट डिलिवरी',
      'en': 'E.g. JioMart Delivery',
    },
    'select_a_category': {
      'gu': 'કેટેગરી પસંદ કરો:',
      'hi': 'एक श्रेणी चुनें:',
      'en': 'Select a category:',
    },
    'food_grocery_2': {
      'gu': 'ફૂડ / ગ્રોસરી',
      'hi': 'भोजन / किराना',
      'en': 'Food / Grocery',
    },
    'service_other': {
      'gu': 'સર્વિસ / અન્ય',
      'hi': 'सेवा/अन्य',
      'en': 'Service / Other',
    },
    'there_was_a_problem_starting_the': {
      'gu': 'કેમેરા શરૂ કરવામાં મુશ્કેલી આવી. કૃપા કરીને ફરી પ્રયાસ કરો.',
      'hi': 'कैमरा प्रारंभ करने में कोई समस्या थी. कृपया पुन: प्रयास करें।',
      'en': 'There was a problem starting the camera. Please try again.',
    },
    'please_enter_the_visitors_name': {
      'gu': 'કૃપા કરીને મુલાકાતીનું નામ દાખલ કરો.',
      'hi': 'कृपया आगंतुक का नाम दर्ज करें.',
      'en': 'Please enter the visitor\'s name.',
    },
    'please_take_a_photo_of_the': {
      'gu': 'કૃપા કરીને મુલાકાતીનો ફોટો લો.',
      'hi': 'कृपया आगंतुक की एक तस्वीर लें।',
      'en': 'Please take a photo of the visitor.',
    },
    'please_select_a_flat_for_visit': {
      'gu': 'કૃપા કરીને મુલાકાત માટે ફ્લેટ પસંદ કરો.',
      'hi': 'कृपया यात्रा के लिए एक फ्लैट का चयन करें।',
      'en': 'Please select a flat for visit.',
    },
    'entry_successful_visitor_entries_are_registered': {
      'gu': 'એન્ટ્રી સફળ. આખી સોસાયટી માટે વિઝિટર એન્ટ્રી નોંધાઈ ગઈ છે.',
      'hi': 'प्रवेश सफल. संपूर्ण सोसायटी के लिए आगंतुक प्रविष्टियाँ पंजीकृत की जाती हैं।',
      'en': 'Entry successful. Visitor entries are registered for the entire society.',
    },
    'new_visitor_gate_alert': {
      'gu': 'નવા મુલાકાતી (Gate Alert)',
      'hi': 'नये आगंतुक (गेट अलर्ट)',
      'en': 'New Visitor (Gate Alert)',
    },
    'sos_alert': {
      'gu': 'SOS એલર્ટ!',
      'hi': 'एसओएस चेतावनी!',
      'en': 'SOS Alert!',
    },
    'do_you_want_to_report_to': {
      'gu': 'શું તમે એડમિનને મદદ માટે જાણ કરવા માંગો છો?',
      'hi': 'क्या आप सहायता के लिए किसी व्यवस्थापक को रिपोर्ट करना चाहते हैं?',
      'en': 'Do you want to report to an admin for help?',
    },
    'emergency_alert_gate': {
      'gu': '🚨 ઇમરજન્સી એલર્ટ (GATE)',
      'hi': '🚨 आपातकालीन चेतावनी (गेट)',
      'en': '🚨 Emergency Alert (GATE)',
    },
    'the_watchman_at_the_gate_needs': {
      'gu': 'ગેટ પર વોચમેનને મદદની જરૂર છે!',
      'hi': 'गेट पर चौकीदार को मदद की ज़रूरत है!',
      'en': 'The watchman at the gate needs help!',
    },
    'sos_push_sent_to_admin': {
      'gu': 'એડમિનને SOS પુશ મોકલાયો.',
      'hi': 'एसओएस पुश व्यवस्थापक को भेजा गया।',
      'en': 'SOS push sent to admin.',
    },
    'a_push_was_sent_to_the': {
      'gu': 'મેમ્બરને પુશ મોકલાયો.',
      'hi': 'सदस्य को एक धक्का भेजा गया.',
      'en': 'A push was sent to the member.',
    },
    'member_doesnt_have_a_phone_token': {
      'gu': 'મેમ્બર પાસે ફોન ટોકન નથી — એક વાર એપ ખોલવા કહો.',
      'hi': 'सदस्य के पास फ़ोन टोकन नहीं है - एक बार ऐप खोलने के लिए कहें।',
      'en': 'Member doesn\'t have a phone token — ask to open the app once.',
    },
    'push_could_not_be_sent': {
      'gu': 'પુશ મોકલાઈ શક્યો નહીં.',
      'hi': 'पुश नहीं भेजा जा सका.',
      'en': 'Push could not be sent.',
    },
    'directory_society_staff': {
      'gu': 'ડિરેક્ટરી & સોસાયટી સ્ટાફ',
      'hi': 'निर्देशिका एवं सोसायटी कर्मचारी',
      'en': 'Directory & Society Staff',
    },
    'emergency_helpline_and_daily_staff_contact': {
      'gu': 'ઇમરજન્સી હેલ્પલાઇન અને દૈનિક સ્ટાફ સંપર્ક',
      'hi': 'आपातकालीन हेल्पलाइन और दैनिक कर्मचारी संपर्क',
      'en': 'Emergency helpline and daily staff contact',
    },
    'emergency_contacts': {
      'gu': 'ઈમરજન્સી કોન્ટેક્ટ્સ',
      'hi': 'आपातकालीन संपर्क',
      'en': 'Emergency contacts',
    },
    'immediate_help': {
      'gu': 'તાત્કાલિક મદદ',
      'hi': 'तत्काल सहायता',
      'en': 'Immediate help',
    },
    'no_emergency_numbers_have_been_added_2': {
      'gu': 'હજુ સુધી કોઈ ઈમરજન્સી નંબર ઉમેરાયા નથી',
      'hi': 'अभी तक कोई आपातकालीन नंबर नहीं जोड़ा गया है',
      'en': 'No emergency numbers have been added yet',
    },
    'police_fire_ambulance_or_security_helpline': {
      'gu': 'એડમિન દ્વારા પોલીસ, ફાયર, એમ્બ્યુલન્સ અથવા સિક્યુરિટી હેલ્પલાઇન નંબર ઉમેરવામાં આવશે.',
      'hi': 'पुलिस, अग्निशमन, एम्बुलेंस या सुरक्षा हेल्पलाइन नंबर व्यवस्थापक द्वारा जोड़े जाएंगे।',
      'en': 'Police, Fire, Ambulance or Security helpline numbers will be added by admin.',
    },
    'a_permanent_staff_of_members': {
      'gu': 'મેમ્બર્સનો કાયમી સ્ટાફ',
      'hi': 'सदस्यों का एक स्थायी स्टाफ',
      'en': 'A permanent staff of members',
    },
    'no_permanent_staff_is_registered': {
      'gu': 'કોઈ કાયમી સ્ટાફ નોંધાયો નથી',
      'hi': 'कोई स्थाई कर्मचारी पंजीकृत नहीं है',
      'en': 'No permanent staff is registered',
    },
    'registration_of_society_maid_driver_security': {
      'gu': 'સોસાયટી મેઇડ, ડ્રાઇવર, સિક્યુરિટી કે માળીની નોંધણી સભ્યો દ્વારા ઉમેર્યા પછી અહીં જોવા મળશે.',
      'hi': 'सोसाइटी की नौकरानी, ड्राइवर, सुरक्षा या माली का पंजीकरण सदस्यों द्वारा जोड़ने के बाद यहां देखा जाएगा।',
      'en': 'Registration of society maid, driver, security or gardener will be seen here after adding by members.',
    },
    'siren_alert_will_sound_immediately_on': {
      'gu': '⚠️ તમામ સોસાયટી એડમિનના ફોનમાં તાત્કાલિક સાયરન એલર્ટ વાગશે.',
      'hi': '⚠️ सभी सोसायटी एडमिन के फोन पर तुरंत सायरन अलर्ट बजेगा।',
      'en': '⚠️ Siren alert will sound immediately on the phones of all society admins.',
    },
    'watchman_gate_system': {
      'gu': 'વોચમેન ગેટ સિસ્ટમ',
      'hi': 'चौकीदार गेट प्रणाली',
      'en': 'Watchman Gate System',
    },
    'today_event': {
      'gu': 'આજનો પ્રસંગ (Today Event)',
      'hi': 'आज की घटना',
      'en': 'Today Event',
    },
    'event_guest': {
      'gu': 'ઇવેન્ટ મહેમાન (Guest)',
      'hi': 'कार्यक्रम अतिथि',
      'en': 'Event Guest',
    },
    'event_guest_quick_entry': {
      'gu': 'ઇવેન્ટ મહેમાન ત્વરિત એન્ટ્રી (Quick Entry)',
      'hi': 'इवेंट अतिथि त्वरित प्रवेश',
      'en': 'Event Guest Quick Entry',
    },
    'security_guard': {
      'gu': 'સુરક્ષા ગાર્ડ',
      'hi': 'सुरक्षा गार्ड',
      'en': 'Security guard',
    },
    'patrol_round_is_in_progress': {
      'gu': '🚨 પેટ્રોલિંગ રાઉન્ડ ચાલુ છે',
      'hi': '🚨गश्ती दौर जारी है',
      'en': '🚨 Patrol round is in progress',
    },
    'night_patrol': {
      'gu': 'રાત્રિ સુરક્ષા પેટ્રોલિંગ (Night Patrol)',
      'hi': 'रात्रि गश्त',
      'en': 'Night Patrol',
    },
    'start_the_qr_scan_round_and': {
      'gu': 'QR સ્કેન રાઉન્ડ શરૂ કરો અને ચેકપોઇન્ટ્સ ઓડિટ કરો',
      'hi': 'क्यूआर स्कैन राउंड शुरू करें और चौकियों का ऑडिट करें',
      'en': 'Start the QR scan round and audit the checkpoints',
    },
    'photo': {
      'gu': 'ફોટો',
      'hi': 'फ़ोटो',
      'en': 'Photo',
    },
    'visitor_name_2': {
      'gu': 'મુલાકાતીનું નામ *',
      'hi': 'आगंतुक का नाम*',
      'en': 'Visitor Name *',
    },
    'write_name': {
      'gu': 'નામ લખો...',
      'hi': 'नाम लिखो...',
      'en': 'write name...',
    },
    'mobile_number_4': {
      'gu': 'મોબાઇલ નંબર (Mobile No)',
      'hi': 'मोबाइल नंबर',
      'en': 'Mobile Number',
    },
    'enter_10_digit_mobile_number': {
      'gu': '10 અંકનો મોબાઈલ નંબર દાખલ કરો...',
      'hi': '10 अंकों का मोबाइल नंबर दर्ज करें...',
      'en': 'Enter 10 digit mobile number...',
    },
    'purpose_of_visit_2': {
      'gu': 'મુલાકાતનું કારણ (Purpose)',
      'hi': 'यात्रा का उद्देश्य',
      'en': 'Purpose of visit',
    },
    'eg_delivery_guest_service_courier': {
      'gu': 'દા.ત. ડિલિવરી, મહેમાન, સર્વિસ, કુરિયર...',
      'hi': 'जैसे डिलीवरी, अतिथि, सेवा, कूरियर...',
      'en': 'E.g. Delivery, Guest, Service, Courier...',
    },
    'whose_home_is_there_a_visit': {
      'gu': 'કોના ઘરે મુલાકાત છે? (Destination)',
      'hi': 'किसके घर का दौरा है? (गंतव्य)',
      'en': 'Whose home is there a visit? (Destination)',
    },
    'choose_flat_or_whole_society': {
      'gu': 'ફ્લેટ અથવા આખી સોસાયટી પસંદ કરો',
      'hi': 'फ्लैट या पूरी सोसायटी चुनें',
      'en': 'Choose flat or whole society',
    },
    'reload_members': {
      'gu': 'સભ્યો ફરી લોડ કરો',
      'hi': 'सदस्यों को पुनः लोड करें',
      'en': 'Reload members',
    },
    'choose_flat': {
      'gu': 'ફ્લેટ પસંદ કરો',
      'hi': 'फ़्लैट चुनें',
      'en': 'Choose Flat',
    },
    'the_whole_society': {
      'gu': 'આખી સોસાયટી',
      'hi': 'पूरा समाज',
      'en': 'The whole society',
    },
    'entire_society_all_blocks_flats': {
      'gu': 'આખી સોસાયટી (બધા બ્લોક & ફ્લેટ)',
      'hi': 'संपूर्ण सोसायटी (सभी ब्लॉक एवं फ्लैट)',
      'en': 'Entire Society (All Blocks & Flats)',
    },
    'for_government_survey_society_general_visitor': {
      'gu': 'સરકારી, સર્વે, સોસાયટી જનરલ મુલાકાતી માટે',
      'hi': 'सरकार, सर्वेक्षण, सोसायटी सामान्य आगंतुक के लिए',
      'en': 'For Government, Survey, Society General Visitor',
    },
    'block_selection': {
      'gu': 'બ્લોક પસંદગી:',
      'hi': 'ब्लॉक चयन:',
      'en': 'Block Selection:',
    },
    'view_all_blocks': {
      'gu': 'બધા બ્લોક જુઓ',
      'hi': 'सभी ब्लॉक देखें',
      'en': 'View all blocks',
    },
    'all_blocks_2': {
      'gu': '🏢 બધા બ્લોક',
      'hi': '🏢 सभी ब्लॉक',
      'en': '🏢 All blocks',
    },
    'select_flat_search_flat': {
      'gu': 'ફ્લેટ પસંદ કરો (Search Flat) *',
      'hi': 'फ़्लैट चुनें (फ़्लैट खोजें) *',
      'en': 'Select Flat (Search Flat) *',
    },
    'loading_members': {
      'gu': 'સભ્યો લોડ થઈ રહ્યા છે...',
      'hi': 'सदस्य लोड हो रहे हैं...',
      'en': 'Loading members...',
    },
    'there_are_no_flats_in_this': {
      'gu': 'આ બ્લોકમાં કોઈ ફ્લેટ નથી',
      'hi': 'इस ब्लॉक में कोई फ्लैट नहीं है',
      'en': 'There are no flats in this block',
    },
    'search_for_a_flat_number_or': {
      'gu': 'ટૅપ કરીને ફ્લેટ નંબર અથવા નામ શોધો...',
      'hi': 'टैप करके फ़्लैट नंबर या नाम खोजें...',
      'en': 'Search for a flat number or name by tapping...',
    },
    'see_all': {
      'gu': 'બધા જુઓ >',
      'hi': 'सभी देखें >',
      'en': 'See all >',
    },
    'selected_flats': {
      'gu': 'પસંદ કરેલ ફ્લેટ:',
      'hi': 'चयनित फ्लैट:',
      'en': 'Selected Flats:',
    },
    'another_flat': {
      'gu': '+ બીજો ફ્લેટ',
      'hi': '+ एक और फ्लैट',
      'en': '+ Another flat',
    },
    'remove_all': {
      'gu': 'બધા હટાવો',
      'hi': 'सब हटाओ',
      'en': 'Remove all',
    },
    'house': {
      'gu': 'ઘર',
      'hi': 'घर',
      'en': 'house',
    },
    'society_resident': {
      'gu': '🏡 સોસાયટી રહેવાસી',
      'hi': '🏡 सोसायटी निवासी',
      'en': '🏡 Society resident',
    },
    'saving_entry_and_sending_notification': {
      'gu': 'એન્ટ્રી સેવ અને નોટિફિકેશન મોકલાઈ રહ્યું છે...',
      'hi': 'प्रविष्टि सहेजी जा रही है और अधिसूचना भेजी जा रही है...',
      'en': 'Saving entry and sending notification...',
    },
    'make_an_entry_and_notify_the': {
      'gu': 'એન્ટ્રી કરો અને મેમ્બરને જાણ કરો',
      'hi': 'एक प्रविष्टि करें और सदस्य को सूचित करें',
      'en': 'Make an entry and notify the member',
    },
    'quick_selection_1tap_quick_fill': {
      'gu': 'ઝડપી સિલેક્શન (1-Tap Quick Fill)',
      'hi': 'त्वरित चयन (1-टैप त्वरित भरण)',
      'en': 'Quick Selection (1-Tap Quick Fill)',
    },
    'set_delivery_or_appointment_type_in': {
      'gu': 'એક જ ટૅપમાં ડિલિવરી કે મુલાકાત પ્રકાર સેટ કરો',
      'hi': 'एक टैप में डिलीवरी या अपॉइंटमेंट प्रकार सेट करें',
      'en': 'Set delivery or appointment type in a single tap',
    },
    'food_grocery_3': {
      'gu': 'ફૂડ & ગ્રોસરી',
      'hi': 'भोजन एवं किराना',
      'en': 'Food & Grocery',
    },
    'parcel_courier_2': {
      'gu': 'પાર્સલ & કુરિયર',
      'hi': 'पार्सल एवं कूरियर',
      'en': 'Parcel & Courier',
    },
    'service_visit': {
      'gu': 'સર્વિસ & મુલાકાત',
      'hi': 'सेवा एवं यात्रा',
      'en': 'Service & Visit',
    },
    'new_type': {
      'gu': '+ નવો પ્રકાર',
      'hi': '+ नया प्रकार',
      'en': '+ New type',
    },
    'cab_driver': {
      'gu': 'કેબ ડ્રાઇવર (Cab)',
      'hi': 'कैब ड्राइवर',
      'en': 'Cab Driver',
    },
    'service_person': {
      'gu': 'સર્વિસ પર્સન (Service)',
      'hi': 'सेवा व्यक्ति',
      'en': 'Service Person',
    },
    'inside': {
      'gu': 'અંદર',
      'hi': 'अंदर',
      'en': 'inside',
    },
    'out': {
      'gu': 'બહાર',
      'hi': 'बाहर',
      'en': 'out',
    },
    'phone_number_not_available': {
      'gu': 'ફોન નંબર ઉપલબ્ધ નથી',
      'hi': 'फ़ोन नंबर उपलब्ध नहीं है',
      'en': 'Phone number not available',
    },
    'the_call_could_not_be_initiated': {
      'gu': 'કૉલ શરૂ કરી શકાયો નહીં',
      'hi': 'कॉल प्रारंभ नहीं की जा सकी',
      'en': 'The call could not be initiated',
    },
    'select_a_time_period': {
      'gu': 'સમયગાળો પસંદ કરો',
      'hi': 'एक समयावधि चुनें',
      'en': 'Select a time period',
    },
    'todays_entry': {
      'gu': 'આજની એન્ટ્રી (Today)',
      'hi': 'आज का प्रवेश',
      'en': 'Today\'s Entry',
    },
    'last_7_days_2': {
      'gu': 'છેલ્લા ૭ દિવસ (7 Days)',
      'hi': 'पिछले 7 दिन',
      'en': 'Last 7 Days',
    },
    'last_30_days_2': {
      'gu': 'છેલ્લા ૩૦ દિવસ (30 Days)',
      'hi': 'पिछले 30 दिन',
      'en': 'Last 30 Days',
    },
    'checkout_confirmation': {
      'gu': 'ચેક-આઉટ કન્ફર્મેશન',
      'hi': 'चेक-आउट की पुष्टि',
      'en': 'Check-out confirmation',
    },
    'yes_went_out_out': {
      'gu': 'હા, બહાર ગયા (OUT)',
      'hi': 'हाँ, बाहर चला गया (बाहर)',
      'en': 'yes, went out (OUT)',
    },
    'flat_unit': {
      'gu': 'ફ્લેટ / યુનિટ',
      'hi': 'फ़्लैट/यूनिट',
      'en': 'Flat / Unit',
    },
    'mobile_number_5': {
      'gu': 'મોબાઈલ નંબર',
      'hi': 'मोबाइल नंबर',
      'en': 'Mobile number',
    },
    'entry_time_3': {
      'gu': 'એન્ટ્રી સમય',
      'hi': 'प्रवेश का समय',
      'en': 'Entry time',
    },
    'exit_time_2': {
      'gu': 'એક્ઝિટ સમય',
      'hi': 'बाहर निकलने का समय',
      'en': 'Exit time',
    },
    'guest_mark_out': {
      'gu': 'મહેમાન બહાર ગયા (Mark Out)',
      'hi': 'अतिथि मार्क आउट',
      'en': 'Guest Mark Out',
    },
    'refused': {
      'gu': 'ના પાડી',
      'hi': 'मना कर दिया',
      'en': 'Refused',
    },
    'wait': {
      'gu': 'રાહ જુઓ',
      'hi': 'रुको',
      'en': 'wait',
    },
    'search_name_flat_or_vehicle_number': {
      'gu': 'નામ, ફ્લેટ કે વાહન નંબર શોધો...',
      'hi': 'नाम, फ़्लैट या वाहन नंबर खोजें...',
      'en': 'Search name, flat or vehicle number...',
    },
    'no_guest_found_according_to_search': {
      'gu': 'સર્ચ મુજબ કોઈ મહેમાન મળ્યા નથી.',
      'hi': 'खोज के अनुसार कोई अतिथि नहीं मिला.',
      'en': 'No guest found according to search.',
    },
    'there_are_no_guests_in_the': {
      'gu': 'પસંદ કરેલ ફિલ્ટરમાં કોઈ મહેમાન નથી.',
      'hi': 'चयनित फ़िल्टर में कोई अतिथि नहीं हैं.',
      'en': 'There are no guests in the selected filter.',
    },
    'there_are_currently_no_visitors_recorded': {
      'gu': 'હાલ કોઈ મુલાકાતીની નોંધ નથી.',
      'hi': 'वर्तमान में कोई भी आगंतुक दर्ज नहीं किया गया है।',
      'en': 'There are currently no visitors recorded.',
    },
    'check_again_by_changing_the_search': {
      'gu': 'સર્ચ અથવા સ્ટેટસ ફિલ્ટર બદલીને ફરી તપાસો.',
      'hi': 'खोज या स्थिति फ़िल्टर बदलकर दोबारा जाँचें।',
      'en': 'Check again by changing the search or status filter.',
    },
    'visitors_can_be_registered_from_the': {
      'gu': 'નવી એન્ટ્રી ટેબમાંથી મુલાકાતી નોંધી શકાય છે.',
      'hi': 'आगंतुकों को न्यू एंट्री टैब से पंजीकृत किया जा सकता है।',
      'en': 'Visitors can be registered from the New Entry tab.',
    },
    'note_the_new_entry': {
      'gu': 'નવી એન્ટ્રી નોંધો',
      'hi': 'नई प्रविष्टि पर ध्यान दें',
      'en': 'Note the new entry',
    },
    'the_guest_went_out': {
      'gu': 'મહેમાન બહાર ગયા 🚪',
      'hi': 'मेहमान बाहर चला गया 🚪',
      'en': 'The guest went out 🚪',
    },
    'guest_has_checkedout': {
      'gu': 'મહેમાન ચેક-આઉટ થઈ ગયા છે',
      'hi': 'अतिथि ने चेक-आउट कर लिया है',
      'en': 'Guest has checked-out',
    },
    'enter_the_pass_code': {
      'gu': 'પાસ કોડ દાખલ કરો',
      'hi': 'पास कोड दर्ज करें',
      'en': 'Enter the pass code',
    },
    'enter_the_preapproval_id_received_in': {
      'gu': 'મહેમાનના WhatsApp અથવા SMS માં આવેલો પ્રી-અપ્રૂવલ ID લખો',
      'hi': 'अतिथि के व्हाट्सएप या एसएमएस में प्राप्त पूर्व-अनुमोदन आईडी दर्ज करें',
      'en': 'Enter the pre-approval ID received in the guest\'s WhatsApp or SMS',
    },
    'eg_pass1234_or_id': {
      'gu': 'દા.ત. PASS-1234 અથવા ID',
      'hi': 'जैसे पास-1234 या आईडी',
      'en': 'E.g. PASS-1234 or ID',
    },
    'verify_3': {
      'gu': 'ચકાસો',
      'hi': 'सत्यापित करें',
      'en': 'verify',
    },
    'this_qr_is_not_valid_for': {
      'gu': 'આ QR આ સોસાયટી માટે માન્ય નથી.',
      'hi': 'यह QR इस समाज के लिए मान्य नहीं है.',
      'en': 'This QR is not valid for this society.',
    },
    'qr_scan_successful': {
      'gu': 'QR સ્કેન સફળ!',
      'hi': 'क्यूआर स्कैन सफल!',
      'en': 'QR scan successful!',
    },
    'qr_code_scanner': {
      'gu': 'QR કોડ સ્કેનર',
      'hi': 'QR कोड स्कैनर',
      'en': 'QR code scanner',
    },
    'scan_the_guest_pass_or_preapproved': {
      'gu': 'મહેમાન પાસ અથવા પ્રી-અપ્રૂવ્ડ QR સ્કેન કરો',
      'hi': 'अतिथि पास या पूर्व-अनुमोदित क्यूआर को स्कैन करें',
      'en': 'Scan the guest pass or pre-approved QR',
    },
    'torch_flash': {
      'gu': 'ટોર્ચ (Flash)',
      'hi': 'मशाल (फ्लैश)',
      'en': 'Torch (Flash)',
    },
    'change_the_camera': {
      'gu': 'કેમેરા બદલો',
      'hi': 'कैमरा बदलें',
      'en': 'Change the camera',
    },
    'camera_or_qr_scanner_could_not': {
      'gu': 'કેમેરા અથવા QR સ્કેનર શરૂ થઈ શક્યું નથી.',
      'hi': 'कैमरा या QR स्कैनर प्रारंभ नहीं किया जा सका.',
      'en': 'Camera or QR scanner could not be started.',
    },
    'please_grant_camera_permission_or_enter': {
      'gu': 'કૃપા કરીને કેમેરા પરમિશન આપો અથવા નીચેથી કોડ મેન્યુઅલી દાખલ કરો.',
      'hi': 'कृपया कैमरे की अनुमति दें या नीचे से मैन्युअल रूप से कोड दर्ज करें।',
      'en': 'Please grant camera permission or enter the code manually from below.',
    },
    'place_the_qr_code_in_the': {
      'gu': 'કેમેરા સામે ચોરસમાં QR કોડ રાખો',
      'hi': 'क्यूआर कोड को कैमरे के सामने वर्ग में रखें',
      'en': 'Place the QR code in the square in front of the camera',
    },
    'not_scanning_write_the_code_manually': {
      'gu': 'સ્કેન નથી થતું? મેન્યુઅલી કોડ લખો',
      'hi': 'स्कैन नहीं हो रहा? कोड को मैन्युअल रूप से लिखें',
      'en': 'Not scanning? Write the code manually',
    },
    'scan_digital_guest_pass_qr_generated': {
      'gu': '🔒 સભ્યો દ્વારા બનાવેલ ડિજિટલ ગેસ્ટ પાસ QR સ્કેન કરો',
      'hi': '🔒 सदस्यों द्वारा उत्पन्न डिजिटल अतिथि पास क्यूआर को स्कैन करें',
      'en': '🔒 Scan digital guest pass QR generated by members',
    },
    'search_by_name_or_flat_number': {
      'gu': 'નામ અથવા ફ્લેટ નંબરથી શોધો',
      'hi': 'नाम या फ़्लैट नंबर से खोजें',
      'en': 'Search by name or flat number',
    },
    'multiflat': {
      'gu': 'મલ્ટિ-ફ્લેટ',
      'hi': 'बहु-सपाट',
      'en': 'Multi-flat',
    },
    'flat_no_eg_101_or_member': {
      'gu': 'ફ્લેટ નં. (દા.ત. 101) અથવા સભ્યનું નામ...',
      'hi': 'फ़्लैट नं. (उदाहरण 101) या सदस्य का नाम...',
      'en': 'Flat no. (eg 101) or member name...',
    },
    'no_flat_found': {
      'gu': 'કોઈ ફ્લેટ મળ્યો નથી',
      'hi': 'कोई फ्लैट नहीं मिला',
      'en': 'No flat found',
    },
    'there_are_no_flats_available_in': {
      'gu': 'આ બ્લોકમાં કોઈ ફ્લેટ ઉપલબ્ધ નથી.',
      'hi': 'इस ब्लॉक में कोई फ्लैट उपलब्ध नहीं है.',
      'en': 'There are no flats available in this block.',
    },
    'the_resident': {
      'gu': 'રહેવાસી',
      'hi': 'निवासी',
      'en': 'the resident',
    },
    'email_address_not_available': {
      'gu': 'ઈમેલ સરનામું ઉપલબ્ધ નથી.',
      'hi': 'ईमेल पता उपलब्ध नहीं है.',
      'en': 'Email address not available.',
    },
    'type_your_message_herenn': {
      'gu': '[અહીં તમારો સંદેશો લખો]\\n\\n',
      'hi': '[अपना संदेश यहां टाइप करें]\\n\\n',
      'en': '[Type your message here]\\n\\n',
    },
    'thank_youn': {
      'gu': 'આભાર,\\n',
      'hi': 'धन्यवाद,\\n',
      'en': 'Thank you,\\n',
    },
    'super_admin_head_office_buildingguard': {
      'gu': 'સુપર એડમિન હેડ ઓફિસ - BuildingGuard',
      'hi': 'सुपर एडमिन हेड ऑफिस - बिल्डिंगगार्ड',
      'en': 'Super Admin Head Office - BuildingGuard',
    },
    'could_not_open_email_app': {
      'gu': 'ઈમેલ એપ ખોલી શકાઈ નથી.',
      'hi': 'ईमेल ऐप नहीं खुल सका.',
      'en': 'Could not open email app.',
    },
    'phone_number_not_available_2': {
      'gu': 'ફોન નંબર ઉપલબ્ધ નથી.',
      'hi': 'फ़ोन नंबर उपलब्ध नहीं है.',
      'en': 'Phone number not available.',
    },
    'type_details_here': {
      'gu': '[અહીં વિગત લખો]',
      'hi': '[विवरण यहां टाइप करें]',
      'en': '[Type details here]',
    },
    'whatsapp_could_not_be_opened': {
      'gu': 'WhatsApp ખોલી શકાયું નથી.',
      'hi': 'व्हाट्सएप नहीं खुल सका.',
      'en': 'WhatsApp could not be opened.',
    },
    'want_to_activate_the_society': {
      'gu': 'સોસાયટી સક્રિય કરવી છે?',
      'hi': 'समाज को सक्रिय करना चाहते हैं?',
      'en': 'Want to activate the society?',
    },
    'yes_activate': {
      'gu': 'હા, સક્રિય કરો',
      'hi': 'हाँ, सक्रिय करें',
      'en': 'Yes, activate',
    },
    'your_appeal_has_been_accepted_and': {
      'gu': 'તમારી અપીલ સ્વીકારી લેવામાં આવી છે અને સોસાયટી પુનઃસક્રિય કરી દેવામાં આવી છે.',
      'hi': 'आपकी अपील स्वीकार कर ली गई है और सोसायटी पुनः सक्रिय हो गई है।',
      'en': 'Your appeal has been accepted and the society has been reactivated.',
    },
    'society_and_admin_have_been_activated': {
      'gu': 'સોસાયટી અને એડમિન સફળતાપૂર્વક સક્રિય થઈ ગયા છે.',
      'hi': 'सोसाइटी और एडमिन को सफलतापूर्वक सक्रिय कर दिया गया है.',
      'en': 'Society and admin have been activated successfully.',
    },
    'app_push_notification_reply': {
      'gu': 'એપ પુશ નોટિફિકેશન રિપ્લાય',
      'hi': 'ऐप पुश अधिसूचना उत्तर',
      'en': 'App push notification reply',
    },
    'this_message_will_go_directly_to': {
      'gu': 'આ સંદેશો સીધો એડમિનના ફોનમાં નોટિફિકેશન તરીકે જશે.',
      'hi': 'यह मैसेज नोटिफिकेशन के तौर पर सीधे एडमिन के फोन पर जाएगा.',
      'en': 'This message will go directly to the admin\'s phone as a notification.',
    },
    'resolved_3': {
      'gu': 'મંજૂર (Resolved)',
      'hi': 'सुलझ गया',
      'en': 'Resolved',
    },
    'more_details_needs_info': {
      'gu': 'વધુ વિગત (Needs Info)',
      'hi': 'अधिक विवरण (जानकारी चाहिए)',
      'en': 'More details (Needs Info)',
    },
    'write_your_official_message_as_super': {
      'gu': 'સુપર એડમિન તરીકે તમારો સત્તાવાર સંદેશો લખો...',
      'hi': 'अपना आधिकारिक संदेश सुपर एडमिन के रूप में लिखें...',
      'en': 'Write your official message as super admin...',
    },
    'also_unblock_activate_society_and_admin': {
      'gu': 'સાથે સાથે સોસાયટી અને એડમિનને અનબ્લોક (સક્રિય) કરો',
      'hi': 'साथ ही सोसायटी और एडमिन को अनब्लॉक (सक्रिय) करें',
      'en': 'Also unblock (activate) society and admin',
    },
    'please_write_a_message': {
      'gu': 'કૃપા કરીને સંદેશો લખો.',
      'hi': 'कृपया एक संदेश लिखें.',
      'en': 'Please write a message.',
    },
    'notification_reply_has_been_sent_successfully': {
      'gu': 'નોટિફિકેશન રિપ્લાય સફળતાપૂર્વક મોકલાઈ ગયો છે.',
      'hi': 'अधिसूचना उत्तर सफलतापूर्वक भेज दिया गया है.',
      'en': 'Notification reply has been sent successfully.',
    },
    'send_a_reply': {
      'gu': 'જવાબ મોકલો',
      'hi': 'उत्तर भेजें',
      'en': 'Send a reply',
    },
    'active_resolved': {
      'gu': '✅ સક્રિય / ઉકેલાયેલ',
      'hi': '✅ सक्रिय/समाधान',
      'en': '✅ Active / Resolved',
    },
    'appeal_pending': {
      'gu': '⏳ અપીલ પેન્ડિંગ',
      'hi': '⏳ अपील लंबित',
      'en': '⏳ Appeal pending',
    },
    'admins_appeal_message': {
      'gu': 'એડમિનનો અપીલ સંદેશો:',
      'hi': 'व्यवस्थापक का अपील संदेश:',
      'en': 'Admin\'s appeal message:',
    },
    'your_previous_official_reply': {
      'gu': 'તમારો અગાઉનો સત્તાવાર જવાબ:',
      'hi': 'आपका पिछला आधिकारिक उत्तर:',
      'en': 'Your previous official reply:',
    },
    'activate_society_admin_unblock_now': {
      'gu': 'સોસાયટી & એડમિન સક્રિય કરો (Unblock Now)',
      'hi': 'सोसाइटी और एडमिन को सक्रिय करें (अभी अनब्लॉक करें)',
      'en': 'Activate Society & Admin (Unblock Now)',
    },
    'correspondence_with_admin': {
      'gu': 'એડમિન સાથે પ્રત્યુત્તર માધ્યમ:',
      'hi': 'व्यवस्थापक के साथ पत्राचार:',
      'en': 'Correspondence with Admin:',
    },
    'push_reply': {
      'gu': 'પુશ રિપ્લાય',
      'hi': 'उत्तर पुश करें',
      'en': 'Push Reply',
    },
    'all_users': {
      'gu': 'તમામ યુઝર્સ (All Users)',
      'hi': 'सभी उपयोगकर्ता',
      'en': 'All Users',
    },
    'all_premises_members_shoppers_admins': {
      'gu': 'બધા પરિસરોના સભ્યો, દુકાનદારો & એડમિન્સ',
      'hi': 'सभी परिसर सदस्य, खरीदार और व्यवस्थापक',
      'en': 'All Premises Members, Shoppers & Admins',
    },
    'admins_only': {
      'gu': 'માત્ર એડમિનો (Admins Only)',
      'hi': 'केवल व्यवस्थापक',
      'en': 'Admins Only',
    },
    'all_society_committees_secretaries': {
      'gu': 'તમામ સોસાયટી કમિટી & સેક્રેટરીઓ',
      'hi': 'सभी सोसायटी समितियां एवं सचिव',
      'en': 'All Society Committees & Secretaries',
    },
    'commercial_complexes_only': {
      'gu': 'માત્ર કોમર્શિયલ સંકુલો',
      'hi': 'केवल वाणिज्यिक परिसर',
      'en': 'Commercial complexes only',
    },
    'users_of_shopping_malls_and_business': {
      'gu': 'શોપિંગ મોલ અને બિઝનેસ હબના યુઝર્સ',
      'hi': 'शॉपिंग मॉल और बिजनेस हब के उपयोगकर्ता',
      'en': 'Users of shopping malls and business hubs',
    },
    'global_system_broadcast_sent_successfully': {
      'gu': 'ગ્લોબલ સિસ્ટમ બ્રોડકાસ્ટ સફળતાપૂર્વક મોકલાઈ ગયું!',
      'hi': 'वैश्विक सिस्टम प्रसारण सफलतापूर्वक भेजा गया!',
      'en': 'Global System Broadcast Sent Successfully!',
    },
    'who_to_send_target_audience': {
      'gu': 'કોને મોકલવું? (Target Audience)',
      'hi': 'किसे भेजना है? (लक्षित दर्शक)',
      'en': 'Who to send? (Target Audience)',
    },
    'notice_details': {
      'gu': 'સૂચનાની વિગત (Notice Details)',
      'hi': 'सूचना विवरण',
      'en': 'Notice Details',
    },
    'notice_title': {
      'gu': 'સૂચના શીર્ષક (Notice Title)',
      'hi': 'सूचना शीर्षक',
      'en': 'Notice Title',
    },
    'eg_system_maintenance_or_important_announcements': {
      'gu': 'દા.ત. સિસ્ટમ મેઈન્ટેનન્સ અથવા અગત્યની જાહેરાત',
      'hi': 'जैसे सिस्टम रखरखाव या महत्वपूर्ण घोषणाएँ',
      'en': 'E.g. System maintenance or important announcements',
    },
    'please_enter_a_notification_title': {
      'gu': 'કૃપા કરીને સૂચના શીર્ષક દાખલ કરો',
      'hi': 'कृपया एक अधिसूचना शीर्षक दर्ज करें',
      'en': 'Please enter a notification title',
    },
    'message_body': {
      'gu': 'સંદેશો / નોટિસ વિગત (Message Body)',
      'hi': 'संदेश का मुख्य भाग',
      'en': 'Message Body',
    },
    'write_the_message_to_be_delivered': {
      'gu': 'બધા યુઝર્સ સુધી પહોંચાડવાનો સંદેશો અહીં વિગતવાર લખો...',
      'hi': 'सभी उपयोगकर्ताओं को दिए जाने वाले संदेश को यहां विस्तार से लिखें...',
      'en': 'Write the message to be delivered to all users in detail here...',
    },
    'please_enter_a_message': {
      'gu': 'કૃપા કરીને સંદેશો દાખલ કરો',
      'hi': 'कृपया एक संदेश दर्ज करें',
      'en': 'Please enter a message',
    },
    'priority': {
      'gu': 'પ્રાથમિકતા (Priority)',
      'hi': 'प्राथमिकता',
      'en': 'Priority',
    },
    'live_notification_preview': {
      'gu': 'લાઈવ નોટિફિકેશન પ્રીવ્યૂ (Live Preview)',
      'hi': 'लाइव अधिसूचना पूर्वावलोकन',
      'en': 'Live Notification Preview',
    },
    'super_admin_central_broadcast_facility': {
      'gu': 'સુપર એડમિન સેન્ટ્રલ બ્રોડકાસ્ટ સુવિધા',
      'hi': 'सुपर एडमिन सेंट्रल ब्रॉडकास्ट सुविधा',
      'en': 'Super Admin Central Broadcast Facility',
    },
    'this_broadcast_will_be_received_by': {
      'gu': 'આ બ્રોડકાસ્ટ પસંદ કરેલા વર્ગના તમામ યુઝર્સને તાત્કાલિક એપ્લિકેશન નોટિફિકેશન તથા એલર્ટ સ્વરૂપે પ્રાપ્ત થશે.',
      'hi': 'यह प्रसारण चयनित वर्ग के सभी उपयोगकर्ताओं को एप्लिकेशन अधिसूचना और अलर्ट के रूप में तुरंत प्राप्त होगा।',
      'en': 'This broadcast will be received by all users of the selected class immediately as an application notification and alert.',
    },
    'normal': {
      'gu': 'સામાન્ય (Normal)',
      'hi': 'सामान्य',
      'en': 'Normal',
    },
    'urgent_2': {
      'gu': 'તાકીદનું (Urgent)',
      'hi': 'अत्यावश्यक',
      'en': 'Urgent',
    },
    'the_notification_title_will_appear_here': {
      'gu': 'સૂચના શીર્ષક અહીં દેખાશે',
      'hi': 'अधिसूचना शीर्षक यहां दिखाई देगा',
      'en': 'The notification title will appear here',
    },
    'a_preview_of_the_message_you': {
      'gu': 'તમે જે સંદેશો ટાઇપ કરશો તેનું પ્રીવ્યૂ યુઝર્સના ફોનમાં આ રીતે નજરે પડશે...',
      'hi': 'आपके द्वारा टाइप किए गए संदेश का पूर्वावलोकन उपयोगकर्ता के फ़ोन पर इस प्रकार दिखाई देगा...',
      'en': 'A preview of the message you type will appear on the user\'s phone like this...',
    },
    'just_now': {
      'gu': 'હમણાં જ',
      'hi': 'अभी अभी',
      'en': 'just now',
    },
    'all_users_2': {
      'gu': '👥 તમામ યુઝર્સ',
      'hi': '👥 सभी उपयोगकर्ता',
      'en': '👥 All users',
    },
    'admins_only_2': {
      'gu': '🛡️ માત્ર એડમિન્સ',
      'hi': '🛡️ केवल व्यवस्थापक',
      'en': '🛡️ Admins only',
    },
    'commercial': {
      'gu': '🛍️ કોમર્શિયલ',
      'hi': '🛍️वाणिज्यिक',
      'en': '🛍️ Commercial',
    },
    'send_a_global_broadcast': {
      'gu': 'ગ્લોબલ બ્રોડકાસ્ટ મોકલો',
      'hi': 'एक वैश्विक प्रसारण भेजें',
      'en': 'Send a global broadcast',
    },
    'headquarters': {
      'gu': 'હેડક્વાર્ટર',
      'hi': 'मुख्यालय',
      'en': 'headquarters',
    },
    'personal_security_details': {
      'gu': 'વ્યક્તિગત & સિક્યોરિટી વિગતો',
      'hi': 'व्यक्तिगत एवं सुरक्षा विवरण',
      'en': 'Personal & Security Details',
    },
    'full_name_3': {
      'gu': 'પૂરું નામ (Full Name)',
      'hi': 'पूरा नाम',
      'en': 'Full Name',
    },
    'eg_rajeshbhai_patel': {
      'gu': 'દા.ત. રાજેશભાઈ પટેલ',
      'hi': 'जैसे राजेशभाई पटेल',
      'en': 'E.g. Rajeshbhai Patel',
    },
    'please_enter_full_name': {
      'gu': 'કૃપા કરીને પૂરું નામ દાખલ કરો',
      'hi': 'कृपया पूरा नाम दर्ज करें',
      'en': 'Please enter full name',
    },
    'mobile_number_phone_number': {
      'gu': 'મોબાઈલ નંબર (Phone Number)',
      'hi': 'मोबाइल नंबर (फ़ोन नंबर)',
      'en': 'Mobile Number (Phone Number)',
    },
    'please_enter_a_phone_number': {
      'gu': 'કૃપા કરીને ફોન નંબર દાખલ કરો',
      'hi': 'कृपया एक फ़ोन नंबर दर्ज करें',
      'en': 'Please enter a phone number',
    },
    'enter_a_valid_10_digit_number_2': {
      'gu': 'માન્ય 10 અંકનો નંબર દાખલ કરો',
      'hi': 'एक वैध 10 अंकीय संख्या दर्ज करें',
      'en': 'Enter a valid 10 digit number',
    },
    'official_email_id': {
      'gu': 'ઓફિશિયલ ઈમેલ આઈડી (Email)',
      'hi': 'आधिकारिक ईमेल आईडी',
      'en': 'Official Email Id',
    },
    'please_enter_email': {
      'gu': 'કૃપા કરીને ઈમેલ દાખલ કરો',
      'hi': 'कृपया ईमेल दर्ज करें',
      'en': 'Please enter email',
    },
    'enter_a_valid_email_id': {
      'gu': 'માન્ય ઈમેલ આઈડી દાખલ કરો',
      'hi': 'एक वैध ईमेल आईडी दर्ज करें',
      'en': 'Enter a valid email id',
    },
    'security_password': {
      'gu': 'સુરક્ષા પાસવર્ડ (Password)',
      'hi': 'सुरक्षा पासवर्ड',
      'en': 'Security Password',
    },
    'please_enter_a_password': {
      'gu': 'કૃપા કરીને પાસવર્ડ દાખલ કરો',
      'hi': 'कृपया एक पासवर्ड दर्ज करें',
      'en': 'Please enter a password',
    },
    'a_password_of_at_least_6': {
      'gu': 'ઓછામાં ઓછા ૬ અક્ષરનો પાસવર્ડ જરૂરી છે',
      'hi': 'कम से कम 6 अक्षरों का पासवर्ड आवश्यक है',
      'en': 'A password of at least 6 characters is required',
    },
    'set_a_strong_password': {
      'gu': 'મજબૂત પાસવર્ડ સેટ કરો...',
      'hi': 'एक मजबूत पासवर्ड सेट करें...',
      'en': 'Set a strong password...',
    },
    'management_of_all_society_premises_and': {
      'gu': 'તમામ સોસાયટી પરિસરો અને ગેટ પાસવર્ડ્સનું સંચાલન',
      'hi': 'सभी सोसायटी परिसरों और गेट पासवर्ड का प्रबंधन',
      'en': 'Management of all society premises and gate passwords',
    },
    'platform_finance_commission_and_collection_audit': {
      'gu': 'પ્લેટફોર્મ ફાઇનાન્સ, કમિશન અને કલેક્શન ઑડિટ',
      'hi': 'प्लेटफ़ॉर्म वित्त, कमीशन और संग्रह लेखापरीक्षा',
      'en': 'Platform Finance, Commission and Collection Audit',
    },
    'the_right_to_send_a_global': {
      'gu': 'ગ્લોબલ સિસ્ટમ પુશ બ્રોડકાસ્ટ મોકલવાનો અધિકાર',
      'hi': 'वैश्विक सिस्टम पुश प्रसारण भेजने का अधिकार',
      'en': 'The right to send a global system push broadcast',
    },
    'direct_admin_access_with_default_login': {
      'gu': 'ડિફોલ્ટ લોગિન ક્રેડેન્શિયલ્સ સાથે સીધો એડમિન એક્સેસ',
      'hi': 'डिफ़ॉल्ट लॉगिन क्रेडेंशियल के साथ सीधी व्यवस्थापक पहुंच',
      'en': 'Direct admin access with default login credentials',
    },
    'obtainable_master_permissions': {
      'gu': 'મળવાપાત્ર માસ્ટર પરમિશન્સ',
      'hi': 'प्राप्य मास्टर अनुमतियाँ',
      'en': 'Obtainable master permissions',
    },
    'logout_2': {
      'gu': 'લૉગઆઉટ',
      'hi': 'लॉगआउट करें',
      'en': 'Logout',
    },
    'total_collection_vol': {
      'gu': 'કુલ કલેક્શન વોલ્યુમ',
      'hi': 'कुल संग्रह खंड',
      'en': 'Total collection vol',
    },
    'deposited_this_month': {
      'gu': 'આ મહિને જમા',
      'hi': 'इसी महीने जमा किया गया',
      'en': 'Deposited this month',
    },
    'registered_premises': {
      'gu': 'રજિસ્ટર્ડ પરિસરો',
      'hi': 'पंजीकृत परिसर',
      'en': 'Registered premises',
    },
    'total_users_members': {
      'gu': 'કુલ યુઝર્સ & સભ્યો',
      'hi': 'कुल उपयोगकर्ता एवं सदस्य',
      'en': 'Total Users & Members',
    },
    'get_security_pulse': {
      'gu': 'ગેટ સિક્યોરિટી પલ્સ',
      'hi': 'सुरक्षा पल्स प्राप्त करें',
      'en': 'Get Security Pulse',
    },
    'premises': {
      'gu': 'પરિસરો',
      'hi': 'परिसर',
      'en': 'premises',
    },
    'users': {
      'gu': 'યુઝર્સ',
      'hi': 'उपयोगकर्ता',
      'en': 'users',
    },
    'finance': {
      'gu': 'ફાઇનાન્સ',
      'hi': 'वित्त',
      'en': 'finance',
    },
    'powers': {
      'gu': 'પાવર્સ',
      'hi': 'शक्तियां',
      'en': 'Powers',
    },
    'search_premises_city_admin_or_phone': {
      'gu': 'પરિસર, શહેર, એડમિન કે ફોન શોધો...',
      'hi': 'परिसर, शहर, व्यवस्थापक या फ़ोन खोजें...',
      'en': 'Search Premises, City, Admin or Phone...',
    },
    'commercial_mall': {
      'gu': '🛍️ કોમર્શિયલ મોલ',
      'hi': '🛍️कमर्शियल मॉल',
      'en': '🛍️ Commercial Mall',
    },
    'mixed_complex': {
      'gu': '🏙️ મિક્સ્ડ કોમ્પ્લેક્સ',
      'hi': '🏙️मिश्रित संकुल',
      'en': '🏙️ Mixed complex',
    },
    'residential': {
      'gu': '🏢 રેસિડેન્શિયલ',
      'hi': '🏢आवासीय',
      'en': '🏢 Residential',
    },
    'society_bungalow': {
      'gu': '🏡 સોસાયટી / બંગલો',
      'hi': '🏡 सोसायटी/बंगला',
      'en': '🏡 Society / Bungalow',
    },
    'no_premises_found': {
      'gu': 'કોઈ પરિસર મળ્યું નથી',
      'hi': 'कोई परिसर नहीं मिला',
      'en': 'No premises found',
    },
    'try_changing_the_search_query_or': {
      'gu': 'સર્ચ ક્વેરી અથવા ફિલ્ટર બદલીને પ્રયાસ કરો.',
      'hi': 'खोज क्वेरी या फ़िल्टर बदलने का प्रयास करें.',
      'en': 'Try changing the search query or filter.',
    },
    'mixed_complex_2': {
      'gu': '🏙️ મિક્સ્ડ સંકુલ',
      'hi': '🏙️मिश्रित संकुल',
      'en': '🏙️ Mixed complex',
    },
    'bungalow_society': {
      'gu': '🏡 બંગલો સોસાયટી',
      'hi': '🏡बंगला सोसायटी',
      'en': '🏡 Bungalow Society',
    },
    'flat_tower': {
      'gu': '🏢 ફ્લેટ ટાવર',
      'hi': '🏢 फ्लैट टॉवर',
      'en': '🏢 Flat Tower',
    },
    'working_2': {
      'gu': 'કાર્યરત',
      'hi': 'काम कर रहे हैं',
      'en': 'working',
    },
    'frozen': {
      'gu': 'ફ્રીઝ્ડ',
      'hi': 'जमे हुए',
      'en': 'frozen',
    },
    'guards': {
      'gu': 'ગાર્ડ્સ',
      'hi': 'रक्षक',
      'en': 'Guards',
    },
    'collection': {
      'gu': 'કલેક્શન',
      'hi': 'संग्रह',
      'en': 'collection',
    },
    'coll': {
      'gu': 'કોલ',
      'hi': 'कोल',
      'en': 'Coll',
    },
    'notice': {
      'gu': 'નોટિસ',
      'hi': 'सूचना',
      'en': 'Notice',
    },
    'complete_horoscope': {
      'gu': 'સંપૂર્ણ કુંડળી',
      'hi': 'सम्पूर्ण राशिफल',
      'en': 'Complete horoscope',
    },
    'find_name_phone_email_or_unit': {
      'gu': 'નામ, ફોન, ઈમેલ કે એકમ નંબર શોધો...',
      'hi': 'नाम, फ़ोन, ईमेल या यूनिट नंबर ढूंढें...',
      'en': 'Find name, phone, email or unit number...',
    },
    'super_admin': {
      'gu': '👑 સુપર એડમિન',
      'hi': '👑सुपर एडमिन',
      'en': '👑 Super Admin',
    },
    'try_changing_the_search_query_or_2': {
      'gu': 'સર્ચ ક્વેરી અથવા રોલ ફિલ્ટર બદલીને પ્રયાસ કરો.',
      'hi': 'खोज क्वेरी या भूमिका फ़िल्टर बदलने का प्रयास करें.',
      'en': 'Try changing the search query or role filter.',
    },
    'chief_admin': {
      'gu': 'મુખ્ય એડમિન',
      'hi': 'मुख्य व्यवस्थापक',
      'en': 'Chief Admin',
    },
    'security_guard_2': {
      'gu': 'સિક્યોરિટી ગાર્ડ',
      'hi': 'सुरक्षा गार्ड',
      'en': 'Security guard',
    },
    'member_owner': {
      'gu': 'સભ્ય / માલિક',
      'hi': 'सदस्य/मालिक',
      'en': 'Member / Owner',
    },
    'block_the_user': {
      'gu': 'યુઝર બ્લોક કરો',
      'hi': 'उपयोगकर्ता को ब्लॉक करें',
      'en': 'Block the user',
    },
    'activate_the_user': {
      'gu': 'યુઝર એક્ટિવ કરો',
      'hi': 'उपयोगकर्ता को सक्रिय करें',
      'en': 'Activate the user',
    },
    'send_notification_notice': {
      'gu': 'નોટિફિકેશન / નોટિસ મોકલો',
      'hi': 'अधिसूचना/नोटिस भेजें',
      'en': 'Send notification / notice',
    },
    'create_super_admin': {
      'gu': '👑 સુપર એડમિન બનાવો',
      'hi': '👑 सुपर एडमिन बनाएं',
      'en': '👑 Create Super Admin',
    },
    'revoke_super_admin_authority': {
      'gu': 'સુપર એડમિન સત્તા રદ્દ કરો',
      'hi': 'सुपर एडमिन अथॉरिटी रद्द करें',
      'en': 'Revoke super admin authority',
    },
    'platform_maintenance_account_total_volume': {
      'gu': 'પ્લેટફોર્મ મેન્ટેનન્સ હિસાબ (કુલ વોલ્યુમ)',
      'hi': 'प्लेटफ़ॉर्म रखरखाव खाता (कुल मात्रा)',
      'en': 'Platform Maintenance Account (Total Volume)',
    },
    'total_billing': {
      'gu': 'કુલ બિલિંગ',
      'hi': 'कुल बिलिंग',
      'en': 'Total billing',
    },
    'total_deposited': {
      'gu': 'કુલ જમા થયેલ',
      'hi': 'कुल जमा',
      'en': 'Total deposited',
    },
    'total_amount_due': {
      'gu': 'કુલ બાકી રકમ',
      'hi': 'कुल बकाया राशि',
      'en': 'Total amount due',
    },
    'txt_100_secured_database': {
      'gu': '૧૦૦% સિક્યોર્ડ ડેટાબેઝ',
      'hi': '100% सुरक्षित डेटाबेस',
      'en': '100% secured database',
    },
    'txt_18_gst_invoicing_summary_commercial': {
      'gu': '૧૮% GST ઇન્વોઇસિંગ સમરી (કોમર્શિયલ)',
      'hi': '18% जीएसटी चालान सारांश (वाणिज्यिक)',
      'en': '18% GST Invoicing Summary (Commercial)',
    },
    'total_gst_collection': {
      'gu': 'કુલ GST વસૂલાત',
      'hi': 'कुल जीएसटी संग्रह',
      'en': 'Total GST collection',
    },
    'cgst_9': {
      'gu': 'CGST (૯%)',
      'hi': 'सीजीएसटी (9%)',
      'en': 'CGST (9%)',
    },
    'sgst_9': {
      'gu': 'SGST (૯%)',
      'hi': 'एसजीएसटी (9%)',
      'en': 'SGST (9%)',
    },
    'platform_gate_security_pulse': {
      'gu': 'પ્લેટફોર્મ ગેટ & સિક્યોરિટી પલ્સ',
      'hi': 'प्लेटफ़ॉर्म गेट और सुरक्षा पल्स',
      'en': 'Platform Gate & Security Pulse',
    },
    'todays_total_visitor_entries': {
      'gu': 'આજની કુલ વિઝિટર એન્ટ્રીઓ',
      'hi': 'आज की कुल आगंतुक प्रविष्टियाँ',
      'en': 'Today\'s total visitor entries',
    },
    'total_onduty_security_guards': {
      'gu': 'કુલ ઓન-ડ્યુટી સિક્યોરિટી ગાર્ડ્સ',
      'hi': 'कुल ऑन-ड्यूटी सुरक्षा गार्ड',
      'en': 'Total on-duty security guards',
    },
    'total_pending_society_grievances': {
      'gu': 'કુલ પેન્ડિંગ સોસાયટી ફરિયાદો',
      'hi': 'कुल लंबित सोसायटी शिकायतें',
      'en': 'Total Pending Society Grievances',
    },
    'society_appeals_reviews': {
      'gu': 'સોસાયટી અપીલ વિનંતીઓ (Appeals & Reviews)',
      'hi': 'सोसायटी अपील एवं समीक्षा',
      'en': 'Society Appeals & Reviews',
    },
    'verify_and_decide_reactivation_appeals_from': {
      'gu': 'સ્થગિત સોસાયટીના એડમિન તરફથી આવેલી પુનઃસક્રિયતા અપીલો ચકાસો અને નિર્ણય લો',
      'hi': 'निलंबित सोसायटी व्यवस्थापकों से पुनः सक्रियण अपीलों को सत्यापित करें और निर्णय लें',
      'en': 'Verify and decide reactivation appeals from suspended society admins',
    },
    'create_a_new_cosuper_admin': {
      'gu': 'નવા કો-સુપર એડમિન બનાવો (Co-Super Admin)',
      'hi': 'एक नया सह-सुपर एडमिन बनाएं',
      'en': 'Create a new Co-Super Admin',
    },
    'give_full_master_access_to_your': {
      'gu': 'તમારા પાર્ટનર કે ઓપરેશન્સ મેનેજરને સંપૂર્ણ માસ્ટર એક્સેસ આપો',
      'hi': 'अपने साझेदार या संचालन प्रबंधक को पूर्ण मास्टर एक्सेस प्रदान करें',
      'en': 'Give full master access to your partner or operations manager',
    },
    'onboard_new_society_1click_setup': {
      'gu': 'નવી સોસાયટી ઓનબોર્ડ કરો (1-Click Setup)',
      'hi': 'जहाज पर नई सोसायटी (1-क्लिक सेटअप)',
      'en': 'Onboard New Society (1-Click Setup)',
    },
    'create_a_new_premises_and_set': {
      'gu': 'નવું પરિસર બનાવીને ચેરમેન/સેક્રેટરીનો એડમિન પાસવર્ડ સેટ કરો',
      'hi': 'एक नया परिसर बनाएं और अध्यक्ष/सचिव का एडमिन पासवर्ड सेट करें',
      'en': 'Create a new premises and set the admin password of Chairman/Secretary',
    },
    'global_system_broadcast_global_notice': {
      'gu': 'ગ્લોબલ સિસ્ટમ બ્રોડકાસ્ટ (Global Notice)',
      'hi': 'ग्लोबल सिस्टम ब्रॉडकास्ट (वैश्विक सूचना)',
      'en': 'Global System Broadcast (Global Notice)',
    },
    'send_official_notification_to_all_society': {
      'gu': 'તમામ સોસાયટીના એડમિનો અથવા મેમ્બર્સને ઓફિશિયલ સૂચના મોકલો',
      'hi': 'सभी सोसायटी व्यवस्थापकों या सदस्यों को आधिकारिक अधिसूचना भेजें',
      'en': 'Send official notification to all society admins or members',
    },
    'system_cache_clean_data_refresh': {
      'gu': 'સિસ્ટમ કેશ ક્લીન & ડેટા રિફ્રેશ',
      'hi': 'सिस्टम कैश साफ़ करें और डेटा ताज़ा करें',
      'en': 'System cache clean & data refresh',
    },
    'resync_the_database_cache_of_all': {
      'gu': 'તમામ સોસાયટીઓ અને યુઝર્સનો ડેટાબેઝ કેશ ફરીથી સિંક કરો',
      'hi': 'सभी सोसायटियों और उपयोगकर्ताओं के डेटाबेस कैश को पुन: समन्वयित करें',
      'en': 'Resync the database cache of all societies and users',
    },
    'system_cache_refresh_succeeded': {
      'gu': 'સિસ્ટમ કેશ રિફ્રેશ સફળ થઈ ગઈ છે!',
      'hi': 'सिस्टम कैश रिफ्रेश सफल हुआ!',
      'en': 'System cache refresh succeeded!',
    },
    'society_id': {
      'gu': 'સોસાયટી આઈડી',
      'hi': 'सोसायटी आईडी',
      'en': 'Society Id',
    },
    'admin_email': {
      'gu': 'એડમિન ઈમેલ',
      'hi': 'व्यवस्थापक ईमेल',
      'en': 'Admin email',
    },
    'number_of_members': {
      'gu': 'સભ્યો સંખ્યા',
      'hi': 'सदस्यों की संख्या',
      'en': 'Number of members',
    },
    'security_staff': {
      'gu': 'સિક્યોરિટી સ્ટાફ',
      'hi': 'सुरक्षा कर्मचारी',
      'en': 'Security staff',
    },
    'current_month_billing': {
      'gu': 'ચાલુ મહિને બિલિંગ',
      'hi': 'चालू माह की बिलिंग',
      'en': 'Current month billing',
    },
    'current_month_collection': {
      'gu': 'ચાલુ મહિને કલેક્શન',
      'hi': 'चालू माह का संग्रह',
      'en': 'Current month collection',
    },
    'pending_complaints': {
      'gu': 'પેન્ડિંગ ફરિયાદો',
      'hi': 'लंबित शिकायतें',
      'en': 'Pending Complaints',
    },
    'active_2': {
      'gu': 'એક્ટિવ (ચાલુ)',
      'hi': 'सक्रिय',
      'en': 'active',
    },
    'suspended_freeze': {
      'gu': 'સસ્પેન્ડેડ (ફ્રીઝ)',
      'hi': 'निलंबित (फ्रीज)',
      'en': 'suspended (freeze)',
    },
    'enter_this_society_as_an_admin': {
      'gu': 'આ સોસાયટીમાં એડમિન તરીકે પ્રવેશ કરો (View As Admin)',
      'hi': 'इस सोसायटी में एक व्यवस्थापक के रूप में प्रवेश करें (व्यवस्थापक के रूप में देखें)',
      'en': 'Enter this society as an admin (View As Admin)',
    },
    'send_admin_credentials_email_whatsapp': {
      'gu': 'એડમિન ક્રેડેન્શિયલ્સ મોકલો (Email / WhatsApp)',
      'hi': 'एडमिन क्रेडेंशियल भेजें (ईमेल/व्हाट्सएप)',
      'en': 'Send Admin Credentials (Email / WhatsApp)',
    },
    'send_direct_notification_to_admin_notify': {
      'gu': 'એડમિનને ડાયરેક્ટ નોટિફિકેશન મોકલો (Notify Admin)',
      'hi': 'व्यवस्थापक को सीधे सूचना भेजें (व्यवस्थापक को सूचित करें)',
      'en': 'Send direct notification to admin (Notify Admin)',
    },
    'send_password_reset_link_to_admin': {
      'gu': 'એડમિનને પાસવર્ડ રીસેટ લિંક મોકલો (Reset Password)',
      'hi': 'व्यवस्थापक को पासवर्ड रीसेट लिंक भेजें (पासवर्ड रीसेट करें)',
      'en': 'Send password reset link to admin (Reset Password)',
    },
    'head_office_official_notification': {
      'gu': 'હેડ ઓફિસ સત્તાવાર સૂચના',
      'hi': 'प्रधान कार्यालय आधिकारिक अधिसूचना',
      'en': 'Head Office Official Notification',
    },
    'matter_of_submission_of_annual_audit': {
      'gu': '📊 વાર્ષિક ઓડિટ રિપોર્ટ સબમિટ કરવા બાબત',
      'hi': '📊वार्षिक ऑडिट रिपोर्ट जमा करने का मामला',
      'en': '📊 Matter of submission of annual audit report',
    },
    'system_maintenance_security_update': {
      'gu': '⚠️ સિસ્ટમ મેન્ટેનન્સ & સિક્યોરિટી અપડેટ',
      'hi': '⚠️ सिस्टम रखरखाव और सुरक्षा अद्यतन',
      'en': '⚠️ System Maintenance & Security Update',
    },
    'accountmember_data_verification_notice': {
      'gu': '📋 એકાઉન્ટ/મેમ્બર ડેટા વેરિફિકેશન સૂચના',
      'hi': '📋खाता/सदस्य डेटा सत्यापन सूचना',
      'en': '📋 Account/Member Data Verification Notice',
    },
    'matter_of_uploading_committee_meeting_and': {
      'gu': '💼 કમિટી મિટિંગ અને ઠરાવ અપલોડ કરવા બાબત',
      'hi': '💼 समिति की बैठक एवं प्रस्ताव अपलोड करने का मामला',
      'en': '💼 Matter of uploading committee meeting and resolution',
    },
    'notification_to_particular_society_admin': {
      'gu': 'ચોક્કસ સોસાયટી / એડમિનને નોટિફિકેશન',
      'hi': 'विशेष सोसायटी/प्रशासन को अधिसूचना',
      'en': 'Notification to particular Society / Admin',
    },
    'to_all_members_of_the_entire': {
      'gu': '📢 આખી સોસાયટીના તમામ સભ્યોને',
      'hi': '📢सम्पूर्ण समाज के सभी सदस्यों को',
      'en': '📢 To all members of the entire society',
    },
    'to_society_admin_only': {
      'gu': '👤 માત્ર સોસાયટી એડમિનને',
      'hi': '👤 केवल सोसायटी एडमिन के लिए',
      'en': '👤 To Society Admin only',
    },
    'all_flat_owners_will_be_pushed': {
      'gu': 'તમામ ફ્લેટ માલિકોને પુશ જશે',
      'hi': 'सभी फ्लैट मालिकों को धक्का दिया जाएगा',
      'en': 'All flat owners will be pushed',
    },
    'only_the_committeeadmins_phone_will_be': {
      'gu': 'માત્ર કમિટી/એડમિનના ફોનમાં પુશ જશે',
      'hi': 'केवल समिति/व्यवस्थापक का फ़ोन ही पुश किया जायेगा',
      'en': 'Only the committee/admin\'s phone will be pushed',
    },
    'quick_template': {
      'gu': 'ઝડપી ટેમ્પલેટ:',
      'hi': 'त्वरित टेम्पलेट:',
      'en': 'Quick Template:',
    },
    'notification_title': {
      'gu': 'સૂચના શીર્ષક *',
      'hi': 'अधिसूचना शीर्षक *',
      'en': 'Notification Title *',
    },
    'message_detail': {
      'gu': 'સંદેશ / વિગત *',
      'hi': 'संदेश/विस्तार*',
      'en': 'Message / Detail *',
    },
    'write_an_important_notice_from_super': {
      'gu': 'સુપર એડમિન તરફથી અગત્યની સૂચના લખો...',
      'hi': 'सुपर एडमिन से एक महत्वपूर्ण सूचना लिखें...',
      'en': 'Write an important notice from Super Admin...',
    },
    'please_fill_in_both_title_and_2': {
      'gu': 'કૃપા કરીને શીર્ષક અને સંદેશ બંને ભરો.',
      'hi': 'कृपया शीर्षक और संदेश दोनों भरें।',
      'en': 'Please fill in both title and message.',
    },
    'send_push_notification': {
      'gu': 'પુશ નોટિફિકેશન મોકલો (Send Push)',
      'hi': 'पुश सूचना भेजें',
      'en': 'Send Push Notification',
    },
    'want_to_freeze_suspend_the_society': {
      'gu': 'સોસાયટી ફ્રીઝ (સસ્પેન્ડ) કરવી છે?',
      'hi': 'समाज को फ्रीज (निलंबित) करना चाहते हैं?',
      'en': 'Want to freeze (suspend) the society?',
    },
    'yes_freeze': {
      'gu': 'હા, ફ્રીઝ કરો',
      'hi': 'हाँ, फ्रीज करो',
      'en': 'Yes, freeze',
    },
    'society_appeal_requests': {
      'gu': 'સોસાયટી અપીલ વિનંતીઓ',
      'hi': 'सोसायटी अपील अनुरोध',
      'en': 'Society appeal requests',
    },
    'there_is_currently_no_appeal_request': {
      'gu': 'હાલ કોઈ અપીલ વિનંતી પેન્ડિંગ નથી.',
      'hi': 'वर्तमान में कोई अपील अनुरोध लंबित नहीं है।',
      'en': 'There is currently no appeal request pending.',
    },
    'rejected_4': {
      'gu': 'અસ્વીકૃત',
      'hi': 'अस्वीकृत',
      'en': 'rejected',
    },
    'create_super_admin_2': {
      'gu': 'સુપર એડમિન બનાવો છો?',
      'hi': 'सुपर एडमिन बनाएं?',
      'en': 'Create super admin?',
    },
    'yes_create_super_admin': {
      'gu': 'હા, સુપર એડમિન બનાવો',
      'hi': 'हां, सुपर एडमिन बनाएं',
      'en': 'Yes, create super admin',
    },
    'revoke_super_admin_rights': {
      'gu': 'સુપર એડમિન અધિકાર રદ્દ કરવો છે?',
      'hi': 'सुपर व्यवस्थापक अधिकार निरस्त करें?',
      'en': 'Revoke super admin rights?',
    },
    'yes_cancel_the_power': {
      'gu': 'હા, સત્તા રદ્દ કરો',
      'hi': 'हाँ, बिजली रद्द करो',
      'en': 'Yes, cancel the power',
    },
    'logout_3': {
      'gu': 'લૉગઆઉટ કરવું છે?',
      'hi': 'लॉगआउट?',
      'en': 'Logout?',
    },
    'are_you_sure_you_want_to': {
      'gu': 'શું તમે ખરેખર સુપર એડમિન કમાન્ડ સેન્ટરમાંથી લૉગઆઉટ કરવા માંગો છો?',
      'hi': 'क्या आप वाकई सुपर एडमिन कमांड सेंटर से लॉग आउट करना चाहते हैं?',
      'en': 'Are you sure you want to log out of Super Admin Command Center?',
    },
    'yes_logout': {
      'gu': 'હા, લૉગઆઉટ કરો',
      'hi': 'हाँ, लॉगआउट करें',
      'en': 'Yes, logout',
    },
    'surat': {
      'gu': 'સુરત',
      'hi': 'सूरत',
      'en': 'Surat',
    },
    'commercial_mall_2': {
      'gu': 'કોમર્શિયલ મોલ',
      'hi': 'वाणिज्यिक मॉल',
      'en': 'Commercial Mall',
    },
    'offices_shops_and_malls': {
      'gu': 'ઓફિસ, દુકાનો અને મોલ',
      'hi': 'कार्यालय, दुकानें और मॉल',
      'en': 'Offices, shops and malls',
    },
    'residential_tower': {
      'gu': 'રેસિડેન્શિયલ ટાવર',
      'hi': 'आवासीय टावर',
      'en': 'Residential Tower',
    },
    'high_rise_flats_and_apartments': {
      'gu': 'હાઇરાઇઝ ફ્લેટ્સ અને એપાર્ટમેન્ટ',
      'hi': 'ऊँचे-ऊँचे फ्लैट और अपार्टमेंट',
      'en': 'High rise flats and apartments',
    },
    'bungalow_society_2': {
      'gu': 'બંગલો / સોસાયટી',
      'hi': 'बंगला/सोसाइटी',
      'en': 'BUNGALOW / SOCIETY',
    },
    'rowhouses_tenements_and_plots': {
      'gu': 'રો-હાઉસ, ટેનામેન્ટ્સ અને પ્લોટ',
      'hi': 'पंक्ति-घर, मकान और भूखंड',
      'en': 'Row-houses, tenements and plots',
    },
    'mixed_premises': {
      'gu': 'મિક્સ્ડ પરિસર',
      'hi': 'मिश्रित परिसर',
      'en': 'Mixed premises',
    },
    'residential_shops_complex': {
      'gu': 'રેસિડેન્શિયલ + શોપ્સ કોમ્પ્લેક્સ',
      'hi': 'आवासीय + दुकानें परिसर',
      'en': 'Residential + Shops Complex',
    },
    'txt_1_main_details_of_premises': {
      'gu': '૧. પરિસરની મુખ્ય વિગતો',
      'hi': '1. परिसर का मुख्य विवरण',
      'en': '1. Main details of premises',
    },
    'name_of_society_mall_complex': {
      'gu': 'સોસાયટી / મોલ / સંકુલનું નામ',
      'hi': 'सोसायटी/मॉल/कॉम्प्लेक्स का नाम',
      'en': 'Name of Society / Mall / Complex',
    },
    'eg_silver_heights_residency': {
      'gu': 'દા.ત. સિલ્વર હાઇટ્સ રેસિડેન્સી',
      'hi': 'जैसे सिल्वर हाइट्स रेजीडेंसी',
      'en': 'E.g. Silver Heights Residency',
    },
    'society_name_must_be_entered': {
      'gu': 'સોસાયટીનું નામ દાખલ કરવું જરૂરી છે',
      'hi': 'सोसायटी का नाम दर्ज करना होगा',
      'en': 'Society name must be entered',
    },
    'city_district': {
      'gu': 'શહેર / જિલ્લો',
      'hi': 'शहर/जिला',
      'en': 'City / District',
    },
    'eg_surat': {
      'gu': 'દા.ત. સુરત',
      'hi': 'जैसे सूरत',
      'en': 'E.g. Surat',
    },
    'enter_the_city': {
      'gu': 'શહેર દાખલ કરો',
      'hi': 'शहर में प्रवेश करें',
      'en': 'Enter the city',
    },
    'estimated_units': {
      'gu': 'અંદાજિત એકમો (Units)',
      'hi': 'अनुमानित इकाइयाँ',
      'en': 'Estimated Units',
    },
    'eg_120': {
      'gu': 'દા.ત. 120',
      'hi': 'जैसे 120',
      'en': 'E.g. 120',
    },
    'txt_2_first_adminsecretary_account': {
      'gu': '૨. પ્રથમ એડમિન / સેક્રેટરી એકાઉન્ટ',
      'hi': '2. प्रथम व्यवस्थापक/सचिव खाता',
      'en': '2. First admin/secretary account',
    },
    'full_name_of_secretary_admin': {
      'gu': 'સેક્રેટરી / એડમિનનું પૂરું નામ',
      'hi': 'सचिव/प्रशासन का पूरा नाम',
      'en': 'Full Name of Secretary / Admin',
    },
    'eg_maheshbhai_shah': {
      'gu': 'દા.ત. મહેશભાઈ શાહ',
      'hi': 'जैसे महेशभाई शाह',
      'en': 'E.g. Maheshbhai Shah',
    },
    'enter_admin_name': {
      'gu': 'એડમિનનું નામ દાખલ કરો',
      'hi': 'व्यवस्थापक नाम दर्ज करें',
      'en': 'Enter admin name',
    },
    'mobile_number_phone': {
      'gu': 'મોબાઈલ નંબર (Phone)',
      'hi': 'मोबाइल नंबर (फोन)',
      'en': 'Mobile Number (Phone)',
    },
    'eg_98250_12345': {
      'gu': 'દા.ત. 98250 12345',
      'hi': 'जैसे 98250 12345',
      'en': 'E.g. 98250 12345',
    },
    'enter_the_mobile_number': {
      'gu': 'મોબાઈલ નંબર દાખલ કરો',
      'hi': 'मोबाइल नंबर दर्ज करें',
      'en': 'Enter the mobile number',
    },
    'admin_email_id': {
      'gu': 'એડમિન ઈમેલ આઈડી (Email)',
      'hi': 'एडमिन ईमेल आईडी',
      'en': 'Admin Email Id',
    },
    'enter_email_id': {
      'gu': 'ઈમેલ આઈડી દાખલ કરો',
      'hi': 'ईमेल आईडी दर्ज करें',
      'en': 'Enter email id',
    },
    'provide_a_valid_email_id': {
      'gu': 'માન્ય ઈમેલ આઈડી આપો',
      'hi': 'एक वैध ईमेल आईडी प्रदान करें',
      'en': 'Provide a valid email id',
    },
    'premises_architecture_type': {
      'gu': 'પરિસર આર્કિટેક્ચર પ્રકાર (Architecture Type)',
      'hi': 'परिसर वास्तुकला प्रकार',
      'en': 'Premises Architecture Type',
    },
    'initial_admin_password_default_password': {
      'gu': 'પ્રારંભિક એડમિન પાસવર્ડ (Default Password)',
      'hi': 'प्रारंभिक व्यवस्थापक पासवर्ड (डिफ़ॉल्ट पासवर्ड)',
      'en': 'Initial Admin Password (Default Password)',
    },
    'password_is_required': {
      'gu': 'પાસવર્ડ આપવો જરૂરી છે',
      'hi': 'पासवर्ड आवश्यक है',
      'en': 'Password is required',
    },
    'minimum_6_characters_required': {
      'gu': 'ઓછામાં ઓછા ૬ અક્ષર જરૂરી',
      'hi': 'न्यूनतम 6 अक्षर आवश्यक हैं',
      'en': 'Minimum 6 characters required',
    },
    'enter_the_default_password': {
      'gu': 'ડિફોલ્ટ પાસવર્ડ દાખલ કરો...',
      'hi': 'डिफ़ॉल्ट पासवर्ड दर्ज करें...',
      'en': 'Enter the default password...',
    },
    'send_login_details_to_admin': {
      'gu': 'એડમિનને લૉગિન વિગતો મોકલો',
      'hi': 'व्यवस्थापक को लॉगिन विवरण भेजें',
      'en': 'Send login details to admin',
    },
    'dispatch_credentials_to_email_whatsapp_upon': {
      'gu': 'ઓનબોર્ડ થતાં જ ઈમેલ & WhatsApp પર ક્રેડેન્શિયલ્સ ડિસ્પેચ કરો',
      'hi': 'ऑनबोर्डिंग पर ईमेल और व्हाट्सएप पर क्रेडेंशियल भेजें',
      'en': 'Dispatch Credentials to Email & WhatsApp upon onboarding',
    },
  
    // =============================================================
    // Auto-Generated Comprehensive UI & Widget Translations
    // =============================================================
    'this_account_has_been_disabled_or': {
      'gu': 'આ એકાઉન્ટ નિષ્ક્રિય અથવા બ્લૉક કરવામાં આવ્યું છે.\\nએડમિનનો સંપર્ક કરો.',
      'hi': 'यह खाता अक्षम या अवरुद्ध कर दिया गया है.\\nकिसी व्यवस्थापक से संपर्क करें.',
      'en': 'This account has been disabled or blocked.\\nContact an admin.',
    },
    'overdue': {
      'gu': 'મુદત વીતી ગઈ (Overdue)',
      'hi': 'अतिदेय',
      'en': 'Overdue',
    },
    'wing_block': {
      'gu': 'વિંગ / બ્લોક',
      'hi': 'विंग/ब्लॉक',
      'en': 'Wing / block',
    },
    'street_line': {
      'gu': 'શેરી / લાઇન',
      'hi': 'सड़क/रेखा',
      'en': 'Street / Line',
    },
    'floor_block': {
      'gu': 'ફ્લોર / બ્લોક',
      'hi': 'फर्श/ब्लॉक',
      'en': 'Floor / Block',
    },
    'block_street': {
      'gu': 'બ્લોક / શેરી',
      'hi': 'ब्लॉक/स्ट्रीट',
      'en': 'Block / Street',
    },
    'wing_zone': {
      'gu': 'વિંગ / ઝોન',
      'hi': 'विंग/जोन',
      'en': 'Wing / Zone',
    },
    'wing_2': {
      'gu': 'વિંગ',
      'hi': 'विंग',
      'en': 'Wing',
    },
    'floor': {
      'gu': 'ફ્લોર',
      'hi': 'मंज़िल',
      'en': 'floor',
    },
    'flat_no_2': {
      'gu': 'ફ્લેટ નં.',
      'hi': 'फ़्लैट नं.',
      'en': 'Flat no.',
    },
    'building_plot_no': {
      'gu': 'મકાન / પ્લોટ નં.',
      'hi': 'भवन/प्लॉट नं.',
      'en': 'Building / Plot no.',
    },
    'shop_office_no': {
      'gu': 'દુકાન / ઓફિસ નં.',
      'hi': 'दुकान/कार्यालय नं.',
      'en': 'Shop / Office No.',
    },
    'unit_no': {
      'gu': 'યુનિટ નં.',
      'hi': 'यूनिट नं.',
      'en': 'Unit No.',
    },
    'unit_no_shopflat': {
      'gu': 'યુનિટ નં. (શોપ/ફ્લેટ)',
      'hi': 'इकाई संख्या (दुकान/फ्लैट)',
      'en': 'Unit No. (Shop/Flat)',
    },
    'shopoffice': {
      'gu': 'દુકાન/ઓફિસ',
      'hi': 'दुकान/कार्यालय',
      'en': 'Shop/Office',
    },
    'unit_2': {
      'gu': 'યુનિટ',
      'hi': 'इकाई',
      'en': 'unit',
    },
    'will_stay': {
      'gu': 'રહીશ',
      'hi': 'रहेगा',
      'en': 'will stay',
    },
    'merchant_shopkeeper': {
      'gu': 'વેપારી / દુકાનદાર',
      'hi': 'व्यापारी/दुकानदार',
      'en': 'Merchant / Shopkeeper',
    },
    'member_trader': {
      'gu': 'સભ્ય / વેપારી',
      'hi': 'सदस्य/व्यापारी',
      'en': 'Member / Trader',
    },
    'resident_shopkeeper': {
      'gu': 'રહીશ / દુકાનદાર',
      'hi': 'निवासी/दुकानदार',
      'en': 'Resident / Shopkeeper',
    },
    'society_president': {
      'gu': 'સોસાયટી પ્રમુખ',
      'hi': 'सोसायटी अध्यक्ष',
      'en': 'Society President',
    },
    'president_of_the_chamber_of_commerce': {
      'gu': 'વેપારી મંડળ પ્રમુખ',
      'hi': 'चैंबर ऑफ कॉमर्स के अध्यक्ष',
      'en': 'President of the Chamber of Commerce',
    },
    'chief_president': {
      'gu': 'મુખ્ય પ્રમુખ',
      'hi': 'प्रमुख अध्यक्ष',
      'en': 'Chief President',
    },
    'wing_apartment': {
      'gu': '🏢 વિંગ / એપાર્ટમેન્ટ',
      'hi': '🏢 विंग/अपार्टमेंट',
      'en': '🏢 Wing / Apartment',
    },
    'street_bungalow': {
      'gu': '🏡 શેરી / બંગલો',
      'hi': '🏡गली/बंगला',
      'en': '🏡 Street / Bungalow',
    },
    'shopping_mall_market_2': {
      'gu': '🏬 શોપિંગ મોલ / માર્કેટ',
      'hi': '🏬 शॉपिंग मॉल/बाजार',
      'en': '🏬 Shopping Mall / Market',
    },
    'mixed_shop_flats': {
      'gu': '🏙️ મિક્સ્ડ (દુકાન + ફ્લેટ્સ)',
      'hi': '🏙️ मिश्रित (दुकान + फ्लैट)',
      'en': '🏙️ Mixed (Shop + Flats)',
    },
    'street_rowhouse': {
      'gu': '🏡 શેરી / રો-હાઉસ',
      'hi': '🏡स्ट्रीट/रो-हाउस',
      'en': '🏡 Street / Row-house',
    },
    'shopping_commercial': {
      'gu': '🏬 શોપિંગ / કોમર્શિયલ',
      'hi': '🏬 शॉपिंग/वाणिज्यिक',
      'en': '🏬 Shopping / Commercial',
    },
    'mixed_shop_flat': {
      'gu': '🏙️ મિક્સ્ડ (દુકાન + ફ્લેટ)',
      'hi': '🏙️ मिश्रित (दुकान + फ्लैट)',
      'en': '🏙️ Mixed (Shop + Flat)',
    },
    'shop_4': {
      'gu': 'શોપ',
      'hi': 'दुकान',
      'en': 'shop',
    },
    'street1': {
      'gu': 'શેરી-૧',
      'hi': 'गली-1',
      'en': 'Street-1',
    },
    'society_as_a_whole_common': {
      'gu': 'સમગ્ર સોસાયટી (કોમન)',
      'hi': 'समग्र रूप से समाज (सामान्य)',
      'en': 'Society as a Whole (Common)',
    },
    'upi_qr_online': {
      'gu': 'UPI / QR ઓનલાઇન',
      'hi': 'यूपीआई/क्यूआर ऑनलाइन',
      'en': 'UPI / QR online',
    },
    'bank_transfer_neftimps': {
      'gu': 'બેંક ટ્રાન્સફર (NEFT/IMPS)',
      'hi': 'बैंक स्थानांतरण (एनईएफटी/आईएमपीएस)',
      'en': 'Bank Transfer (NEFT/IMPS)',
    },
    'expenses': {
      'gu': 'ખર્ચ',
      'hi': 'व्यय',
      'en': 'expenses',
    },
    'all_society_4': {
      'gu': 'આખી સોસાયટી (All)',
      'hi': 'सर्व समाज',
      'en': 'All Society',
    },
    'no_emergency_numbers_have_been_added_3': {
      'gu': 'હજુ સુધી કોઈ ઈમરજન્સી નંબર ઉમેરાયો નથી.\\nઉપરના પ્રીસેટ પર ટેપ કરીને નંબર ઉમેરો.',
      'hi': 'अभी तक कोई आपातकालीन नंबर नहीं जोड़ा गया है।\\nउपरोक्त प्रीसेट पर टैप करके एक नंबर जोड़ें।',
      'en': 'No emergency numbers have been added yet.\\nAdd a number by tapping on the preset above.',
    },
    'members_can_scan_this_qr_from_2': {
      'gu': 'મેમ્બર તેમના મોબાઈલની કોઈપણ UPI એપ\\n(Google Pay, PhonePe, Paytm, BHIM)\\nથી આ QR સ્કેન કરી શકે છે.',
      'hi': 'सदस्य इस QR को अपने मोबाइल पर किसी भी UPI ऐप\\n(Google Pay, PhonePe, Paytm, BHIM)\\n से स्कैन कर सकते हैं।',
      'en': 'Members can scan this QR from any UPI app\\n(Google Pay, PhonePe, Paytm, BHIM)\\n on their mobile.',
    },
    'click_on_the_following_link_to_2': {
      'gu': 'ઓનલાઇન UPI થી ચૂકવવા નીચેની લિંક પર ક્લિક કરો:\\n',
      'hi': 'UPI से ऑनलाइन भुगतान करने के लिए निम्नलिखित लिंक पर क्लिक करें:\\n',
      'en': 'Click on the following link to pay online with UPI:\\n',
    },
    'no_common_plot_slots_have_been_2': {
      'gu': 'હજુ સુધી કોઈ કોમન પ્લોટ સ્લોટ્સ બનાવવામાં આવ્યા નથી.\\n(શેરી સોસાયટીમાં દરેક સભ્ય ઘર આગળ પાર્ક કરે છે).',
      'hi': 'अभी तक कोई सामान्य प्लॉट स्लॉट नहीं बनाया गया है।\\n(एक सड़क सोसायटी में प्रत्येक सदस्य घर के सामने पार्क करता है)।',
      'en': 'No common plot slots have been created yet.\\n(In a street society every member parks in front of the house).',
    },
    'no_wings_slots_have_been_created_2': {
      'gu': 'હજુ સુધી કોઈ વિંગ્સ સ્લોટ્સ બનાવવામાં આવ્યા નથી.\\nઉપરના બટનથી સ્લોટ્સ જનરેટ કરો.',
      'hi': 'अभी तक कोई विंग स्लॉट नहीं बनाया गया है।\\nऊपर दिए गए बटन से स्लॉट जेनरेट करें।',
      'en': 'No wings slots have been created yet.\\nGenerate slots with the button above.',
    },
    'txt_1_clicking_open_upi_app_below_2': {
      'gu': '૧. નીચે "UPI એપ ખોલો" દબાવતા Google Pay / PhonePe ખુલશે.\\n',
      'hi': '1. नीचे "ओपन यूपीआई ऐप" पर क्लिक करने पर Google Pay/PhonePe खुल जाएगा।\\n',
      'en': '1. Clicking "Open UPI App" below will open Google Pay / PhonePe.\\n',
    },
    'txt_2_paste_this_copied_id_in_2': {
      'gu': '૨. એપમાં "Pay UPI ID" અથવા Search બારમાં આ કૉપી કરેલ ID Paste કરો.\\n',
      'hi': '2. इस कॉपी की गई आईडी को "पे यूपीआई आईडी" या ऐप में सर्च बार में पेस्ट करें।\\n',
      'en': '2. Paste this copied ID in "Pay UPI ID" or Search bar in the app.\\n',
    },
    'txt_3_npci_bank_server_will_directly_2': {
      'gu': '૩. NPCI બેંક સર્વર સીધું જ રજીસ્ટર્ડ બેંક ખાતાધારકનું સાચું નામ (Verified Name) બતાવશે.\\n',
      'hi': '3. एनपीसीआई बैंक सर्वर सीधे पंजीकृत बैंक खाताधारक का सत्यापित नाम दिखाएगा।\\n',
      'en': '3. NPCI Bank server will directly show the Verified Name of the registered bank account holder.\\n',
    },
    'your_society_is_peaceful_and_wellorderednif_2': {
      'gu': 'તમારી સોસાયટી શાંતિપૂર્ણ અને સુવ્યવસ્થિત છે.\\nજો કોઈ પ્રશ્ન જણાય તો ઉપરથી સરળતાથી નોંધાવો.',
      'hi': 'आपका समाज शांतिपूर्ण और सुव्यवस्थित है।\\nयदि आपके कोई प्रश्न हैं, तो बस ऊपर से पंजीकरण करें।',
      'en': 'Your society is peaceful and well-ordered.\\nIf you have any query, simply register from above.',
    },
    'type_your_message_herenn_2': {
      'gu': '[અહીં તમારો સંદેશો લખો]\\n\\n',
      'hi': '[अपना संदेश यहां टाइप करें]\\n\\n',
      'en': '[Type your message here]\\n\\n',
    },
    'thank_youn_2': {
      'gu': 'આભાર,\\n',
      'hi': 'धन्यवाद,\\n',
      'en': 'Thank you,\\n',
    },
    'chief_society_admin': {
      'gu': 'ચીફ સોસાયટી એડમિન (Chief Admin)',
      'hi': 'मुख्य सोसायटी प्रशासन',
      'en': 'Chief Society Admin',
    },
    'encrypted_for_security_set_a_new': {
      'gu': 'સુરક્ષા માટે એન્ક્રિપ્ટેડ (ઈમેલ પર મોકલેલ પાસવર્ડ રીસેટ લિંકથી નવો પાસવર્ડ સેટ કરો)',
      'hi': 'सुरक्षा के लिए एन्क्रिप्ट किया गया (ईमेल पर भेजे गए पासवर्ड रीसेट लिंक से एक नया पासवर्ड सेट करें)',
      'en': 'Encrypted for security (set a new password from the password reset link sent to the email)',
    },
    'encrypted_for_security_set_from_password': {
      'gu': 'સુરક્ષા માટે એન્ક્રિપ્ટેડ (ઈમેલ પર મોકલેલ પાસવર્ડ રીસેટ લિંક પરથી સેટ કરો)',
      'hi': 'सुरक्षा के लिए एन्क्रिप्टेड (ईमेल पर भेजे गए पासवर्ड रीसेट लिंक से सेट)',
      'en': 'Encrypted for security (set from password reset link sent to email)',
    },
    'commercial_mall_shopping_centre': {
      'gu': '🛍️ કોમર્શિયલ મોલ / શોપિંગ સેન્ટર',
      'hi': '🛍️कमर्शियल मॉल/शॉपिंग सेंटर',
      'en': '🛍️ Commercial Mall / Shopping Centre',
    },
    'hybrid_mixed_premises': {
      'gu': '🏢 હાઇબ્રિડ / મિક્સ્ડ પરિસર',
      'hi': '🏢संकर/मिश्रित परिसर',
      'en': '🏢 Hybrid / Mixed premises',
    },
    'bungalow_rowhouse_society': {
      'gu': '🏡 બંગલો / રો-હાઉસ સોસાયટી',
      'hi': '🏡बंगला/रो-हाउस सोसायटी',
      'en': '🏡 Bungalow / Row-House Society',
    },
    'residency_wing_society': {
      'gu': '🏙️ રેસીડેન્સી / વિંગ સોસાયટી',
      'hi': '🏙️रेजीडेंसी/विंग सोसायटी',
      'en': '🏙️ Residency / Wing Society',
    },
    'new_amenity_booking': {
      'gu': '🏛️ નવું એમેનિટી બુકિંગ',
      'hi': '🏛️ नई सुविधा बुकिंग',
      'en': '🏛️ New Amenity Booking',
    },
    'hall': {
      'gu': 'હોલ',
      'hi': 'हॉल',
      'en': 'Hall',
    },
    'amenity_booking_approved': {
      'gu': '🎉 એમેનિટી બુકિંગ મંજૂર થયું!',
      'hi': '🎉सुविधा बुकिंग स्वीकृत!',
      'en': '🎉 Amenity Booking Approved!',
    },
    'todays_events': {
      'gu': 'આજની ઇવેન્ટ્સ',
      'hi': 'आज की घटनाएँ',
      'en': 'Today\'s events',
    },
    'main_entrance_gate': {
      'gu': 'મુખ્ય પ્રવેશ દ્વાર (Main Entrance Gate)',
      'hi': 'मुख्य प्रवेश द्वार',
      'en': 'Main Entrance Gate',
    },
    'ground_floor_opposite_security_cabin': {
      'gu': 'ગ્રાઉન્ડ ફ્લોર - સિક્યોરિટી કેબિન સામે',
      'hi': 'भूतल - सुरक्षा केबिन के सामने',
      'en': 'Ground Floor - Opposite Security Cabin',
    },
    'wing_a_b_terrace_entrance_door': {
      'gu': 'વિંગ A & B ટેરેસ પ્રવેશ દ્વાર (Terrace Door)',
      'hi': 'विंग ए एवं बी छत प्रवेश द्वार',
      'en': 'Wing A & B Terrace Entrance Door',
    },
    'top_floor_near_terrace_stairs': {
      'gu': 'ટોપ ફ્લોર - ટેરેસ સીડી પાસે',
      'hi': 'सबसे ऊपरी मंजिल - छत की सीढ़ियों के पास',
      'en': 'Top Floor - Near Terrace Stairs',
    },
    'basement_parking_b1_basement_parking': {
      'gu': 'બેઝમેન્ટ પાર્કિંગ B1 (Basement Parking)',
      'hi': 'बेसमेंट पार्किंग बी1 (बेसमेंट पार्किंग)',
      'en': 'Basement Parking B1 (Basement Parking)',
    },
    'basement_pillar_no_near_05': {
      'gu': 'બેઝમેન્ટ - પિલર નં. ૦૫ પાસે',
      'hi': 'तहखाना - स्तम्भ नं. 05 के पास',
      'en': 'Basement - Pillar no. Near 05',
    },
    'generator_and_power_panel_room_electric': {
      'gu': 'જનરેટર અને પાવર પેનલ રૂમ (Electric Room)',
      'hi': 'जेनरेटर और पावर पैनल रूम (इलेक्ट्रिक रूम)',
      'en': 'Generator and Power Panel Room (Electric Room)',
    },
    'garden_perimeter': {
      'gu': 'ગાર્ડન અને પાછળનો પેરીમીટર (Garden & Perimeter)',
      'hi': 'उद्यान एवं परिधि',
      'en': 'Garden & Perimeter',
    },
    'back_boundary_wall_corner_2': {
      'gu': 'પાછળની બાઉન્ડ્રી વોલ - કોર્નર ૨',
      'hi': 'पीछे की सीमा दीवार - कोना 2',
      'en': 'Back Boundary Wall - Corner 2',
    },
    'this_qr_code_is_not_a': {
      'gu': 'આ QR કોડ પેટ્રોલિંગ ચેકપોઇન્ટનો નથી!',
      'hi': 'यह क्यूआर कोड कोई गश्ती चौकी नहीं है!',
      'en': 'This QR code is not a patrol checkpoint!',
    },
    'this_qr_code_belongs_to_another': {
      'gu': 'આ QR કોડ અન્ય સોસાયટીનો છે!',
      'hi': 'यह QR कोड दूसरे समाज का है!',
      'en': 'This QR code belongs to another society!',
    },
    'patrol_session_could_not_be_found': {
      'gu': 'પેટ્રોલિંગ સેશન મળી શક્યું નથી!',
      'hi': 'गश्ती सत्र नहीं मिल सका!',
      'en': 'Patrol session could not be found!',
    },
    'security_patrols_are_not_set_up': {
      'gu': 'સુરક્ષા પેટ્રોલિંગ સેટ કરેલ નથી',
      'hi': 'सुरक्षा गश्ती दल स्थापित नहीं किये गये हैं',
      'en': 'Security patrols are not set up',
    },
    'tonights_night_patrol_will_start_from': {
      'gu': 'આજનું રાત્રિ પેટ્રોલિંગ ૧૧:૦૦ PM થી શરૂ થશે 🛡️',
      'hi': 'आज रात की गश्त रात्रि 11:00 बजे से प्रारंभ होगी 🛡️',
      'en': 'Tonight\'s night patrol will start from 11:00 PM 🛡️',
    },
    'gujarati': {
      'gu': 'ગુજરાતી',
      'hi': 'गुजराती',
      'en': 'Gujarati',
    },
    'default_local_language': {
      'gu': 'ડિફૉલ્ટ સ્થાનિક ભાષા',
      'hi': 'डिफ़ॉल्ट स्थानीय भाषा',
      'en': 'Default local language',
    },
    'successfully_paid': {
      'gu': 'સફળતાપૂર્વક ચૂકવેલ',
      'hi': 'सफलतापूर्वक भुगतान किया गया',
      'en': 'Successfully paid',
    },
    'pending_payment': {
      'gu': 'ચુકવણી બાકી',
      'hi': 'भुगतान लंबित है',
      'en': 'Pending payment',
    },
    'successfully_paid_verified': {
      'gu': 'સફળતાપૂર્વક ચૂકવેલ - VERIFIED',
      'hi': 'सफलतापूर्वक भुगतान किया गया - सत्यापित',
      'en': 'Successfully paid - VERIFIED',
    },
    'payment_due_due': {
      'gu': 'ચુકવણી બાકી - DUE',
      'hi': 'देय भुगतान - देय',
      'en': 'Payment Due - DUE',
    },
    'owner_2': {
      'gu': 'Owner (માલિક)',
      'hi': 'मालिक',
      'en': 'Owner',
    },
    'admin_2': {
      'gu': 'Admin (એડમિન)',
      'hi': 'व्यवस्थापक',
      'en': 'Admin',
    },
    'tenant_2': {
      'gu': 'Tenant (ભાડુઆત)',
      'hi': 'किरायेदार',
      'en': 'Tenant',
    },
    'society_president_secretary': {
      'gu': 'સોસાયટી પ્રમુખ / સેક્રેટરી',
      'hi': 'सोसायटी अध्यक्ष/सचिव',
      'en': 'Society President / Secretary',
    },
    'official_receipt_of_maintenance_payment': {
      'gu': 'મેન્ટેનન્સ ચુકવણી સત્તાવાર રસીદ',
      'hi': 'रखरखाव भुगतान की आधिकारिक रसीद',
      'en': 'Official Receipt of Maintenance Payment',
    },
    'maintenance_payment_demand_form': {
      'gu': 'મેન્ટેનન્સ ચુકવણી માંગણી પત્રક',
      'hi': 'रखरखाव भुगतान मांग प्रपत्र',
      'en': 'Maintenance Payment Demand Form',
    },
    'successfully_authenticated': {
      'gu': 'સફળતાપૂર્વક પ્રમાણિત',
      'hi': 'सफलतापूर्वक प्रमाणित किया गया',
      'en': 'Successfully authenticated',
    },
    'unpaid': {
      'gu': 'ચુકવણી બાકી (UNPAID)',
      'hi': 'अवैतनिक',
      'en': 'UNPAID',
    },
    'member_unit_details': {
      'gu': 'MEMBER & UNIT DETAILS (સભ્ય અને ફ્લેટ વિગત)',
      'hi': 'सदस्य एवं इकाई विवरण',
      'en': 'MEMBER & UNIT DETAILS',
    },
    'charges_settlement_breakdown_payment_account_detail': {
      'gu': 'CHARGES & SETTLEMENT BREAKDOWN (ચુકવણી હિસાબ વિગત)',
      'hi': 'शुल्क एवं निपटान विवरण (भुगतान खाता विवरण)',
      'en': 'CHARGES & SETTLEMENT BREAKDOWN (Payment Account Detail)',
    },
    'particulars': {
      'gu': 'PARTICULARS (વિગત)',
      'hi': 'विवरण',
      'en': 'PARTICULARS',
    },
    'period': {
      'gu': 'PERIOD (મુદત)',
      'hi': 'अवधि',
      'en': 'PERIOD',
    },
    'amount_2': {
      'gu': 'AMOUNT (રકમ)',
      'hi': 'राशि',
      'en': 'AMOUNT',
    },
    'late_fee_penalty': {
      'gu': 'Late Fee / Penalty (દંડ)',
      'hi': 'विलंब शुल्क/जुर्माना',
      'en': 'Late Fee / Penalty',
    },
    'festival_contribution': {
      'gu': 'Festival Contribution (તહેવાર ફાળો)',
      'hi': 'महोत्सव योगदान',
      'en': 'Festival Contribution',
    },
    'total_amount_paid': {
      'gu': 'TOTAL AMOUNT PAID (કુલ ચૂકવેલ રકમ):',
      'hi': 'कुल भुगतान राशि:',
      'en': 'TOTAL AMOUNT PAID:',
    },
    'total_amount_due_2': {
      'gu': 'TOTAL AMOUNT DUE (કુલ બાકી રકમ):',
      'hi': 'कुल बकाया राशि:',
      'en': 'TOTAL AMOUNT DUE:',
    },
    'successfully_deposited_verified': {
      'gu': 'સફળતાપૂર્વક જમા (VERIFIED)',
      'hi': 'सफलतापूर्वक जमा किया गया (सत्यापित)',
      'en': 'Successfully deposited (VERIFIED)',
    },
    'payment_pending_2': {
      'gu': 'ચુકવણી બાકી (PENDING)',
      'hi': 'भुगतान लंबित है',
      'en': 'Payment Pending',
    },
    'official_society_notice': {
      'gu': 'સત્તાવાર સોસાયટી નોંધ (Official Notice):',
      'hi': 'आधिकारिक सोसायटी सूचना:',
      'en': 'Official Society Notice:',
    },
    'authorized_digital_signature': {
      'gu': 'અધિકૃત ડિજિટલ સહી (Authorized)',
      'hi': 'अधिकृत डिजिटल हस्ताक्षर',
      'en': 'Authorized Digital Signature',
    },
    'festival_fund': {
      'gu': 'તહેવાર ફંડ',
      'hi': 'महोत्सव निधि',
      'en': 'Festival Fund',
    },
    'maintenance_receipt': {
      'gu': 'મેન્ટેનન્સ રસીદ (Receipt)',
      'hi': 'रखरखाव रसीद',
      'en': 'Maintenance Receipt',
    },
    'download_the_pdf': {
      'gu': 'PDF ડાઉનલોડ કરો',
      'hi': 'पीडीएफ डाउनलोड करें',
      'en': 'Download the PDF',
    },
    'preparing_digital_receipt': {
      'gu': 'ડિજિટલ રસીદ તૈયાર થઈ રહી છે...',
      'hi': 'डिजिटल रसीद तैयार की जा रही है...',
      'en': 'Preparing digital receipt...',
    },
    'to_pay_on_society_upi_id': {
      'gu': '💳 *સોસાયટી UPI ID પર ચૂકવણી કરવા:*',
      'hi': '💳 *सोसाइटी यूपीआई आईडी पर भुगतान करने के लिए:*',
      'en': '💳 *To pay on Society UPI ID:*',
    },
    'instant_1tap_upi_payment_link': {
      'gu': '🔗 *તત્કાલ ૧-ટૅપ UPI ચુકવણી લિંક:*',
      'hi': '🔗 *तत्काल 1-टैप UPI भुगतान लिंक:*',
      'en': '🔗 *Instant 1-Tap UPI Payment Link:*',
    },
    'you_can_also_open_my_building': {
      'gu': '📲 આપ *My Building Guard* એપ ખોલીને પણ સીધા QR કોડથી પેમેન્ટ કરી તુરંત પાકી PDF રસીદ મેળવી શકો છો.',
      'hi': '📲 आप *माई बिल्डिंग गार्ड* ऐप भी खोल सकते हैं और सीधे क्यूआर कोड से भुगतान कर सकते हैं और तुरंत पीडीएफ रसीद प्राप्त कर सकते हैं।',
      'en': '📲 You can also open *My Building Guard* app and pay directly with QR code and get instant PDF receipt.',
    },
    'if_this_amount_has_been_paid': {
      'gu': 'જો આપ દ્વારા આ રકમ ચૂકવાઈ ગઈ હોય, તો કૃપા કરીને આ મેસેજને અવગણશો.',
      'hi': 'यदि यह राशि आपके द्वारा भुगतान की गई है, तो कृपया इस संदेश पर ध्यान न दें।',
      'en': 'If this amount has been paid by you, please ignore this message.',
    },
    'thanks_co': {
      'gu': 'આભાર સહ,',
      'hi': 'धन्यवाद सह,',
      'en': 'thanks co,',
    },
    'this_members_mobile_number_is_not': {
      'gu': 'આ સભ્યનો મોબાઈલ નંબર નોંધાયેલ નથી.',
      'hi': 'इस सदस्य का मोबाइल नंबर पंजीकृत नहीं है.',
      'en': 'This member\'s mobile number is not registered.',
    },
    'having_trouble_opening_whatsapp_please_check': {
      'gu': 'WhatsApp ખોલવામાં મુશ્કેલી આવી. કૃપા કરીને ચેક કરો કે એપ ઇન્સ્ટોલ છે.',
      'hi': 'व्हाट्सएप खोलने में दिक्कत हो रही है. कृपया जांचें कि ऐप इंस्टॉल है।',
      'en': 'Having trouble opening WhatsApp. Please check that the app is installed.',
    },
    'maintenance_bill_is_due': {
      'gu': '⚠️ મેન્ટેનન્સ બિલ બાકી છે',
      'hi': '⚠️मेंटेनेंस बिल बकाया है',
      'en': '⚠️ Maintenance bill is due',
    },
    'october_2026_maintenance': {
      'gu': 'ઓક્ટોબર ૨૦૨૬ મેન્ટેનન્સ',
      'hi': 'अक्टूबर 2026 रखरखाव',
      'en': 'October 2026 Maintenance',
    },
    'new_upi_maintenance_payment': {
      'gu': '💳 નવું UPI મેન્ટેનન્સ પેમેન્ટ',
      'hi': '💳 नया यूपीआई रखरखाव भुगतान',
      'en': '💳 New UPI Maintenance Payment',
    },
    'maintenance_payment_approved': {
      'gu': '✅ મેન્ટેનન્સ પેમેન્ટ મંજૂર',
      'hi': '✅ रखरखाव भुगतान स्वीकृत',
      'en': '✅ Maintenance payment approved',
    },
    'cash_2': {
      'gu': 'રોકડ',
      'hi': 'नकद',
      'en': 'Cash',
    },
    'check_2': {
      'gu': 'ચેક',
      'hi': 'जांचें',
      'en': 'Check',
    },
    'maintenance_receipt_generated': {
      'gu': '🧾 મેન્ટેનન્સ રસીદ જનરેટ થઈ',
      'hi': '🧾रखरखाव रसीद जनरेट हुई',
      'en': '🧾 Maintenance receipt generated',
    },
    'official_member_consent_register': {
      'gu': 'સત્તાવાર સભ્ય સંમતિ રજીસ્ટર',
      'hi': 'आधिकारिक सदस्य सहमति रजिस्टर',
      'en': 'Official member consent register',
    },
    'society_member_signature_sheet': {
      'gu': 'સોસાયટી સભ્ય સહી પત્રક',
      'hi': 'सोसायटी सदस्य हस्ताक्षर पत्रक',
      'en': 'Society member signature sheet',
    },
    'member_consent_signature_register': {
      'gu': 'સભ્ય સંમતિ / સહી પત્રક (MEMBER CONSENT & SIGNATURE REGISTER)',
      'hi': 'सदस्य सहमति एवं हस्ताक्षर रजिस्टर',
      'en': 'MEMBER CONSENT & SIGNATURE REGISTER',
    },
    'general_meeting_resolution_member_consent': {
      'gu': 'સામાન્ય સભા ઠરાવ / સભ્ય સંમતિ',
      'hi': 'सामान्य बैठक का संकल्प/सदस्य की सहमति',
      'en': 'General Meeting Resolution / Member Consent',
    },
    'subject_resolution_purpose': {
      'gu': 'વિષય / ઠરાવ હેતુ:',
      'hi': 'विषय/संकल्प उद्देश्य:',
      'en': 'Subject / Resolution Purpose:',
    },
    'reference_general_resolution': {
      'gu': 'સંદર્ભ: સામાન્ય ઠરાવ',
      'hi': 'संदर्भ: सामान्य संकल्प',
      'en': 'Reference: General Resolution',
    },
    'premises_all_units': {
      'gu': 'પરિસર: તમામ એકમો (All)',
      'hi': 'परिसर: सभी इकाइयाँ',
      'en': 'Premises: All Units',
    },
    'consent_conditions_note': {
      'gu': 'સંમતિ શરતો / નોંધ:',
      'hi': 'सहमति की शर्तें/नोट:',
      'en': 'Consent Conditions / Note:',
    },
    'wingblock': {
      'gu': 'વિંગ/બ્લોક',
      'hi': 'विंग/ब्लॉक',
      'en': 'Wing/Block',
    },
    'flatshop': {
      'gu': 'ફ્લેટ/દુકાન',
      'hi': 'फ्लैट/दुकान',
      'en': 'Flat/Shop',
    },
    'name_of_member': {
      'gu': 'સભ્યનું નામ',
      'hi': 'सदस्य का नाम',
      'en': 'Name of member',
    },
    'consent_opinion': {
      'gu': 'સંમતિ / મંતવ્ય',
      'hi': 'सहमति/राय',
      'en': 'Consent / Opinion',
    },
    'members_signature': {
      'gu': 'સભ્યની સહી (Sign)',
      'hi': 'सदस्य के हस्ताक्षर',
      'en': 'Member\'s Signature',
    },
    'agree': {
      'gu': 'સંમત',
      'hi': 'सहमत',
      'en': 'agree',
    },
    'signature_of_committee_member': {
      'gu': 'કમિટી સભ્યની સહી',
      'hi': 'समिति सदस्य के हस्ताक्षर',
      'en': 'Signature of Committee Member',
    },
    'signature_of_secretary_minister': {
      'gu': 'સેક્રેટરી / મંત્રીની સહી',
      'hi': 'सचिव/मंत्री के हस्ताक्षर',
      'en': 'Signature of Secretary / Minister',
    },
    'chairman_president_coin': {
      'gu': 'ચેરમેન / પ્રમુખ & સિક્કો',
      'hi': 'अध्यक्ष/अध्यक्ष एवं सिक्का',
      'en': 'Chairman / President & Coin',
    },
    'parking_slot_alert': {
      'gu': 'પાર્કિંગ સ્લોટ એલર્ટ',
      'hi': 'पार्किंग स्लॉट चेतावनी',
      'en': 'Parking slot alert',
    },
    'i_remove_the_car': {
      'gu': 'હું ગાડી હટાવી લઉં છું',
      'hi': 'मैं कार हटाता हूं',
      'en': 'I remove the car',
    },
    'get_emergency_sos_alert': {
      'gu': '🚨 ગેટ ઇમરજન્સી SOS એલર્ટ!',
      'hi': '🚨 आपातकालीन एसओएस अलर्ट प्राप्त करें!',
      'en': '🚨 Get Emergency SOS Alert!',
    },
    'security_assistance_is_urgently_needed_at': {
      'gu': 'ગેટ પર સુરક્ષા સહાયતાની તાત્કાલિક જરૂર છે.',
      'hi': 'गेट पर सुरक्षा सहायता की तत्काल आवश्यकता है।',
      'en': 'Security assistance is urgently needed at the gate.',
    },
    'contact_the_watchman_or_security_cabin': {
      'gu': 'વોચમેન અથવા સિક્યોરિટી કેબિનનો તાત્કાલિક સંપર્ક કરો.',
      'hi': 'तुरंत चौकीदार या सुरक्षा केबिन से संपर्क करें।',
      'en': 'Contact the watchman or security cabin immediately.',
    },
    'i_saw_the_alert_dismiss': {
      'gu': 'મેં એલર્ટ જોયો (Dismiss)',
      'hi': 'मैंने अलर्ट (ख़ारिज) देखा।',
      'en': 'I saw the alert (Dismiss).',
    },
    'official_head_office_notice': {
      'gu': 'સત્તાવાર હેડ ઓફિસ નોટિસ',
      'hi': 'आधिकारिक प्रधान कार्यालय सूचना',
      'en': 'Official Head Office Notice',
    },
    'super_admin_notification': {
      'gu': 'સુપર એડમિન સૂચના',
      'hi': 'सुपर एडमिन अधिसूचना',
      'en': 'Super Admin Notification',
    },
    'an_important_notification_has_been_issued': {
      'gu': 'હેડ ઓફિસ તરફથી અગત્યની સૂચના આપવામાં આવી છે.',
      'hi': 'मुख्यालय से एक महत्वपूर्ण अधिसूचना जारी की गयी है.',
      'en': 'An important notification has been issued from the head office.',
    },
    'acknowledge': {
      'gu': 'સમજાઈ ગયું (Acknowledge)',
      'hi': 'स्वीकार करें',
      'en': 'Acknowledge',
    },
    'reply_from_super_admin': {
      'gu': 'સુપર એડમિન તરફથી જવાબ',
      'hi': 'सुपर एडमिन से उत्तर',
      'en': 'Reply from super admin',
    },
    'your_societys_appeal_has_been_replied': {
      'gu': 'તમારી સોસાયટીની અપીલ અંગે સુપર એડમિન દ્વારા પ્રત્યુત્તર આપવામાં આવ્યો છે.',
      'hi': 'आपकी सोसायटी की अपील का उत्तर सुपर एडमिन द्वारा दे दिया गया है।',
      'en': 'Your society\'s appeal has been replied by Super Admin.',
    },
    'got_it_ok': {
      'gu': 'સમજાઈ ગયું (OK)',
      'hi': 'समझ गया (ठीक है)',
      'en': 'Got it (OK)',
    },
    'fcm_titlemessage_not_found_notification_or': {
      'gu': 'FCM: શીર્ષક/સંદેશ ન મળ્યો (notification અથવા data.title/body)',
      'hi': 'एफसीएम: शीर्षक/संदेश नहीं मिला (अधिसूचना या डेटा.शीर्षक/बॉडी)',
      'en': 'FCM: title/message not found (notification or data.title/body)',
    },
    'push_not_confirmed_functions_are_usually': {
      'gu': 'પુશની પુષ્ટિ મળી નહીં. સામાન્ય રીતે Firebase પર Functions ડિપ્લોય થયેલા નથી અથવા સર્વર ધીમો છે — એડમિન/ડેવલપરને તપાસ કરાવો. મેમ્બર એપ ખોલી નોટિફિકેશન પરવાનગી આપે તે પણ જરૂરી છે.',
      'hi': 'पुश की पुष्टि नहीं हुई. फ़ंक्शंस आमतौर पर फ़ायरबेस पर तैनात नहीं होते हैं या सर्वर धीमा होता है - व्यवस्थापक/डेवलपर से जांच करवाएं। सदस्य के लिए ऐप खोलना और नोटिफिकेशन की अनुमति देना भी जरूरी है।',
      'en': 'Push not confirmed. Functions are usually not deployed on Firebase or the server is slow — have an admin/developer check. It is also necessary for the member to open the app and allow notifications.',
    },
    'server_push_confirmation_not_received_cloud': {
      'gu': 'સર્વર પુશની પુષ્ટિ મળી નહીં — Cloud Function `sendNotification` ચાલતું હોવું જોઈએ. ટર્મિનલ: firebase deploy --only functions',
      'hi': 'सर्वर पुश पुष्टिकरण प्राप्त नहीं हुआ - क्लाउड फ़ंक्शन `sendNotification` चालू होना चाहिए। टर्मिनल: फायरबेस परिनियोजन--केवल फ़ंक्शन',
      'en': 'Server push confirmation not received — Cloud Function `sendNotification` must be running. Terminal: firebase deploy --only functions',
    },
    'push_sent_to_members_phone_fcm': {
      'gu': 'મેમ્બરના ફોન પર પુશ મોકલાયો (FCM સ્વીકાર્યું). સ્ક્રીન પર ન દેખાય તો ફોનની નોટિફિકેશન પરવાનગી તપાસો.',
      'hi': 'सदस्य के फोन पर पुश भेजा गया (एफसीएम स्वीकृत)। यदि फ़ोन स्क्रीन पर दिखाई नहीं देता है तो उसकी अधिसूचना अनुमति की जाँच करें।',
      'en': 'Push sent to member\'s phone (FCM accepted). Check the phone\'s notification permission if it doesn\'t appear on the screen.',
    },
    'push_sent_to_all_members_topic': {
      'gu': 'બધા મેમ્બર્સને પુશ મોકલાયો (ટોપિક અથવા સીધા ફોન ટોકન).',
      'hi': 'सभी सदस्यों को पुश भेजा गया (विषय या प्रत्यक्ष फ़ोन टोकन)।',
      'en': 'Push sent to all members (topic or direct phone token).',
    },
    'push_sent_to_admin': {
      'gu': 'એડમિનને પુશ મોકલાયો.',
      'hi': 'पुश एडमिन को भेजा गया.',
      'en': 'Push sent to admin.',
    },
    'a_push_was_sent_to_the_2': {
      'gu': 'વોચમેનને પુશ મોકલાયો.',
      'hi': 'चौकीदार को एक धक्का भेजा गया।',
      'en': 'A push was sent to the watchman.',
    },
    'member_doesnt_have_a_phone_token_2': {
      'gu': 'મેમ્બર પાસે ફોન ટોકન નથી — એમને એપ એક વાર ખોલવા કહો.',
      'hi': 'सदस्य के पास फ़ोन टोकन नहीं है - उन्हें एक बार ऐप खोलने के लिए कहें।',
      'en': 'Member doesn\'t have a phone token — ask them to open the app once.',
    },
    'this_user_was_not_found_check': {
      'gu': 'આ યુઝર મળ્યો નથી — UID તપાસો.',
      'hi': 'यह उपयोगकर्ता नहीं मिला - यूआईडी जांचें।',
      'en': 'This user was not found — check the UID.',
    },
    'missing_title_or_message': {
      'gu': 'શીર્ષક કે સંદેશ ખૂટે છે.',
      'hi': 'गुम शीर्षक या संदेश.',
      'en': 'Missing title or message.',
    },
    'firestore_rules_unable_to_read_notifications': {
      'gu': 'Firestore rules: notifications ડોક વાંચી શકાતું નથી. Console માં મોકલનાર (senderId) ને read પરવાનગી આપો.',
      'hi': 'फ़ायरस्टोर नियम: अधिसूचना दस्तावेज़ पढ़ने में असमर्थ। कंसोल में प्रेषक (प्रेषकआईडी) को पढ़ने की अनुमति दें।',
      'en': 'Firestore rules: Unable to read notifications doc. Grant read permission to sender (senderId) in Console.',
    },
    'error_reading_notification_status_check_internet': {
      'gu': 'સૂચના સ્થિતિ વાંચવામાં ભૂલ — ઇન્ટરનેટ તપાસો.',
      'hi': 'अधिसूचना स्थिति पढ़ने में त्रुटि - इंटरनेट जांचें।',
      'en': 'Error reading notification status — check internet.',
    },
    'firestore_rules_notifications_cannot_be_read': {
      'gu': 'Firestore rules: notifications ડોક સર્વર પરથી વાંચી શકાતું નથી — મોકલનાર user ને read કરવા દો.',
      'hi': 'फायरस्टोर नियम: डॉक सर्वर से सूचनाएं नहीं पढ़ी जा सकतीं - भेजने वाले उपयोगकर्ता को पढ़ने दें।',
      'en': 'Firestore rules: notifications cannot be read from the doc server — let the sending user read.',
    },
    'basement_1_b1_2': {
      'gu': 'બેઝમેન્ટ - 1 (B1)',
      'hi': 'बेसमेंट - 1 (बी1)',
      'en': 'Basement - 1 (B1)',
    },
    'basement_2_b2_2': {
      'gu': 'બેઝમેન્ટ - 2 (B2)',
      'hi': 'बेसमेंट - 2 (बी2)',
      'en': 'Basement - 2 (B2)',
    },
    'basement_3_b3_2': {
      'gu': 'બેઝમેન્ટ - 3 (B3)',
      'hi': 'बेसमेंट - 3 (बी3)',
      'en': 'Basement - 3 (B3)',
    },
    'open_parking': {
      'gu': 'ઓપન પાર્કિંગ',
      'hi': 'खुली पार्किंग',
      'en': 'Open parking',
    },
    'loading_tempo_two': {
      'gu': 'લોડિંગ / ટેમ્પો બે',
      'hi': 'लोडिंग/टेम्पो दो',
      'en': 'Loading / Tempo Two',
    },
    'general': {
      'gu': 'જનરલ',
      'hi': 'सामान्य',
      'en': 'General',
    },
    'wadi_parking': {
      'gu': 'વાડી પાર્કિંગ',
      'hi': 'वाडी पार्किंग',
      'en': 'Wadi Parking',
    },
    'flathouse': {
      'gu': 'ફ્લેટ/મકાન',
      'hi': 'फ्लैट/घर',
      'en': 'Flat/House',
    },
    'at_home': {
      'gu': 'ઘર આંગણે',
      'hi': 'घर पर',
      'en': 'At home',
    },
    'near_home': {
      'gu': 'ઘર પાસે',
      'hi': 'घर के पास',
      'en': 'near home',
    },
    'against_the_plot': {
      'gu': 'પ્લોટ સામે',
      'hi': 'साजिश के खिलाफ',
      'en': 'Against the plot',
    },
    'road_side': {
      'gu': 'રોડ સાઇડ',
      'hi': 'सड़क के किनारे',
      'en': 'road side',
    },
    'please_enter_the_vehicle_number_plate': {
      'gu': 'કૃપા કરીને વાહન નંબર પ્લેટ દાખલ કરો',
      'hi': 'कृपया वाहन नंबर प्लेट दर्ज करें',
      'en': 'Please enter the vehicle number plate',
    },
    'the_number_plate_is_too_short': {
      'gu': 'નંબર પ્લેટ ખૂબ ટૂંકી છે (દા.ત. GJ 01 AB 1234)',
      'hi': 'नंबर प्लेट बहुत छोटी है (जैसे जीजे 01 एबी 1234)।',
      'en': 'The number plate is too short (eg GJ 01 AB 1234).',
    },
    'invalid_vehicle_number_has_too_many': {
      'gu': 'અમાન્ય વાહન નંબર (વધુ પડતા અક્ષરો છે)',
      'hi': 'अमान्य वाहन नंबर (बहुत अधिक अक्षर हैं)',
      'en': 'Invalid vehicle number (has too many characters)',
    },
    'invalid_number_plate_format_eg_gj': {
      'gu': 'અમાન્ય નંબર પ્લેટ ફોર્મેટ! (દા.ત. GJ 01 AB 1234)',
      'hi': 'अमान्य नंबर प्लेट प्रारूप! (जैसे जीजे 01 एबी 1234)',
      'en': 'Invalid number plate format! (eg GJ 01 AB 1234)',
    },
    'logged_in_to_another_device': {
      'gu': 'અન્ય ડિવાઇસમાં લૉગિન થયેલ છે',
      'hi': 'किसी अन्य डिवाइस में लॉग इन किया गया',
      'en': 'Logged in to another device',
    },
    'your_account_is_logged_in_on': {
      'gu': 'તમારું એકાઉન્ટ અન્ય ડિવાઇસ પર લૉગિન કરવામાં આવ્યું હોવાથી આ ડિવાઇસમાંથી સુરક્ષિત રીતે લૉગઆઉટ કરવામાં આવ્યું છે.\\n\\nસુરક્ષાના નિયમ મુજબ એક સમયે માત્ર ૧ જ ડિવાઇસમાં લૉગિન રહી શકાય છે.',
      'hi': 'आपका खाता किसी अन्य डिवाइस पर लॉग इन है और इस डिवाइस से सुरक्षित रूप से लॉग आउट कर दिया गया है।\\n\\nसुरक्षा नियमों के अनुसार, आप एक समय में केवल 1 डिवाइस में लॉग इन हो सकते हैं।',
      'en': 'Your account is logged in on another device and has been safely logged out of this device.\\n\\nAccording to security rules, you can only be logged in to 1 device at a time.',
    },
    'got_it_login': {
      'gu': 'સમજાઈ ગયું (લૉગિન કરો)',
      'hi': 'समझ गया (लॉगिन)',
      'en': 'Got it (login)',
    },
    'online': {
      'gu': 'ઓનલાઇન',
      'hi': 'ऑनलाइन',
      'en': 'Online',
    },
    'official_audit_account': {
      'gu': 'સત્તાવાર ઓડિટ હિસાબ',
      'hi': 'आधिकारिक लेखापरीक्षा खाता',
      'en': 'Official Audit Account',
    },
    'society_financial_statement_ledger': {
      'gu': 'સોસાયટી નાણાકીય ખાતાવહી & પાસબુક અહેવાલ (Financial Statement & Ledger)',
      'hi': 'सोसायटी वित्तीय विवरण एवं बही',
      'en': 'Society Financial Statement & Ledger',
    },
    'datewise_ledger_current_account': {
      'gu': 'તારીખવાર ખાતાવહી & ચાલુ સિલક',
      'hi': 'दिनांक-वार खाता बही और चालू खाता',
      'en': 'Date-wise ledger & current account',
    },
    'cost_wise_segmentation': {
      'gu': 'ખર્ચ મુજબ વિભાજન',
      'hi': 'लागत के अनुसार विभाजन',
      'en': 'Cost wise segmentation',
    },
    'total_income': {
      'gu': '(કુલ આવક)',
      'hi': '(कुल आय)',
      'en': '(Total Income)',
    },
    'total_cost': {
      'gu': '(કુલ ખર્ચ)',
      'hi': '(कुल लागत)',
      'en': '(Total Cost)',
    },
    'present_final_silak': {
      'gu': '(વર્તમાન આખર સિલક)',
      'hi': '(वर्तमान अंतिम सिलाक)',
      'en': '(Present Final Silak)',
    },
    'savings_reserve': {
      'gu': '(બચત અનામત)',
      'hi': '(बचत आरक्षित)',
      'en': '(savings reserve)',
    },
    'wrong_coin': {
      'gu': '(ખોટ સિલક)',
      'hi': '(गलत सिक्का)',
      'en': '(wrong coin)',
    },
    'society_secretary_treasurer': {
      'gu': 'સોસાયટી સેક્રેટરી / ખજાનચી',
      'hi': 'सोसायटी सचिव/कोषाध्यक्ष',
      'en': 'Society Secretary / Treasurer',
    },
    'ledger_detail_flat_paid_to': {
      'gu': 'ખાતાવહી વિગત / ફ્લેટ / કોને ચૂકવ્યા',
      'hi': 'खाता बही विवरण/फ्लैट/भुगतान किया हुआ',
      'en': 'Ledger Detail / Flat / Paid To',
    },
    'type_purpose': {
      'gu': 'પ્રકાર / હેતુ',
      'hi': 'प्रकार/उद्देश्य',
      'en': 'Type / Purpose',
    },
    'mod': {
      'gu': 'મોડ',
      'hi': 'मॉड',
      'en': 'Mod',
    },
    'deposit_income': {
      'gu': 'જમા આવક',
      'hi': 'जमा आय',
      'en': 'Deposit income',
    },
    'borrowing_costs': {
      'gu': 'ઉધાર ખર્ચ',
      'hi': 'उधार लेने की लागत',
      'en': 'Borrowing costs',
    },
    'current_silak_rs': {
      'gu': 'ચાલુ સિલક (Rs.)',
      'hi': 'वर्तमान सिलाक (रु.)',
      'en': 'Current Silak (Rs.)',
    },
    'expenditure_type': {
      'gu': 'ખર્ચ પ્રકાર',
      'hi': 'व्यय प्रकार',
      'en': 'Expenditure type',
    },
    'share_2': {
      'gu': 'હિસ્સો',
      'hi': 'साझा करें',
      'en': 'share',
    },
    'society_financial_statement_pdf': {
      'gu': 'સોસાયટી નાણાકીય સ્ટેટમેન્ટ (PDF)',
      'hi': 'सोसायटी वित्तीय विवरण (पीडीएफ)',
      'en': 'Society Financial Statement (PDF)',
    },
    'date_wise_ledger_passbook_is_being': {
      'gu': 'તારીખવાર ખાતાવહી & પાસબુક તૈયાર થઈ રહી છે...',
      'hi': 'तिथिवार बही-खाता और पासबुक तैयार किया जा रहा है...',
      'en': 'Date wise ledger & passbook is being prepared...',
    },
    'maintenance_festival_contribution': {
      'gu': 'મેન્ટેનન્સ + તહેવાર ફાળો',
      'hi': 'रखरखाव + उत्सव योगदान',
      'en': 'Maintenance + festival contribution',
    },
    'maintenance_income': {
      'gu': 'મેન્ટેનન્સ આવક',
      'hi': 'रखरखाव आय',
      'en': 'Maintenance income',
    },
    'please_write_an_appeal_message': {
      'gu': 'કૃપા કરીને અપીલ સંદેશો લખો.',
      'hi': 'कृपया एक अपील संदेश लिखें.',
      'en': 'Please write an appeal message.',
    },
    'society_reactivation_appeal': {
      'gu': '🚨 સોસાયટી પુનઃસક્રિયતા અપીલ',
      'hi': '🚨समाज पुनर्सक्रियन अपील',
      'en': '🚨 Society Reactivation Appeal',
    },
    'society_reactivated': {
      'gu': '✅ સોસાયટી પુનઃસક્રિય કરાઈ',
      'hi': 'समाज पुनः सक्रिय हुआ',
      'en': 'Society reactivated',
    },
    'reply_from_super_admin_head_office': {
      'gu': '📢 સુપર એડમિન / હેડ ઓફિસ તરફથી જવાબ',
      'hi': '📢 सुपर एडमिन/हेड ऑफिस से उत्तर',
      'en': '📢 Reply from Super Admin / Head Office',
    },
    'society_id_not_available': {
      'gu': 'સોસાયટી ID ઉપલબ્ધ નથી.',
      'hi': 'सोसाइटी आईडी उपलब्ध नहीं है.',
      'en': 'Society ID not available.',
    },
    'there_should_be_at_least_2': {
      'gu': 'ઓછામાં ઓછા ૨ વિકલ્પો હોવા જરૂરી છે.',
      'hi': 'कम से कम 2 विकल्प होने चाहिए.',
      'en': 'There should be at least 2 options.',
    },
    'society_decision_voting': {
      'gu': '🗳️ સોસાયટી નિર્ણય મતદાન',
      'hi': '🗳️ समाज निर्णय मतदान',
      'en': '🗳️ Society decision voting',
    },
    'please_login_first': {
      'gu': 'કૃપા કરીને પહેલા લોગિન કરો.',
      'hi': 'कृपया पहले लॉगइन करें.',
      'en': 'Please login first.',
    },
    'pollspolls_do_not_exist': {
      'gu': 'મતદાન/પોલ અસ્તિત્વમાં નથી.',
      'hi': 'मतदान/मतदान मौजूद नहीं है.',
      'en': 'Polls/Polls do not exist.',
    },
    'this_poll_has_expired': {
      'gu': 'આ મતદાનની મુદત સમાપ્ત થઈ ગઈ છે.',
      'hi': 'यह मतदान समाप्त हो गया है.',
      'en': 'This poll has expired.',
    },
    'you_have_already_voted': {
      'gu': 'આપ દ્વારા પહેલેથી જ મત આપવામાં આવેલ છે.',
      'hi': 'आपके द्वारा पहले ही वोट दिया जा चुका है।',
      'en': 'You have already voted.',
    },
    'invalid_option_selected': {
      'gu': 'અમાન્ય વિકલ્પ પસંદ કર્યો છે.',
      'hi': 'अमान्य विकल्प चयनित.',
      'en': 'Invalid option selected.',
    },
    'ground': {
      'gu': 'ગ્રાઉન્ડ',
      'hi': 'ज़मीन',
      'en': 'Ground',
    },
    'ground_floor': {
      'gu': 'ગ્રાઉન્ડ ફ્લોર',
      'hi': 'भूतल',
      'en': 'Ground floor',
    },
    'ground_floor_g': {
      'gu': 'ગ્રાઉન્ડ ફ્લોર (G)',
      'hi': 'भूतल (जी)',
      'en': 'Ground Floor (G)',
    },
    'txt_1st_floor_1': {
      'gu': '૧ લો માળ (1)',
      'hi': 'पहली मंजिल (1)',
      'en': '1st floor (1)',
    },
    'wing_a': {
      'gu': 'વિંગ A',
      'hi': 'विंग ए',
      'en': 'Wing A',
    },
    'ground_floor_shops_g': {
      'gu': 'ગ્રાઉન્ડ ફ્લોર / શોપ્સ (G)',
      'hi': 'ग्राउंड फ्लोर/दुकानें (जी)',
      'en': 'Ground Floor / Shops (G)',
    },
    'admin_not_allocated': {
      'gu': 'એડમિન ફાળવ્યો નથી',
      'hi': 'व्यवस्थापक आवंटित नहीं किया गया',
      'en': 'Admin not allocated',
    },
    'default_residential_complex': {
      'gu': 'ડિફોલ્ટ રેસિડેન્શિયલ સંકુલ',
      'hi': 'डिफ़ॉल्ट आवासीय परिसर',
      'en': 'Default residential complex',
    },
    'super_secretary': {
      'gu': 'સુપર સેક્રેટરી',
      'hi': 'सुपर सचिव',
      'en': 'Super Secretary',
    },
    'anonymous_user': {
      'gu': 'અનામી યુઝર',
      'hi': 'अनाम उपयोगकर्ता',
      'en': 'Anonymous user',
    },
    'the_security_password_must_be_at': {
      'gu': 'સિક્યોરિટી પાસવર્ડ ઓછામાં ઓછો 6 અક્ષરનો હોવો જોઈએ.',
      'hi': 'सुरक्षा पासवर्ड कम से कम 6 अक्षर लंबा होना चाहिए।',
      'en': 'The security password must be at least 6 characters long.',
    },
    'admins_firebase_auth_account_could_not': {
      'gu': 'એડમિનનું Firebase Auth એકાઉન્ટ તૈયાર થઈ શક્યું નથી. ફરી પ્રયાસ કરો.',
      'hi': 'व्यवस्थापक का फ़ायरबेस प्रामाणिक खाता नहीं बनाया जा सका. पुनः प्रयास करें।',
      'en': 'Admin\'s Firebase Auth account could not be created. Try again.',
    },
    'email_address_is_empty': {
      'gu': 'ઈમેલ એડ્રેસ ખાલી છે.',
      'hi': 'ईमेल पता खाली है.',
      'en': 'Email address is empty.',
    },
    'auth_account_of_super_admin_could': {
      'gu': 'સુપર એડમિનનું Auth એકાઉન્ટ તૈયાર થઈ શક્યું નથી.',
      'hi': 'सुपर एडमिन का प्रामाणिक खाता नहीं बनाया जा सका.',
      'en': 'Auth account of super admin could not be created.',
    },
    'notification_broadcast': {
      'gu': 'સૂચના બ્રોડકાસ્ટ',
      'hi': 'अधिसूचना प्रसारण',
      'en': 'Notification broadcast',
    },
    'notice_to_member': {
      'gu': 'સભ્યને સૂચના',
      'hi': 'सदस्य को सूचना',
      'en': 'Notice to Member',
    },
    'all_society_members_will_get_push': {
      'gu': 'સોસાયટીના તમામ સભ્યોને પુશ એલર્ટ મળશે',
      'hi': 'सभी सोसायटी सदस्यों को पुश अलर्ट मिलेंगे',
      'en': 'All society members will get push alerts',
    },
    'target_all_members': {
      'gu': 'લક્ષ્ય: તમામ સભ્યો',
      'hi': 'लक्ष्य: सभी सदस्य',
      'en': 'Target: All members',
    },
    'title': {
      'gu': 'વિષય (Title) *',
      'hi': 'शीर्षक*',
      'en': 'Title *',
    },
    'eg_notice_regarding_water_supply': {
      'gu': 'દા.ત. પાણી સપ્લાય અંગે સૂચના',
      'hi': 'जैसे जल आपूर्ति के संबंध में सूचना',
      'en': 'E.g. Notice regarding water supply',
    },
    'message': {
      'gu': 'સંદેશ / સૂચના (Message) *',
      'hi': 'संदेश*',
      'en': 'Message *',
    },
    'enter_notification_details': {
      'gu': 'સૂચનાની વિગત લખો...',
      'hi': 'अधिसूचना विवरण दर्ज करें...',
      'en': 'Enter notification details...',
    },
    'send': {
      'gu': 'મોકલો',
      'hi': 'भेजो',
      'en': 'send',
    },
    'notification_has_been_sent_to_all': {
      'gu': '✅ સોસાયટીના તમામ સભ્યોને સૂચના મોકલાઈ ગઈ છે!',
      'hi': '✅ सोसायटी के सभी सदस्यों को अधिसूचना भेज दी गई है!',
      'en': '✅ Notification has been sent to all members of the society!',
    },
    'push_notification_successfully_reached_the_members': {
      'gu': '✅ સભ્યના ફોન પર પુશ નોટિફિકેશન સફળતાપૂર્વક પહોંચી ગયું!',
      'hi': '✅ पुश अधिसूचना सदस्य के फोन पर सफलतापूर्वक पहुंच गई!',
      'en': '✅ Push notification successfully reached the member\'s phone!',
    },
    'the_members_phone_token_was_not': {
      'gu': 'સભ્યના ફોનનું ટોકન મળ્યું નથી, પરંતુ ઇન-એપ સૂચના સફળતાપૂર્વક સેવ કરી દીધી છે.',
      'hi': 'सदस्य का फ़ोन टोकन नहीं मिला, लेकिन इन-ऐप अधिसूचना सफलतापूर्वक सहेजी गई थी।',
      'en': 'The member\'s phone token was not found, but the in-app notification was successfully saved.',
    },
    'normal_2': {
      'gu': '📢 સામાન્ય',
      'hi': '📢 सामान्य',
      'en': '📢 Normal',
    },
    'water_2': {
      'gu': '💧 પાણી',
      'hi': '💧पानी',
      'en': '💧 Water',
    },
    'light_2': {
      'gu': '⚡ લાઈટ',
      'hi': '⚡रोशनी',
      'en': '⚡ Light',
    },
    'meeting_2': {
      'gu': '🗓️ મીટિંગ',
      'hi': '🗓️बैठक',
      'en': '🗓️ meeting',
    },
    'festival_2': {
      'gu': '🪅 ઉત્સવ',
      'hi': '🪅उत्सव',
      'en': '🪅 festival',
    },
    'cleaning_2': {
      'gu': '🧹 સફાઈ',
      'hi': '🧹 सफाई',
      'en': '🧹 Cleaning',
    },
    'publish_new_notice_on_society_digital': {
      'gu': 'સોસાયટી ડિજિટલ બોર્ડ પર નવી નોટિસ જાહેર કરો',
      'hi': 'सोसायटी डिजिटल बोर्ड पर नया नोटिस प्रकाशित करें',
      'en': 'Publish new notice on society digital board',
    },
    'select_category_optional': {
      'gu': 'કેટેગરી પસંદ કરો (વૈકલ્પિક):',
      'hi': 'श्रेणी चुनें (वैकल्पिक):',
      'en': 'Select Category (Optional):',
    },
    'eg_annual_general_meeting': {
      'gu': 'દા.ત. વાર્ષિક જનરલ મીટિંગ',
      'hi': 'जैसे वार्षिक आम बैठक',
      'en': 'E.g. Annual General Meeting',
    },
    'notice_message_detail_message': {
      'gu': 'નોટિસનો સંદેશ / વિગત (Message) *',
      'hi': 'सूचना संदेश/विस्तार (संदेश)*',
      'en': 'Notice Message / Detail (Message) *',
    },
    'write_detailed_instructions_required_for_members': {
      'gu': 'સભ્યો માટે જરૂરી સૂચના વિગતવાર લખો...',
      'hi': 'सदस्यों के लिए आवश्यक विस्तृत निर्देश लिखें...',
      'en': 'Write detailed instructions required for members...',
    },
    'send_push_notifications_to_everyone': {
      'gu': 'બધાને પુશ નોટિફિકેશન મોકલો',
      'hi': 'सभी को पुश सूचनाएँ भेजें',
      'en': 'Send push notifications to everyone',
    },
    'an_alert_will_go_immediately_on': {
      'gu': 'સભ્યોના ફોનમાં તુરંત એલર્ટ જશે',
      'hi': 'सदस्य के फोन पर तुरंत अलर्ट चला जाएगा',
      'en': 'An alert will go immediately on the member\'s phone',
    },
    'notice_published': {
      'gu': 'નોટિસ પ્રકાશિત!',
      'hi': 'सूचना प्रकाशित!',
      'en': 'Notice published!',
    },
    'admin_login_credentials': {
      'gu': 'એડમિન લૉગિન ક્રેડેન્શિયલ્સ',
      'hi': 'व्यवस्थापक लॉगिन क्रेडेंशियल',
      'en': 'Admin login credentials',
    },
    'premises_successfully_onboarded': {
      'gu': 'પરિસર સફળતાપૂર્વક ઓનબોર્ડ થઈ ગયું છે!',
      'hi': 'परिसर सफलतापूर्वक ऑनबोर्ड हो गया!',
      'en': 'Premises successfully onboarded!',
    },
    'premises_society': {
      'gu': 'પરિસર / સોસાયટી',
      'hi': 'परिसर/समाज',
      'en': 'Premises / Society',
    },
    'admin_name_city': {
      'gu': 'એડમિન નામ & શહેર',
      'hi': 'व्यवस्थापक का नाम और शहर',
      'en': 'Admin Name & City',
    },
    'login_email': {
      'gu': 'લૉગિન ઈમેલ',
      'hi': 'ईमेल लॉगिन करें',
      'en': 'Login email',
    },
    'email_copied_to_clipboard': {
      'gu': '📧 ઈમેલ ક્લિપબોર્ડમાં કોપી થયો!',
      'hi': '📧 ईमेल को क्लिपबोर्ड पर कॉपी किया गया!',
      'en': '📧 Email copied to clipboard!',
    },
    'password_copied_to_clipboard': {
      'gu': '🔑 પાસવર્ડ ક્લિપબોર્ડમાં કોપી થયો!',
      'hi': '🔑 पासवर्ड क्लिपबोर्ड पर कॉपी किया गया!',
      'en': '🔑 Password copied to clipboard!',
    },
    'registered_mobile': {
      'gu': 'રજીસ્ટર્ડ મોબાઇલ',
      'hi': 'पंजीकृत मोबाइल',
      'en': 'Registered mobile',
    },
    'copied_to_mobile_clipboard': {
      'gu': '📱 મોબાઇલ ક્લિપબોર્ડમાં કોપી થયો!',
      'hi': '📱 मोबाइल क्लिपबोर्ड पर कॉपी किया गया!',
      'en': '📱 Copied to mobile clipboard!',
    },
    'admin_does_not_have_to_select': {
      'gu': 'લૉગિન વખતે એડમિનને કોઈ રોલ સિલેક્ટ કરવાનો નથી — ફક્ત ઈમેલ/મોબાઇલ અને પાસવર્ડ નાખતાં જ સિસ્ટમ ઑટોમેટિક એડમિન રોલ ફેચ કરી લેશે.',
      'hi': 'एडमिन को लॉगिन करते समय कोई भूमिका चुनने की आवश्यकता नहीं है - सिस्टम केवल ईमेल/मोबाइल और पासवर्ड दर्ज करके स्वचालित रूप से एडमिन भूमिका प्राप्त कर लेगा।',
      'en': 'Admin does not have to select any role at login — system will automatically fetch admin role by just entering email/mobile and password.',
    },
    'email_app_is_open_send_proof': {
      'gu': '📧 ઈમેલ એપ ખુલી ગઈ છે! ડ્રાફ્ટ ચકાસી મોકલો.',
      'hi': '📧 ईमेल ऐप खुला है! ड्राफ्ट का प्रमाण भेजें.',
      'en': '📧 Email app is open! Send proof of draft.',
    },
    'if_the_email_app_does_not': {
      'gu': '⚠️ ઈમેલ એપ ન ખુલી, વિગતો ક્લિપબોર્ડમાં કોપી કરી શકો છો.',
      'hi': '⚠️ यदि ईमेल ऐप नहीं खुलता है, तो आप विवरण को क्लिपबोर्ड पर कॉपी कर सकते हैं।',
      'en': '⚠️ If the email app does not open, you can copy the details to the clipboard.',
    },
    'send_an_email': {
      'gu': 'ઈમેલ મોકલો',
      'hi': 'एक ईमेल भेजें',
      'en': 'Send an email',
    },
    'whatsapp_chat_is_opening': {
      'gu': '💬 WhatsApp ચેટ ખુલી રહી છે...',
      'hi': '💬व्हाट्सएप चैट खुल रही है...',
      'en': '💬 WhatsApp chat is opening...',
    },
    'whatsapp_could_not_open': {
      'gu': '⚠️ WhatsApp ન ખુલી શક્યું.',
      'hi': '⚠️व्हाट्सएप नहीं खुल सका।',
      'en': '⚠️ WhatsApp could not open.',
    },
    'copy_everything': {
      'gu': 'બધું કોપી કરો',
      'hi': 'सब कुछ कॉपी करें',
      'en': 'Copy everything',
    },
    'full_credentials_letter_copied': {
      'gu': '📋 સંપૂર્ણ ક્રેડેન્શિયલ્સ પત્ર કોપી થઈ ગયો!',
      'hi': '📋 पूर्ण क्रेडेंशियल पत्र की प्रतिलिपि बनाई गई!',
      'en': '📋 Full credentials letter copied!',
    },
    'share_to_other_apps': {
      'gu': 'અન્ય એપમાં શેર',
      'hi': 'अन्य ऐप्स पर साझा करें',
      'en': 'Share to other apps',
    },
    'send_password_reset_link_to_admins': {
      'gu': 'એડમિનના ઈમેલ પર પાસવર્ડ રીસેટ લિંક મોકલો',
      'hi': 'व्यवस्थापक के ईमेल पर पासवर्ड रीसेट लिंक भेजें',
      'en': 'Send password reset link to admin\'s email',
    },
    'done': {
      'gu': 'પૂર્ણ થયું (Done)',
      'hi': 'हो गया',
      'en': 'Done',
    },
    'copy_3': {
      'gu': 'કોપી કરો',
      'hi': 'प्रतिलिपि',
      'en': 'Copy',
    },
    'initial_password': {
      'gu': 'પ્રારંભિક પાસવર્ડ',
      'hi': 'प्रारंभिक पासवर्ड',
      'en': 'Initial password',
    },
    'encrypted_for_security': {
      'gu': '(સુરક્ષા ખાતર એન્ક્રિપ્ટેડ)',
      'hi': '(सुरक्षा के लिए एन्क्रिप्टेड)',
      'en': '(encrypted for security)',
    },
    'hide': {
      'gu': 'છુપાવો',
      'hi': 'छिपाओ',
      'en': 'hide',
    },
    'see': {
      'gu': 'જોવો',
      'hi': 'देखिये',
      'en': 'see',
    },
    'immediate_helpline_for_society_members': {
      'gu': 'સોસાયટી સભ્યો માટે તાત્કાલિક હેલ્પલાઇન',
      'hi': 'समाज के सदस्यों के लिए तत्काल हेल्पलाइन',
      'en': 'Immediate helpline for society members',
    },
    'name_of_service_eg_lift': {
      'gu': 'સેવાનું નામ (દા.ત. લિફ્ટ)',
      'hi': 'सेवा का नाम (जैसे लिफ्ट)',
      'en': 'Name of service (e.g. lift)',
    },
    'phone_number': {
      'gu': 'ફોન નંબર',
      'hi': 'फ़ोन नंबर',
      'en': 'phone number',
    },
    'add_to_list': {
      'gu': 'લિસ્ટમાં ઉમેરો',
      'hi': 'सूची में जोड़ें',
      'en': 'Add to list',
    },
    'no_emergency_number_has_been_added': {
      'gu': 'હજુ કોઈ ઈમરજન્સી નંબર ઉમેરાયો નથી.\\nઉપરના સૂચન બટન પર ક્લિક કરીને ઉમેરો.',
      'hi': 'अभी तक कोई आपातकालीन नंबर नहीं जोड़ा गया है।\\nउपरोक्त सुझाव बटन पर क्लिक करके जोड़ें।',
      'en': 'No emergency number has been added yet.\\nAdd by clicking the suggestion button above.',
    },
    'emergency_contacts_saved': {
      'gu': 'ઈમરજન્સી કોન્ટેક્ટ્સ સેવ થઈ ગયા!',
      'hi': 'आपातकालीन संपर्क सहेजे गए!',
      'en': 'Emergency contacts saved!',
    },
    'new_user_registration': {
      'gu': 'નવું યુઝર રજીસ્ટ્રેશન',
      'hi': 'नया उपयोगकर्ता पंजीकरण',
      'en': 'New User Registration',
    },
    'create_a_member_subadmin_or_watchman': {
      'gu': 'મેમ્બર, સબ-એડમિન કે વોચમેન એકાઉન્ટ બનાવો',
      'hi': 'एक सदस्य, उप-व्यवस्थापक या चौकीदार खाता बनाएँ',
      'en': 'Create a member, sub-admin or watchman account',
    },
    'select_a_user_role': {
      'gu': 'યુઝર રોલ પસંદ કરો:',
      'hi': 'उपयोगकर्ता भूमिका चुनें:',
      'en': 'Select a user role:',
    },
    'eg_rameshgmailcom': {
      'gu': 'દા.ત. ramesh@gmail.com',
      'hi': 'जैसे ramesh@gmail.com',
      'en': 'E.g. ramesh@gmail.com',
    },
    'password': {
      'gu': 'પાસવર્ડ *',
      'hi': 'पासवर्ड*',
      'en': 'password *',
    },
    'at_least_6_characters_2': {
      'gu': 'ઓછામાં ઓછા ૬ અક્ષર',
      'hi': 'कम से कम 6 अक्षर',
      'en': 'At least 6 characters',
    },
    'mobile_number_optional': {
      'gu': 'મોબાઈલ નંબર (વૈકલ્પિક)',
      'hi': 'मोबाइल नंबर (वैकल्पिक)',
      'en': 'Mobile Number (Optional)',
    },
    'txt_10_digit_number_2': {
      'gu': '૧૦ અંકનો નંબર',
      'hi': '10 अंकों की संख्या',
      'en': '10 digit number',
    },
    'select_block_house_details': {
      'gu': 'બ્લોક & ઘરની વિગત પસંદ કરો *',
      'hi': 'ब्लॉक और घर का विवरण चुनें *',
      'en': 'Select Block & House Details *',
    },
    'wing_block_floor': {
      'gu': 'વિંગ / બ્લોક / ફ્લોર',
      'hi': 'विंग/ब्लॉक/फर्श',
      'en': 'Wing / Block / Floor',
    },
    'house_flat_no': {
      'gu': 'ઘર / ફ્લેટ નંબર *',
      'hi': 'मकान/फ्लैट नं.*',
      'en': 'House / Flat No. *',
    },
    'eg_101_a202': {
      'gu': 'દા.ત. 101, A-202',
      'hi': 'जैसे 101, ए-202',
      'en': 'E.g. 101, A-202',
    },
    'select_a_home': {
      'gu': 'ઘર પસંદ કરો',
      'hi': 'एक घर चुनें',
      'en': 'Select a home',
    },
    'select_a_block_first_or_write': {
      'gu': 'પહેલા બ્લોક પસંદ કરો અથવા સીધો ફ્લેટ નંબર લખો',
      'hi': 'पहले एक ब्लॉक चुनें या सीधे एक फ्लैट नंबर लिखें',
      'en': 'Select a block first or write a flat number directly',
    },
    'please_fill_in_all_required_details': {
      'gu': 'કૃપા કરીને બધી જરૂરી વિગતો ભરો!',
      'hi': 'कृपया सभी आवश्यक विवरण भरें!',
      'en': 'Please fill in all required details!',
    },
    'enter_a_valid_email_address': {
      'gu': 'માન્ય ઇમેઇલ એડ્રેસ દાખલ કરો!',
      'hi': 'एक मान्य ईमेल पता दर्ज करें!',
      'en': 'Enter a valid email address!',
    },
    'password_must_be_at_least_6_2': {
      'gu': 'પાસવર્ડ ઓછામાં ઓછો ૬ અક્ષરનો હોવો જોઈએ!',
      'hi': 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए!',
      'en': 'Password must be at least 6 characters long!',
    },
    'please_selectwrite_block_and_house_number': {
      'gu': 'કૃપા કરીને બ્લોક અને ઘર નંબર પસંદ/લખો!',
      'hi': 'कृपया ब्लॉक और मकान नंबर चुनें/लिखें!',
      'en': 'Please select/write block and house number!',
    },
    'create_an_account': {
      'gu': 'એકાઉન્ટ બનાવો',
      'hi': 'एक खाता बनाएं',
      'en': 'Create an account',
    },
    'security_gate_staff_and_active_status': {
      'gu': 'સુરક્ષા ગેટ સ્ટાફ અને એક્ટિવ સ્ટેટસ',
      'hi': 'सुरक्षा गेट कर्मचारी और सक्रिय स्थिति',
      'en': 'Security Gate Staff and Active Status',
    },
    'no_watchman_registered': {
      'gu': 'કોઈ વોચમેન નોંધાયેલ નથી.',
      'hi': 'कोई चौकीदार पंजीकृत नहीं है।',
      'en': 'No watchman registered.',
    },
    'add_new_watchmen': {
      'gu': '+ નવો વોચમેન ઉમેરો',
      'hi': '+ नए चौकीदार जोड़ें',
      'en': '+ Add new watchmen',
    },
    'on_duty_2': {
      'gu': 'ફરજ પર',
      'hi': 'ड्यूटी पर',
      'en': 'on duty',
    },
    'inactive': {
      'gu': 'નિષ્ક્રિય',
      'hi': 'निष्क्रिय',
      'en': 'inactive',
    },
    'the_new_watchman': {
      'gu': 'નવો વોચમેન',
      'hi': 'नया चौकीदार',
      'en': 'The new watchman',
    },
    'january': {
      'gu': 'જાન્યુઆરી',
      'hi': 'जनवरी',
      'en': 'January',
    },
    'february': {
      'gu': 'ફેબ્રુઆરી',
      'hi': 'फ़रवरी',
      'en': 'February',
    },
    'march': {
      'gu': 'માર્ચ',
      'hi': 'मार्च',
      'en': 'March',
    },
    'april': {
      'gu': 'એપ્રિલ',
      'hi': 'अप्रैल',
      'en': 'April',
    },
    'may': {
      'gu': 'મે',
      'hi': 'मई',
      'en': 'May',
    },
    'june': {
      'gu': 'જૂન',
      'hi': 'जून',
      'en': 'June',
    },
    'july': {
      'gu': 'જુલાઈ',
      'hi': 'जुलाई',
      'en': 'July',
    },
    'august': {
      'gu': 'ઓગસ્ટ',
      'hi': 'अगस्त',
      'en': 'August',
    },
    'september': {
      'gu': 'સપ્ટેમ્બર',
      'hi': 'सितम्बर',
      'en': 'September',
    },
    'october': {
      'gu': 'ઓક્ટોબર',
      'hi': 'अक्टूबर',
      'en': 'October',
    },
    'november': {
      'gu': 'નવેમ્બર',
      'hi': 'नवंबर',
      'en': 'November',
    },
    'december': {
      'gu': 'ડિસેમ્બર',
      'hi': 'दिसंबर',
      'en': 'December',
    },
    'visitor_report': {
      'gu': 'વિઝિટર રિપોર્ટ',
      'hi': 'आगंतुक रिपोर्ट',
      'en': 'Visitor report',
    },
    'total_registered_visitors': {
      'gu': 'કુલ નોંધાયેલ મુલાકાતીઓ',
      'hi': 'कुल पंजीकृत आगंतुक',
      'en': 'Total registered visitors',
    },
    'approved_3': {
      'gu': 'મંજૂર (Approved)',
      'hi': 'स्वीकृत',
      'en': 'Approved',
    },
    'under_scrutiny': {
      'gu': 'ચકાસણી હેઠળ',
      'hi': 'जांच के अधीन',
      'en': 'Under scrutiny',
    },
    'rejected_5': {
      'gu': 'નકાર્યું (Rejected)',
      'hi': 'अस्वीकृत',
      'en': 'Rejected',
    },
    'access_blocked': {
      'gu': 'પ્રવેશ રોકેલ',
      'hi': 'प्रवेश अवरुद्ध',
      'en': 'Access blocked',
    },
    'checked_out_2': {
      'gu': 'ચેક-આઉટ થયેલ',
      'hi': 'जांच की गई',
      'en': 'Checked out',
    },
    'went_back': {
      'gu': 'પરત ગયા',
      'hi': 'वापस चला गया',
      'en': 'went back',
    },
    'status_proportion_analysis': {
      'gu': 'સ્ટેટસ પ્રમાણ વિશ્લેષણ:',
      'hi': 'स्थिति अनुपात विश्लेषण:',
      'en': 'Status Proportion Analysis:',
    },
    'got_it_close_3': {
      'gu': 'સમજાઈ ગયું (બંધ કરો)',
      'hi': 'मिल गया (बंद करें)',
      'en': 'Got it (close)',
    },
    'upi_payment_is_under_verification': {
      'gu': 'UPI પેમેન્ટ ચકાસણી હેઠળ છે',
      'hi': 'UPI भुगतान सत्यापन के अधीन है',
      'en': 'UPI payment is under verification',
    },
    'detail': {
      'gu': 'વિગત',
      'hi': 'विवरण',
      'en': 'detail',
    },
    'pay_now': {
      'gu': 'હમણાં ચૂકવો',
      'hi': 'अभी भुगतान करें',
      'en': 'pay now',
    },
    'maintenance_payment_receipt': {
      'gu': 'મેન્ટેનન્સ ચુકવણી રસીદ',
      'hi': 'रखरखाव भुगतान रसीद',
      'en': 'Maintenance Payment Receipt',
    },
    'amount_paid_paid': {
      'gu': 'ચૂકવેલ રકમ (PAID)',
      'hi': 'भुगतान की गई राशि (भुगतान)',
      'en': 'Amount Paid (PAID)',
    },
    'successfully_verified_verified': {
      'gu': 'સફળતાપૂર્વક પ્રમાણિત (VERIFIED)',
      'hi': 'सफलतापूर्वक सत्यापित (सत्यापित)',
      'en': 'Successfully verified (VERIFIED)',
    },
    'billing_month': {
      'gu': 'બિલિંગ મહિનો',
      'hi': 'बिलिंग माह',
      'en': 'Billing month',
    },
    'payment_method': {
      'gu': 'ચુકવણી પદ્ધતિ',
      'hi': 'भुगतान विधि',
      'en': 'Payment Method',
    },
    'utr_transaction_no': {
      'gu': 'UTR / ટ્રાન્ઝેક્શન નં',
      'hi': 'यूटीआर/लेनदेन संख्या',
      'en': 'UTR / Transaction no',
    },
    'check_number': {
      'gu': 'ચેક નંબર',
      'hi': 'नंबर जांचें',
      'en': 'Check number',
    },
    'date_of_payment': {
      'gu': 'ચુકવણી તારીખ',
      'hi': 'भुगतान की तिथि',
      'en': 'Date of payment',
    },
    'checker': {
      'gu': 'ચકાસણી કરનાર',
      'hi': 'चेकर',
      'en': 'Checker',
    },
    'share_receipt_pdf': {
      'gu': 'રસીદ PDF શેર કરો (Share)',
      'hi': 'रसीद पीडीएफ साझा करें',
      'en': 'Share Receipt PDF',
    },
    'maintenance_online_payment': {
      'gu': 'મેન્ટેનન્સ & ઓનલાઇન પેમેન્ટ',
      'hi': 'रखरखाव एवं ऑनलाइन भुगतान',
      'en': 'Maintenance & Online Payment',
    },
    'pay': {
      'gu': 'ચુકવણી (Pay)',
      'hi': 'भुगतान करें',
      'en': 'Pay',
    },
    'history_receipts': {
      'gu': 'ઇતિહાસ & રસીદો',
      'hi': 'इतिहास एवं प्राप्तियाँ',
      'en': 'History & Receipts',
    },
    'no_bill_or_receipt_received_yet': {
      'gu': 'હજુ સુધી કોઈ બિલ કે રસીદ મળી નથી.',
      'hi': 'अभी तक कोई बिल या रसीद नहीं मिली.',
      'en': 'No bill or receipt received yet.',
    },
    'the_bill_will_be_listed_here': {
      'gu': 'સોસાયટી દ્વારા બિલ જનરેટ થશે ત્યારે અહીં લિસ્ટ થશે.',
      'hi': 'सोसायटी द्वारा जनरेट किए जाने पर बिल यहां सूचीबद्ध किया जाएगा।',
      'en': 'The bill will be listed here when generated by the society.',
    },
    'all_maintenance_bills_are_paid': {
      'gu': '🎉 તમામ મેન્ટેનન્સ બિલ ચૂકવાઈ ગયા છે!',
      'hi': '🎉 सभी रखरखाव बिलों का भुगतान कर दिया गया है!',
      'en': '🎉 All maintenance bills are paid!',
    },
    'you_have_no_arrears_society_account': {
      'gu': 'તમારું કોઈ બાકી લેણું નથી • સોસાયટી ખાતું સંપૂર્ણ ક્લિયર છે.',
      'hi': 'आपका कोई बकाया नहीं है • सोसायटी का खाता पूरी तरह से चुका दिया गया है।',
      'en': 'You have no arrears • Society account is fully cleared.',
    },
    'receipt_of_last_payment': {
      'gu': 'છેલ્લી ચુકવણીની રસીદ',
      'hi': 'अंतिम भुगतान की प्राप्ति',
      'en': 'Receipt of last payment',
    },
    'digital_verified_receipt': {
      'gu': 'ડિજિટલ વેરિફાઇડ રસીદ',
      'hi': 'डिजिटल सत्यापित रसीद',
      'en': 'Digital Verified Receipt',
    },
    'view_receipt_pdf': {
      'gu': 'રસીદ PDF જુઓ',
      'hi': 'रसीद पीडीएफ देखें',
      'en': 'View receipt PDF',
    },
    'view_all_old_receipts_history': {
      'gu': 'બધી જૂની રસીદો & ઇતિહાસ જુઓ',
      'hi': 'सभी पुरानी रसीदें और इतिहास देखें',
      'en': 'View all old receipts & history',
    },
    'see_2': {
      'gu': 'જુઓ',
      'hi': 'देखिये',
      'en': 'see',
    },
    'pay_now_2': {
      'gu': 'હમણાં ચૂકવો (Pay Now)',
      'hi': 'अभी भुगतान करें',
      'en': 'Pay Now',
    },
    'chairmanadmin_will_verify_this_amount_so': {
      'gu': 'ચેરમેન/એડમિન આ રકમ વેરિફાય કરશે એટલે તરત જ તમને ડિજિટલ રસીદ મળી જશે અને PDF ડાઉનલોડ થઈ શકશે.',
      'hi': 'अध्यक्ष/प्रशासक इस राशि का सत्यापन करेंगे जिससे आपको तुरंत डिजिटल रसीद मिल जाएगी और पीडीएफ डाउनलोड किया जा सकता है।',
      'en': 'Chairman/Admin will verify this amount so immediately you will get digital receipt and PDF can be downloaded.',
    },
    'upi_id_has_not_yet_been': {
      'gu': 'સોસાયટી દ્વારા હજુ સુધી UPI ID સેટ કરવામાં આવ્યો નથી. કૃપા કરીને એડમિનનો સંપર્ક કરી રોકડ અથવા ચેકથી ચુકવણી કરો.',
      'hi': 'सोसायटी द्वारा अभी तक यूपीआई आईडी निर्धारित नहीं की गई है। कृपया व्यवस्थापक से संपर्क करें और नकद या चेक से भुगतान करें।',
      'en': 'UPI ID has not yet been set by the Society. Please contact the admin and pay by cash or cheque.',
    },
    'unable_to_open_upi_app_scan': {
      'gu': 'UPI એપ ખૂલી શકી નથી. નીચે આપેલ QR કોડ સ્કેન કરો.',
      'hi': 'UPI ऐप खोलने में असमर्थ. नीचे दिए गए QR कोड को स्कैन करें.',
      'en': 'Unable to open UPI app. Scan the QR code below.',
    },
    'pay_with_google_pay_phonepe_1tap': {
      'gu': 'Google Pay / PhonePe થી ચૂકવો (1-Tap)',
      'hi': 'Google Pay/PhonePe से भुगतान करें (1-टैप)',
      'en': 'Pay with Google Pay / PhonePe (1-Tap)',
    },
    'or_scan_from_another_mobile': {
      'gu': 'અથવા અન્ય મોબાઈલથી સ્કેન કરો:',
      'hi': 'या दूसरे मोबाइल से स्कैन करें:',
      'en': 'Or scan from another mobile:',
    },
    'after_making_payment_enter_utr_number': {
      'gu': 'પેમેન્ટ કર્યા પછી અહીં UTR નંબર દાખલ કરો:',
      'hi': 'भुगतान करने के बाद यहां यूटीआर नंबर दर्ज करें:',
      'en': 'After making payment enter UTR number here:',
    },
    'txt_12digit_utr_transaction_number': {
      'gu': '૧૨-આંકડાનો UTR / ટ્રાન્ઝેક્શન નંબર *',
      'hi': '12-अंकीय यूटीआर / लेनदेन संख्या *',
      'en': '12-digit UTR / Transaction Number *',
    },
    'eg_4289xxxxxxxx': {
      'gu': 'દા.ત. 4289XXXXXXXX',
      'hi': 'जैसे 4289XXXXXXXX',
      'en': 'E.g. 4289XXXXXXXX',
    },
    'please_enter_a_valid_utr_number': {
      'gu': 'કૃપા કરીને માન્ય UTR નંબર દાખલ કરો',
      'hi': 'कृपया एक वैध यूटीआर नंबर दर्ज करें',
      'en': 'Please enter a valid UTR number',
    },
    'upi_payment_submitted_for_verification': {
      'gu': 'UPI પેમેન્ટ વેરિફિકેશન માટે સબમિટ થઈ ગયું!',
      'hi': 'सत्यापन के लिए UPI भुगतान सबमिट किया गया!',
      'en': 'UPI payment submitted for verification!',
    },
    'confirm_payment': {
      'gu': 'ચુકવણી કન્ફર્મ કરો',
      'hi': 'भुगतान की पुष्टि करें',
      'en': 'Confirm payment',
    },
    'receipts_and_important_updates': {
      'gu': 'રસીદ અને મહત્ત્વપૂર્ણ અપડેટ્સ',
      'hi': 'प्राप्तियाँ एवं महत्वपूर्ण अद्यतन',
      'en': 'Receipts and important updates',
    },
    'notification': {
      'gu': 'સૂચના',
      'hi': 'अधिसूचना',
      'en': 'notification',
    },
    'see_receipt': {
      'gu': 'રસીદ જુઓ',
      'hi': 'रसीद देखें',
      'en': 'See receipt',
    },
    'open_up': {
      'gu': 'ખોલો',
      'hi': 'खोलो',
      'en': 'open up',
    },
    'currently_there_are_no_new_notifications': {
      'gu': 'હાલ કોઈ નવી નોટિફિકેશન નથી',
      'hi': 'फिलहाल कोई नई अधिसूचना नहीं है',
      'en': 'Currently there are no new notifications',
    },
    'when_an_admin_accepts_payment_or': {
      'gu': 'જ્યારે એડમિન પેમેન્ટ સ્વીકારશે અથવા સોસાયટી એલર્ટ મોકલશે, ત્યારે અહીં દેખાશે.',
      'hi': 'जब कोई व्यवस्थापक भुगतान स्वीकार करता है या सोसाइटी अलर्ट भेजता है, तो वह यहां दिखाई देगा।',
      'en': 'When an admin accepts payment or sends a society alert, it will appear here.',
    },
    'society_common_plot_parking': {
      'gu': 'સોસાયટી કોમન પ્લોટ પાર્કિંગ',
      'hi': 'सोसायटी कॉमन प्लॉट पार्किंग',
      'en': 'Society Common Plot Parking',
    },
    'common_plot_slots_approved_by_admin': {
      'gu': 'એડમિન દ્વારા મંજૂર કરેલા કોમન પ્લોટ સ્લોટ્સ',
      'hi': 'सामान्य प्लॉट स्लॉट व्यवस्थापक द्वारा अनुमोदित',
      'en': 'Common plot slots approved by admin',
    },
    'slots_approved_by_your_wings_admin': {
      'gu': 'તમારી વિંગના એડમિન દ્વારા માન્ય સ્લોટ્સ',
      'hi': 'आपके विंग के व्यवस्थापक द्वारा अनुमोदित स्लॉट',
      'en': 'Slots approved by your wing\'s admin',
    },
    'no_common_plot_slots': {
      'gu': 'કોઈ કોમન પ્લોટ સ્લોટ્સ નથી',
      'hi': 'कोई सामान्य प्लॉट स्लॉट नहीं',
      'en': 'No common plot slots',
    },
    'no_common_plot_slots_have_been_3': {
      'gu': 'સોસાયટી એડમિન દ્વારા હજુ કોઈ કોમન પ્લોટ સ્લોટ્સ બનાવવામાં આવ્યા નથી.',
      'hi': 'सोसाइटी एडमिन द्वारा अभी तक कोई सामान्य प्लॉट स्लॉट नहीं बनाया गया है।',
      'en': 'No common plot slots have been created by society admin yet.',
    },
    'no_slots_found': {
      'gu': 'સ્લોટ્સ મળ્યા નથી',
      'hi': 'कोई स्लॉट नहीं मिला',
      'en': 'No slots found',
    },
    'there_are_no_slots_available_in': {
      'gu': 'આ કેટેગરીમાં કોઈ સ્લોટ્સ ઉપલબ્ધ નથી.',
      'hi': 'इस श्रेणी में कोई स्लॉट उपलब्ध नहीं है।',
      'en': 'There are no slots available in this category.',
    },
    'selected_parking_slots': {
      'gu': 'પસંદ કરેલ પાર્કિંગ સ્લોટ:',
      'hi': 'चयनित पार्किंग स्लॉट:',
      'en': 'Selected parking slots:',
    },
    'no_slot_preferred': {
      'gu': 'કોઈ સ્લોટ પસંદ નથી',
      'hi': 'कोई स्लॉट पसंदीदा नहीं',
      'en': 'No slot preferred',
    },
    'confirm_parking': {
      'gu': 'પાર્કિંગ કન્ફર્મ કરો',
      'hi': 'पार्किंग की पुष्टि करें',
      'en': 'Confirm parking',
    },
    'all_slots': {
      'gu': 'બધા સ્લોટ્સ',
      'hi': 'सभी स्लॉट',
      'en': 'All slots',
    },
    'txt_4wheeler_car_2': {
      'gu': '૪-વ્હીલર કાર',
      'hi': '4-पहिया कार',
      'en': '4-wheeler car',
    },
    'txt_2wheeler_bike_2': {
      'gu': '૨-વ્હીલર બાઇક',
      'hi': '2-पहिया बाइक',
      'en': '2-wheeler bike',
    },
    'ev_charging': {
      'gu': '⚡ EV ચાર્જિંગ',
      'hi': '⚡ ईवी चार्जिंग',
      'en': '⚡ EV charging',
    },
    'is_allocated_to': {
      'gu': '} ને ફાળવેલ છે!',
      'hi': '} को आवंटित किया गया है !',
      'en': '} is allocated to !',
    },
    'available_2': {
      'gu': '🟢 ઉપલબ્ધ (Available)',
      'hi': '🟢 उपलब्ध',
      'en': '🟢 Available',
    },
    'smart_maintenance_reminder': {
      'gu': 'સ્માર્ટ મેન્ટેનન્સ રીમાઇન્ડર',
      'hi': 'स्मार्ट रखरखाव अनुस्मारक',
      'en': 'Smart maintenance reminder',
    },
    'add_special_note_optional': {
      'gu': 'ખાસ નોંધ ઉમેરો (વૈકલ્પિક)',
      'hi': 'विशेष नोट जोड़ें (वैकल्पिक)',
      'en': 'Add special note (optional)',
    },
    'eg_please_meet_at_the_society': {
      'gu': 'દા.ત. કૃપા કરીને સોસાયટી ઓફિસે મળવું...',
      'hi': 'जैसे कृपया सोसायटी कार्यालय में मिलें...',
      'en': 'E.g. Please meet at the Society Office...',
    },
    'whatsapp_message_preview': {
      'gu': 'WhatsApp મેસેજ પ્રિવ્યુ (Message Preview):',
      'hi': 'व्हाट्सएप संदेश पूर्वावलोकन:',
      'en': 'WhatsApp Message Preview:',
    },
    'app_push_notification_has_been_successfully': {
      'gu': '✅ સભ્યને એપ પુશ નોટિફિકેશન સફળતાપૂર્વક મોકલાઈ ગયું.',
      'hi': '✅ ऐप पुश नोटिफिकेशन सदस्य को सफलतापूर्वक भेज दिया गया है।',
      'en': '✅ App push notification has been successfully sent to the member.',
    },
    'notification_saved_fcm_token_was_not': {
      'gu': 'નોટિફિકેશન સેવ થયું (FCM ટોકન ઉપલબ્ધ નહોતું).',
      'hi': 'अधिसूचना सहेजी गई (एफसीएम टोकन उपलब्ध नहीं था)।',
      'en': 'Notification saved (FCM token was not available).',
    },
    'app_push': {
      'gu': 'એપ પુશ',
      'hi': 'ऐप पुश',
      'en': 'App Push',
    },
    'send_on_whatsapp': {
      'gu': 'WhatsApp પર મોકલો',
      'hi': 'व्हाट्सएप पर भेजें',
      'en': 'Send on WhatsApp',
    },
    'there_is_no_pending_maintenance_bill': {
      'gu': 'આ મહિના માટે કોઈ બાકી મેન્ટેનન્સ બિલ નથી.',
      'hi': 'इस माह का कोई रखरखाव बिल लंबित नहीं है।',
      'en': 'There is no pending maintenance bill for this month.',
    },
    'smart_reminder_queue': {
      'gu': 'સ્માર્ટ રીમાઇન્ડર કતાર (Queue)',
      'hi': 'स्मार्ट अनुस्मारक कतार',
      'en': 'Smart Reminder Queue',
    },
    'search_flat_name_or_mobile_number': {
      'gu': 'ફ્લેટ, નામ કે મોબાઈલ નંબર શોધો...',
      'hi': 'फ्लैट, नाम या मोबाइल नंबर खोजें...',
      'en': 'Search flat, name or mobile number...',
    },
    'remaining_members': {
      'gu': 'બાકી સભ્યો',
      'hi': 'शेष सदस्य',
      'en': 'remaining members',
    },
    'there_are_no_remaining_members_according': {
      'gu': 'પસંદ કરેલા ફિલ્ટર મુજબ કોઈ બાકી સભ્ય નથી.',
      'hi': 'चयनित फ़िल्टर के अनुसार कोई भी सदस्य शेष नहीं है।',
      'en': 'There are no remaining members according to the selected filter.',
    },
    'no_number': {
      'gu': 'નંબર નથી',
      'hi': 'कोई संख्या नहीं',
      'en': 'no number',
    },
    'sent': {
      'gu': 'મોકલાઈ ગયું',
      'hi': 'भेजा गया',
      'en': 'Sent',
    },
    'sending_push_notification': {
      'gu': 'પુશ નોટિફિકેશન મોકલાઈ રહ્યું છે...',
      'hi': 'पुश सूचना भेजी जा रही है...',
      'en': 'Sending push notification...',
    },
    'valid_phone_number_not_found': {
      'gu': 'માન્ય ફોન નંબર મળ્યો નથી.',
      'hi': 'वैध फ़ोन नंबर नहीं मिला.',
      'en': 'Valid phone number not found.',
    },
    'txt_20society20get20pass20context': {
      'gu': '},%20સોસાયટી%20ગેટ%20પાસ%20સંદર્ભે.',
      'hi': '},%20समाज%20प्राप्त%20पास%20संदर्भ।',
      'en': '},%20society%20get%20pass%20context.',
    },
    'not_available': {
      'gu': 'ઉપલબ્ધ નથી',
      'hi': 'उपलब्ध नहीं है',
      'en': 'Not available',
    },
    'admission_approved': {
      'gu': 'પ્રવેશ મંજૂર (Approved)',
      'hi': 'प्रवेश स्वीकृत',
      'en': 'Admission Approved',
    },
    'admission_rejected': {
      'gu': 'પ્રવેશ નકાર્યો (Rejected)',
      'hi': 'प्रवेश अस्वीकृत',
      'en': 'Admission Rejected',
    },
    'checkedout_from_society': {
      'gu': 'સોસાયટીમાંથી બહાર ગયા (Checked-out)',
      'hi': 'सोसायटी से चेक-आउट किया गया',
      'en': 'Checked-out from society',
    },
    'pending_approval_2': {
      'gu': 'મંજૂરીની રાહ (Pending Approval)',
      'hi': 'अनुमोदन लंबित',
      'en': 'Pending Approval',
    },
    'just_arrived': {
      'gu': 'હમણાં જ આવ્યા',
      'hi': 'अभी आया',
      'en': 'Just arrived',
    },
    'vegetables': {
      'gu': 'શાકભાજી',
      'hi': 'सब्जियाँ',
      'en': 'vegetables',
    },
    'cook_2': {
      'gu': 'કૂક',
      'hi': 'पकाना',
      'en': 'Cook',
    },
    'pending_approval_3': {
      'gu': 'મંજૂરીની રાહ (Pending)',
      'hi': 'अनुमोदन लंबित है',
      'en': 'Pending approval',
    },
    'visitor_complete_details': {
      'gu': 'વિઝિટર સંપૂર્ણ વિગતો',
      'hi': 'विजिटर की पूरी जानकारी',
      'en': 'Visitor complete details',
    },
    'a_general_visit': {
      'gu': 'સામાન્ય મુલાકાત',
      'hi': 'एक सामान्य दौरा',
      'en': 'A general visit',
    },
    'verification_logs': {
      'gu': 'ચકાસણી અને સમય વિગત (Verification & Logs):',
      'hi': 'सत्यापन और लॉग:',
      'en': 'Verification & Logs:',
    },
    'entry_time_4': {
      'gu': 'પ્રવેશ સમય (Entry Time)',
      'hi': 'प्रवेश समय',
      'en': 'Entry Time',
    },
    'exit_time_3': {
      'gu': 'બહાર ગયા (Exit Time)',
      'hi': 'बाहर निकलने का समय',
      'en': 'Exit Time',
    },
    'still_within_the_society': {
      'gu': 'હજુ સોસાયટીની અંદર જ છે',
      'hi': 'अभी भी समाज के अंदर',
      'en': 'Still within the society',
    },
    'duration_of_total_stay': {
      'gu': 'કુલ રોકાણનો સમયગાળો (Duration)',
      'hi': 'कुल प्रवास की अवधि',
      'en': 'Duration of Total Stay',
    },
    'target_flat_building': {
      'gu': 'લક્ષ્ય ફ્લેટ / મકાન',
      'hi': 'लक्ष्य फ्लैट/भवन',
      'en': 'Target Flat / Building',
    },
    'host': {
      'gu': 'રહીશ / યજમાન (Host)',
      'hi': 'मेज़बान',
      'en': 'Host',
    },
    'registration_gate_security': {
      'gu': 'નોંધણી ગેટ / સુરક્ષા',
      'hi': 'पंजीकरण गेट/सुरक्षा',
      'en': 'Registration Gate / Security',
    },
    'main_society_gate_security_checkpoint': {
      'gu': 'મુખ્ય સોસાયટી ગેટ (સુરક્ષા ચેકપોઇન્ટ)',
      'hi': 'मुख्य सोसायटी गेट (सुरक्षा जांच चौकी)',
      'en': 'Main Society Gate (Security Checkpoint)',
    },
    'gate_action': {
      'gu': 'ગેટ પ્રવેશ નિર્ણય (Gate Action):',
      'hi': 'गेट एक्शन:',
      'en': 'Gate Action:',
    },
    'allow_access': {
      'gu': 'પ્રવેશ મંજૂર કરો',
      'hi': 'पहुंच की अनुमति दें',
      'en': 'Allow access',
    },
    'valid_phone_number_not_found_2': {
      'gu': 'માન્ય ફોન નંબર મળ્યો નથી',
      'hi': 'वैध फ़ोन नंबर नहीं मिला',
      'en': 'Valid phone number not found',
    },
    'incorrect_parking_alert': {
      'gu': 'ખોટું પાર્કિંગ એલર્ટ',
      'hi': 'ग़लत पार्किंग चेतावनी',
      'en': 'Incorrect parking alert',
    },
    'send_an_alert': {
      'gu': 'એલર્ટ મોકલો',
      'hi': 'अलर्ट भेजें',
      'en': 'Send an alert',
    },
    'vehicle_removal_request': {
      'gu': '🚨 વાહન હટાવવાની વિનંતી',
      'hi': '🚨 वाहन हटाने का अनुरोध',
      'en': '🚨 Vehicle removal request',
    },
    'parking_alert_successfully_sent': {
      'gu': 'પાર્કિંગ એલર્ટ સફળતાપૂર્વક મોકલાયું!',
      'hi': 'पार्किंग अलर्ट सफलतापूर्वक भेजा गया!',
      'en': 'Parking alert successfully sent!',
    },
    'vehicle_number_search_vehicle_lookup': {
      'gu': 'વાહન નંબર સર્ચ (Vehicle Lookup)',
      'hi': 'वाहन नंबर खोज (वाहन लुकअप)',
      'en': 'Vehicle Number Search (Vehicle Lookup)',
    },
    'resident_vehicle_details_and_parking_information': {
      'gu': 'રહેવાસી વાહન વિગત અને પાર્કિંગ માહિતી',
      'hi': 'निवासी वाहन विवरण और पार्किंग जानकारी',
      'en': 'Resident vehicle details and parking information',
    },
    'find_vehicle_number_eg_gj01_model': {
      'gu': 'ગાડી નંબર (દા.ત. GJ-01), મોડેલ કે ફ્લેટ શોધો...',
      'hi': 'वाहन नंबर (जैसे GJ-01), मॉडल या फ़्लैट ढूंढें...',
      'en': 'Find vehicle number (eg GJ-01), model or flat...',
    },
    'parking_alert': {
      'gu': 'પાર્કિંગ એલર્ટ',
      'hi': 'पार्किंग चेतावनी',
      'en': 'Parking Alert',
    },
    'no_vehicle_is_registered_with_the': {
      'gu': 'સોસાયટીમાં કોઈ વાહન નોંધાયેલ નથી',
      'hi': 'कोई भी वाहन सोसायटी में पंजीकृत नहीं है',
      'en': 'No vehicle is registered with the society',
    },
    'reverify_vehicle_number_model_or_flat': {
      'gu': 'ગાડી નંબર, મોડેલ અથવા ફ્લેટ નંબર ફરીથી ચકાસો.',
      'hi': 'वाहन नंबर, मॉडल या फ्लैट नंबर को दोबारा सत्यापित करें।',
      'en': 'Re-verify vehicle number, model or flat number.',
    },
    'no_vehicle_has_been_registered_by': {
      'gu': 'હજુ સુધી કોઈ સભ્ય દ્વારા વાહનની નોંધણી કરવામાં આવી નથી.',
      'hi': 'अभी तक किसी भी सदस्य द्वारा कोई वाहन पंजीकृत नहीं कराया गया है।',
      'en': 'No vehicle has been registered by any member yet.',
    },
    'members_can_add_vehicle_number_from': {
      'gu': 'સભ્યો પોતાની પ્રોફાઇલમાંથી વાહન નંબર ઉમેરી શકે છે.',
      'hi': 'सदस्य अपनी प्रोफ़ाइल से वाहन नंबर जोड़ सकते हैं।',
      'en': 'Members can add vehicle number from their profile.',
    },
    'view_all_vehicles': {
      'gu': 'બધા વાહનો જુઓ',
      'hi': 'सभी वाहन देखें',
      'en': 'View all vehicles',
    },
    'avg_recovery_rate': {
      'gu': 'સરેરાશ વસૂલાત દર',
      'hi': 'औसत वसूली दर',
      'en': 'Avg Recovery Rate',
    },
    'guests_label': {
      'gu': 'મહેમાનો',
      'hi': 'आगंतुक',
      'en': 'Guests',
    },
    'guards_label': {
      'gu': 'જવાનો',
      'hi': 'गार्ड',
      'en': 'Guards',
    },
    'complaints_label': {
      'gu': 'ફરિયાદો',
      'hi': 'शिकायतें',
      'en': 'Complaints',
    },
    'call_btn': {
      'gu': 'કૉલ કરો',
      'hi': 'कॉल करें',
      'en': 'Call',
    },
    'view_appeal_btn': {
      'gu': 'અપીલ જુઓ',
      'hi': 'अपील देखें',
      'en': 'View Appeal',
    },
    'society_appeals_tab': {
      'gu': 'સોસાયટી અપીલ્સ',
      'hi': 'सोसायटी अपील',
      'en': 'Society Appeals',
    },
    'admin_messages_tab': {
      'gu': 'એડમિન સંદેશાઓ',
      'hi': 'व्यवस्थापक संदेश',
      'en': 'Admin Messages',
    },
    'call_short': {
      'gu': 'કૉલ',
      'hi': 'कॉल',
      'en': 'Call',
    },
    'registered_on': {
      'gu': 'રજિસ્ટર્ડ',
      'hi': 'पंजीकृत',
      'en': 'Registered',
    },
    'flats_shops': {
      'gu': 'ફ્લેટ્સ/દુકાનો',
      'hi': 'फ्लैट्स/दुकानें',
      'en': 'Flats/Shops',
    },
    'units_suffix': {
      'gu': 'ફ્લેટ્સ/દુકાનો',
      'hi': 'फ्लैट्स/दुकानें',
      'en': 'Flats/Shops',
    },
    'members_suffix': {
      'gu': 'સભ્યો',
      'hi': 'सदस्य',
      'en': 'Members',
    },
    'guards_suffix': {
      'gu': 'ગાર્ડ્સ',
      'hi': 'गार्ड',
      'en': 'Guards',
    },
    'complaints_suffix': {
      'gu': 'ફરિયાદો',
      'hi': 'शिकायतें',
      'en': 'Complaints',
    },
    'appeal_notif_prefix': {
      'gu': '',
      'hi': '',
      'en': '',
    },
    'appeal_notif_suffix': {
      'gu': 'તરફથી સોસાયટી અનબ્લોક કરવાની અપીલ વિનંતી આવી છે.',
      'hi': 'की ओर से सोसायटी अनब्लॉक करने का अपील अनुरोध आया है।',
      'en': 'has requested to unblock society appeal.',
    },
    'no_pending_appeals_yet': {
      'gu': 'હાલ કોઈ અપીલ વિનંતી પેન્ડિંગ નથી.',
      'hi': 'फिलहाल कोई अपील अनुरोध लंबित नहीं है।',
      'en': 'No appeal requests pending.',
    },
    'સોસાયટી અપીલ્સ': {
      'gu': 'સોસાયટી અપીલ્સ',
      'hi': 'सोसायटी अपील',
      'en': 'Society Appeals',
    },
    'એડમિન સંદેશાઓ': {
      'gu': 'એડમિન સંદેશાઓ',
      'hi': 'व्यवस्थापक संदेश',
      'en': 'Admin Messages',
    },
    'કૉલ કરો': {
      'gu': 'કૉલ કરો',
      'hi': 'कॉल करें',
      'en': 'Call',
    },
    'અપીલ જુઓ': {
      'gu': 'અપીલ જુઓ',
      'hi': 'अपील देखें',
      'en': 'View Appeal',
    },
    'કૉલ': {
      'gu': 'કૉલ',
      'hi': 'कॉल',
      'en': 'Call',
    },
    'હાલ કોઈ અપીલ વિનંતી પેન્ડિંગ નથી.': {
      'gu': 'હાલ કોઈ અપીલ વિનંતી પેન્ડિંગ નથી.',
      'hi': 'फिलहाल कोई अपील अनुरोध लंबित नहीं है।',
      'en': 'No appeal requests pending.',
    },
    'past_appeal_history_title': {
      'gu': 'ગત અપીલ અને પ્રત્યુત્તર ઇતિહાસ',
      'hi': 'पिछली अपील एवं उत्तर इतिहास',
      'en': 'Past Appeal & Reply History',
    },
    'past_appeal_resolved_badge': {
      'gu': 'અગાઉ ઉકેલાયેલ',
      'hi': 'पहले हल किया गया',
      'en': 'Previously Resolved',
    },
    'current_appeal_pending_title': {
      'gu': 'અપીલ સુપર એડમિન સમીક્ષા હેઠળ છે',
      'hi': 'अपीલ सुपर एडमिन की समीक्षाधीन है',
      'en': 'Appeal Under Super Admin Review',
    },
    'current_appeal_pending_hint': {
      'gu': 'તમારી પુનઃસક્રિયતા અપીલ સુપર એડમિનની સમીક્ષા હેઠળ છે. સુપર એડમિન દ્વારા ટૂંક સમયમાં નિર્ણય લેવામાં આવશે.',
      'hi': 'आपकी पुनर्प्रवर्तन अपील सुपर एडमिन की समीक्षा में है। जल्द ही निर्णय लिया जाएगा।',
      'en': 'Your reactivation appeal is under Super Admin review. A decision will be made shortly.',
    },
    'send_additional_appeal_btn': {
      'gu': 'બીજો સંદેશ અથવા સુધારેલી અપીલ મોકલો',
      'hi': 'अन्य संदेश या संशोधित अपील भेजें',
      'en': 'Send Additional Note or Appeal',
    },
    'reconsideration_appeal_form_title': {
      'gu': 'પુનઃવિચારણા અપીલ ફોર્મ',
      'hi': 'पुनर्विचार अपील फॉर्म',
      'en': 'Reconsideration Appeal Form',
    },

    // Bottom Navigation Tabs
    'nav_home': {
      'gu': 'હોમ',
      'hi': 'होम',
      'en': 'Home',
    },
    'nav_security': {
      'gu': 'સિક્યોરિટી',
      'hi': 'सुरक्षा',
      'en': 'Security',
    },
    'nav_finance': {
      'gu': 'હિસાબ',
      'hi': 'हिसाब',
      'en': 'Finance',
    },
    'nav_society': {
      'gu': 'સોસાયટી',
      'hi': 'सोसायटी',
      'en': 'Society',
    },

    // Drawer - General Section
    'drawer_general_settings': {
      'gu': 'સામાન્ય સેટિંગ્સ',
      'hi': 'सामान्य सेटिंग्स',
      'en': 'General Settings',
    },
    'drawer_my_profile': {
      'gu': 'મારી પ્રોફાઇલ & સોસાયટી',
      'hi': 'मेरी प्रोफ़ाइल और सोसायटी',
      'en': 'My Profile & Society',
    },
    'drawer_my_profile_sub': {
      'gu': 'વ્યક્તિગત & ફ્લેટ વિગતો જુઓ',
      'hi': 'व्यक्तिगत और फ्लैट विवरण देखें',
      'en': 'View personal & unit details',
    },
    'drawer_change_language': {
      'gu': 'ભાષા બદલો (Language)',
      'hi': 'भाषा बदलें (Language)',
      'en': 'Change Language',
    },
    'drawer_admin_shortcuts': {
      'gu': 'એડમિન કંટ્રોલ & શોર્ટકટ્સ',
      'hi': 'एडमिन कंट्रोल और शॉर्टकट',
      'en': 'Admin Controls & Shortcuts',
    },
    'drawer_member_shortcuts': {
      'gu': 'મારા શોર્ટકટ્સ',
      'hi': 'मेरे शॉर्टकट',
      'en': 'My Shortcuts',
    },
    'drawer_security_shortcuts': {
      'gu': 'સિક્યોરિટી શોર્ટકટ્સ',
      'hi': 'सुरक्षा शॉर्टकट',
      'en': 'Security Shortcuts',
    },
    'drawer_super_admin_shortcuts': {
      'gu': 'સુપર એડમિન શોર્ટકટ્સ',
      'hi': 'सुपर एडमिन शॉर्टकट',
      'en': 'Super Admin Shortcuts',
    },

    // Drawer Admin items
    'drawer_bank_settings': {
      'gu': 'સોસાયટી બેંક & UPI સેટિંગ્સ',
      'hi': 'सोसायटी बैंक और UPI सेटिंग्स',
      'en': 'Society Bank & UPI Settings',
    },
    'drawer_bank_settings_sub': {
      'gu': 'QR કોડ & બેંક એકાઉન્ટ માહિતી',
      'hi': 'QR कोड और बैंक खाता विवरण',
      'en': 'QR Code & Bank Account Info',
    },
    'drawer_directory': {
      'gu': 'મેમ્બર્સ & સ્ટાફ ડિરેક્ટરી',
      'hi': 'सदस्य एवं स्टाफ डायरेक्टरी',
      'en': 'Members & Staff Directory',
    },
    'drawer_directory_sub': {
      'gu': 'તમામ સભ્યો અને સ્ટાફની યાદી',
      'hi': 'सभी सदस्यों और कर्मचारियों की सूची',
      'en': 'List of all members & staff',
    },
    'drawer_maintenance': {
      'gu': 'મેઇન્ટેનન્સ મેનેજમેન્ટ',
      'hi': 'रखरखाव प्रबंधन',
      'en': 'Maintenance Management',
    },
    'drawer_maintenance_sub': {
      'gu': 'બિલિંગ, પેમેન્ટ્સ & રસીદો',
      'hi': 'बिलिंग, भुगतान एवं रसीदें',
      'en': 'Billing, Payments & Receipts',
    },
    'drawer_complaints': {
      'gu': 'ફરિયાદો & નિરાકરણ',
      'hi': 'शिकायतें एवं निवारण',
      'en': 'Complaints & Resolutions',
    },
    'drawer_complaints_sub': {
      'gu': 'સભ્યોની ફરિયાદો તપાસો',
      'hi': 'सदस्यों की शिकायतों की जाँच करें',
      'en': 'Review member complaints',
    },
    'drawer_broadcast': {
      'gu': 'બ્રોડકાસ્ટ & નોટિસ બોર્ડ',
      'hi': 'प्रसारण एवं नोटिस बोर्ड',
      'en': 'Broadcast & Notice Board',
    },
    'drawer_broadcast_sub': {
      'gu': 'સોસાયટીમાં મહત્વની સૂચના મોકલો',
      'hi': 'सोसायटी में महत्वपूर्ण सूचना भेजें',
      'en': 'Send notices to society',
    },
    'drawer_accounts': {
      'gu': 'સોસાયટી એકાઉન્ટ્સ & ઑડિટ',
      'hi': 'सोसायटी खाते एवं ऑडिट',
      'en': 'Society Accounts & Audit',
    },
    'drawer_accounts_sub': {
      'gu': 'આવક, ખર્ચ & બેલેન્સ શીટ',
      'hi': 'आय, व्यय एवं बैलेंस शीट',
      'en': 'Income, Expense & Balance Sheet',
    },
    'drawer_help_security': {
      'gu': 'સહાય & સુરક્ષા',
      'hi': 'सहायता एवं सुरक्षा',
      'en': 'Help & Security',
    },
    'drawer_emergency_helpline': {
      'gu': 'ઇમરજન્સી હેલ્પલાઇન નંબર્સ',
      'hi': 'आपातकालीन हेल्पलाइन नंबर',
      'en': 'Emergency Helpline Numbers',
    },
    'drawer_emergency_helpline_sub': {
      'gu': 'પોલીસ, ફાયર, એમ્બ્યુલન્સ',
      'hi': 'पुलिस, फायर, एम्बुलेंस',
      'en': 'Police, Fire, Ambulance',
    },
    'drawer_app_security': {
      'gu': 'એપ સુરક્ષા & ગોપનીયતા',
      'hi': 'ऐप सुरक्षा और गोपनीयता',
      'en': 'App Security & Privacy',
    },
    'drawer_app_security_sub': {
      'gu': 'એન્ડ-ટુ-એન્ડ સુરક્ષિત',
      'hi': 'एंड-टू-एंड सुरक्षित',
      'en': 'End-to-End Secure',
    },
    'drawer_logout': {
      'gu': 'લૉગઆઉટ',
      'hi': 'लॉगआउट',
      'en': 'Logout',
    },
    'drawer_active_status': {
      'gu': 'સક્રિય',
      'hi': 'सक्रिय',
      'en': 'Active',
    },

    // Security Tab
    'sec_gate_control_title': {
      'gu': 'સિક્યોરિટી & ગેટ કંટ્રોલ',
      'hi': 'सुरक्षा एवं गेट नियंत्रण',
      'en': 'Security & Gate Control',
    },
    'sec_night_patrol': {
      'gu': 'રાત્રિ પેટ્રોલિંગ',
      'hi': 'रात्रि गश्त (पेट्रोलिंग)',
      'en': 'Night Patrol',
    },
    'sec_qr_checkpoints': {
      'gu': 'QR ચેકપોઇન્ટ્સ',
      'hi': 'QR चेकपॉइंट्स',
      'en': 'QR Checkpoints',
    },
    'sec_watchmen_staff': {
      'gu': 'વોચમેન સ્ટાફ',
      'hi': 'वॉचमैन स्टाफ',
      'en': 'Guard Staff',
    },
    'sec_on_duty_pin': {
      'gu': 'ઓન-ડ્યુટી & પિન',
      'hi': 'ऑन-ड्यूटी एवं पिन',
      'en': 'On-Duty & PIN',
    },
    'sec_visitor_report': {
      'gu': 'વિઝિટર રિપોર્ટ',
      'hi': 'आगंतुक रिपोर्ट',
      'en': 'Visitor Report',
    },
    'sec_history_excel': {
      'gu': 'હિસ્ટ્રી & એક્સેલ',
      'hi': 'इतिहास एवं एक्सेल',
      'en': 'History & Excel',
    },
    'sec_emergency_help': {
      'gu': 'ઇમરજન્સી હેલ્પ',
      'hi': 'आपातकालीन सहायता',
      'en': 'Emergency Help',
    },
    'sec_contact_numbers': {
      'gu': 'સંપર્ક નંબર',
      'hi': 'संपर्क नंबर',
      'en': 'Contact Numbers',
    },
    'sec_live_gate_feed': {
      'gu': 'લાઇવ ગેટ ગતિવિધિ',
      'hi': 'लाइव गेट गतिविधि',
      'en': 'Live Gate Activity',
    },
    'sec_filter_all': {
      'gu': 'બધા',
      'hi': 'सभी',
      'en': 'All',
    },
    'sec_filter_at_gate': {
      'gu': 'ગેટ પર',
      'hi': 'गेट पर',
      'en': 'At Gate',
    },
    'sec_filter_inside': {
      'gu': 'અંદર છે',
      'hi': 'अंदर हैं',
      'en': 'Inside',
    },
    'sec_filter_out': {
      'gu': 'બહાર ગયા',
      'hi': 'प्रस्थान किया',
      'en': 'Checked Out',
    },

    // Accounts / Finance Tab
    'fin_accounts_title': {
      'gu': 'હિસાબ & બેંક સેટિંગ્સ',
      'hi': 'हिसाब एवं बैंक सेटिंग्स',
      'en': 'Accounts & Bank Settings',
    },
    'fin_society_ledger': {
      'gu': 'સોસાયટી ખાતાવહી',
      'hi': 'सोसायटी बहीखाता',
      'en': 'Society Ledger',
    },
    'fin_expense_passbook': {
      'gu': 'ખર્ચ & પાસબુક',
      'hi': 'खर्च एवं पासबुक',
      'en': 'Expense & Passbook',
    },
    'fin_maintenance_desk': {
      'gu': 'મેઇન્ટેનન્સ ડેસ્ક',
      'hi': 'रखरखाव डेस्क',
      'en': 'Maintenance Desk',
    },
    'fin_bills_payments': {
      'gu': 'બિલ & પેમેન્ટ',
      'hi': 'बिल एवं भुगतान',
      'en': 'Bills & Payments',
    },
    'fin_bulk_billing': {
      'gu': 'બલ્ક બિલિંગ',
      'hi': 'बल्क बिलिंग',
      'en': 'Bulk Billing',
    },
    'fin_all_flats_together': {
      'gu': 'બધા ફ્લેટ એકસાથે',
      'hi': 'सभी फ्लैट एक साथ',
      'en': 'All Flats Together',
    },
    'fin_bank_upi': {
      'gu': 'બેંક / UPI સેટિંગ',
      'hi': 'बैंक / UPI सेटिंग',
      'en': 'Bank / UPI Setting',
    },
    'fin_qr_account_info': {
      'gu': 'QR & એકાઉન્ટ માહિતી',
      'hi': 'QR एवं खाता जानकारी',
      'en': 'QR & Account Info',
    },
    'fin_member_signature_sheet': {
      'gu': 'સદસ્ય સહી પત્રક (PDF)',
      'hi': 'सदस्य हस्ताक्षर प्रपत्र (PDF)',
      'en': 'Member Signature Sheet (PDF)',
    },
    'fin_annual_sign_verification': {
      'gu': 'વાર્ષિક સહી લિસ્ટ વેરિફિકેશન',
      'hi': 'वार्षिक हस्ताक्षर सत्यापन',
      'en': 'Annual Sign Verification',
    },

    // Analytics Card
    'analytics_visitor_title': {
      'gu': 'મુલાકાતી વિશ્લેષણ',
      'hi': 'आगंतुक विश्लेषण',
      'en': 'Visitor Analytics',
    },
    'analytics_visitor_subtitle': {
      'gu': 'ગેટ ટ્રાફિક & એન્ટ્રી આંકડા',
      'hi': 'गेट यातायात और प्रवेश आँकड़े',
      'en': 'Gate traffic & entry statistics',
    },
    'analytics_total_prefix': {
      'gu': 'કુલ',
      'hi': 'कुल',
      'en': 'Total',
    },
    'analytics_approved': {
      'gu': 'સ્વીકૃત',
      'hi': 'स्वीकृत',
      'en': 'Approved',
    },
    'analytics_pending': {
      'gu': 'બાકી',
      'hi': 'शेष',
      'en': 'Pending',
    },
    'analytics_rejected': {
      'gu': 'અસ્વીકૃત',
      'hi': 'अस्वीकृत',
      'en': 'Rejected',
    },
    'analytics_checked_out': {
      'gu': 'પ્રસ્થાન કર્યું',
      'hi': 'प्रस्थान किया',
      'en': 'Checked Out',
    },
    'analytics_top_blocks': {
      'gu': 'સૌથી વધુ વિઝિટર્સ ધરાવતા બ્લોક્સ',
      'hi': 'सर्वाधिक विज़िटर वाले ब्लॉक',
      'en': 'Top Visitor Blocks',
    },

    // =============================================================
    // Drawer & Role Shortcuts (Canonical Keys)
    // =============================================================
    'drawer_members_directory': {
      'gu': 'મેમ્બર્સ & સ્ટાફ ડિરેક્ટરી',
      'hi': 'सदस्य एवं स्टाफ डायरेक्टरी',
      'en': 'Members & Staff Directory',
    },
    'drawer_members_subtitle': {
      'gu': 'તમામ સભ્યો અને સ્ટાફની યાદી',
      'hi': 'सभी सदस्यों और कर्मचारियों की सूची',
      'en': 'List of all members & staff',
    },
    'drawer_maintenance_mgmt': {
      'gu': 'મેઇન્ટેનન્સ મેનેજમેન્ટ',
      'hi': 'रखरखाव प्रबंधन',
      'en': 'Maintenance Management',
    },
    'drawer_maintenance_subtitle': {
      'gu': 'બિલિંગ, પેમેન્ટ્સ & રસીદો',
      'hi': 'बिलिंग, भुगतान एवं रसीदें',
      'en': 'Billing, Payments & Receipts',
    },
    'drawer_complaints_res': {
      'gu': 'ફરિયાદો & નિરાકરણ',
      'hi': 'शिकायतें एवं निवारण',
      'en': 'Complaints & Resolutions',
    },
    'drawer_complaints_subtitle': {
      'gu': 'સભ્યોની ફરિયાદો તપાસો',
      'hi': 'सदस्यों की शिकायतों की जाँच करें',
      'en': 'Review member complaints',
    },
    'drawer_broadcast_notice': {
      'gu': 'બ્રોડકાસ્ટ & નોટિસ બોર્ડ',
      'hi': 'प्रसारण एवं नोटिस बोर्ड',
      'en': 'Broadcast & Notice Board',
    },
    'drawer_broadcast_subtitle': {
      'gu': 'સોસાયટીમાં મહત્વની સૂચના મોકલો',
      'hi': 'सोसायटी में महत्वपूर्ण सूचना भेजें',
      'en': 'Send notices to society',
    },
    'drawer_society_accounts': {
      'gu': 'સોસાયટી એકાઉન્ટ્સ & ઓડિટ',
      'hi': 'सोसायटी खाते एवं ऑडिट',
      'en': 'Society Accounts & Audit',
    },
    'drawer_society_accounts_subtitle': {
      'gu': 'આવક, ખર્ચ & બેલેન્સ શીટ',
      'hi': 'आय, व्यय एवं बैलेंस शीट',
      'en': 'Income, Expense & Balance Sheet',
    },
    'drawer_polls_opinions': {
      'gu': 'પોલ્સ & મંતવ્યો (Polls)',
      'hi': 'पोल एवं राय (Polls)',
      'en': 'Polls & Opinions',
    },
    'drawer_polls_subtitle': {
      'gu': 'સોસાયટી વોટિંગ & સર્વે',
      'hi': 'सोसायटी वोटिंग एवं सर्वेक्षण',
      'en': 'Society Voting & Survey',
    },
    'drawer_view_personal_flat': {
      'gu': 'વ્યક્તિગત & ફ્લેટ વિગતો જુઓ',
      'hi': 'व्यक्तिगत और फ्लैट विवरण देखें',
      'en': 'View personal & unit details',
    },
    'drawer_bank_subtitle': {
      'gu': 'QR કોડ & બેંક એકાઉન્ટ માહિતી',
      'hi': 'QR कोड और बैंक खाता विवरण',
      'en': 'QR Code & Bank Account Info',
    },
    'drawer_support_security': {
      'gu': 'સહાય & સુરક્ષા',
      'hi': 'सहायता एवं सुरक्षा',
      'en': 'Help & Security',
    },
    'drawer_emergency_numbers': {
      'gu': 'ઇમરજન્સી હેલ્પલાઇન નંબર્સ',
      'hi': 'आपातकालीन हेल्पलाइन नंबर',
      'en': 'Emergency Helpline Numbers',
    },
    'drawer_emergency_subtitle': {
      'gu': 'પોલીસ, ફાયર, એમ્બ્યુલન્સ',
      'hi': 'पुलिस, फायर, एम्बुलेंस',
      'en': 'Police, Fire, Ambulance',
    },
    'drawer_end_to_end_secure': {
      'gu': 'એન્ડ-ટુ-એન્ડ સુરક્ષિત',
      'hi': 'एंड-टू-एंड सुरक्षित',
      'en': 'End-to-End Secure',
    },
    'drawer_my_shortcuts': {
      'gu': 'મારા શોર્ટકટ્સ',
      'hi': 'मेरे शॉर्टकट',
      'en': 'My Shortcuts',
    },
    'sign_out': {
      'gu': 'સાઇન આઉટ',
      'hi': 'साइन आउट',
      'en': 'Sign Out',
    },

    // =============================================================
    // Drawer Shortcuts (Role Based Phrases)
    // =============================================================
    'ગાર્ડ પેટ્રોલીંગ (QR Patrol)': {
      'gu': 'ગાર્ડ પેટ્રોલીંગ (QR Patrol)',
      'hi': 'गार्ड गश्त (QR Patrol)',
      'en': 'Guard Patrol (QR Patrol)',
    },
    'ચોકીદાર પેટ્રોલિંગ લોગ્સ': {
      'gu': 'ચોકીદાર પેટ્રોલિંગ લોગ્સ',
      'hi': 'चौकीदार गश्त लॉग',
      'en': 'Watchman patrol logs',
    },
    'મારા વાહનો (My Vehicles)': {
      'gu': 'મારા વાહનો (My Vehicles)',
      'hi': 'मेरे वाहन (My Vehicles)',
      'en': 'My Vehicles',
    },
    'રજિસ્ટર્ડ વાહનો & પાર્કિંગ': {
      'gu': 'રજિસ્ટર્ડ વાહનો & પાર્કિંગ',
      'hi': 'पंजीकृत वाहन एवं पार्किंग',
      'en': 'Registered Vehicles & Parking',
    },
    'પ્રિ-અપ્રૂવ્ડ વિઝિટર્સ': {
      'gu': 'પ્રિ-અપ્રૂવ્ડ વિઝિટર્સ',
      'hi': 'पूर्व-स्वीकृत आगंतुक',
      'en': 'Pre-Approved Visitors',
    },
    'મહેમાન અથવા ડિલિવરી પાસ બનાવો': {
      'gu': 'મહેમાન અથવા ડિલિવરી પાસ બનાવો',
      'hi': 'अतिथि या डिलीवरी पास बनाएं',
      'en': 'Create guest or delivery pass',
    },
    'ડેઇલી સ્ટાફ & હેલ્પર્સ': {
      'gu': 'ડેઇલી સ્ટાફ & હેલ્પર્સ',
      'hi': 'दैनिक स्टाफ एवं सहायक',
      'en': 'Daily Staff & Helpers',
    },
    'કામવાળા બાઈ, ડ્રાઈવર, કૂક': {
      'gu': 'કામવાળા બાઈ, ડ્રાઈવર, કૂક',
      'hi': 'घरेलू सहायिका, ड्राइवर, कुक',
      'en': 'Housekeeper, driver, cook',
    },
    'ફરિયાદ નોંધાવો (Complaints)': {
      'gu': 'ફરિયાદ નોંધાવો (Complaints)',
      'hi': 'शिकायत दर्ज करें (Complaints)',
      'en': 'Register Complaint',
    },
    'સોસાયટી કમિટીને ફરિયાદ મોકલો': {
      'gu': 'સોસાયટી કમિટીને ફરિયાદ મોકલો',
      'hi': 'सोसायटी समिति को शिकायत भेजें',
      'en': 'Send complaint to society committee',
    },
    'સોસાયટી એકાઉન્ટ સ્ટેટમેન્ટ': {
      'gu': 'સોસાયટી એકાઉન્ટ સ્ટેટમેન્ટ',
      'hi': 'सोसायटी खाता विवरण',
      'en': 'Society Account Statement',
    },
    'સોસાયટીના ખર્ચ અને ફંડ વિગતો': {
      'gu': 'સોસાયટીના ખર્ચ અને ફંડ વિગતો',
      'hi': 'सोसायटी के व्यय और फंड का विवरण',
      'en': 'Society expense and fund details',
    },
    'પોલ્સ & વોટિંગ (Polls)': {
      'gu': 'પોલ્સ & વોટિંગ (Polls)',
      'hi': 'पोल एवं वोटिंग (Polls)',
      'en': 'Polls & Voting',
    },
    'તમારો કિંમતી મત આપો': {
      'gu': 'તમારો કિંમતી મત આપો',
      'hi': 'अपना बहुमूल्य वोट दें',
      'en': 'Cast your valuable vote',
    },
    'વાહન નંબર સર્ચ (Vehicle Search)': {
      'gu': 'વાહન નંબર સર્ચ (Vehicle Search)',
      'hi': 'वाहन नंबर खोज (Vehicle Search)',
      'en': 'Vehicle Search',
    },
    'વાહન માલિકની ફ્લેટ વિગતો જાણો': {
      'gu': 'વાહન માલિકની ફ્લેટ વિગતો જાણો',
      'hi': 'वाहन मालिक के फ्लैट का विवरण जानें',
      'en': 'Find vehicle owner flat details',
    },
    'કૃપા કરીને હોમ સ્ક્રીન પરથી વાહન સર્ચ આયકન દબાવો': {
      'gu': 'કૃપા કરીને હોમ સ્ક્રીન પરથી વાહન સર્ચ આયકન દબાવો',
      'hi': 'कृपया होम स्क्रीन से वाहन खोज आइकन दबाएं',
      'en': 'Please tap the vehicle search icon on home screen',
    },
    'ઇમરજન્સી SOS મોકલો': {
      'gu': 'ઇમરજન્સી SOS મોકલો',
      'hi': 'आपातकालीन SOS भेजें',
      'en': 'Send Emergency SOS',
    },
    'તમામ એડમિન અને સભ્યોને તાત્કાલિક એલર્ટ': {
      'gu': 'તમામ એડમિન અને સભ્યોને તાત્કાલિક એલર્ટ',
      'hi': 'सभी एडमिन और सदस्यों को तत्काल अलर्ट',
      'en': 'Immediate alert to all admins and members',
    },
    'ઇમરજન્સી SOS હેડર આયકન પર ઉપલબ્ધ છે': {
      'gu': 'ઇમરજન્સી SOS હેડર આયકન પર ઉપલબ્ધ છે',
      'hi': 'आपातकालीन SOS हेडर आइकन पर उपलब्ध है',
      'en': 'Emergency SOS is available on the header icon',
    },
    'તમામ સોસાયટી ડિરેક્ટરી': {
      'gu': 'તમામ સોસાયટી ડિરેક્ટરી',
      'hi': 'सभी सोसायटी डायरेक्टरी',
      'en': 'All Societies Directory',
    },
    'રજિસ્ટર્ડ સોસાયટીઓ તપાસો': {
      'gu': 'રજિસ્ટર્ડ સોસાયટીઓ તપાસો',
      'hi': 'पंजीकृत सोसायटियों की जाँच करें',
      'en': 'Check registered societies',
    },
    'લાઈવ અપીલ્સ & વિનંતીઓ': {
      'gu': 'લાઈવ અપીલ્સ & વિનંતીઓ',
      'hi': 'लाइव अपील और अनुरोध',
      'en': 'Live Appeals & Requests',
    },
    'એડમિન્સ દ્વારા આવેલી અપીલ': {
      'gu': 'એડમિન્સ દ્વારા આવેલી અપીલ',
      'hi': 'एडमिन द्वारा भेजी गई अपील',
      'en': 'Appeals submitted by admins',
    },

    // =============================================================
    // Profile & Info Modal Labels
    // =============================================================
    'પ્રોફાઇલ & એકાઉન્ટ માહિતી': {
      'gu': 'પ્રોફાઇલ & એકાઉન્ટ માહિતી',
      'hi': 'प्रोफ़ाइल और खाता जानकारी',
      'en': 'Profile & Account Info',
    },
    'નામ:': {
      'gu': 'નામ:',
      'hi': 'नाम:',
      'en': 'Name:',
    },
    'મોબાઇલ:': {
      'gu': 'મોબાઇલ:',
      'hi': 'मोबाइल:',
      'en': 'Mobile:',
    },
    'સોસાયટી:': {
      'gu': 'સોસાયટી:',
      'hi': 'सोसायटी:',
      'en': 'Society:',
    },
    'ફ્લેટ / યુનિટ:': {
      'gu': 'ફ્લેટ / યુનિટ:',
      'hi': 'फ्लैट / यूनिट:',
      'en': 'Flat / Unit:',
    },
    'યુઝર આઈડી:': {
      'gu': 'યુઝર આઈડી:',
      'hi': 'यूज़र आईडी:',
      'en': 'User ID:',
    },
    'સુરક્ષા & ગોપનીયતા': {
      'gu': 'સુરક્ષા & ગોપનીયતા',
      'hi': 'सुरक्षा एवं गोपनीयता',
      'en': 'Security & Privacy',
    },
    'બરાબર છે': {
      'gu': 'બરાબર છે',
      'hi': 'ठीक है',
      'en': 'OK',
    },
    'સમજાઈ ગયું': {
      'gu': 'સમજાઈ ગયું',
      'hi': 'समझ गया',
      'en': 'Understood',
    },
    'વોચમેન / સિક્યોરિટી': {
      'gu': 'વોચમેન / સિક્યોરિટી',
      'hi': 'चौकीदार / सुरक्षा',
      'en': 'Watchman / Security',
    },
    'સોસાયટી સભ્ય (Member)': {
      'gu': 'સોસાયટી સભ્ય',
      'hi': 'सोसायटी सदस्य',
      'en': 'Society Member',
    },

    // =============================================================
    // Pre-Approve & Visitor Reasons
    // =============================================================
    'દા.ત. ટ્યુશન, ડોક્ટર, ઇન્ટરવ્યુ...': {
      'gu': 'દા.ત. ટ્યુશન, ડોક્ટર, ઇન્ટરવ્યુ...',
      'hi': 'उदा. ट्यूशन, डॉक्टर, इंटरव्यू...',
      'en': 'e.g. Tuition, Doctor, Interview...',
    },
    'નવો હેતુ ઉમેરો': {
      'gu': 'નવો હેતુ ઉમેરો',
      'hi': 'नया उद्देश्य जोड़ें',
      'en': 'Add New Purpose',
    },
    'હેતુનું નામ લખો *': {
      'gu': 'હેતુનું નામ લખો *',
      'hi': 'उद्देश्य का नाम लिखें *',
      'en': 'Enter purpose name *',
    },
    'હેતુ તરીકે પસંદ કર્યો.': {
      'gu': 'હેતુ તરીકે પસંદ કર્યો.',
      'hi': 'उद्देश्य के रूप में चुना गया।',
      'en': 'selected as purpose.',
    },
    '+ નવો હેતુ': {
      'gu': '+ નવો હેતુ',
      'hi': '+ नया उद्देश्य',
      'en': '+ New Purpose',
    },
    'ઉમેરો અને પસંદ કરો': {
      'gu': 'ઉમેરો અને પસંદ કરો',
      'hi': 'जोड़ें और चुनें',
      'en': 'Add and Select',
    },
    'ઝડપી સૂચનોમાંથી પસંદ કરો:': {
      'gu': 'ઝડપી સૂચનોમાંથી પસંદ કરો:',
      'hi': 'त्वरित सुझावों में से चुनें:',
      'en': 'Choose from quick suggestions:',
    },
    'મહેમાનના આવવાનું કારણ પસંદ કરો અથવા નવું લખો': {
      'gu': 'મહેમાનના આવવાનું કારણ પસંદ કરો અથવા નવું લખો',
      'hi': 'आगंतुक के आने का कारण चुनें या नया लिखें',
      'en': 'Select visit reason or type a new one',
    },
    '📚 ટ્યુશન / ક્લાસિસ': {
      'gu': '📚 ટ્યુશન / ક્લાસિસ',
      'hi': '📚 ट्यूशन / क्लासेज',
      'en': '📚 Tuition / Classes',
    },
    '🩺 ડોક્ટર / મેડિકલ': {
      'gu': '🩺 ડોક્ટર / મેડિકલ',
      'hi': '🩺 डॉक्टर / मेडिकल',
      'en': '🩺 Doctor / Medical',
    },
    '💼 ઓફિસ / ઇન્ટરવ્યુ': {
      'gu': '💼 ઓફિસ / ઇન્ટરવ્યુ',
      'hi': '💼 ऑफिस / इंटरव्यू',
      'en': '💼 Office / Interview',
    },
    '🎉 ઇવેન્ટ / પાર્ટી': {
      'gu': '🎉 ઇવેન્ટ / પાર્ટી',
      'hi': '🎉 इवेंट / पार्टी',
      'en': '🎉 Event / Party',
    },
    '🍽️ કેટરિંગ / રસોઈ': {
      'gu': '🍽️ કેટરિંગ / રસોઈ',
      'hi': '🍽️ कैटरिंग / रसोइया',
      'en': '🍽️ Catering / Cooking',
    },
    '🎨 પેઇન્ટર / સુથાર': {
      'gu': '🎨 પેઇન્ટર / સુથાર',
      'hi': '🎨 पेंटर / बढ़ई',
      'en': '🎨 Painter / Carpenter',
    },
    '🛒 શિફ્ટિંગ / સામાન': {
      'gu': '🛒 શિફ્ટિંગ / સામાન',
      'hi': '🛒 शिफ्टिंग / सामान',
      'en': '🛒 Shifting / Luggage',
    },
    '🧹 ઘરકામ / હેલ્પર': {
      'gu': '🧹 ઘરકામ / હેલ્પર',
      'hi': '🧹 घरेलू काम / सहायक',
      'en': '🧹 Maid / Helper',
    },

    // =============================================================
    // Member Dashboard & Actions
    // =============================================================
    'વિઝિટર્સ': {
      'gu': 'વિઝિટર્સ',
      'hi': 'आगंतुक',
      'en': 'Visitors',
    },
    'સેવાઓ': {
      'gu': 'સેવાઓ',
      'hi': 'सेवाएं',
      'en': 'Services',
    },
    'મેઇન્ટેનન્સ બિલ & રસીદ': {
      'gu': 'મેઇન્ટેનન્સ બિલ & રસીદ',
      'hi': 'रखरखाव बिल एवं रसीद',
      'en': 'Maintenance Bill & Receipt',
    },
    'પ્રી-એપ્રૂવ અતિથિ': {
      'gu': 'પ્રી-એપ્રૂવ અતિથિ',
      'hi': 'पूर्व-स्वीकृत अतिथि',
      'en': 'Pre-Approve Guest',
    },
    'સોસાયટી સેવાઓ & સુવિધાઓ': {
      'gu': 'સોસાયટી સેવાઓ & સુવિધાઓ',
      'hi': 'सोसायटी सेवाएं एवं सुविधाएं',
      'en': 'Society Services & Amenities',
    },
    'સોસાયટી પાસબુક (ખાતાવહી)': {
      'gu': 'સોસાયટી પાસબુક (ખાતાવહી)',
      'hi': 'सोसायटी पासबुक (खाताबही)',
      'en': 'Society Passbook (Ledger)',
    },
    'સોસાયટીના તમામ ખર્ચ & આવકનું ટ્રાન્સપરન્ટ સ્ટેટમેન્ટ': {
      'gu': 'સોસાયટીના તમામ ખર્ચ & આવકનું ટ્રાન્સપરન્ટ સ્ટેટમેન્ટ',
      'hi': 'सोसायटी के सभी खर्च और आय का पारदर्शी विवरण',
      'en': 'Transparent statement of all society income & expenses',
    },
    'UPI પેમેન્ટ, પાછલી રસીદો & બાકી સ્ટેટમેન્ટ': {
      'gu': 'UPI પેમેન્ટ, પાછલી રસીદો & બાકી સ્ટેટમેન્ટ',
      'hi': 'UPI भुगतान, पिछली रसीदें एवं बकाया विवरण',
      'en': 'UPI payments, past receipts & dues',
    },
    'ગેટ સિક્યોરિટી અને એડમિનને તાત્કાલિક એલર્ટ મોકલો': {
      'gu': 'ગેટ સિક્યોરિટી અને એડમિનને તાત્કાલિક એલર્ટ મોકલો',
      'hi': 'गेट सुरक्षा और एडमिन को तत्काल अलर्ट भेजें',
      'en': 'Send immediate alert to gate security & admin',
    },

    // =============================================================
    // Amenities, Booking, Staff, Guard
    // =============================================================
    'સોસાયટી રિઝર્વેશન હબ': {
      'gu': 'સોસાયટી રિઝર્વેશન હબ',
      'hi': 'सोसायटी आरक्षण हब',
      'en': 'Society Reservation Hub',
    },
    'સ્લોટ્સ': {
      'gu': 'સ્લોટ્સ',
      'hi': 'स्लॉट्स',
      'en': 'Slots',
    },
    'પ્રસંગ': {
      'gu': 'પ્રસંગ',
      'hi': 'अवसर / प्रसंग',
      'en': 'Event / Occasion',
    },
    'કોપી': {
      'gu': 'કોપી',
      'hi': 'कॉपी',
      'en': 'Copy',
    },
    'બુકિંગ': {
      'gu': 'બુકિંગ',
      'hi': 'बुकिंग',
      'en': 'Booking',
    },
    'નોંધાયેલ સ્ટાફ': {
      'gu': 'નોંધાયેલ સ્ટાફ',
      'hi': 'पंजीकृत स्टाफ',
      'en': 'Registered Staff',
    },
    'વિઝિટર લોગ': {
      'gu': 'વિઝિટર લોગ',
      'hi': 'आगंतुक लॉग',
      'en': 'Visitor Log',
    },
    'પેટ્રોલિંગ': {
      'gu': 'પેટ્રોલિંગ',
      'hi': 'गश्त (पेट्रोलिंग)',
      'en': 'Patrolling',
    },
    'ગેટ એન્ટ્રી': {
      'gu': 'ગેટ એન્ટ્રી',
      'hi': 'गेट प्रवेश',
      'en': 'Gate Entry',
    },

    // =============================================================
    // Super Admin Operations
    // =============================================================
    'ઓડિટ': {
      'gu': 'ઓડિટ',
      'hi': 'ऑडिट',
      'en': 'Audit',
    },
    'ઓપરેશન્સ': {
      'gu': 'ઓપરેશન્સ',
      'hi': 'संचालन (Operations)',
      'en': 'Operations',
    },
    'સૂચનાઓ & અપીલ્સ': {
      'gu': 'સૂચનાઓ & અપીલ્સ',
      'hi': 'सूचनाएं और अपील',
      'en': 'Notices & Appeals',
    },
    'રિવ્યુ કરો': {
      'gu': 'રિવ્યુ કરો',
      'hi': 'समीक्षा करें',
      'en': 'Review',
    },
    'સોસાયટી પુનઃસક્રિય (Unblocked) કરવામાં આવી છે.': {
      'gu': 'સોસાયટી પુનઃસક્રિય (Unblocked) કરવામાં આવી છે.',
      'hi': 'सोसायटी पुनः सक्रिय (Unblock) कर दी गई है।',
      'en': 'Society has been unblocked and reactivated.',
    },
    'એડમિન એકાઉન્ટ પુનઃસક્રિય (Unblocked) કરવામાં આવ્યું છે.': {
      'gu': 'એડમિન એકાઉન્ટ પુનઃસક્રિય (Unblocked) કરવામાં આવ્યું છે.',
      'hi': 'एडमिन खाता पुनः सक्रिय (Unblock) कर दिया गया है।',
      'en': 'Admin account has been unblocked and reactivated.',
    },

    // =============================================================
    // Suspended Notices & Alerts
    // =============================================================
    'સોસાયટી સ્થગિત': {
      'gu': 'સોસાયટી સ્થગિત',
      'hi': 'सोसायटी निलंबित / स्थगित',
      'en': 'Society Suspended',
    },
    'હજુ સેવાઓ સ્થગિત છે. કૃપા કરીને થોડી વાર પછી તપાસો.': {
      'gu': 'હજુ સેવાઓ સ્થગિત છે. કૃપા કરીને થોડી વાર પછી તપાસો.',
      'hi': 'सेवाएं अभी भी निलंबित हैं। कृपया थोड़ी देर बाद जांचें।',
      'en': 'Services are still suspended. Please check back after some time.',
    },
    'સુધારેલી / વધારાની અપીલ નોંધ': {
      'gu': 'સુધારેલી / વધારાની અપીલ નોંધ',
      'hi': 'संशोधित / अतिरिक्त अपील नोट',
      'en': 'Revised / Additional Appeal Note',
    },
    'અગાઉનો ઇતિહાસ': {
      'gu': 'અગાઉનો ઇતિહાસ',
      'hi': 'पिछला इतिहास',
      'en': 'Previous History',
    },
    'અગાઉ મોકલેલી અપીલ વિગત:': {
      'gu': 'અગાઉ મોકલેલી અપીલ વિગત:',
      'hi': 'पहले भेजी गई अपील का विवरण:',
      'en': 'Previously submitted appeal details:',
    },
    'સુપર એડમિનનો અગાઉનો પ્રત્યુત્તર:': {
      'gu': 'સુપર એડમિનનો અગાઉનો પ્રત્યુત્તર:',
      'hi': 'सुपर एडमिन का पिछला उत्तर:',
      'en': 'Super admin previous response:',
    },
    'આ અગાઉના સસ્પેન્શનનો ઉકેલાયેલ ઇતિહાસ છે. વર્તમાન સસ્પેન્શન માટે ઉપરનું ફોર્મ ભરીને નવી અપીલ મોકલો.': {
      'gu': 'આ અગાઉના સસ્પેન્શનનો ઉકેલાયેલ ઇતિહાસ છે. વર્તમાન સસ્પેન્શન માટે ઉપરનું ફોર્મ ભરીને નવી અપીલ મોકલો.',
      'hi': 'यह पिछले निलंबन का सुलझा हुआ इतिहास है। वर्तमान निलंबन के लिए ऊपर दिया गया फ़ॉर्म भरकर नई अपील भेजें।',
      'en': 'This is a resolved history of previous suspension. For the current suspension, submit a new appeal using the form above.',
    },

    // =============================================================
    // Emergency & Parking Warnings
    // =============================================================
    'હજુ કોઈ ઈમરજન્સી નંબર ઉમેરાયો નથી.\nઉપરના સૂચન બટન પર ક્લિક કરીને ઉમેરો.': {
      'gu': 'હજુ કોઈ ઈમરજન્સી નંબર ઉમેરાયો નથી.\nઉપરના સૂચન બટન પર ક્લિક કરીને ઉમેરો.',
      'hi': 'अभी तक कोई आपातकालीन नंबर नहीं जोड़ा गया है।\nऊपर दिए गए सुझाव बटन पर क्लिक करके जोड़ें।',
      'en': 'No emergency contact added yet.\nTap the suggestions button above to add.',
    },
    'હજુ સુધી કોઈ ઈમરજન્સી નંબર ઉમેરાયો નથી.\nઉપરના પ્રીસેટ પર ટેપ કરીને નંબર ઉમેરો.': {
      'gu': 'હજુ સુધી કોઈ ઈમરજન્સી નંબર ઉમેરાયો નથી.\nઉપરના પ્રીસેટ પર ટેપ કરીને નંબર ઉમેરો.',
      'hi': 'अभी तक कोई आपातकालीन नंबर नहीं जोड़ा गया है।\nऊपर दिए गए प्रीसेट पर टैप करके नंबर जोड़ें।',
      'en': 'No emergency number added yet.\nTap on the presets above to add.',
    },
    'હજુ સુધી કોઈ કોમન પ્લોટ સ્લોટ્સ બનાવવામાં આવ્યા નથી.\n(શેરી સોસાયટીમાં દરેક સભ્ય ઘર આગળ પાર્ક કરે છે).': {
      'gu': 'હજુ સુધી કોઈ કોમન પ્લોટ સ્લોટ્સ બનાવવામાં આવ્યા નથી.\n(શેરી સોસાયટીમાં દરેક સભ્ય ઘર આગળ પાર્ક કરે છે).',
      'hi': 'अभी तक कोई कॉमन प्लॉट स्लॉट नहीं बनाया गया है।\n(स्ट्रीट सोसायटी में प्रत्येक सदस्य घर के आगे पार्क करते हैं)।',
      'en': 'No common plot slots created yet.\n(In street societies, members park in front of their houses).',
    },
    'હજુ સુધી કોઈ વિંગ્સ સ્લોટ્સ બનાવવામાં આવ્યા નથી.\nઉપરના બટનથી સ્લોટ્સ જનરેટ કરો.': {
      'gu': 'હજુ સુધી કોઈ વિંગ્સ સ્લોટ્સ બનાવવામાં આવ્યા નથી.\nઉપરના બટનથી સ્લોટ્સ જનરેટ કરો.',
      'hi': 'अभी तक कोई विंग स्लॉट नहीं बनाया गया है।\nऊपर दिए गए बटन से स्लॉट जनरेट करें।',
      'en': 'No wing slots created yet.\nGenerate slots using the button above.',
    },
    'છેલ્લી તારીખ:': {
      'gu': 'છેલ્લી તારીખ:',
      'hi': 'अंतिम तिथि:',
      'en': 'Due Date:',
    },
    'તમારી સોસાયટી શાંતિપૂર્ણ અને સુવ્યવસ્થિત છે.\nજો કોઈ પ્રશ્ન જણાય તો ઉપરથી સરળતાથી નોંધાવો.': {
      'gu': 'તમારી સોસાયટી શાંતિપૂર્ણ અને સુવ્યવસ્થિત છે.\nજો કોઈ પ્રશ્ન જણાય તો ઉપરથી સરળતાથી નોંધાવો.',
      'hi': 'आपकी सोसायटी शांत और व्यवस्थित है।\nयदि कोई समस्या दिखे तो ऊपर से आसानी से दर्ज करें।',
      'en': 'Your society is peaceful and well-organized.\nIf any issue arises, submit it easily above.',
    },
    'તમારું એકાઉન્ટ અન્ય ડિવાઇસ પર લૉગિન કરવામાં આવ્યું હોવાથી આ ડિવાઇસમાંથી સુરક્ષિત રીતે લૉગઆઉટ કરવામાં આવ્યું છે.\n\nસુરક્ષાના નિયમ મુજબ એક સમયે માત્ર ૧ જ ડિવાઇસમાં લૉગિન રહી શકાય છે.': {
      'gu': 'તમારું એકાઉન્ટ અન્ય ડિવાઇસ પર લૉગિન કરવામાં આવ્યું હોવાથી આ ડિવાઇસમાંથી સુરક્ષિત રીતે લૉગઆઉટ કરવામાં આવ્યું છે.\n\nસુરક્ષાના નિયમ મુજબ એક સમયે માત્ર ૧ જ ડિવાઇસમાં લૉગિન રહી શકાય છે.',
      'hi': 'आपका खाता किसी अन्य डिवाइस पर लॉग इन होने के कारण इस डिवाइस से सुरक्षित रूप से लॉग आउट कर दिया गया है।\n\nसुरक्षा नियमों के अनुसार एक समय में केवल 1 डिवाइस पर लॉग इन रहा जा सकता है।',
      'en': 'Your account was logged in on another device, so this device has been safely logged out.\n\nAs per security policies, only 1 device can be active at a time.',
    },
    'મેમ્બર તેમના મોબાઈલની કોઈપણ UPI એપ\n(Google Pay, PhonePe, Paytm, BHIM)\nથી આ QR સ્કેન કરી શકે છે.': {
      'gu': 'મેમ્બર તેમના મોબાઈલની કોઈપણ UPI એપ\n(Google Pay, PhonePe, Paytm, BHIM)\nથી આ QR સ્કેન કરી શકે છે.',
      'hi': 'सदस्य अपने मोबाइल के किसी भी UPI ऐप\n(Google Pay, PhonePe, Paytm, BHIM)\nसे इस QR को स्कैन कर सकते हैं।',
      'en': 'Members can scan this QR code with any UPI app\n(Google Pay, PhonePe, Paytm, BHIM).',
    },
    '૧. નીચે "UPI એપ ખોલો" દબાવતા Google Pay / PhonePe ખુલશે.\n': {
      'gu': '૧. નીચે "UPI એપ ખોલો" દબાવતા Google Pay / PhonePe ખુલશે.\n',
      'hi': '१. नीचे "UPI ऐप खोलें" दबाने पर Google Pay / PhonePe खुलेगा।\n',
      'en': '1. Tapping "Open UPI App" below will launch Google Pay / PhonePe.\n',
    },
    '૨. એપમાં "Pay UPI ID" અથવા Search બારમાં આ કૉપી કરેલ ID Paste કરો.\n': {
      'gu': '૨. એપમાં "Pay UPI ID" અથવા Search બારમાં આ કૉપી કરેલ ID Paste કરો.\n',
      'hi': '२. ऐप में "Pay UPI ID" या खोज बार में कॉपी की गई ID पेस्ट करें।\n',
      'en': '2. Paste this copied ID into "Pay UPI ID" or Search in the app.\n',
    },
    '૩. NPCI બેંક સર્વર સીધું જ રજીસ્ટર્ડ બેંક ખાતાધારકનું સાચું નામ (Verified Name) બતાવશે.\n': {
      'gu': '૩. NPCI બેંક સર્વર સીધું જ રજીસ્ટર્ડ બેંક ખાતાધારકનું સાચું નામ (Verified Name) બતાવશે.\n',
      'hi': '३. NPCI बैंक सर्वर सीधे पंजीकृत बैंक खाताधारक का सत्यापित नाम (Verified Name) दिखाएगा।\n',
      'en': '3. The NPCI bank server will directly show the registered account holder verified name.\n',
    },
    '🌟 તમામ': {
      'gu': '🌟 તમામ',
      'hi': '🌟 सभी',
      'en': '🌟 All',
    },
    '🟢 કબજેદાર': {
      'gu': '🟢 કબજેદાર',
      'hi': '🟢 अधिकृत',
      'en': '🟢 Occupied',
    },
    '⚪ ખાલી': {
      'gu': '⚪ ખાલી',
      'hi': '⚪ रिक्त',
      'en': '⚪ Vacant',
    },
    '🟢 મંજૂર': {
      'gu': '🟢 મંજૂર',
      'hi': '🟢 स्वीकृत',
      'en': '🟢 Approved',
    },
    '⏳ પેન્ડિંગ': {
      'gu': '⏳ પેન્ડિંગ',
      'hi': '⏳ लंबित',
      'en': '⏳ Pending',
    },
    '🔴 નકારેલ': {
      'gu': '🔴 નકારેલ',
      'hi': '🔴 अस्वीकृत',
      'en': '🔴 Rejected',
    },
    'બધા': {
      'gu': 'બધા',
      'hi': 'सभी',
      'en': 'All',
    },
    'ખર્ચાઓ': {
      'gu': 'ખર્ચાઓ',
      'hi': 'खर्च',
      'en': 'Expenses',
    },
    'એકમો': {
      'gu': 'એકમો',
      'hi': 'इकाइयाँ',
      'en': 'Units',
    },
    'સક્રિય': {
      'gu': 'સક્રિય',
      'hi': 'सक्रिय',
      'en': 'Active',
    },
    '[અહીં તમારો સંદેશો લખો]': {
      'gu': '[અહીં તમારો સંદેશો લખો]',
      'hi': '[यहाँ अपना संदेश लिखें]',
      'en': '[Write your message here]',
    },
    'આભાર,': {
      'gu': 'આભાર,',
      'hi': 'धन्यवाद,',
      'en': 'Thanks,',
    },
    'તમને મળવા આવ્યા છે': {
      'gu': 'તમને મળવા આવ્યા છે',
      'hi': 'आपसे मिलने आए हैं',
      'en': 'is here to see you',
    },
    'સોસાયટી પુનઃસક્રિયતા અપીલ સંદર્ભે': {
      'gu': 'સોસાયટી પુનઃસક્રિયતા અપીલ સંદર્ભે',
      'hi': 'सोसायटी पुनःसक्रियता अपील के संदर्भ में',
      'en': 'Regarding Society Reactivation Appeal',
    },
    'કુલ ફ્લેટ્સ': {
      'gu': 'કુલ ફ્લેટ્સ',
      'hi': 'कुल फ्लैट्स',
      'en': 'Total Flats',
    },
    'ફ્લેટ્સ ચૂકવેલ': {
      'gu': 'ફ્લેટ્સ ચૂકવેલ',
      'hi': 'फ्लैट्स भुगतान',
      'en': 'Flats Paid',
    },
    'ફ્લેટ્સ બાકી': {
      'gu': 'ફ્લેટ્સ બાકી',
      'hi': 'फ्लैट्स बकाया',
      'en': 'Flats Due',
    },
    'માર્ક પેઇડ': {
      'gu': 'માર્ક પેઇડ',
      'hi': 'भुगतान दर्ज',
      'en': 'Mark Paid',
    },
    'કલેક્શન પ્રગતિ': {
      'gu': 'કલેક્શન પ્રગતિ',
      'hi': 'कलेक्शन प्रगति',
      'en': 'Collection Progress',
    },
    'સોસાયટી બિલિંગ & કલેક્શન': {
      'gu': 'સોસાયટી બિલિંગ & કલેક્શન',
      'hi': 'सोसायटी बिलिंग एवं कलेक्शन',
      'en': 'Society Billing & Collection',
    },
    'ડ્યુ': {
      'gu': 'ડ્યુ',
      'hi': 'देय',
      'en': 'Due',
    },
    'ચૂકવ્યા': {
      'gu': 'ચૂકવ્યા',
      'hi': 'भुगतान',
      'en': 'Paid',
    },
    'QR પે': {
      'gu': 'QR પે',
      'hi': 'QR भुगतान',
      'en': 'QR Pay',
    },
    'રસીદ ડાઉનલોડ': {
      'gu': 'રસીદ ડાઉનલોડ',
      'hi': 'रसीद डाउनलोड',
      'en': 'Download Receipt',
    },
    'પૂર્ણ': {
      'gu': 'પૂર્ણ',
      'hi': 'पूर्ण',
      'en': 'Complete',
    },
  };

  /// Precomputed reverse lookup map that indexes all translations & English keys
  static final Map<String, String> _phraseToKey = () {
    final map = <String, String>{};
    for (final entry in _localizedValues.entries) {
      final engKey = entry.key;
      map[engKey] = engKey;
      map[engKey.toLowerCase()] = engKey;

      for (final translation in entry.value.values) {
        final trimmed = translation.trim();
        if (trimmed.isNotEmpty) {
          map[trimmed] = engKey;
          map[trimmed.toLowerCase()] = engKey;
        }
      }
    }
    return map;
  }();

  /// Translate any string key OR phrase directly into the current language
  static String translate(String text, [String? langCode]) {
    if (text.isEmpty) return text;
    final code = langCode ?? LocalizationService.instance.currentCode;

    // 1. Direct match on English key or exact phrase
    var mapEntry = _localizedValues[text];

    // 2. Phrase reverse match (Gujarati/Hindi/English phrase to English key)
    if (mapEntry == null) {
      final trimmed = text.trim();
      final mappedKey = _phraseToKey[text] ?? _phraseToKey[trimmed] ?? _phraseToKey[trimmed.toLowerCase()];
      if (mappedKey != null) {
        mapEntry = _localizedValues[mappedKey];
      }
    }

    if (mapEntry != null) {
      final res = mapEntry[code] ?? mapEntry['gu'] ?? mapEntry['en'] ?? text;
      final leading = text.length - text.trimLeft().length;
      final trailing = text.length - text.trimRight().length;
      if (leading > 0 || trailing > 0) {
        return '${" " * leading}$res${" " * trailing}';
      }
      return res;
    }

    // 3. Smart Pattern Matching for dynamic expressions:
    // (A) Matches strings ending with parenthesized numbers: e.g. "બધા (12)", "🟢 મંજૂર (5)", "🌟 તમામ (20)"
    final parenMatch = RegExp(r'^(.+?)(\s*\([0-9]+\))$').firstMatch(text);
    if (parenMatch != null) {
      final prefix = parenMatch.group(1)!;
      final count = parenMatch.group(2)!;
      final transPrefix = translate(prefix, code);
      if (transPrefix != prefix) {
        return '$transPrefix$count';
      }
    }

    // (B) Matches error / exception prefixes: e.g. "ભૂલ આવી: ...", "ભૂલ: ...", "ક્ષતિ: ..."
    for (final errPrefix in ['ભૂલ આવી: ', 'ભૂલ: ', 'ક્ષતિ: ', 'એરર આવી: ', 'Error: ']) {
      if (text.startsWith(errPrefix)) {
        final rest = text.substring(errPrefix.length);
        final localizedPrefix = code == 'hi'
            ? 'त्रुटि: '
            : code == 'en'
                ? 'Error: '
                : 'ભૂલ આવી: ';
        return '$localizedPrefix$rest';
      }
    }

    // (C) Matches count + noun: e.g. "5 ખર્ચાઓ", "12 એકમો"
    final countNounMatch = RegExp(r'^([0-9]+)\s+([^\d]+)$').firstMatch(text);
    if (countNounMatch != null) {
      final count = countNounMatch.group(1)!;
      final noun = countNounMatch.group(2)!;
      final transNoun = translate(noun, code);
      if (transNoun != noun) {
        return '$count $transNoun';
      }
    }

    // (D) Matches floor representations: e.g. "3 મો માળ", "2 લો માળ"
    final floorMatch = RegExp(r'^([0-9]+)\s*(?:મો|જો|લો)?\s*માળ.*$').firstMatch(text);
    if (floorMatch != null) {
      final fNum = floorMatch.group(1)!;
      if (code == 'hi') return '$fNumवीं मंजिल';
      if (code == 'en') return 'Floor $fNum';
      return '$fNum જો માળ';
    }

    // 4. Fallback to original text
    return text;
  }

  /// Alias for translate: `AppStrings.get('key')`
  static String get(String key, [String? langCode]) => translate(key, langCode);
}

/// Extension on String for instant template translation: `"મેન્ટેનન્સ".tr`
extension StringLocalizationExtension on String {
  String get tr => AppStrings.translate(this);
}

/// Extension on BuildContext for template translation: `context.tr("save")`
extension LocalizationContextExtension on BuildContext {
  String tr(String keyOrText) => AppStrings.translate(keyOrText);
}
