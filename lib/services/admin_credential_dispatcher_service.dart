import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_firestore.dart';

/// સર્વિસ: સુપર એડમિન દ્વારા નવા સોસાયટી એડમિનને ઈમેલ, WhatsApp અને શેરિંગ દ્વારા ક્રેડેન્શિયલ્સ પહોંચાડવા
class AdminCredentialDispatcherService {
  AdminCredentialDispatcherService._();
  static final AdminCredentialDispatcherService instance =
      AdminCredentialDispatcherService._();

  /// ઈમેલ સબજેક્ટ જનરેટ કરવો
  String buildEmailSubject({
    required String societyName,
  }) {
    return '🔐 [MyBuildingGuard] આપના સોસાયટી એડમિન લૉગિન ક્રેડેન્શિયલ્સ - $societyName';
  }

  /// ઔપચારિક વિગતવાર ઈમેલ બોડી જનરેટ કરવો (Email Body)
  String buildEmailBody({
    required String societyName,
    required String architectureType,
    required String city,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required String adminPhone,
    String? roleTitle,
  }) {
    final role = roleTitle ?? 'ચીફ સોસાયટી એડમિન (Chief Admin)';
    final arch = _formatArchitecture(architectureType);
    final passDisplay = adminPassword.contains('••')
        ? 'સુરક્ષા માટે એન્ક્રિપ્ટેડ (ઈમેલ પર મોકલેલ પાસવર્ડ રીસેટ લિંકથી નવો પાસવર્ડ સેટ કરો)'
        : adminPassword.trim();

    return '''
નમસ્તે $adminName જી,

અભિનંદન! આપની સોસાયટી "$societyName" નું MyBuildingGuard ERP સિસ્ટમમાં સફળતાપૂર્વક ઓનબોર્ડિંગ થઈ ગયું છે.
આપને સોસાયટીના $role તરીકે અધિકૃત કરવામાં આવ્યા છે.

📋 આપના એડમિન લૉગિન ક્રેડેન્શિયલ્સ:
────────────────────────────────────────
🏢 પરિસર / સોસાયટી : $societyName ($arch)
📍 શહેર            : $city
👤 એડમિન નામ      : $adminName
📧 લૉગિન ઈમેલ      : $adminEmail
🔑 સિક્યોરિટી પાસવર્ડ: $passDisplay
📱 રજીસ્ટર્ડ મોબાઇલ : $adminPhone
────────────────────────────────────────

🚀 કેવી રીતે લૉગિન કરવું?
૧. MyBuildingGuard મોબાઇલ એપ ખોલો (અથવા વેબ પોર્ટલ પર જાઓ).
૨. કોઈપણ રોલ પસંદ કરવાનો નથી — ફક્ત આપનો ઈમેલ (અથવા રજીસ્ટર્ડ મોબાઇલ) અને પાસવર્ડ દાખલ કરો. સિસ્ટમ આપમેળે આપનો એડમિન રોલ ઓળખી લેશે.
૩. પ્રથમ લૉગિન કર્યા બાદ પ્રોફાઇલ સેટિંગ્સમાંથી આપનો વ્યક્તિગત પાસવર્ડ બદલી લેવો હિતાવહ છે.

🛡️ મહત્વની સુરક્ષા સૂચનાઓ:
• આ ક્રેડેન્શિયલ્સ આપની સોસાયટીના વહીવટી અને નાણાકીય સંચાલન માટે ગોપનીય છે.
• કોઈપણ અજાણી વ્યક્તિ સાથે આપનો પાસવર્ડ શેર કરશો નહીં.

કોઈપણ પ્રકારની તકનીકી સહાયતા કે ટ્રેનિંગ માટે સપોર્ટ ટીમનો સંપર્ક કરી શકો છો.

આભાર અને સાદર વંદન,
MyBuildingGuard ERP Platform Team
હેલ્પલાઇન & સપોર્ટ
────────────────────────────────────────
''';
  }

