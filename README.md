# 🏢 My Building Guard (સોસાયટી મેનેજમેન્ટ, વિઝિટર સિક્યુરિટી & સ્માર્ટ એકાઉન્ટિંગ સિસ્ટમ)

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20FCM%20%7C%20Functions%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Architecture](https://img.shields.io/badge/Architecture-Multi--Tenant%20RBAC-blueviolet)](#-મલ્ટી-ટેનન્ટ-સોસાયટી-આર્કિટેક્ચર-multi-tenancy)
[![Security](https://img.shields.io/badge/Security-Single--Device%20Session%20Guard-red)](#-સિંગલ-ડિવાઇસ-સેશન-ગાર્ડ--rbac-સિક્યુરિટી)
[![Localization](https://img.shields.io/badge/Language-Gujarati%20%7C%20Hindi%20%7C%20English-success)](#-ત્રિભાષી-લાઇવ-લેંગ્વેજ-એન્જિન-tri-lingual-system)
[![License](https://img.shields.io/badge/License-Proprietary-black)](#)

**My Building Guard** એ રહેણાંક સોસાયટીઓ, હાઇરાઇઝ એપાર્ટમેન્ટ્સ, વિલા અને રો-હાઉસ ટાઉનશિપ માટે તૈયાર કરવામાં આવેલી એક અત્યાધુનિક, મલ્ટી-ટેનન્ટ સોસાયટી એડમિનિસ્ટ્રેશન, વિઝિટર ગેટ સિક્યુરિટી, ૦% કમિશન UPI મેન્ટેનન્સ બિલિંગ અને સ્માર્ટ ઓડિટ એકાઉન્ટિંગ એપ્લિકેશન છે.

આ પ્લેટફોર્મ ચાર મુખ્ય સ્તરો વચ્ચે રીઅલ-ટાઇમ ક્લાઉડ સિન્ક્રોનાઇઝેશન પ્રદાન કરે છે:
1. 👑 **પ્લેટફોર્મ સુપર એડમિન (Platform Super Admin)**
2. 🏛️ **સોસાયટી એડમિન & મેનેજિંગ કમિટી (Society Admin / Committee)**
3. 🛡️ **સિક્યુરિટી ગાર્ડ / વોચમેન (Security Guard / Watchman)**
4. 🏠 **સોસાયટીના સભ્યો / રહીશો (Residents / Members)**

---

## 📑 અનુક્રમણિકા (Table of Contents)
- [✨ તમામ રોલ મુજબ વિગતવાર કાર્યપ્રણાલી (Role-wise Architecture)](#-તમામ-રોલ-મુજબ-વિગતવાર-કાર્યપ્રણાલી-role-wise-architecture)
  - [૧. 👑 સુપર એડમિન પ્લેટફોર્મ (Super Admin Platform)](#૧--સુપર-એડમિન-પ્લેટફોર્મ-super-admin-platform)
  - [૨. 🏛️ સોસાયટી એડમિન & કમિટી પોર્ટલ (Admin Portal)](#૨-️-સોસાયટી-એડમિન--કમિટી-પોર્ટલ-admin-portal)
  - [૩. 🛡️ સિક્યુરિટી ગાર્ડ / વોચમેન પોર્ટલ (Watchman Portal)](#૩-️-સિક્યુરિટી-ગાર્ડ--વોચમેન-પોર્ટલ-watchman-portal)
  - [૪. 🏠 સભ્ય / રહીશ પોર્ટલ (Resident / Member Portal)](#૪--સભ્ય--રહીશ-પોર્ટલ-resident--member-portal)
- [💎 ૧૦ મુખ્ય વિશિષ્ટ સબ-સિસ્ટમ્સ (Core Specialized Subsystems)](#-૧૦-મુખ્ય-વિશિષ્ટ-સબ-સિસ્ટમ્સ-core-specialized-subsystems)
  - [૧. 💳 ૦% ફી મેન્ટેનન્સ બિલિંગ & ૧-ટેપ UPI સિસ્ટમ](#૧--૦-ફી-મેન્ટેનન્સ-બિલિંગ--૧-ટેપ-upi-સિસ્ટમ)
  - [૨. 📄 સત્તાવાર ડિજિટલ PDF રસીદ & રબર સ્ટેમ્પ એન્જિન](#૨--સત્તાવાર-ડિજિટલ-pdf-રસીદ--રબર-સ્ટેમ્પ-એન્જિન)
  - [૩. 🚶‍♂️ ગાર્ડ QR પેટ્રોલિંગ સિસ્ટમ (Guard QR Patrol)](#૩-️-ગાર્ડ-qr-પેટ્રોલિંગ-સિસ્ટમ-guard-qr-patrol)
  - [૪. 📊 સોસાયટી એકાઉન્ટ્સ, ખર્ચ & ઓડિટ બેલેન્સ શીટ PDF](#૪--સોસાયટી-એકાઉન્ટ્સ-ખર્ચ--ઓડિટ-બેલેન્સ-શીટ-pdf)
  - [૫. 🗳️ સોસાયટી પોલ્સ & ડિજિટલ વોટિંગ (Democracy Polls)](#૫-️-સોસાયટી-પોલ્સ--ડિજિટલ-વોટિંગ-democracy-polls)
  - [૬. 🏊‍♂️ એમેનિટીઝ & ક્લબહાઉસ સ્લોટ બુકિંગ સિસ્ટમ](#૬-️-એમેનિટીઝ--ક્લબહાઉસ-સ્લોટ-બુકિંગ-સિસ્ટમ)
  - [૭. 🌐 ત્રિભાષી લાઇવ લેંગ્વેજ એન્જિન (Gujarati, Hindi, English)](#૭--ત્રિભાષી-લાઇવ-લેંગ્વેજ-એન્જિન-gujarati-hindi-english)
  - [૮. 🗂️ યુનિવર્સલ રોલ-અવેર નેવિગેશન ડ્રોઅર (`AppNavigationDrawer`)](#૮-️-યુનિવર્સલ-રોલ-અવેર-નેવિગેશન-ડ્રોઅર-appnavigationdrawer)
  - [૯. 🔔 સ્માર્ટ નોટિફિકેશન રીડાયરેક્શન & ડીપ લિંકિંગ સેન્ટર](#૯--સ્માર્ટ-નોટિફિકેશન-રીડાયરેક્શન--ડીપ-લિંકિંગ-સેન્ટર)
  - [૧૦. 🔐 સિંગલ-ડિવાઇસ સેશન ગાર્ડ & એન્ટરપ્રાઇઝ RBAC](#૧૦--સિંગલ-ડિવાઇસ-સેશન-ગાર્ડ--એન્ટરપ્રાઇઝ-rbac)
- [🛠️ ટેકનોલોજી સ્ટેક (Tech Stack & Libraries)](#️-ટેકનોલોજી-સ્ટેક-tech-stack--libraries)
- [📂 પ્રોજેક્ટ ફાઇલ સ્ટ્રક્ચર (Project Directory Structure)](#-પ્રોજેક્ટ-ફાઇલ-સ્ટ્રક્ચર-project-directory-structure)
- [🗄️ ડેટાબેઝ મોડેલ (Firestore Collections Schema)](#️-ડેટાબેઝ-મોડેલ-firestore-collections-schema)
- [⚡ ક્લાઉડ ફંક્શન્સ (Firebase Cloud Functions v2)](#-ક્લાઉડ-ફંક્શન્સ-firebase-cloud-functions-v2)
- [🚀 સેટઅપ અને ઇન્સ્ટોલેશન (Getting Started)](#-સેટઅપ-અને-ઇન્સ્ટોલેશન-getting-started)
- [🧪 ટેસ્ટિંગ અને બિલ્ડ (Build & Production)](#-ટેસ્ટિંગ-અને-બિલ્ડ-build--production)

---

## ✨ તમામ રોલ મુજબ વિગતવાર કાર્યપ્રણાલી (Role-wise Architecture)

### ૧. 👑 સુપર એડમિન પ્લેટફોર્મ (Super Admin Platform)
પ્લેટફોર્મ ઓનર માટે તમામ સોસાયટીઓ, સબ્સ્ક્રિપ્શન્સ અને સેન્ટ્રલ સિસ્ટમ ગવર્નન્સ માટેનું એક્ઝિક્યુટિવ કમાન્ડ સેન્ટર (`super_admin_dashboard.dart`):

* **લાઇવ KPI ડેક & પ્લેટફોર્મ એનાલિટિક્સ**:
  * કુલ રજિસ્ટર્ડ સોસાયટીઓ, સક્રિય યુઝર્સ, કુલ ગાર્ડ્સ અને પ્લેટફોર્મ હેલ્થ સ્ટેટસ.
  * સોસાયટી સ્ટેટસ મોનિટરિંગ: સક્રિય (Active), મુલતવી (Suspended/Blocked) કે ટ્રાયલ હેઠળ.
* **નવી સોસાયટી ઓનબોર્ડિંગ (`super_admin_onboard_society_screen.dart`)**:
  * સોસાયટીનું નામ, સરનામું, વિંગ/શેરી આર્કિટેક્ચર અને એડમિન ઓળખ સાથે નવી સોસાયટીનું ઇન્સ્ટન્ટ પ્રોવિઝનિંગ.
* **સોસાયટી એડમિન ક્રિએશન & ડિસ્પેચર (`super_admin_create_admin_screen.dart`, `admin_credential_dispatcher_service.dart`)**:
  * નવા સોસાયટી એડમિનનું એકાઉન્ટ જનરેશન અને SMS / WhatsApp / Email દ્વારા ક્રેડેન્શિયલ્સ ડિસ્પેચ.
* **સોસાયટી સસ્પેન્શન & અપીલ રિવ્યુ એન્જિન (`super_admin_appeal_detail_screen.dart`, `society_appeal_service.dart`)**:
  * નિયમોના ઉલ્લંઘન બદલ કારણ સાથે સોસાયટીને સસ્પેન્ડ કરવી.
  * સસ્પેન્ડ થયેલી સોસાયટીના એડમિન દ્વારા દાખલ કરાયેલી સત્તાવાર અપીલોની સમીક્ષા, દસ્તાવેજ ચકાસણી અને ૧-ક્લિક અનબ્લોક.
* **પ્લેટફોર્મ-વાઇડ ગ્લોબલ બ્રોડકાસ્ટ (`super_admin_broadcast_screen.dart`)**:
  * પ્લેટફોર્મની તમામ સોસાયટીઓના એડમિન્સ અથવા સભ્યોને એક સાથે ઇમરજન્સી કે મેન્ટેનન્સ નોટિસ મોકલવી.

---

### ૨. 🏛️ સોસાયટી એડમિન & કમિટી પોર્ટલ (Admin Portal)
સોસાયટી ચેરમેન, સેક્રેટરી અને મેનેજિંગ કમિટી માટે સમગ્ર કેમ્પસનું વહીવટી નિયંત્રણ (`admin_dashboard.dart`):

* **ડેશબોર્ડ & લાઈવ એનાલિટિક્સ**:
  * સોસાયટીના કુલ ફ્લેટ્સ/મકાનો, સક્રિય રહીશો, ઓન-ડ્યુટી ગાર્ડ્સ અને પેન્ડિંગ ફરિયાદોનું રીયલ-ટાઇમ કાઉન્ટર.
  * લાઈવ મેન્ટેનન્સ કલેક્શન પ્રોગ્રેસ બાર (કુલ જમા રકમ, કુલ બાકી રકમ, ચૂકવણી કરનાર ફ્લેટ્સની ટકાવારી).
  * વિઝિટર એનાલિટિક્સ રિપોર્ટ: દૈનિક, માસિક અને વિંગ-વાઇઝ વિઝિટર ટ્રાફિક ગ્રાફ, પીક-અવર્સ એનાલિસિસ (`admin_visitor_report_screen.dart`).
* **સોસાયટી આર્કિટેક્ચર વિઝાર્ડ (`admin_setup_wizard_screen.dart`, `admin_add_block_screen.dart`)**:
  * **વિંગ સિસ્ટમ (Wing Architecture)**: હાઇરાઇઝ એપાર્ટમેન્ટ્સ માટે વિંગ (A, B, C...), માળની સંખ્યા અને ફ્લોર મુજબ ફ્લેટ ઓટો-જનરેશન.
  * **શેરી સિસ્ટમ (Street / Row-House)**: ટેનામેન્ટ/રો-હાઉસ માટે શેરી નંબર અને પ્લોટ નંબરિંગ.
  * **આર્કિટેક્ચર પ્રિવ્યુ (`architecture_preview.dart`)**: દરેક વિંગ/શેરી અને ફ્લેટની લાઈવ ઇન્ટરેક્ટિવ ગ્રીડ.
* **સભ્યો & સ્ટાફ ડિરેક્ટરી (`admin_users_directory_screen.dart`, `admin_add_user_screen.dart`)**:
  * સભ્યોનું નવું રજીસ્ટ્રેશન (માલિક અથવા ભાડુઆત તરીકે), પ્રોફાઇલ એડિટિંગ અને એકાઉન્ટ સસ્પેન્શન.
* **વોચમેન મેનેજમેન્ટ (`admin_watchmen_manage_screen.dart`)**:
  * સિક્યુરિટી ગાર્ડ્સના એકાઉન્ટ્સ બનાવવી, ગેટ અસાઇનમેન્ટ, પાસવર્ડ રીસેટ અને એક્ટિવિટી મોનિટરિંગ.
* **મેન્ટેનન્સ & હિસાબ કંટ્રોલ સેન્ટર (`admin_maintenance_screen.dart`, `admin_bulk_bill_screen.dart`)**:
  * **૧-ક્લિક બલ્ક બિલ જનરેશન**: મહિનાના પ્રથમ દિવસે આખી સોસાયટીના તમામ ફ્લેટ્સ માટે એક સાથે માસિક બિલ બનાવવું.
  * **UPI પેમેન્ટ વેરિફિકેશન**: સભ્યો દ્વારા જમા કરાયેલા UPI ટ્રાન્ઝેક્શન્સ (UTR નંબર) ની ચકાસણી અને ૧-ક્લિક એપ્રૂવલ.
  * **ઓફલાઇન પેમેન્ટ્સ (Mark Paid)**: રોકડ (Cash) કે ચેક (Cheque) થી પેમેન્ટ નોંધી ઇન્સ્ટન્ટ રસીદ બનાવવી.
  * **૧-ક્લિક ડ્યુ રીમાઇન્ડર એલર્ટ**: બાકી રકમ વાળા તમામ સભ્યોને એક સાથે હાઈ-પ્રાયોરિટી પુશ એલર્ટ મોકલવું.
* **સોસાયટી બેંક & UPI સેટિંગ્સ (`admin_society_bank_settings_screen.dart`)**:
  * સોસાયટીનો સત્તાવાર UPI ID (VPA), બેંક એકાઉન્ટ વિગતો, IFSC અને QR કોડ ઇમેજ કન્ફિગરેશન.
* **સત્તાવાર ડિજિટલ PDF રસીદ એન્જિન (`maintenance_receipt_pdf_service.dart`)**:
  * ચૂકવેલા તમામ બિલ માટે અધિકૃત ડિજિટલ રસીદ જનરેટ કરવી (PAID ગ્રીન અને UNPAID રેડ રબર સ્ટેમ્પ સાથે).
* **સોસાયટી એકાઉન્ટ્સ & ફાઇનાન્સિયલ ઓડિટ (`admin_accounts_screen.dart`, `society_accounts_pdf_service.dart`)**:
  * સોસાયટીના દૈનિક/માસિક આવક-ખર્ચની એન્ટ્રી, બેલેન્સ શીટ અને ઑડિટ રિપોર્ટ PDF જનરેશન.
* **ગાર્ડ QR પેટ્રોલિંગ મેનેજમેન્ટ (`admin_patrol_screen.dart`)**:
  * સોસાયટીના મુખ્ય પોઇન્ટ્સ (લિફ્ટ, પાર્કિંગ, બેકગેટ, ટેરેસ) પર QR ચેકપોઇન્ટ્સ બનાવવી અને પેટ્રોલિંગ લોગ્સ તપાસવા.
* **પોલ્સ & વોટિંગ મેનેજમેન્ટ (`admin_polls_screen.dart`)**:
  * સોસાયટીના નિર્ણયો માટે ડિજિટલ વોટિંગ પોલ્સ બનાવવા અને રીયલ-ટાઇમ પરિણામો જોવા.
* **ક્લબહાઉસ & એમેનિટીઝ કંટ્રોલ (`admin_amenities_screen.dart`)**:
  * પાર્ટી પ્લોટ, ક્લબહાઉસ, જિમ વગેરેની સમય મર્યાદા અને સભ્યોના બુકિંગ મંજૂર કરવા.
* **સાધારણ સભા સહી શીટ (`admin_member_signature_sheet_screen.dart`, `member_signature_sheet_pdf_service.dart`)**:
  * AGM કે સ્પેશિયલ મીટિંગ માટે સભ્યોની સહી લેવા માટે રેડી-ટુ-પ્રિન્ટ PDF લિસ્ટ બનાવવું.
* **બ્રોડકાસ્ટ & નોટિસ બોર્ડ (`admin_broadcast_screen.dart`, `admin_publish_notice_screen.dart`)**:
  * તાત્કાલિક પુશ સૂચનાઓ મોકલવી અને નોટિસ બોર્ડ પર પરિપત્રો પ્રસિદ્ધ કરવા.
* **ફરિયાદ નિવારણ ડેસ્ક (`admin_complaints_screen.dart`)**:
  * સભ્યો દ્વારા ફોટો પુરાવા સાથે મુકાયેલી ફરિયાદોની સમીક્ષા કરી 'ઉકેલાઈ' (Resolved) માર્ક કરવી.

---

### ૩. 🛡️ સિક્યુરિટી ગાર્ડ / વોચમેન પોર્ટલ (Watchman Portal)
સોસાયટીના મુખ્ય દરવાજે વિઝિટર્સની ઝડપી એન્ટ્રી અને કડક સુરક્ષા માટેનું હાઇ-સ્પીડ ગાર્ડ પોર્ટલ (`watchmen_screen.dart`):

* **૧-ટેપ ક્વિક ડિલિવરી એન્ટ્રી (Quick Tags)**:
  * Swiggy, Zomato, Amazon, Flipkart, Blinkit, Zepto, Uber, Rapido વગેરે માટે વન-ટેપ ઓટોફિલ એન્ટ્રી.
* **લાઇવ કેમેરા ફોટો કેપ્ચર વિઝિટર એન્ટ્રી**:
  * મુલાકાતીનો લાઇવ ફોટો કેપ્ચર, નામ, ફોન નંબર, આવવાનો હેતુ અને લક્ષ્ય ફ્લેટ પસંદગી.
  * સબમિટ કરતાં જ રહીશના મોબાઇલ પર ઇન્સ્ટન્ટ રિંગ/નોટિફિકેશન રવાના.
* **પ્રી-એપ્રુવ્ડ QR ગેટ પાસ સ્કેનિંગ**:
  * `mobile_scanner` વડે મુલાકાતીના મોબાઇલ પર રહેલા QR કોડનું ૧-સેકન્ડમાં લાઈવ સ્કેનિંગ અને ઓટોમેટિક વેરિફિકેશન.
* **વાહન સર્ચ & રોંગ પાર્કિંગ એલર્ટ (`watchman_vehicle_lookup_sheet.dart`)**:
  * કોઈપણ ગાડી/બાઇકના નંબર પરથી ફ્લેટ અને વાહન માલિકની તાત્કાલિક શોધ.
  * રસ્તો રોકતા વાહનો માટે એપમાંથી જ વાહન માલિકને ૧-ક્લિક **ખોટું પાર્કિંગ પુશ નોટિફિકેશન**.
* **રીઅલ-ટાઇમ મુલાકાતી લોગ & ઑડિયો એલર્ટ**:
  * સભ્ય તરફથી મંજૂરી કે નકાર આવે ત્યારે ઓટોમેટિક સાઉન્ડ ચાઇમ (`audioplayers`).
  * બહાર જતી વખતે સરળ "ચેક-આઉટ" (Exit Logging) બટન.
* **રાત્રિ પેટ્રોલિંગ QR સ્કેનર (`watchman_patrol_screen.dart`)**:
  * ડ્યુટી દરમિયાન સોસાયટીના નિયત ચેકપોઇન્ટ્સ પર લાગેલા QR કોડ સ્કેન કરી પેટ્રોલિંગ પૂર્ણ કરવું.
* **ઇમરજન્સી SOS મોનિટરિંગ**:
  * સોસાયટીના કોઈપણ ફ્લેટમાંથી SOS એલર્ટ વાગે એટલે ગાર્ડની સ્ક્રીન પર ફ્લેટ નંબર સાથે હાઈ-પ્રાયોરિટી રેડ એલર્ટ ડિસ્પ્લે થાય છે.

---

### ૪. 🏠 સભ્ય / રહીશ પોર્ટલ (Resident / Member Portal)
સોસાયટીના સભ્યો માટે સુવિધા, પારદર્શિતા અને સલામતી આપતું ઓલ-ઇન-વન પોર્ટલ (`member_screen.dart`):

* **લાઇવ ગેટ એલર્ટ્સ & વિઝિટર મંજૂરી/નકાર**:
  * ગેટ પર મુલાકાતી આવે ત્યારે મહેમાનના ફોટા સાથે ઇન્સ્ટન્ટ પોપ-અપ -> ૧-ક્લિક **મંજૂરી (Approve)** અથવા **અસ્વીકાર (Reject)**.
* **અગાઉથી મંજૂરી (Pre-Approve Visitor Pass) (`member_pre_approve_screen.dart`)**:
  * આવનારા સંબંધી, મહેમાન કે ડિલિવરી બોય માટે અગાઉથી QR ગેટ પાસ જનરેટ કરવો અને WhatsApp દ્વારા શેર કરવો.
* **મેન્ટેનન્સ બિલિંગ & ૦% ફી ૧-ટેપ UPI પેમેન્ટ (`member_maintenance_sheet.dart`)**:
  * **૧-ટેપ UPI ઇન્ટેન્ટ**: Google Pay, PhonePe, Paytm કે BHIM સીધું ખોલીને ચુકવણી.
  * **ડાયનેમિક સોસાયટી UPI QR કોડ**: કોઈપણ અન્ય બેંક એપથી સ્કેન કરી પેમેન્ટ કરવાની સુવિધા.
  * **UTR સબમિશન**: ૧૨ આંકડાનો UTR નંબર દાખલ કરી પેમેન્ટ વેરિફિકેશન માટે મોકલવું.
  * **ડિજિટલ રસીદ હિસ્ટ્રી**: ચૂકવેલા તમામ બિલ્સની સત્તાવાર ડિજિટલ રસીદો (PAID Stamp સાથે) જોવી અને PDF ડાઉનલોડ/શેર કરવી.
* **મારા વાહનો & પાર્કિંગ સ્લોટ મેનેજમેન્ટ (`member_vehicles_screen.dart`, `parking_slot_selector_sheet.dart`)**:
  * વિંગ મુજબ ૪-વ્હીલર, ૨-વ્હીલર અને EV સ્લોટ્સનું સ્માર્ટ ડિસ્પ્લે અને નો-ડબલ-બુકિંગ સુરક્ષા.
* **સંપૂર્ણ વિઝિટર હિસ્ટ્રી (`member_visitors_screen.dart`, `visitor_detail_sheet.dart`)**:
  * સર્ચ બાર અને ટાઇમ ફિલ્ટર્સ સાથે તમામ મુલાકાતીઓનો સમય, ફોટો અને વિગતો.
* **સોસાયટી એકાઉન્ટ્સ સ્ટેટમેન્ટ (`member_accounts_screen.dart`)**:
  * સોસાયટીનું માસિક ફંડ, કુલ આવક, ખર્ચ અને બેલેન્સની સંપૂર્ણ પારદર્શિતા.
* **સોસાયટી પોલ્સ & લોકશાહી વોટિંગ (`member_polls_screen.dart`)**:
  * સોસાયટીના મહત્વના વિષયો પર ૧-ફ્લેટ-૧-વોટ મુજબ ગુપ્ત કે ખુલ્લું મતદાન કરવું.
* **ક્લબહાઉસ & એમેનિટીઝ બુકિંગ (`member_amenities_screen.dart`)**:
  * પર્સનલ પ્રસંગ માટે સોસાયટીનો પાર્ટી પ્લોટ કે ક્લબહાઉસ અગાઉથી બુક કરવું.
* **કાયમી સ્ટાફ મેનેજમેન્ટ (Daily Staff) (`member_daily_staff_screen.dart`)**:
  * કામવાળા બાઈ, ડ્રાઈવર, કૂક વગેરેની નોંધણી અને એન્ટ્રી ટ્રેકિંગ.
* **ડિજિટલ ફરિયાદ પોર્ટલ (`member_complaint_register_screen.dart`)**:
  * કેમેરામાંથી ફોટો પુરાવા સાથે લિકેજ કે લિફ્ટ સંબંધિત ફરિયાદ નોંધાવવી.
* **🚨 વન-ટચ ઇમરજન્સી SOS પેનિક બટન**:
  * કટોકટીમાં ૧-ક્લિકથી એડમિન અને વોચમેનને તાત્કાલિક સાયરન એલર્ટ મોકલવું.

---

## 💎 ૧૦ મુખ્ય વિશિષ્ટ સબ-સિસ્ટમ્સ (Core Specialized Subsystems)

### ૧. 💳 ૦% ફી મેન્ટેનન્સ બિલિંગ & ૧-ટેપ UPI સિસ્ટમ
* **ડાયરેક્ટ એકાઉન્ટ ટ્રાન્સફર**: કોઈ થર્ડ-પાર્ટી પેમેન્ટ ગેટવે વચ્ચે નથી; પૈસા સીધા સોસાયટીના બેંક એકાઉન્ટમાં જમા થાય છે.
* **ઝીરો પ્લેટફોર્મ ફી (0% Commission)**: સોસાયટી કે સભ્યને કોઈપણ પ્રકારનો કમિશન ચાર્જ લાગતો નથી.
* **૧-ટેપ UPI ડીપ લિંકિંગ**: NPCI સ્ટાન્ડર્ડ `upi://pay` URI પ્રોટોકોલ દ્વારા GPay, PhonePe, Paytm સીધું ઓપન થાય છે.
* **ડાયનેમિક ફ્લેટ-સ્પેસિફિક QR કોડ**: ફ્લેટ નંબર, મહિનો અને રકમ સાથેનો ઓટોમેટિક QR કોડ જનરેટ થાય છે.

### ૨. 📄 સત્તાવાર ડિજિટલ PDF રસીદ & રબર સ્ટેમ્પ એન્જિન
* **ઓથેન્ટિક રબર સ્ટેમ્પિંગ (`maintenance_receipt_pdf_service.dart`)**:
  * ચૂકવેલ બિલ માટે: **લીલો (PAID) સ્ટેમ્પ** વિથ ડબલ-રીંગ ગિયર સર્કલ, ઑફિશિયલ સ્ટાર્સ અને ટિલ્ટેડ એન્ગલ.
  * બાકી બિલ માટે: **લાલ (UNPAID) સ્ટેમ્પ**.
* **દ્વિભાષી લેઆઉટ (Gujarati & English)**: ગુજરાતી અને અંગ્રેજી બંને ભાષામાં પરફેક્ટ ફોન્ટ રેન્ડરિંગ (`Noto Sans Gujarati`).
* **પ્રિન્ટ & શેરિંગ**: પીડીએફ ડાઉનલોડ, પ્રિન્ટિંગ (`printing` પેકેજ) અને WhatsApp શેરિંગ સપોર્ટ.

### ૩. 🚶‍♂️ ગાર્ડ QR પેટ્રોલિંગ સિસ્ટમ (Guard QR Patrol)
* **સ્માર્ટ ચેકપોઇન્ટ્સ (`GuardPatrolService`)**: એડમિન સોસાયટીના વિવિધ ખૂણાઓમાં QR કોડ સ્થાપિત કરે છે.
* **વોચમેન સ્કેનિંગ**: રાત્રિ ડ્યુટી દરમિયાન વોચમેન `watchman_patrol_screen.dart` દ્વારા ચેકપોઇન્ટ્સ સ્કેન કરે છે.
* **ઓડિટ લોગ્સ**: સમય અને લોકેશન સ્ટેમ્પ સાથે કયો ચેકપોઇન્ટ ક્યારે સ્કેન થયો તેની એડમિનને લાઈવ માહિતી મળે છે.

### ૪. 📊 સોસાયટી એકાઉન્ટ્સ, ખર્ચ & ઓડિટ બેલેન્સ શીટ PDF
* **ડિજિટલ ખાતાવહી (`society_accounts_service.dart`)**: સોસાયટીની આવક (મેન્ટેનન્સ, હોલ ભાડું) અને ખર્ચ (લાઇટ બિલ, સિક્યુરિટી પગાર, સફાઈ) ની એન્ટ્રી.
* **સત્તાવાર ઓડિટ સ્ટેટમેન્ટ (`society_accounts_pdf_service.dart`)**: બેંક બેલેન્સ, ઓપનિંગ બેલેન્સ અને કેટેગરી-વાઇઝ ખર્ચ સાથેની ઓડિટેડ PDF શીટ.

### ૫. 🗳️ સોસાયટી પોલ્સ & ડિજિટલ વોટિંગ (Democracy Polls)
* **પારદર્શક નિર્ણય પ્રક્રિયા (`society_poll_service.dart`)**: સોસાયટીમાં રંગકામ કરાવવું, CCTV વધારવા કે સુરક્ષા ગાર્ડ બદલવા જેવા વિષયો પર સભ્યોનું વોટિંગ.
* **લાઈવ પરિણામો**: ટકાવારી અને ગ્રાફ સાથેનું રીઅલ-ટાઇમ ડિસ્પ્લે.

### ૬. 🏊‍♂️ એમેનિટીઝ & ક્લબહાઉસ સ્લોટ બુકિંગ સિસ્ટમ
* **ડબલ બુકિંગ રોકથામ (`amenity_booking_service.dart`)**: ક્લબહાઉસ, સ્વિમિંગ પૂલ, ટેરેસ કે જિમ માટે સ્લોટ બુકિંગ.
* **ઓટોમેટિક કન્ફર્મેશન**: એડમિન એપ્રૂવલ અને કેલેન્ડર વ્યુ.

### ૭. 🌐 ત્રિભાષી લાઇવ લેંગ્વેજ એન્જિન (Gujarati, Hindi, English)
* **ઇન્સ્ટન્ટ રિએક્ટિવ રીબિલ્ડ (`LocalizationService`)**: એપ રીસ્ટાર્ટ કર્યા વગર ૧-ટેપમાં ભાષા બદલાઈ જાય છે.
* **સંપૂર્ણ સ્થાનિકીકરણ**:
  * **ગુજરાતી (Default)**: સ્થાનિક સમુદાય માટે સરળ અને પરિચિત ભાષા.
  * **हिन्दी (Hindi)**: રાષ્ટ્રભાષા અને સ્ટાફ સાથે સરળ સંચાર.
  * **English**: વૈશ્વિક સ્ટાન્ડર્ડ ટર્મ્સ.

### ૮. 🗂️ યુનિવર્સલ રોલ-અવેર નેવિગેશન ડ્રોઅર (`AppNavigationDrawer`)
* **કન્સિસ્ટન્ટ એક્સેસ**: તમામ ચારેય ડેશબોર્ડ્સ (Super Admin, Admin, Member, Watchman) પર ઉપલબ્ધ.
* **સુવિધાઓ**:
  * ગ્રેડિયન્ટ લક્ઝરી હેડર, યુઝર અવતાર અને સક્રિયતા સ્ટેટસ.
  * મારી પ્રોફાઇલ અને સોસાયટી વિગતો માટે સ્માર્ટ બોટમ શીટ.
  * ભાષા પસંદગી શોર્ટકટ (GU / HI / EN).
  * રોલ મુજબના ફાસ્ટ શોર્ટકટ્સ.
  * ૧-ટેપ લૉગઆઉટ કન્ફર્મેશન (`PremiumLogoutDialog`).

### ૯. 🔔 સ્માર્ટ નોટિફિકેશન રીડાયરેક્શન & ડીપ લિંકિંગ સેન્ટર
* **ડીપ-લિંકિંગ નેવિગેશન એન્જિન (`NotificationNavigationService`)**:
  * સિસ્ટમ ટ્રે અથવા ફોરગ્રાઉન્ડ નોટિફિકેશન પર ટેપ કરતાં જ યુઝર સીધા સંબંધિત પેજ પર પહોંચી જાય છે:
    * `maintenance_receipt` -> સીધી ડિજિટલ રસીદ ખૂલશે.
    * `maintenance_due_reminder` -> સીધું UPI પેમેન્ટ પોર્ટલ ખૂલશે.
    * `complaint` -> ફરિયાદ સ્ક્રીન ખૂલશે.
    * `visitor_alert` -> ગેટ એન્ટ્રી અપ્રુવલ ખૂલશે.

### ૧૦. 🔐 સિંગલ-ડિવાઇસ સેશન ગાર્ડ & એન્ટરપ્રાઇઝ RBAC
* **સિંગલ-ડિવાઇસ લોગિન (`SessionGuardService`)**: એક એકાઉન્ટ એક જ સમયે એક ફોનમાં ખુલી શકે છે; બીજા ફોનમાં લોગિન થતાં જૂના ફોનમાં તાત્કાલિક લોગઆઉટ થાય છે.
* **સર્વર-લેવલ સુરક્ષા (`firestore.rules`)**: એડમિન, મેમ્બર અને વોચમેન માટે સુરક્ષિત નિયમો.
* **વોચમેન સિક્યોરિટી**: વોચમેનનું પબ્લિક સેલ્ફ-રજીસ્ટ્રેશન બંધ છે; માત્ર અધિકૃત ચેરમેન જ ગાર્ડ એકાઉન્ટ બનાવી શકે છે.

---

## 🛠️ ટેકનોલોજી સ્ટેક (Tech Stack & Libraries)

| ઘટક (Component) | ટેકનોલોજી (Technology) | વિગત (Description) |
| :--- | :--- | :--- |
| **Frontend Framework** | [Flutter](https://flutter.dev) (Dart SDK ^3.10.7) | ક્રોસ-પ્લેટફોર્મ નેટિવ પર્ફોર્મન્સ |
| **Authentication** | Firebase Authentication | સિક્યોર ઇમેઇલ/પાસવર્ડ સેશન |
| **Database** | Cloud Firestore (Enterprise Native) | રીઅલ-ટાઇમ નો-SQL ડેટાબેઝ |
| **Serverless Backend** | Firebase Cloud Functions v2 (Node.js) | પુશ નોટિફિકેશન, એનાલિટિક્સ અને ઇવેન્ટ ટ્રિગર્સ |
| **Cloud Storage** | Firebase Cloud Storage | વિઝિટર ફોટો અને ફરિયાદ પુરાવા સંગ્રહ |
| **Push Notifications** | Firebase Cloud Messaging (FCM v1) & Local Notifications | બેકગ્રાઉન્ડ & ફોરગ્રાઉન્ડ હાઈ-પ્રાયોરિટી પુશ |
| **PDF Generation** | `pdf` (^3.13.1) & `printing` (^5.15.1) | સત્તાવાર મેન્ટેનન્સ રસીદો, બેલેન્સ શીટ અને સ્ટેમ્પ્સ |
| **QR Code Scanner** | `mobile_scanner` | કેમેરા વડે પ્રી-એપ્રુવ્ડ ગેટ પાસ અને પેટ્રોલિંગ સ્કેનિંગ |
| **QR Code Generator** | `qr_flutter` | UPI પેમેન્ટ અને વિઝિટર પાસ QR નિર્માણ |
| **Audio Effects** | `audioplayers` | ગાર્ડ માટે એપ્રૂવલ ચાઇમ સાઉન્ડ |
| **Camera & Photos** | `image_picker` | કેમેરાથી મુલાકાતીનો લાઈવ ફોટો લેવા માટે |
| **Phone & External Links** | `url_launcher` (^6.3.1) | ૧-ટેપ કૉલિંગ, વોટ્સએપ અને UPI ઇન્ટેન્ટ |
| **Preferences & Cache** | `shared_preferences` (^2.5.6) | ભાષા પસંદગી અને લોકલ સ્ટેટ |

---

## 📂 પ્રોજેક્ટ ફાઇલ સ્ટ્રક્ચર (Project Directory Structure)

```text
my_building_guard/
├── android/                         # Android નેટિવ કોડ, આઇકન્સ અને મેનિફેસ્ટ સેટિંગ્સ
├── ios/                             # iOS નેટિવ કોન્ફિગરેશન અને Podfile
├── functions/                       # Firebase Cloud Functions (Node.js)
│   ├── index.js                     # v2 Triggers & Callable APIs (FCM push, alerts)
│   ├── package.json                 # Node dependencies
│   └── .eslintrc.js
├── lib/
│   ├── main.dart                    # એપ એન્ટ્રી પોઈન્ટ, થીમ, AuthWrapper
│   ├── firebase_options.dart        # FlutterFire કન્ફિગરેશન
│   ├── firebase_messaging_background.dart # FCM બેકગ્રાઉન્ડ હેન્ડલર
│   ├── core/
│   │   └── app_firestore.dart       # સુરક્ષિત Firestore ઇન્સ્ટન્સ રેપર
│   ├── l10n/
│   │   └── app_strings.dart         # ત્રિભાષી શબ્દકોશ (GU, HI, EN)
│   ├── models/
│   │   ├── amenity_model.dart       # સોસાયટી એમેનિટીઝ & બુકિંગ મોડેલ
│   │   ├── maintenance_model.dart   # મેન્ટેનન્સ બિલિંગ & UPI પેમેન્ટ મોડેલ
│   │   ├── patrol_model.dart        # ગાર્ડ પેટ્રોલિંગ ચેકપોઇન્ટ & લોગ મોડેલ
│   │   ├── poll_model.dart          # સોસાયટી પોલ & વોટિંગ મોડેલ
│   │   ├── premise_type.dart        # સોસાયટી આર્કિટેક્ચર વોકેબ્યુલરી (Wing/Street)
│   │   ├── society_expense_model.dart # આવક-ખર્ચ અને બેલેન્સ શીટ મોડેલ
│   │   ├── super_admin_models.dart  # પ્લેટફોર્મ સુપર એડમિન એનાલિટિક્સ મોડેલ
│   │   ├── user_model.dart          # યુઝર મોડેલ (Admin, Member, Watchman, SuperAdmin)
│   │   └── visitor_model.dart       # વિઝિટર અને એન્ટ્રી/એક્ઝિટ મોડેલ
│   ├── screens/
│   │   ├── super_admin/             # સુપર એડમિન કમાન્ડ સેન્ટર
│   │   │   ├── super_admin_dashboard.dart
│   │   │   ├── super_admin_create_admin_screen.dart
│   │   │   ├── super_admin_onboard_society_screen.dart
│   │   │   ├── super_admin_appeal_detail_screen.dart
│   │   │   └── super_admin_broadcast_screen.dart
│   │   ├── login_screen.dart        # મલ્ટી-સોસાયટી સિક્યોર લૉગિન
│   │   ├── admin_dashboard.dart     # એડમિન ડેશબોર્ડ & એનાલિટિક્સ
│   │   ├── admin_setup_wizard_screen.dart # સોસાયટી આર્કિટેક્ચર સેટઅપ વિઝાર્ડ
│   │   ├── admin_add_block_screen.dart    # નવા બ્લોક/વિંગ ઉમેરવા
│   │   ├── admin_add_user_screen.dart     # નવો યુઝર ઉમેરવો
│   │   ├── admin_users_directory_screen.dart # સભ્યોની ડિરેક્ટરી
│   │   ├── admin_watchmen_manage_screen.dart # વોચમેન મેનેજમેન્ટ
│   │   ├── admin_maintenance_screen.dart  # મેન્ટેનન્સ કંટ્રોલ & રસીદો
│   │   ├── admin_bulk_bill_screen.dart    # ૧-ક્લિક બલ્ક બિલિંગ
│   │   ├── admin_society_bank_settings_screen.dart # સોસાયટી બેંક & UPI સેટિંગ્સ
│   │   ├── admin_accounts_screen.dart     # સોસાયટી એકાઉન્ટ્સ & ઓડિટ
│   │   ├── admin_patrol_screen.dart       # ગાર્ડ પેટ્રોલિંગ ચેકપોઇન્ટ મેનેજર
│   │   ├── admin_polls_screen.dart        # સોસાયટી પોલ્સ & વોટિંગ
│   │   ├── admin_amenities_screen.dart    # ક્લબહાઉસ & એમેનિટીઝ કંટ્રોલ
│   │   ├── admin_member_signature_sheet_screen.dart # સભ્યોની સહી શીટ
│   │   ├── admin_parking_management_screen.dart # પાર્કિંગ સ્લોટ્સ કંટ્રોલ
│   │   ├── admin_broadcast_screen.dart    # બ્રોડકાસ્ટ પુશ નોટિફિકેશન
│   │   ├── admin_publish_notice_screen.dart # નોટિસ બોર્ડ જાહેરાત
│   │   ├── admin_complaints_screen.dart   # ફરિયાદ નિવારણ ડેસ્ક
│   │   ├── admin_emergency_contacts_screen.dart # ઇમરજન્સી હેલ્પલાઇન નંબર્સ
│   │   ├── admin_visitor_report_screen.dart # વિઝિટર રિપોર્ટ અને એનાલિટિક્સ
│   │   ├── architecture_preview.dart      # સોસાયટી ફ્લોર/શેરી પ્રિવ્યુ
│   │   ├── watchmen_screen.dart     # વોચમેન પોર્ટલ: ડિલિવરી ટેગ્સ, QR સ્કેનર
│   │   ├── watchman_patrol_screen.dart # વોચમેન નાઇટ પેટ્રોલ સ્કેનર
│   │   ├── member_screen.dart       # સભ્ય પોર્ટલ: ગેટ એલર્ટ્સ, SOS, વિઝિટર્સ
│   │   ├── member_pre_approve_screen.dart # અગાઉથી મંજૂરી ગેટ પાસ (QR)
│   │   ├── member_vehicles_screen.dart    # મારા વાહનો અને પાર્કિંગ સ્લોટ્સ
│   │   ├── member_daily_staff_screen.dart # કાયમી સ્ટાફ મેનેજમેન્ટ
│   │   ├── member_complaint_register_screen.dart # ફોટો સાથે ફરિયાદ નોંધણી
│   │   ├── member_accounts_screen.dart    # સોસાયટી એકાઉન્ટ્સ સ્ટેટમેન્ટ
│   │   ├── member_polls_screen.dart       # પોલ્સ & વોટિંગ
│   │   └── member_amenities_screen.dart   # ક્લબહાઉસ બુકિંગ
│   ├── services/
│   │   ├── firebase_app_guard.dart  # Firebase App Instance Helper
│   │   ├── notification_service.dart # FCM Token મેનેજમેન્ટ અને લોકલ નોટિફિકેશન
│   │   ├── notification_navigation_service.dart # સેન્ટ્રલ ડીપ લિંકિંગ & રીડાયરેક્શન
│   │   ├── maintenance_service.dart # ૦% ફી 1-Tap UPI પેમેન્ટ્સ & ડિજિટલ રસીદો
│   │   ├── maintenance_receipt_pdf_service.dart # ઓથેન્ટિક રબર સ્ટેમ્પ્સ સાથે PDF રસીદ
│   │   ├── society_accounts_service.dart # સોસાયટી ખાતાવહી & ફંડ મેનેજમેન્ટ
│   │   ├── society_accounts_pdf_service.dart # સોસાયટી ઓડિટ બેલેન્સ શીટ PDF
│   │   ├── guard_patrol_service.dart # QR પેટ્રોલિંગ ચેકપોઇન્ટ & ઓડિટ એન્જિન
│   │   ├── society_poll_service.dart # સોસાયટી પોલ્સ & વોટિંગ સર્વિસ
│   │   ├── amenity_booking_service.dart # એમેનિટીઝ & સ્લોટ બુકિંગ એન્જિન
│   │   ├── member_signature_sheet_pdf_service.dart # AGM સહી શીટ PDF જનરેશન
│   │   ├── session_guard_service.dart # સિંગલ-ડિવાઇસ સેશન ગાર્ડ
│   │   ├── society_service.dart     # Multi-tenancy & ડેટા ફિલ્ટરિંગ
│   │   ├── society_appeal_service.dart # સોસાયટી સસ્પેન્શન અપીલ સર્વિસ
│   │   ├── super_admin_service.dart # પ્લેટફોર્મ સુપર એડમિન સર્વિસ
│   │   ├── admin_credential_dispatcher_service.dart # એડમિન ક્રેડેન્શિયલ ડિસ્પેચ
│   │   └── localization_service.dart # ત્રિભાષી (GU/HI/EN) લાઇવ રિએક્ટિવ એન્જિન
│   ├── theme/
│   │   └── premium_theme.dart       # મટીરિયલ ૩ પ્રીમિયમ સોસાયટી કલર થીમ
│   └── widgets/
│       ├── app_navigation_drawer.dart # યુનિવર્સલ રોલ-અવેર નેવિગેશન ડ્રોઅર
│       ├── premium_app_bar.dart     # અલ્ટ્રા-પ્રીમિયમ સ્ક્વિર્કલ AppBar
│       ├── premium_ui.dart          # પુનઃઉપયોગી UI કોમ્પોનન્ટ્સ & લૉગઆઉટ ડાયલોગ
│       ├── member_maintenance_sheet.dart # 1-Tap UPI ઇન્ટેન્ટ, ડાયનેમિક QR, રસીદો
│       ├── member_notifications_sheet.dart # ઇન-એપ નોટિફિકેશન સેન્ટર
│       ├── parking_slot_selector_sheet.dart # વિઝ્યુઅલ પાર્કિંગ લોટ સિલેક્ટર
│       ├── visitor_detail_sheet.dart # મુલાકાતી વિગતવાર માહિતી શીટ
│       └── watchman_vehicle_lookup_sheet.dart # વાહન સર્ચ & રોંગ પાર્કિંગ એલર્ટ
├── firestore.rules                  # એન્ટરપ્રાઇઝ Multi-tenant RBAC સિક્યોરિટી રૂલ્સ
├── firestore.indexes.json           # Firestore કમ્પાઉન્ડ ઇન્ડેક્સ
├── firebase.json                    # Firebase હોસ્ટિંગ, ફંક્શન્સ અને રૂલ્સ સેટિંગ્સ
└── pubspec.yaml                     # Flutter પેકેજીસ અને એસેટ્સ
```

---

## 🗄️ ડેટાબેઝ મોડેલ (Firestore Collections Schema)

| કલેક્શન (Collection) | હેતુ (Purpose) | મુખ્ય ફીલ્ડ્સ (Key Fields) |
| :--- | :--- | :--- |
| `users` | તમામ વપરાશકર્તાઓ (Admins, Members, Guards, SuperAdmins) | `uid`, `name`, `email`, `role`, `societyId`, `blockName`, `unitNumber`, `fcmToken`, `isActive`, `phone`, `currentSessionId` |
| `society_settings` | સોસાયટી કન્ફિગરેશન | `societyId`, `societyName`, `architectureType`, `isSetupComplete`, `societyUpiId`, `societyBankDetails`, `status` (`active`/`suspended`) |
| `blocks` | વિંગ અથવા શેરી વિગતો | `name`, `type` (`Wing`/`Street`), `v1` (floors), `v2` (units/floor), `societyId` |
| `units` | સોસાયટીના ફ્લેટ્સ / મકાનો | `unitNumber`, `blockName`, `societyId`, `memberId`, `memberIds`, `isOccupied` |
| `visitors` | મુલાકાતીઓનો લાઈવ લોગ | `name`, `phone`, `purpose`, `photoUrl`, `memberId`, `watchmanId`, `unitNumber`, `societyId`, `status`, `entryTime`, `exitTime` |
| `pre_approvals` | અગાઉથી મંજૂર કરેલ મહેમાનો | `name`, `phone`, `date`, `memberId`, `societyId`, `unitNumber`, `status`, `qrCode` |
| `maintenance_bills` | મેન્ટેનન્સ બિલિંગ & UPI ટ્રાન્ઝેક્શન્સ | `billTitle`, `societyId`, `blockName`, `unitNumber`, `memberId`, `memberName`, `dueDate`, `amount`, `status`, `paymentMode`, `utrNumber`, `receiptNumber`, `paidAt` |
| `society_accounts` | સોસાયટી આવક & ખર્ચ ખાતાવહી | `title`, `amount`, `type` (`income`/`expense`), `category`, `date`, `receiptUrl`, `societyId`, `recordedBy` |
| `patrol_checkpoints` | ગાર્ડ પેટ્રોલિંગ QR ચેકપોઇન્ટ્સ | `title`, `locationTag`, `qrToken`, `societyId`, `createdAt` |
| `patrol_logs` | ગાર્ડ પેટ્રોલિંગ સ્કેન ઇતિહાસ | `checkpointId`, `checkpointTitle`, `watchmanId`, `watchmanName`, `scannedAt`, `societyId` |
| `society_polls` | સોસાયટી વોટિંગ પોલ્સ | `title`, `description`, `options`, `votes`, `societyId`, `expiryDate`, `isClosed` |
| `amenities` | સોસાયટી એમેનિટીઝ & સુવિધાઓ | `name`, `description`, `capacity`, `rules`, `isActive`, `societyId` |
| `amenity_bookings` | એમેનિટીઝ બુકિંગ સ્લોટ્સ | `amenityId`, `amenityName`, `memberId`, `unitNumber`, `bookingDate`, `slot`, `status`, `societyId` |
| `society_appeals` | સસ્પેન્શન સામે સોસાયટી અપીલ્સ | `societyId`, `societyName`, `adminName`, `reason`, `appealText`, `status` (`pending`/`reviewed`), `createdAt` |
| `notices` | નોટિસ બોર્ડ પરિપત્રો | `title`, `description`, `societyId`, `createdAt`, `authorName` |
| `complaints` | રહીશોની ફરિયાદો | `title`, `description`, `photoUrl`, `memberName`, `memberId`, `societyId`, `status`, `createdAt` |
| `daily_staff` | કાયમી કામદારો (Maid, Driver) | `name`, `phone`, `role`, `unitNumber`, `societyId` |
| `notifications` | પુશ નોટિફિકેશન કતાર | `title`, `body`, `targetUID`, `societyId`, `type`, `billId`, `receiptNumber` |

---

## ⚡ ક્લાઉડ ફંક્શન્સ (Firebase Cloud Functions v2)

`functions/index.js` માં નીચે મુજબના સર્વરલેસ ફંક્શન્સ સામેલ છે:

1. **`sendMemberPush` (Callable)**:
   - વોચમેન દ્વારા વિઝિટર એન્ટ્રી થતાં અથવા એડમિન દ્વારા મેન્ટેનન્સ પેમેન્ટ મંજૂર થતાં ડાયરેક્ટ મેમ્બરના ફોન પર હાઈ-પ્રાયોરિટી FCM પુશ મોકલે છે.
2. **`sendBroadcastPush` (Callable)**:
   - એડમિન દ્વારા સોસાયટીના તમામ સભ્યોને સામૂહિક સૂચના મોકલવા માટે.
3. **`sendTopicAlertPush` (Callable)**:
   - મેમ્બર અથવા ગાર્ડ દ્વારા વન-ટચ ઇમરજન્સી SOS એલર્ટ (`admins` અથવા `watchmen` ને) મોકલવા માટે.
4. **`sendNotification` (Firestore Trigger - `onDocumentCreated`)**:
   - `notifications/{notifId}` બનવા પર ઓટોમેટિક બેકગ્રાઉન્ડ ડિલિવરી (ટોપિક અથવા મલ્ટીકાસ્ટ ફેન-આઉટ સાથે).
5. **`onStatusChange` (Firestore Trigger - `onDocumentUpdated`)**:
   - જ્યારે સભ્ય વિઝિટરને **Approved** કે **Rejected** કરે ત્યારે વોચમેનને ઓટોમેટિક જાણ કરે છે.
   - જ્યારે મુલાકાતી **Checked-out** થાય ત્યારે રહીશને જાણ કરે છે.

---

## 🚀 સેટઅપ અને ઇન્સ્ટોલેશન (Getting Started)

### પૂર્વજરૂરિયાતો (Prerequisites)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.10.7)
- [Node.js](https://nodejs.org/) (v18 અથવા v20)
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- Android Studio / Xcode

### પગલાં (Step-by-Step Installation)

1. **પ્રોજેક્ટ ક્લોન કરો**:
   ```bash
   git clone https://github.com/your-username/my_building_guard.git
   cd my_building_guard
   ```

2. **Flutter ડિપેન્ડન્સી ઇન્સ્ટોલ કરો**:
   ```bash
   flutter pub get
   ```

3. **Firebase પ્રોજેક્ટ કન્ફિગર કરો**:
   - Firebase CLI વડે લોગિન કરો:
     ```bash
     firebase login
     ```
   - FlutterFire કન્ફિગરેશન રન કરો:
     ```bash
     flutterfire configure
     ```

4. **Cloud Functions ડિપેન્ડન્સી & ડિપ્લોય**:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   cd ..
   ```

5. **Firestore Security Rules & Indexes ડિપ્લોય કરો**:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

---

## 🧪 ટેસ્ટિંગ અને બિલ્ડ (Build & Production)

### ડીબગ મોડમાં રન કરવા:
```bash
flutter run
```

### સ્ટેટિક એનાલિસિસ (Linter & Type Checking):
```bash
flutter analyze
```

### યુનિટ અને વિજેટ ટેસ્ટ્સ રન કરવા:
```bash
flutter test
```

### Android APK બિલ્ડ કરવા (Release):
```bash
flutter build apk --release
```

### Android App Bundle (Google Play Store):
```bash
flutter build appbundle --release
```

### iOS બિલ્ડ (Apple App Store):
```bash
flutter build ipa --release
```

---

## 👨‍💻 યોગદાન અને સપોર્ટ (Contributing & Support)
જો તમને કોઈ પ્રશ્ન હોય અથવા નવું ફીચર સૂચવવું હોય, તો કૃપા કરીને Issue અથવા Pull Request સબમિટ કરો.

**Made with ❤️ for safer, smarter and transparent society communities.**
