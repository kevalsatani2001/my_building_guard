# 🏢 My Building Guard (સોસાયટી મેનેજમેન્ટ & સિક્યુરિટી ગેટ પાસ સિસ્ટમ)

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20FCM%20%7C%20Functions%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Architecture](https://img.shields.io/badge/Architecture-Multi--Tenant-blueviolet)](#-મલ્ટી-ટેનન્ટ-આર્કિટેક્ચર-multi-tenancy)
[![Security](https://img.shields.io/badge/Security-Single--Device%20Session%20Guard-red)](#-સિક્યુરિટી-અને-સેશન-ગાર્ડ-security--session-guard)
[![Language](https://img.shields.io/badge/UI_Language-Gujarati_%26_English-success)](#)

**My Building Guard** એ રહેણાંક સોસાયટીઓ, હાઇરાઇઝ એપાર્ટમેન્ટ્સ અને રો-હાઉસ ટાઉનશિપ માટે તૈયાર કરવામાં આવેલી એક અત્યાધુનિક, મલ્ટી-ટેનન્ટ સોસાયટી મેનેજમેન્ટ, વિઝિટર સિક્યુરિટી અને ૦% કમિશન મેન્ટેનન્સ બિલિંગ એપ્લિકેશન છે.

આ એપ્લિકેશન સોસાયટીના **ચેરમેન/એડમિન**, **સિક્યુરિટી ગાર્ડ (વોચમેન)** અને **સોસાયટીના રહીશો (મેમ્બર્સ)** વચ્ચે ત્રિસ્તરીય રીઅલ-ટાઇમ સંકલન સાધે છે.

---

## 📑 અનુક્રમણિકા (Table of Contents)
- [✨ તમામ રોલ મુજબ વિગતવાર ફીચર્સ (Role-wise Functionality)](#-તમામ-રોલ-મુજબ-વિગતવાર-ફીચર્સ-role-wise-functionality)
  - [૧. 👑 એડમિન / કમિટી પોર્ટલ (Admin Portal)](#૧--એડમિન--કમિટી-પોર્ટલ-admin-portal)
  - [૨. 🛡️ સિક્યુરિટી ગાર્ડ / વોચમેન પોર્ટલ (Watchman Portal)](#૨-️-સિક્યુરિટી-ગાર્ડ--વોચમેન-પોર્ટલ-watchman-portal)
  - [૩. 🏠 સભ્ય / રહીશ પોર્ટલ (Resident / Member Portal)](#૩--સભ્ય--રહીશ-પોર્ટલ-resident--member-portal)
- [💎 મુખ્ય વિશિષ્ટ સબ-સિસ્ટમ્સ (Core Specialized Systems)](#-મુખ્ય-વિશિષ્ટ-સબ-સિસ્ટમ્સ-core-specialized-systems)
  - [૧. 💳 ૦% ફી મેન્ટેનન્સ બિલિંગ & UPI સિસ્ટમ](#૧--૦-ફી-મેન્ટેનન્સ-બિલિંગ--upi-સિસ્ટમ)
  - [૨. 📄 સત્તાવાર ડિજિટલ PDF રસીદ & રબર સ્ટેમ્પ એન્જિન](#૨--સત્તાવાર-ડિજિટલ-pdf-રસીદ--રબર-સ્ટેમ્પ-એન્જિન)
  - [૩. 🔔 સ્માર્ટ નોટિફિકેશન રીડાયરેક્શન & ઇન-એપ સેન્ટર](#૩--સ્માર્ટ-નોટિફિકેશન-રીડાયરેક્શન--ઇન-એપ-સેન્ટર)
  - [૪. 🚗 વાહન લુકઅપ & રોંગ પાર્કિંગ એલર્ટ સિસ્ટમ](#૪--વાહન-લુકઅપ--રોંગ-પાર્કિંગ-એલર્ટ-સિસ્ટમ)
  - [૫. 🚨 વન-ટચ ઇમરજન્સી SOS પેનિક સાયરન](#૫--વન-ટચ-ઇમરજન્સી-sos-પેનિક-સાયરન)
  - [૬. 🏢 મલ્ટી-ટેનન્ટ સોસાયટી પાર્ટીશનીંગ](#૬--મલ્ટી-ટેનન્ટ-સોસાયટી-પાર્ટીશનીંગ)
  - [૭. 🔐 સિંગલ-ડિવાઇસ સેશન ગાર્ડ & RBAC સિક્યુરિટી](#૭--સિંગલ-ડિવાઇસ-સેશન-ગાર્ડ--rbac-સિક્યુરિટી)
- [🛠️ ટેકનોલોજી સ્ટેક (Tech Stack & Libraries)](#️-ટેકનોલોજી-સ્ટેક-tech-stack--libraries)
- [📂 પ્રોજેક્ટ ફાઇલ સ્ટ્રક્ચર (Project Directory Structure)](#-પ્રોજેક્ટ-ફાઇલ-સ્ટ્રક્ચર-project-directory-structure)
- [🗄️ ડેટાબેઝ મોડેલ (Firestore Collections Schema)](#️-ડેટાબેઝ-મોડેલ-firestore-collections-schema)
- [⚡ ક્લાઉડ ફંક્શન્સ (Firebase Cloud Functions v2)](#-ક્લાઉડ-ફંક્શન્સ-firebase-cloud-functions-v2)
- [🚀 સેટઅપ અને ઇન્સ્ટોલેશન (Getting Started)](#-સેટઅપ-અને-ઇન્સ્ટોલેશન-getting-started)
- [🧪 ઓટોમેટેડ ટેસ્ટિંગ (Automated Tests)](#-ઓટોમેટેડ-ટેસ્ટિંગ-automated-tests)
- [📱 બિલ્ડ અને પ્રોડક્શન (Build & Release)](#-બિલ્ડ-અને-પ્રોડક્શન-build--release)

---

## ✨ તમામ રોલ મુજબ વિગતવાર ફીચર્સ (Role-wise Functionality)

### ૧. 👑 એડમિન / કમિટી પોર્ટલ (Admin Portal)
સોસાયટી ચેરમેન અને મેનેજિંગ કમિટી માટે સમગ્ર સોસાયટીનું સંચાલન કરવા માટેનું શક્તિશાળી એડમિન કંટ્રોલ સેન્ટર:

* **ડેશબોર્ડ & લાઈવ એનાલિટિક્સ (`admin_dashboard.dart`)**:
  * સોસાયટીના કુલ ફ્લેટ્સ/મકાનો, સક્રિય રહીશો, ઓન-ડ્યુટી ગાર્ડ્સ અને પેન્ડિંગ ફરિયાદોનું રીયલ-ટાઇમ કાઉન્ટર.
  * લાઈવ મેન્ટેનન્સ કલેક્શન પ્રોગ્રેસ બાર (કુલ જમા રકમ, કુલ બાકી રકમ, ચૂકવણી કરનાર ફ્લેટ્સની ટકાવારી).
  * વિઝિટર એનાલિટિક્સ રિપોર્ટ: દૈનિક, માસિક અને વિંગ-વાઇઝ વિઝિટર ટ્રાફિક ગ્રાફ, પીક-અવર્સ એનાલિસિસ.
* **સોસાયટી આર્કિટેક્ચર સેટઅપ વિઝાર્ડ (`admin_setup_wizard_screen.dart`, `admin_add_block_screen.dart`)**:
  * **વિંગ સિસ્ટમ (Wing Architecture)**: હાઇરાઇઝ એપાર્ટમેન્ટ્સ માટે વિંગ (A, B, C...), માળની સંખ્યા અને ફ્લોર મુજબ ફ્લેટ ઓટો-જનરેશન.
  * **શેરી સિસ્ટમ (Street / Row-House)**: ટેનામેન્ટ/રો-હાઉસ માટે શેરી નંબર અને પ્લોટ નંબરિંગ.
  * **આર્કિટેક્ચર પ્રિવ્યુ (`architecture_preview.dart`)**: દરેક વિંગ/શેરી અને ફ્લેટની લાઈવ ઇન્ટરેક્ટિવ ગ્રીડ.
  * સેટઅપ પૂર્ણ થયા બાદ ડેટા અખંડિતતા જાળવવા આર્કિટેક્ચર સુરક્ષિત રીતે લૉક થાય છે.
* **સભ્યોની ડિરેક્ટરી & યુઝર કંટ્રોલ (`admin_users_directory_screen.dart`, `admin_add_user_screen.dart`)**:
  * સભ્યોનું નવું રજીસ્ટ્રેશન (ફ્લેટ માલિક અથવા ભાડુઆત તરીકે).
  * સભ્યની પ્રોફાઇલ એડિટ કરવી અથવા યુનિટ બદલવું.
  * એકાઉન્ટ એક્ટિવેટ / સસ્પેન્ડ (સસ્પેન્ડ થતાં જ સભ્યના ફોનમાં ઇન્સ્ટન્ટ ઓટો-લૉગઆઉટ થાય છે).
* **સિક્યુરિટી ગાર્ડ મેનેજમેન્ટ (`admin_watchmen_manage_screen.dart`)**:
  * વોચમેનનું પબ્લિક રજીસ્ટ્રેશન બંધ હોવાથી માત્ર એડમિન જ સિક્યુરિટી ગાર્ડ્સનું એકાઉન્ટ બનાવી શકે છે.
  * ગેટ અસાઇનમેન્ટ, પાસવર્ડ રીસેટ અને સસ્પેન્શન કંટ્રોલ.
* **મેન્ટેનન્સ & હિસાબ કંટ્રોલ સેન્ટર (`admin_maintenance_screen.dart`)**:
  * **૧-ક્લિક બલ્ક બિલ જનરેશન**: મહિનાના પ્રથમ દિવસે આખી સોસાયટીના તમામ ફ્લેટ્સ માટે એક જ ક્લિકમાં માસિક બિલ બનાવવું.
  * **UPI પેમેન્ટ વેરિફિકેશન**: સભ્યો દ્વારા ઓનલાઇન જમા કરાયેલા UPI ટ્રાન્ઝેક્શન્સ (UTR નંબર) ની ચકાસણી અને ૧-ક્લિક એપ્રૂવલ.
  * **ઓફલાઇન પેમેન્ટ્સ (Mark Paid)**: રોકડ (Cash), ચેક (Cheque) કે રૂબરૂ QR સ્કેનથી પેમેન્ટ નોંધી ઇન્સ્ટન્ટ રસીદ બનાવવી.
  * **૧-ક્લિક ડ્યુ રીમાઇન્ડર એલર્ટ**: બાકી રકમ વાળા તમામ સભ્યોને એક સાથે હાઈ-પ્રાયોરિટી પુશ એલર્ટ મોકલવું.
  * **સભ્ય વિગતવાર પ્રોફાઇલ શીટ (Redesigned 5-Star Executive UI)**:
    * ૫૮x૫૮ સ્ક્વિર્કલ ગ્રેડિયન્ટ અવતાર વિથ યુઝર ઇનિશિયલ્સ ("KS") / ફોટો અને વેરિફાઇડ બેજ.
    * લગ્ઝરી ડાર્ક સ્લેટ ફ્લેટ બેજ (`S-1-1`) અને ઓક્યુપન્ટ બેજ (`ફ્લેટ માલિક (Owner)` / `ભાડુઆત (Tenant)`).
    * ફાઇનાન્સિયલ સ્ટેટસ હીરો કાર્ડ (પેઇડ, પેન્ડિંગ અથવા અંડર-રિવ્યુ).
    * ૧-ટેપ કૉપિ સંપર્ક કાર્ડ (મોબાઇલ નંબર અને ઇમેઇલ ૧-ટેપમાં ક્લિપબોર્ડમાં કૉપિ).
    * ૨-ટાયર એક્શન બાર: [📞 કૉલ કરો] અને [💬 વોટ્સએપ] (ટેક્સ્ટ ક્યારેય તૂટશે નહીં), [✉️ મેસેજ મોકલો], [📄 રસીદ જુઓ / રોકડ સ્વીકારો].
* **સોસાયટી બેંક & UPI સેટિંગ્સ (`admin_society_bank_settings_screen.dart`)**:
  * સોસાયટીનો સત્તાવાર UPI ID (VPA), એકાઉન્ટ નંબર, બેંક નામ, IFSC અને પેમેન્ટ QR કોડ ઇમેજ કન્ફિગરેશન.
  * ડિફૉલ્ટ માસિક રકમ, લેટ પેનલ્ટી અને નિયત તારીખ સેટિંગ્સ.
* **સત્તાવાર ડિજિટલ PDF રસીદ એન્જિન (`maintenance_receipt_pdf_service.dart`)**:
  * ચૂકવેલા તમામ બિલ માટે અધિકૃત ડિજિટલ રસીદ જનરેટ કરવી.
  * ઓથેન્ટિક **PAID (ગ્રીન) અને UNPAID (રેડ) ડિજિટલ રબર સ્ટેમ્પ**.
  * ઇન-એપ PDF વ્યુઅર, ડાઉનલોડ અને WhatsApp શેરિંગ સપોર્ટ.
* **બ્રોડકાસ્ટ પુશ નોટિફિકેશન (`admin_broadcast_screen.dart`)**:
  * સમગ્ર સોસાયટીના તમામ સભ્યોને કે ચોક્કસ બ્લોકના રહીશોને તાત્કાલિક પુશ નોટિફિકેશન મોકલવું.
* **ડિજિટલ નોટિસ બોર્ડ (`admin_publish_notice_screen.dart`)**:
  * સોસાયટી માટે મહત્વની જાહેરાતો, પાણી કાપ, વાર્ષિક સાધારણ સભા (AGM) ના પરિપત્રો પ્રસિદ્ધ કરવા.
* **ફરિયાદ નિવારણ ડેસ્ક (`admin_complaints_screen.dart`)**:
  * સભ્યો દ્વારા મુકાયેલી ફરિયાદો (ફોટો પુરાવા સહિત) ની સમીક્ષા કરવી અને 'ઉકેલાઈ' (Resolved) માર્ક કરવી.
* **ઇમરજન્સી હેલ્પલાઇન ડિરેક્ટરી (`admin_emergency_contacts_screen.dart`)**:
  * પોલીસ, એમ્બ્યુલન્સ, ફાયર, ઇલેક્ટ્રિશિયન, પ્લમ્બર અને લિફ્ટ ટેકનિશિયનના નંબર્સ મેનેજ કરવા.

---

### ૨. 🛡️ સિક્યુરિટી ગાર્ડ / વોચમેન પોર્ટલ (Watchman Portal)
સોસાયટીના મુખ્ય દરવાજે સુરક્ષા જાળવવા અને વિઝિટર્સની ઝડપી એન્ટ્રી કરવા માટેનું હાઇ-સ્પીડ ગાર્ડ પોર્ટલ (`watchmen_screen.dart`):

* **૧-ટેપ ક્વિક ડિલિવરી એન્ટ્રી (Quick Tags)**:
  * Swiggy, Zomato, Amazon, Flipkart, Blinkit, Zepto, Uber, Rapido વગેરે ડિલિવરી પાર્ટનર્સ માટે વન-ટેપ ઓટોફિલ એન્ટ્રી.
* **લાઇવ કેમેરા ફોટો કેપ્ચર વિઝિટર એન્ટ્રી**:
  * મોબાઇલ કેમેરા વડે મુલાકાતીનો લાઇવ ફોટો કેપ્ચર અને Firebase Storage અપલોડ.
  * મુલાકાતીનું નામ, ફોન નંબર, આવવાનું કારણ અને લક્ષ્ય ફ્લેટ/વિંગ પસંદગી.
  * સબમિટ કરતાં જ રહીશના મોબાઇલ પર ઇન્સ્ટન્ટ રિંગ/નોટિફિકેશન રવાના.
* **પ્રી-એપ્રુવ્ડ QR ગેટ પાસ સ્કેનિંગ**:
  * `mobile_scanner` વડે મુલાકાતીના મોબાઇલ પર રહેલા QR કોડનું ૧-સેકન્ડમાં લાઈવ સ્કેનિંગ.
  * ઓટોમેટિક પાસ વેરિફિકેશન અને ગેટ એન્ટ્રી એપ્રૂવલ.
  * મહેમાનના નામ કે ફોન નંબર દ્વારા પ્રી-એપ્રુવ્ડ પાસનું લાઈવ સર્ચ.
* **વાહન સર્ચ & રોંગ પાર્કિંગ એલર્ટ (`watchman_vehicle_lookup_sheet.dart`)**:
  * કોઈપણ ગાડી/બાઇકના નંબર પરથી ફ્લેટ અને વાહન માલિકની તાત્કાલિક શોધ.
  * એપમાંથી જ વાહન માલિકને ડાયરેક્ટ ફોન કૉલિંગ.
  * રસ્તો રોકતા વાહનો માટે ૧-ક્લિક **ખોટું પાર્કિંગ પુશ નોટિફિકેશન (Wrong Parking Alert)**.
* **રીઅલ-ટાઇમ મુલાકાતી લોગ & ઑડિયો એલર્ટ**:
  * પેન્ડિંગ, મંજૂર (Approved), અસ્વીકાર (Rejected) અને ચેક-આઉટ સ્ટેટસ.
  * સભ્ય તરફથી મંજૂરી કે નકાર આવે ત્યારે ઓટોમેટિક સાઉન્ડ ચાઇમ (`audioplayers`).
  * બહાર જતી વખતે સરળ "ચેક-આઉટ" (Exit Logging) બટન.
* **ઇમરજન્સી SOS મોનિટરિંગ**:
  * સોસાયટીના કોઈપણ ફ્લેટમાંથી SOS એલર્ટ વાગે એટલે ગાર્ડની સ્ક્રીન પર ફ્લેટ નંબર સાથે હાઈ-પ્રાયોરિટી રેડ એલર્ટ ડિસ્પ્લે થાય છે.

---

### ૩. 🏠 સભ્ય / રહીશ પોર્ટલ (Resident / Member Portal)
સોસાયટીના સભ્યો માટે પારદર્શિતા, સુવિધા અને સલામતી પૂરી પાડતું ઓલ-ઇન-વન રહીશ પોર્ટલ (`member_screen.dart`):

* **લાઇવ ગેટ એલર્ટ્સ & વિઝિટર મંજૂરી/નકાર**:
  * ગેટ પર મુલાકાતી આવે ત્યારે મહેમાનનો ફોટો, નામ અને વિગતો સાથે ઇન્સ્ટન્ટ સ્ક્રીન પોપ-અપ.
  * એક જ ક્લિકમાં **મંજૂરી (Approve)** અથવા **અસ્વીકાર (Reject)**.
* **અગાઉથી મંજૂરી (Pre-Approve Visitor Pass) (`member_pre_approve_screen.dart`)**:
  * આવનારા સંબંધી, મહેમાન કે ડિલિવરી બોય માટે અગાઉથી ગેટ પાસ જનરેટ કરવો.
  * **QR Code કાર્ડ**: વોટ્સએપ કે મેસેજ દ્વારા મહેમાનને મોકલવા માટે ડાઉનલોડ & શેરિંગ (`share_plus`, `qr_flutter`).
* **મેન્ટેનન્સ બિલિંગ & ૦% ફી ૧-ટેપ UPI પેમેન્ટ (`member_maintenance_sheet.dart`)**:
  * ડેશબોર્ડ પર બાકી બિલનું લાઈવ એલર્ટ કાર્ડ.
  * **૧-ટેપ UPI પેમેન્ટ ઇન્ટેન્ટ**: Google Pay, PhonePe, Paytm કે BHIM સીધું ખોલીને ચુકવણી.
  * **ડાયનેમિક સોસાયટી UPI QR કોડ**: કોઈપણ અન્ય ફોન કે બેંક એપથી સ્કેન કરી પેમેન્ટ કરવાની સુવિધા.
  * **UTR સબમિશન**: ૧૨ આંકડાનો UTR નંબર દાખલ કરી પેમેન્ટને 'ચકાસણી હેઠળ' મૂકવું.
  * **ડિજિટલ રસીદ હિસ્ટ્રી**: ચૂકવેલા તમામ બિલ્સની સત્તાવાર ડિજિટલ રસીદો (PAID Stamp સાથે) જોવી અને PDF ડાઉનલોડ/શેર કરવી.
* **સ્માર્ટ નોટિફિકેશન સેન્ટર & ડીપ લિંકિંગ (`member_notifications_sheet.dart`, `notification_navigation_service.dart`)**:
  * એપબારમાં લાઈવ કાઉન્ટ બેજ સાથે **નોટિફિકેશન બેલ આઇકન (🔔)**.
  * એડમિન પેમેન્ટ સ્વીકારે ત્યારે સભ્યને પુશ નોટિફિકેશન:
    `✅ મેન્ટેનન્સ પેમેન્ટ મંજૂર - રસીદ નં: REC-...`
  * **૧-ટેપ ડીપ લિંક રિડાયરેક્શન**: નોટિફિકેશન પર ટેપ કરતા જ સીધા સંબંધિત સેક્શન (ડિજિટલ રસીદ, પેમેન્ટ પોર્ટલ, ફરિયાદ, નોટિસ) પર આપોઆપ રીડાયરેક્ટ થવું.
* **મારા વાહનો & બિલ્ડિંગ પાર્કિંગ સ્લોટ મેનેજમેન્ટ (`member_vehicles_screen.dart`, `parking_slot_selector_sheet.dart`)**:
  * **બિલ્ડિંગ મુજબ સ્લોટ્સ નિર્માણ**: વિંગ/શેરી મુજબ ૪-વ્હીલર (`A-P01`), ૨-વ્હીલર (`A-B01`) અને EV સ્લોટ્સ (`A-EV01`) નું સ્માર્ટ ડિસ્પ્લે.
  * **સિંગલ-અસાઇનમેન્ટ ગેરંટી (No Double Booking)**: એકવાર સ્લોટ કોઈ વાહનને ફાળવાઈ જાય પછી તે 'બુક થયેલ' (Occupied) થઈને લોક થઈ જાય છે અને બીજા કોઈ સભ્યને ફાળવી શકાતો નથી.
  * **વિઝ્યુઅલ પાર્કિંગ લોટ પીકર**: ઉપલબ્ધ (લીલો), બુક થયેલ (લાલ - લોક) અને તમારા (વાદળી) સ્લોટ્સ સાથેનું ઇન્ટરેક્ટિવ ગ્રીડ.
  * **3D આર્ટ એસેટ્સ**: અલ્ટ્રા-પ્રીમિયમ 3D સ્માર્ટ પાર્કિંગ હીરો બેનર અને 3D કાર એમ્પ્ટી સ્ટેટ આઇકન.
* **સંપૂર્ણ વિઝિટર હિસ્ટ્રી & લાઇવ ટ્રેકિંગ પોર્ટલ (`member_visitors_screen.dart`, `visitor_detail_sheet.dart`)**:
  * **ડેડિકેટેડ વિઝિટર પેજ**: સર્ચ બાર, ટાઇમ ફિલ્ટર્સ (આજે, ૭ દિવસ, ૩૦ દિવસ, બધા) અને સ્ટેટસ ફિલ્ટર્સ સાથેનું ડેડિકેટેડ સ્ક્રીન.
  * **વિઝિટર ડિટેઇલ શીટ**: મુલાકાતીનો હાઇ-રિઝોલ્યુશન ફોટો, નામ, ફોન (+૧-ટેપ કૉલ & વોટ્સએપ), આવવાનો હેતુ, ફ્લેટ નંબર, એન્ટ્રી/એક્ઝિટ સમય અને રોકાણનો સમયગાળો.
  * **ઝીરો-ઓવરફ્લો ડિઝાઇન**: તમામ વિઝિટર ટેગ્સ અને બેજેસ માટે સંપૂર્ણ રિસ્પોન્સિવ વ્રેપિંગ.
* **કાયમી સ્ટાફ મેનેજમેન્ટ (Daily Staff) (`member_daily_staff_screen.dart`)**:
  * ઘરકામ કરનાર (Maid), ડ્રાઈવર, કૂક, ધોબી વગેરેની નોંધણી અને સમયપત્રક.
* **ડિજિટલ ફરિયાદ પોર્ટલ (`member_complaint_register_screen.dart`)**:
  * કેમેરા કે ગેલેરીમાંથી ફોટો પુરાવા સાથે લિકેજ, સિક્યુરિટી કે લિફ્ટ સંબંધિત ફરિયાદ નોંધાવવી.
* **ડિજિટલ નોટિસ બોર્ડ**: સોસાયટીના તમામ જાહેર પરિપત્રો, મીટિંગ વિગતો અને નોટિસો વાંચવી.
* **🚨 વન-ટચ ઇમરજન્સી SOS પેનિક બટન**:
  * અચાનક તકલીફ કે કટોકટીમાં ૧-ક્લિકથી એડમિન અને ગેટ વોચમેનને તાત્કાલિક સાયરન એલર્ટ મોકલવું.
* **ઇમરજન્સી હેલ્પલાઇન ડિરેક્ટરી**: પોલીસ, એમ્બ્યુલન્સ અને ફાયર બ્રિગેડના ૧-ટેપ ડાયલ નંબર્સ.

---

## 💎 મુખ્ય વિશિષ્ટ સબ-સિસ્ટમ્સ (Core Specialized Systems)

### ૧. 💳 ૦% ફી મેન્ટેનન્સ બિલિંગ & UPI સિસ્ટમ
* **ડાયરેક્ટ એકાઉન્ટ ટ્રાન્સફર**: કોઈ થર્ડ-પાર્ટી પેમેન્ટ ગેટવે કે વોલેટ વચ્ચે આવતું નથી; પૈસા સીધા સોસાયટીના સત્તાવાર બેંક એકાઉન્ટમાં જાય છે.
* **ઝીરો ટ્રાન્ઝેક્શન ફી (0% Platform Fee)**: સોસાયટી કે સભ્યને કોઈપણ પ્રકારનો કમિશન ચાર્જ લાગતો નથી.
* **૧-ટેપ UPI ડીપ લિંકિંગ**: NPCI સ્ટાન્ડર્ડ `upi://pay` URI પ્રોટોકોલ દ્વારા GPay, PhonePe, Paytm સીધું ઓપન થાય છે.
* **ડાયનેમિક ફ્લેટ-સ્પેસિફિક QR કોડ**: ફ્લેટ નંબર, મહિનો અને રકમ સાથેનો ઓટોમેટિક QR કોડ જનરેટ થાય છે.

### ૨. 📄 સત્તાવાર ડિજિટલ PDF રસીદ & રબર સ્ટેમ્પ એન્જિન
* **ઓથેન્ટિક રબર સ્ટેમ્પિંગ**:
  * ચૂકવેલ બિલ માટે: **લીલો (PAID) સ્ટેમ્પ** વિથ ડબલ-રીંગ ગિયર સર્કલ, ઑફિશિયલ સ્ટાર્સ અને ટિલ્ટેડ એન્ગલ.
  * બાકી બિલ માટે: **લાલ (UNPAID) સ્ટેમ્પ**.
* **દ્વિભાષી લેઆઉટ (Gujarati & English)**: ગુજરાતી અને અંગ્રેજી બંને ભાષામાં પરફેક્ટ ફોન્ટ રેન્ડરિંગ (`Noto Sans Gujarati`).
* **પ્રિન્ટ & શેરિંગ**: પીડીએફ ડાઉનલોડ, પ્રિન્ટિંગ (`printing` પેકેજ) અને WhatsApp શેરિંગ સપોર્ટ.

### ૩. 🔔 સ્માર્ટ નોટિફિકેશન રીડાયરેક્શન & ઇન-એપ સેન્ટર
* **ડીપ-લિંકિંગ નેવિગેશન એન્જિન (`NotificationNavigationService`)**:
  * સિસ્ટમ ટ્રે અથવા ફોરગ્રાઉન્ડ નોટિફિકેશન પર ટેપ કરતાં જ યુઝર સીધા તે વિષયના પેજ પર પહોંચી જાય છે.
  * `maintenance_receipt` -> સીધી ડિજિટલ રસીદ ખૂલશે.
  * `maintenance_due_reminder` -> સીધું UPI પેમેન્ટ પોર્ટલ ખૂલશે.
  * `complaint` -> ફરિયાદ સ્ક્રીન ખૂલશે.
  * `visitor_alert` -> ગેટ એન્ટ્રી અપ્રુવલ ખૂલશે.
* **ઇન-એપ નોટિફિકેશન સેન્ટર (`member_notifications_sheet.dart`)**:
  * મેમ્બર સ્ક્રીન પર નોટિફિકેશન બેલ આઇકન (🔔) લાઈવ કાઉન્ટ બેજ સાથે.
  * તમામ નોટિફિકેશન્સની હિસ્ટ્રી અને ૧-ક્લિક રીડાયરેક્શન.

### ૪. 🚗 વાહન લુકઅપ & રોંગ પાર્કિંગ એલર્ટ સિસ્ટમ
* ગેટ પર કે પાર્કિંગમાં ઊભેલા કોઈપણ વાહનના નંબર પરથી તરત જ ફ્લેટ નંબર અને માલિકની શોધ.
* રસ્તો રોકતા વાહનો માટે એપમાંથી જ સભ્યને ૧-ક્લિક **ખોટું પાર્કિંગ પુશ એલર્ટ**.

### ૫. 🚨 વન-ટચ ઇમરજન્સી SOS પેનિક સાયરન
* મેમ્બર સ્ક્રીન પરનું લાલ SOS બટન દબાવતા જ સોસાયટીના તમામ એડમિન અને ગેટ વોચમેનને સાયરન અવાજ સાથે હાઈ-પ્રાયોરિટી પુશ એલર્ટ પહોંચે છે.

### ૬. 🏢 મલ્ટી-ટેનન્ટ સોસાયટી પાર્ટીશનીંગ
* એક જ એપ્લિકેશન અને ડેટાબેઝ પરથી અસંખ્ય સોસાયટીઓ ચાલે છે.
* દરેક રેકોર્ડ પર વિશિષ્ટ `societyId` જોડાય છે (દા.ત. `shiv-residency`, `gokul-dham`).
* આઇસોલેટેડ પુશ ટોપિક્સ: `soc_{societyId}_members`, `soc_{societyId}_admins`, `soc_{societyId}_watchmen`.

### ૭. 🔐 સિંગલ-ડિવાઇસ સેશન ગાર્ડ & RBAC સિક્યુરિટી
* **સિંગલ-ડિવાઇસ લોગિન**: એક એકાઉન્ટ એક જ સમયે એક ફોનમાં ખુલી શકે છે; બીજા ફોનમાં લોગિન થતાં જૂના ફોનમાં તાત્કાલિક લોગઆઉટ થાય છે.
* **સર્વર-લેવલ RBAC (`firestore.rules`)**: એડમિન, મેમ્બર અને વોચમેન માટે સુરક્ષિત નિયમો.
* **વોચમેન સિક્યોરિટી**: વોચમેનનું પબ્લિક સેલ્ફ-રજીસ્ટ્રેશન બંધ છે; માત્ર અધિકૃત ચેરમેન જ ગાર્ડ એકાઉન્ટ બનાવી શકે છે.

---

## 🛠️ ટેકનોલોજી સ્ટેક (Tech Stack & Libraries)

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Frontend Framework** | [Flutter](https://flutter.dev) (Dart SDK ^3.10.7) | ક્રોસ-પ્લેટફોર્મ નેટિવ પર્ફોર્મન્સ |
| **Authentication** | Firebase Authentication | સિક્યોર ઇમેઇલ/પાસવર્ડ સેશન |
| **Database** | Cloud Firestore (Enterprise Native) | રીઅલ-ટાઇમ નો-SQL ડેટાબેઝ |
| **Serverless Backend** | Firebase Cloud Functions v2 (Node.js) | પુશ નોટિફિકેશન, એનાલિટિક્સ અને ઇવેન્ટ ટ્રિગર્સ |
| **Cloud Storage** | Firebase Cloud Storage | વિઝિટર ફોટો અને ફરિયાદ પુરાવા સંગ્રહ |
| **Push Notifications** | Firebase Cloud Messaging (FCM v1) & Local Notifications | બેકગ્રાઉન્ડ & ફોરગ્રાઉન્ડ હાઈ-પ્રાયોરિટી પુશ |
| **PDF Generation** | `pdf` & `printing` | સત્તાવાર મેન્ટેનન્સ રસીદો અને ડિજિટલ સ્ટેમ્પ્સ |
| **QR Code Scanner** | `mobile_scanner` | કેમેરા વડે પ્રી-એપ્રુવ્ડ ગેટ પાસ સ્કેનિંગ |
| **QR Code Generator** | `qr_flutter` | UPI પેમેન્ટ અને વિઝિટર પાસ QR નિર્માણ |
| **Audio Effects** | `audioplayers` | ગાર્ડ માટે એપ્રૂવલ ચાઇમ સાઉન્ડ |
| **Camera & Photos** | `image_picker` | કેમેરાથી મુલાકાતીનો લાઈવ ફોટો લેવા માટે |
| **Phone & External Links** | `url_launcher` | ૧-ટેપ કૉલિંગ, વોટ્સએપ અને UPI ઇન્ટેન્ટ |

---

## 📂 પ્રોજેક્ટ ફાઇલ સ્ટ્રક્ચર (Project Directory Structure)

```text
my_building_guard/
├── android/                         # Android નેટિવ કોડ અને મેનિફેસ્ટ સેટિંગ્સ
├── ios/                             # iOS નેટિવ કોન્ફિગરેશન
├── functions/                       # Firebase Cloud Functions (Node.js)
│   ├── index.js                     # v2 Triggers & Callable APIs (FCM push, alerts)
│   ├── package.json                 # Node dependencies
│   └── .eslintrc.js
├── lib/
│   ├── main.dart                    # એપ એન્ટ્રી પોઈન્ટ, થીમ, AuthWrapper
│   ├── firebase_options.dart        # FlutterFire કન્ફિગરેશન
│   ├── firebase_messaging_background.dart # FCM બેકગ્રાઉન્ડ હેન્ડલર
│   ├── models/
│   │   ├── user_model.dart          # યુઝર મોડેલ (Admin, Member, Watchman)
│   │   ├── visitor_model.dart       # વિઝિટર અને એન્ટ્રી/એક્ઝિટ મોડેલ
│   │   └── maintenance_model.dart   # મેન્ટેનન્સ બિલિંગ & UPI પેમેન્ટ મોડેલ
│   ├── screens/
│   │   ├── login_screen.dart        # લૉગિન અને સિક્યોર મલ્ટી-સોસાયટી રજીસ્ટ્રેશન
│   │   ├── admin_dashboard.dart     # એડમિન ડેશબોર્ડ & એનાલિટિક્સ
│   │   ├── admin_setup_wizard_screen.dart # સોસાયટી આર્કિટેક્ચર સેટઅપ વિઝાર્ડ
│   │   ├── admin_add_block_screen.dart    # નવા બ્લોક/વિંગ ઉમેરવા
│   │   ├── admin_add_user_screen.dart     # નવો યુઝર ઉમેરવો
│   │   ├── admin_users_directory_screen.dart # સભ્યોની ડિરેક્ટરી
│   │   ├── admin_watchmen_manage_screen.dart # વોચમેન મેનેજમેન્ટ
│   │   ├── admin_maintenance_screen.dart  # બલ્ક મેન્ટેનન્સ જનરેટર, રસીદો, UPI
│   │   ├── admin_society_bank_settings_screen.dart # સોસાયટી બેંક & UPI સેટિંગ્સ
│   │   ├── admin_broadcast_screen.dart    # બ્રોડકાસ્ટ પુશ નોટિફિકેશન
│   │   ├── admin_publish_notice_screen.dart # નોટિસ બોર્ડ જાહેરાત
│   │   ├── admin_complaints_screen.dart   # ફરિયાદ નિવારણ ડેસ્ક
│   │   ├── admin_emergency_contacts_screen.dart # ઇમરજન્સી હેલ્પલાઇન નંબર્સ
│   │   ├── admin_visitor_report_screen.dart # વિઝિટર રિપોર્ટ અને એનાલિટિક્સ
│   │   ├── architecture_preview.dart      # સોસાયટી ફ્લોર/શેરી પ્રિવ્યુ
│   │   ├── watchmen_screen.dart     # ગાર્ડ પોર્ટલ: ડિલિવરી ટેગ્સ, QR સ્કેનર, હિસ્ટ્રી
│   │   ├── member_screen.dart       # સભ્ય પોર્ટલ: વ્હીકલ, SOS, સ્ટાફ, ગેટ એલર્ટ્સ
│   │   ├── member_pre_approve_screen.dart # અગાઉથી મંજૂરી ગેટ પાસ (QR)
│   │   ├── member_vehicles_screen.dart    # મારા વાહનો અને પાર્કિંગ સ્લોટ
│   │   ├── member_daily_staff_screen.dart # કાયમી સ્ટાફ મેનેજમેન્ટ
│   │   └── member_complaint_register_screen.dart # ફોટો સાથે ફરિયાદ નોંધણી
│   ├── services/
│   │   ├── firebase_app_guard.dart  # Firebase App Instance Helper
│   │   ├── notification_service.dart # FCM Token મેનેજમેન્ટ અને લોકલ નોટિફિકેશન
│   │   ├── notification_navigation_service.dart # સેન્ટ્રલ ડીપ લિંકિંગ & રીડાયરેક્શન
│   │   ├── maintenance_service.dart # ૦% ફી 1-Tap UPI પેમેન્ટ્સ & ડિજિટલ રસીદો
│   │   ├── maintenance_receipt_pdf_service.dart # ઓથેન્ટિક રબર સ્ટેમ્પ્સ સાથે PDF રસીદ
│   │   ├── session_guard_service.dart # સિંગલ-ડિવાઇસ સેશન ગાર્ડ
│   │   └── society_service.dart     # Multi-tenancy, ટોપિક નામકરણ અને ડોક ફિલ્ટરિંગ
│   ├── theme/
│   │   └── premium_theme.dart       # મટીરિયલ ૩ પ્રીમિયમ સોસાયટી કલર થીમ
│   └── widgets/
│       ├── premium_ui.dart          # પુનઃઉપયોગી UI કોમ્પોનન્ટ્સ (હેડર્સ, સ્ટેટ કાર્ડ્સ)
│       ├── admin_broadcast_dialogs.dart # સૂચના પુશ & નોટિસ બોર્ડ બ્રોડકાસ્ટ
│       ├── admin_emergency_contacts_dialog.dart # સોસાયટી ઇમરજન્સી હેલ્પલાઇન ડાયલોગ
│       ├── admin_user_manage_dialogs.dart # યુઝર રજીસ્ટ્રેશન & વોચમેન મેનેજમેન્ટ
│       ├── member_maintenance_sheet.dart  # 1-Tap UPI ઇન્ટેન્ટ, ડાયનેમિક QR, રસીદો
│       ├── member_notifications_sheet.dart # ઇન-એપ નોટિફિકેશન સેન્ટર બોટમ શીટ
│       └── watchman_vehicle_lookup_sheet.dart # નંબર પ્લેટ સર્ચ & રોંગ પાર્કિંગ એલર્ટ
├── firestore.rules                  # એન્ટરપ્રાઇઝ Multi-tenant RBAC સિક્યોરિટી રૂલ્સ
├── firestore.indexes.json           # Firestore કમ્પાઉન્ડ ઇન્ડેક્સ
├── firebase.json                    # Firebase હોસ્ટિંગ, ફંક્શન્સ અને રૂલ્સ સેટિંગ્સ
└── pubspec.yaml                     # Flutter પેકેજીસ અને એસેટ્સ
```

---

## 🗄️ ડેટાબેઝ મોડેલ (Firestore Collections Schema)

| Collection | Description | Main Fields |
| :--- | :--- | :--- |
| `users` | તમામ વપરાશકર્તાઓ | `uid`, `name`, `email`, `role` (`admin`/`member`/`watchman`), `societyId`, `blockName`, `unitNumber`, `fcmToken`, `isActive`, `phone`, `currentSessionId` |
| `society_settings` | સોસાયટી કન્ફિગરેશન | `societyId`, `societyName`, `architectureType` (`Wing`/`Street`), `isSetupComplete`, `societyUpiId`, `societyBankDetails` |
| `blocks` | વિંગ અથવા શેરી વિગતો | `name`, `type` (`Wing`/`Street`), `v1` (floors), `v2` (units/floor), `societyId` |
| `units` | સોસાયટીના ફ્લેટ્સ / મકાનો | `unitNumber`, `blockName`, `societyId`, `memberId`, `memberIds`, `isOccupied` |
| `visitors` | મુલાકાતીઓનો લાઈવ લોગ | `name`, `phone`, `purpose`, `photoUrl`, `memberId`, `watchmanId`, `unitNumber`, `societyId`, `status` (`pending`/`approved`/`rejected`/`checked_out`), `entryTime`, `exitTime` |
| `pre_approvals` | અગાઉથી મંજૂર કરેલ મહેમાનો | `name`, `phone`, `date`, `memberId`, `societyId`, `unitNumber`, `status`, `qrCode` |
| `notices` | નોટિસ બોર્ડ જાહેરાતો | `title`, `description`, `societyId`, `createdAt`, `authorName` |
| `complaints` | રહીશોની ફરિયાદો | `title`, `description`, `photoUrl`, `memberName`, `memberId`, `societyId`, `status` (`pending`/`resolved`), `createdAt` |
| `daily_staff` | કાયમી કામદારો | `name`, `phone`, `role` (maid/driver/cook), `unitNumber`, `societyId` |
| `maintenance_bills` | મેન્ટેનન્સ બિલિંગ & UPI ટ્રાન્ઝેક્શન્સ | `billTitle`, `societyId`, `blockName`, `unitNumber`, `memberId`, `memberName`, `dueDate`, `amount`, `penaltyAmount`, `status` (`unpaid`/`underReview`/`paid`/`overdue`), `paymentMode` (`upi`/`cash`/`cheque`), `utrNumber`, `receiptNumber`, `verifiedBy`, `paidAt` |
| `notifications` | પુશ નોટિફિકેશન કતાર | `title`, `body`, `targetUID` (`ALL`/`ADMINS`/`WATCHMEN`/UserUID), `societyId`, `type`, `billId`, `receiptNumber`, `fcmDeliveryStatus` |

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
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10.x કે તેથી વધુ)
- [Node.js](https://nodejs.org/) (v18 અથવા v20)
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- Android Studio / Xcode

### પગલાં (Setup Steps)

1. **પ્રોજેક્ટ ક્લોન કરો**:
   ```bash
   git clone https://github.com/your-username/my_building_guard.git
   cd my_building_guard
   ```

2. **Flutter ડિપેન્ડન્સી ઇન્સ્ટોલ કરો**:
   ```bash
   flutter pub get
   ```

3. **Firebase કન્ફિગરેશન**:
   - Firebase Console માં પ્રોજેક્ટ સેટઅપ કરો.
   - Firebase CLI વડે લૉગિન કરી FlutterFire કન્ફિગર કરો:
     ```bash
     firebase login
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
   firebase deploy --only firestore:rules,firestore:indexes
   ```

---

## 🧪 ઓટોમેટેડ ટેસ્ટિંગ (Automated Tests)
એપ્લિકેશનના પેમેન્ટ, સિક્યુરિટી અને સ્ટેટસ મોડેલ્સના યુનિટ ટેસ્ટ્સ રન કરવા:
```bash
flutter test
```

---

## 📱 બિલ્ડ અને પ્રોડક્શન (Build & Release)

### ડીબગ મોડમાં રન કરવા:
```bash
flutter run
```

### Android APK બિલ્ડ કરવા:
```bash
flutter build apk --release
```

### Android App Bundle (Play Store) બિલ્ડ કરવા:
```bash
flutter build appbundle --release
```

---

## 👨‍💻 યોગદાન અને સપોર્ટ (Contributing & Support)
જો તમને કોઈ પ્રશ્ન હોય અથવા સુધારો સૂચવવો હોય, તો કૃપા કરીને Issue અથવા Pull Request સબમિટ કરો.

**Made with ❤️ for safer, smarter society communities.**