  /// WhatsApp મેસેજ જનરેટ કરવો (WhatsApp Message)
  String buildWhatsAppMessage({
    required String societyName,
    required String architectureType,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required String adminPhone,
  }) {
    final arch = _formatArchitecture(architectureType);
    final passDisplay = adminPassword.contains('••')
        ? 'સુરક્ષા માટે એન્ક્રિપ્ટેડ (ઈમેલ પર મોકલેલ પાસવર્ડ રીસેટ લિંક પરથી સેટ કરો)'
        : '`${adminPassword.trim()}`';

    return '''
*🔐 MyBuildingGuard ERP - સોસાયટી એડમિન લૉગિન વિગતો*

નમસ્તે *${adminName.trim()}* જી,
અભિનંદન! આપની સોસાયટી *"${societyName.trim()}"* નું MyBuildingGuard ERP માં સફળતાપૂર્વક ઓનબોર્ડિંગ થઈ ગયું છે.

📋 *આપના એડમિન ક્રેડેન્શિયલ્સ:*
• *પરિસર:* ${societyName.trim()} ($arch)
• *લૉગિન ઈમેલ:* `${adminEmail.trim()}`
• *પાસવર્ડ:* $passDisplay
• *મોબાઇલ:* ${adminPhone.trim()}

📲 *લૉગિન કરવાની સરળ રીત:*
૧. MyBuildingGuard એપ ખોલો.
૨. કોઈ રોલ સિલેક્ટ કરવાનો નથી — ફક્ત ઈમેલ અને પાસવર્ડ દાખલ કરીને લૉગિન કરો (સિસ્ટમ આપમેળે આપનો એડમિન રોલ ડિટેક્ટ કરશે).
૩. પ્રથમ લૉગિન કર્યા બાદ પાસવર્ડ અપડેટ કરી લેવો.

_સુરક્ષિત અને ડિજિટલ સોસાયટી મેનેજમેન્ટ_
MyBuildingGuard સપોર્ટ ટીમ
''';
  }

  /// ડાયરેક્ટ ઈમેલ એપ્લિકેશન (Gmail, Apple Mail, Outlook વગેરે) લોન્ચ કરવી
  Future<bool> launchEmailClient({
    required String adminEmail,
    required String subject,
    required String body,
  }) async {
    final query = _encodeQueryParameters(<String, String>{
      'subject': subject,
      'body': body,
    });

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: adminEmail.trim(),
      query: query,
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        return await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(emailLaunchUri);
      }
    } catch (_) {
      return false;
    }
  }

  /// WhatsApp ચેટ લોન્ચ કરવી
  Future<bool> launchWhatsApp({
    required String phone,
    required String message,
  }) async {
    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanPhone = digitsOnly.length == 10 ? '91$digitsOnly' : digitsOnly;
    final Uri waUri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(waUri)) {
        return await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(waUri);
      }
    } catch (_) {
      return false;
    }
  }

  /// સિસ્ટમ શેર શીટ ખોલવી (Share.share)
  Future<void> shareCredentials({
    required String text,
    required String subject,
  }) async {
    await Share.share(text, subject: subject);
  }

  /// ક્લિપબોર્ડમાં કોપી કરવી
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// ફાયરસ્ટોર બેકએન્ડ ઈમેલ ક્યુમાં રેકોર્ડ સેવ કરવો
  Future<void> queueEmailInFirestore({
    required String societyName,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required String adminPhone,
    required String architectureType,
    String? city,
  }) async {
    try {
      final subject = buildEmailSubject(societyName: societyName);
      final body = buildEmailBody(
        societyName: societyName,
        architectureType: architectureType,
        city: city ?? '',
        adminName: adminName,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
        adminPhone: adminPhone,
      );

      await AppFirestore.instance.collection('system_emails').add({
        'to': adminEmail.trim(),
        'recipientName': adminName.trim(),
        'societyName': societyName.trim(),
        'role': 'admin',
        'type': 'admin_welcome_credentials',
        'subject': subject,
        'body': body,
        'status': 'queued',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ignored for non-blocking UI
    }
  }

  String _formatArchitecture(String arch) {
    final lower = arch.toLowerCase();
    if (lower.contains('commercial') || lower.contains('shopping') || lower.contains('mall')) {
      return '🛍️ કોમર્શિયલ મોલ / શોપિંગ સેન્ટર';
    } else if (lower.contains('mixed')) {
      return '🏢 હાઇબ્રિડ / મિક્સ્ડ પરિસર';
    } else if (lower.contains('street') || lower.contains('rowhouse') || lower.contains('bungalow')) {
      return '🏡 બંગલો / રો-હાઉસ સોસાયટી';
    }
    return '🏙️ રેસીડેન્સી / વિંગ સોસાયટી';
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
