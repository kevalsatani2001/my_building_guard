# 🏢 My Building Guard (સોસાયટી મેનેજમેન્ટ & સિક્યુરિટી એપ)

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20FCM%20%7C%20Functions%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue)](https://flutter.dev)
[![Language](https://img.shields.io/badge/UI_Language-Gujarati_%26_English-success)](#)

**My Building Guard (Society Manager)** એ રહેણાંક સોસાયટીઓ, એપાર્ટમેન્ટ્સ અને રો-હાઉસ ટાઉનશિપ માટે તૈયાર કરવામાં આવેલી એક અત્યાધુનિક, મલ્ટી-ટેનન્ટ સોસાયટી મેનેજમેન્ટ અને વિઝિટર સિક્યુરિટી ગેટ પાસ એપ્લિકેશન છે. 

આ એપ એડમિન (કમિટી), સિક્યુરિટી ગાર્ડ (વોચમેન) અને સોસાયટીના રહીશો (મેમ્બર્સ) વચ્ચે સીધો સંકલન સાધે છે અને રીઅલ-ટાઇમ નોટિફિકેશન્સ, QR કોડ ગેટ પાસ, વિઝિટર ફોટો કેપ્ચર અને ઇમરજન્સી SOS સિસ્ટમ પૂરી પાડે છે.

---

## 📑 અનુક્રમણિકા (Table of Contents)
- [✨ મુખ્ય વિશેષતાઓ (Key Features)](#-મુખ્ય-વિશેષતાઓ-key-features)
  - [૧. 👑 એડમિન પોર્ટલ (Admin Portal)](#૧--એડમિન-પોર્ટલ-admin-portal)
  - [૨. 🛡️ વોચમેન / ગેટ પાસ મોડ્યુલ (Watchman Module)](#૨-️-વોચમેન--ગેટ-પાસ-મોડ્યુલ-watchman-module)
  - [૩. 🏠 સભ્ય / રહીશ મોડ્યુલ (Resident / Member Module)](#૩--સભ્ય--રહીશ-મોડ્યુલ-resident--member-module)
- [🏢 મલ્ટી-ટેનન્ટ સિસ્ટમ (Multi-Tenant Society Support)](#-મલ્ટી-ટેનન્ટ-સિસ્ટમ-multi-tenant-society-support)
- [🛠️ ટેકનોલોજી સ્ટેક (Tech Stack)](#️-ટેકનોલોજી-સ્ટેક-tech-stack)
- [📂 પ્રોજેક્ટ માળખું (Project Structure)](#-પ્રોજેક્ટ-માળખું-project-structure)
- [🗄️ ડેટાબેઝ મોડેલ (Firestore Collections Schema)](#️-ડેટાબેઝ-મોડેલ-firestore-collections-schema)
- [⚡ ક્લાઉડ ફંક્શન્સ (Firebase Cloud Functions v2)](#-ક્લાઉડ-ફંક્શન્સ-firebase-cloud-functions-v2)
- [🚀 સેટઅપ અને ઇન્સ્ટોલેશન (Getting Started)](#-સેટઅપ-અને-ઇન્સ્ટોલેશન-getting-started)
  - [પૂર્વજરૂરિયાતો (Prerequisites)](#પૂર્વજરૂરિયાતો-prerequisites)
  - [પગલાં (Setup Steps)](#પગલાં-setup-steps)
- [🔔 પુશ નોટિફિકેશન કન્ફિગરેશન (Push Notifications)](#-પુશ-નોટિફિકેશન-કન્ફિગરેશન-push-notifications)
- [📱 બિલ્ડ અને રન (Build & Run)](#-બિલ્ડ-અને-રન-build--run)

---

## ✨ મુખ્ય વિશેષતાઓ (Key Features)

### ૧. 👑 એડમિન પોર્ટલ (Admin Portal)
- **સ્માર્ટ સેટઅપ વિઝાર્ડ (Setup Wizard)**:
  - **વિંગ સિસ્ટમ (Wing Architecture)**: બહુમાળી ઇમારતો માટે (A, B, C... વિંગ, માળની સંખ્યા અને ફ્લેટ નંબરિંગ).
  - **શેરી સિસ્ટમ (Street / Row-House)**: રો-હાઉસ અને સોસાયટી માટે શેરી નંબર અને પ્લોટ નંબરિંગ.
  - સેટઅપ બાદ આર્કિટેક્ચર સુરક્ષિત રીતે લૉક થાય છે જેથી ડેટા મિક્સ ન થાય.
- **આર્કિટેક્ચર પ્રિવ્યુ (Architecture Visualizer)**: દરેક વિંગ/શેરી અને ફ્લેટની લાઈવ ગ્રીડ ડિઝાઇન અને માહિતી.
- **યુઝર અને રોલ મેનેજમેન્ટ**:
  - મેમ્બર, વોચમેન અને એડમિનનું રજીસ્ટ્રેશન અને એકાઉન્ટ એક્ટિવેટ/ડી-એક્ટિવેટ.
  - બ્લૉક કરેલા યુઝર્સ માટે ઇન્સ્ટન્ટ ઑટો-લૉગઆઉટ.
- **વોચમેન મેનેજમેન્ટ**: સિક્યુરિટી ગાર્ડ્સનું લિસ્ટ, ગેટ અસાઇનમેન્ટ અને એક્ટિવ સ્ટેટસ કંટ્રોલ.
- **બ્રોડકાસ્ટ પુશ નોટિફિકેશન**: આખી સોસાયટીના તમામ સભ્યોને એક ક્લિકમાં તાત્કાલિક નોટિફિકેશન (FCM Topics + Device Fanout).
- **ડિજિટલ નોટિસ બોર્ડ (Notice Board)**: સોસાયટી માટે મહત્વની જાહેરાતો અને મીટિંગ પરિપત્રો પ્રસિદ્ધ કરવા.
- **ફરિયાદ નિવારણ ડેસ્ક (Complaint Resolution)**: સભ્યો દ્વારા મૂકેલી ફરિયાદો (ફોટો પુરાવા સાથે) જોવી અને 'ઉકેલાઈ' (Resolved) માર્ક કરવી.
- **વિઝિટર એનાલિટિક્સ અને રિપોર્ટ્સ (Analytics & Insights)**:
  - મહિનો અને વિંગ/શેરી મુજબ ફિલ્ટર.
  - કુલ એન્ટ્રી, એપ્રુવ્ડ, રિજેક્ટેડ અને ચેક-આઉટ આંકડાકીય ચાર્ટ.
  - પીક વિઝિટર કલાકોનું વિશ્લેષણ.
- **મેન્ટેનન્સ બિલિંગ & હિસાબ (Maintenance & Accounts)**:
  - **૧-ક્લિક બલ્ક બિલ જનરેશન**: સોસાયટીના તમામ ફ્લેટ્સ માટે એક સાથે માસિક બિલ બનાવવું.
  - **લાઈવ કલેક્શન ડેશબોર્ડ**: કુલ જમા, કુલ બાકી અને પેન્ડિંગ UPI વેરિફિકેશન સમરી.
  - **રોકડ / ચેક એન્ટ્રી**: ઑફલાઇન પેમેન્ટ્સ સ્વીકારી તાત્કાલિક ડિજિટલ રસીદ ઈશ્યુ કરવી.
  - **૧-ક્લિક ડ્યુ રીમાઇન્ડર**: જેમના પૈસા બાકી છે તેવા તમામ સભ્યોને એક જ ક્લિકથી પુશ એલર્ટ.
  - **સોસાયટી UPI સેટિંગ્સ**: સોસાયટીનો UPI ID (VPA) અને ડિફૉલ્ટ રકમ સેટઅપ.
- **ઇમરજન્સી કોન્ટેક્ટ ડિરેક્ટરી**: પોલીસ, એમ્બ્યુલન્સ, ફાયર બ્રિગેડ, ઇલેક્ટ્રિશિયન અને પ્લમ્બરના સંપર્કો.

### ૨. 🛡️ વોચમેન / ગેટ પાસ મોડ્યુલ (Watchman Module)
- **૧-ટેપ ક્વિક ડિલિવરી એન્ટ્રી (Quick Tags)**:
  - Swiggy, Zomato, Amazon, Flipkart, Blinkit, Zepto વગેરે પાર્ટનર્સ માટે વન-ટેપ ઓટોફિલ.
- **વાહન સર્ચ & પાર્કિંગ મેનેજમેન્ટ (Vehicle Lookup)**:
  - ગાડી નંબર પરથી ફ્લેટ અને માલિકની લાઈવ શોધ.
  - એપમાંથી ડાયરેક્ટ ફોન કૉલિંગ (`url_launcher`).
  - રસ્તો રોકતા વાહનો માટે ૧-ક્લિક **ખોટું પાર્કિંગ પુશ એલર્ટ (Wrong Parking Alert)**.
- **ઝડપી વિઝિટર એન્ટ્રી (New Visitor Entry)**:
  - મોબાઇલ કેમેરા વડે મુલાકાતીનો લાઈવ ફોટો કેપ્ચર અને Firebase Storage અપલોડ.
  - નામ, ફોન નંબર, મુલાકાતનું કારણ (Purpose).
  - વિંગ અને ફ્લેટ નંબર પસંદગી.
  - સબમિટ કરતાં જ રહીશના મોબાઇલ પર ઇન્સ્ટન્ટ રિંગ/નોટિફિકેશન.
- **પ્રી-એપ્રુવ્ડ ગેટ પાસ & QR કોડ સ્કેનિંગ**:
  - મુલાકાતીના અગાઉથી મળેલા QR પાસનું `mobile_scanner` દ્વારા ઇન્સ્ટન્ટ સ્કેનિંગ.
  - લાઈવ પ્રી-એપ્રુવલ સર્ચ (નામ કે ફોનથી).
- **લાઈવ મુલાકાતી ઇતિહાસ (Today's History)**:
  - પેન્ડિંગ, મંજૂર (Approved), અસ્વીકાર (Rejected) અને ચેક-આઉટ સ્ટેટસ.
  - જ્યારે સભ્ય તરફથી મંજૂરી કે નકાર આવે ત્યારે ઓડિયો સાઉન્ડ ચાઇમ (`audioplayers`).
  - બહાર જતી વખતે સરળ "ચેક-આઉટ" (Exit Logging) બટન.

### ૩. 🏠 સભ્ય / રહીશ મોડ્યુલ (Resident / Member Module)
- **મેન્ટેનન્સ બિલિંગ & ૦% ફી ઓનલાઇન પેમેન્ટ (Maintenance & UPI Pay)**:
  - ડેશબોર્ડ પર બાકી બિલનું લાઈવ એલર્ટ કાર્ડ.
  - **૧-ટેપ UPI પેમેન્ટ**: Google Pay, PhonePe, Paytm કે BHIM સીધું ખોલવું.
  - **ડાયનેમિક UPI QR કોડ**: બીજા ફોનથી સ્કેન કરી પેમેન્ટ કરવાની સુવિધા (`qr_flutter`).
  - **UTR સબમિશન**: ૧૨ આંકડાનો UTR નંબર દાખલ કરી સ્ટેટસ "ચકાસણી હેઠળ" મૂકવું.
  - **ડિજિટલ રસીદ & શેરિંગ**: પેઇડ બિલ્સની સત્તાવાર રસીદ અને WhatsApp પર શેરિંગ (`share_plus`).
- **મારા વાહનો (My Vehicles)**:
  - ૨-વ્હીલર અને ૪-વ્હીલર નંબર, મોડેલ અને ફાળવેલ પાર્કિંગ સ્લોટ મેનેજમેન્ટ.
- **લાઈવ ગેટ એલર્ટ્સ (Visitor Approval/Denial)**:
  - ગેટ પર આવેલા મહેમાનનો ફોટો, નામ અને વિગતો સાથે તુરંત સ્ક્રીન પર પોપ-અપ.
  - એક ક્લિકમાં **મંજૂરી (Approve)** અથવા **નકાર (Reject)**.
- **અગાઉથી મંજૂરી (Pre-Approve Visitor Pass)**:
  - આવનારા મહેમાન, ડિલિવરી કે સંબંધી માટે અગાઉથી ગેટ પાસ જનરેટ કરવો.
  - **QR Code કાર્ડ**: વોટ્સએપ કે મેસેજ દ્વારા મહેમાનને મોકલવા માટે ડાઉનલોડ & શેરિંગ (`share_plus`, `qr_flutter`).
- **ડિજિટલ ફરિયાદ પોર્ટલ (Complaints Desk)**:
  - ફોટો સાથે લિકેજ, સિક્યુરિટી કે લિફ્ટ સંબંધિત ફરિયાદ નોંધાવવી.
- **કાયમી સ્ટાફ મેનેજમેન્ટ (Daily Staff)**:
  - ઘરકામ કરનાર (Maid), ડ્રાઈવર, કૂક, ધોબી વગેરેની એન્ટ્રી અને સમયપત્રક.
- **વિઝિટર હિસ્ટ્રી અને ગ્રાફ**: છેલ્લા ૭ દિવસ, ૩૦ દિવસ કે તમામ સમયના મુલાકાતીઓનો ગ્રાફિકલ રેકોર્ડ.
- **🚨 વન-ટચ ઇમરજન્સી SOS એલર્ટ**:
  - ઘરમાં કોઈ તકલીફ કે આકસ્મિક સંજોગોમાં એક જ બટન દબાવવાથી તમામ એડમિન અને ગેટ વોચમેનને તાત્કાલિક સાયરન એલર્ટ.


---

## 🏢 મલ્ટી-ટેનન્ટ સિસ્ટમ (Multi-Tenant Society Support)

એક જ Firebase પ્રોજેક્ટ અને એક જ ડેટાબેઝ પરથી અસંખ્ય સોસાયટીઓ ચલાવવા માટેનું મજબૂત માળખું:
- **`societyId` પાર્ટીશનીંગ**: દરેક કલેક્શનના ડોક્યુમેન્ટ પર વિશિષ્ટ `societyId` સેવ થાય છે (દા.ત. `shiv-residency`, `gokul-dham`, અથવા `default`).
- **આઇસોલેટેડ પુશ ટોપિક્સ**:
  - `soc_{societyId}_members`
  - `soc_{societyId}_admins`
  - `soc_{societyId}_watchmen`
- **ID કોલિઝન પ્રોટેક્શન**: બ્લોક અને યુનિટ ID માં સોસાયટી પ્રિફિક્સ આપમેળે ઉમેરાય છે.
- **લેગસી માઇગ્રેશન સપોર્ટ**: જૂના ડેટાને સરળતાથી સુસંગત રાખવા `scripts/migrate_default_society.js` સ્ક્રિપ્ટ ઉપલબ્ધ છે.

---

## 🛠️ ટેકનોલોજી સ્ટેક (Tech Stack)

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Frontend Mobile** | [Flutter](https://flutter.dev) (Dart SDK ^3.10.7) | ક્રોસ-પ્લેટફોર્મ નેટિવ UI |
| **Authentication** | Firebase Authentication | ઇમેઇલ/પાસવર્ડ અને સિક્યોર સેશન |
| **Database** | Cloud Firestore (Enterprise/Native) | રીઅલ-ટાઇમ નો-SQL ડેટાબેઝ |
| **Serverless Backend** | Firebase Cloud Functions v2 (Node.js) | પુશ નોટિફિકેશન, સ્ટેટસ લિસનર્સ, httpsCallable |
| **Cloud Storage** | Firebase Cloud Storage | વિઝિટર અને ફરિયાદ ફોટો સંગ્રહ |
| **Push Notifications** | Firebase Cloud Messaging (FCM v1) & Local Notifications | બેકગ્રાઉન્ડ & ફોરગ્રાઉન્ડ હાઈ-પ્રાયોરિટી પુશ |
| **QR Code Scanner** | `mobile_scanner` | કેમેરા વડે લાઈવ QR કોડ સ્કેનિંગ |
| **QR Code Generator** | `qr_flutter` | ડિજિટલ વિઝિટર પાસ જનરેશન |
| **Audio Alert** | `audioplayers` | વોચમેન માટે ઇન્સ્ટન્ટ રિસ્પોન્સ ચાઇમ સાઉન્ડ |
| **Image Picker** | `image_picker` | કેમેરાથી વિઝિટરનો ફોટો લેવા માટે |

---

## 📂 પ્રોજેક્ટ માળખું (Project Structure)

```text
my_building_guard/
├── android/                         # Android નેટિવ કોડ અને મેનિફેસ્ટ સેટિંગ્સ
├── ios/                             # iOS નેટિવ કોન્ફિગરેશન
├── functions/                       # Firebase Cloud Functions (Node.js)
│   ├── index.js                     # v2 Triggers & Callable APIs (FCM push, alerts)
│   ├── package.json                 # Node dependencies
│   └── .eslintrc.js
├── scripts/
│   └── migrate_default_society.js   # જૂના ડેટાને Multi-tenant માં કન્વર્ટ કરવાની સ્ક્રિપ્ટ
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
│   │   ├── admin_dashboard.dart     # એડમિન ડેશબોર્ડ & એનાલિટિક્સ (મોડ્યુલરાઈઝ્ડ)
│   │   ├── admin_setup_wizard_screen.dart # સોસાયટી આર્કિટેક્ચર સેટઅપ વિઝાર્ડ
│   │   ├── admin_maintenance_screen.dart  # બલ્ક મેન્ટેનન્સ જનરેટર, UPI વેરિફિકેશન
│   │   ├── admin_complaints_screen.dart   # ફરિયાદ નિવારણ ડેસ્ક
│   │   ├── architecture_preview.dart      # સોસાયટી ફ્લોર/શેરી પ્રિવ્યુ
│   │   ├── watchmen_screen.dart     # ગાર્ડ પોર્ટલ: ડિલિવરી ટેગ્સ, QR સ્કેનર, હિસ્ટ્રી
│   │   └── member_screen.dart       # સભ્ય પોર્ટલ: વ્હીકલ મેનેજમેન્ટ, SOS, સ્ટાફ
│   ├── services/
│   │   ├── firebase_app_guard.dart  # Firebase App Instance Helper
│   │   ├── notification_service.dart # FCM Token મેનેજમેન્ટ, ટોપિક્સ અને રિટ્રાય
│   │   ├── maintenance_service.dart # 0% Fee 1-Tap UPI પેમેન્ટ્સ & ડિજિટલ રસીદો
│   │   └── society_service.dart     # Multi-tenancy, ટોપિક નામકરણ અને ડોક ફિલ્ટરિંગ
│   ├── theme/
│   │   └── premium_theme.dart       # મટીરિયલ ૩ કસ્ટમ સોસાયટી કલર થીમ
│   └── widgets/
│       ├── premium_ui.dart          # પુનઃઉપયોગી UI કોમ્પોનન્ટ્સ (હેડર્સ, એમ્પ્ટી સ્ટેટ્સ)
│       ├── admin_broadcast_dialogs.dart # સૂચના પુશ & નોટિસ બોર્ડ બ્રોડકાસ્ટ
│       ├── admin_emergency_contacts_dialog.dart # સોસાયટી ઇમરજન્સી હેલ્પલાઇન ડાયલોગ
│       ├── admin_user_manage_dialogs.dart # યુઝર રજીસ્ટ્રેશન & વોચમેન મેનેજમેન્ટ
│       ├── member_maintenance_sheet.dart  # 1-Tap UPI ઇન્ટેન્ટ, ડાયનેમિક QR, રસીદો
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
| `users` | તમામ વપરાશકર્તાઓ | `uid`, `name`, `email`, `role` (`admin`/`member`/`watchman`), `societyId`, `blockName`, `unitNumber`, `fcmToken`, `isActive`, `phone` |
| `society_settings` | સોસાયટી કન્ફિગરેશન | `societyId`, `societyName`, `architectureType` (`Wing`/`Street`), `isSetupComplete` |
| `blocks` | વિંગ અથવા શેરી વિગતો | `name`, `type` (`Wing`/`Street`), `v1` (floors), `v2` (units/floor), `societyId` |
| `units` | સોસાયટીના ફ્લેટ્સ / મકાનો | `unitNumber`, `blockName`, `societyId`, `ownerUid` |
| `visitors` | મુલાકાતીઓનો લાઈવ લોગ | `name`, `phone`, `purpose`, `photoUrl`, `memberId`, `watchmanId`, `unitNumber`, `societyId`, `status` (`pending`/`approved`/`rejected`/`checked_out`), `entryTime`, `exitTime` |
| `pre_approvals` | અગાઉથી મંજૂર કરેલ મહેમાનો | `name`, `phone`, `date`, `memberId`, `societyId`, `unitNumber`, `status` |
| `notices` | નોટિસ બોર્ડ જાહેરાતો | `title`, `description`, `societyId`, `createdAt`, `authorName` |
| `complaints` | રહીશોની ફરિયાદો | `title`, `description`, `photoUrl`, `memberName`, `memberId`, `societyId`, `status` (`pending`/`resolved`), `createdAt` |
| `daily_staff` | કાયમી કામદારો | `name`, `phone`, `role` (maid/driver/cook), `unitNumber`, `societyId` |
| `maintenance_bills` | મેન્ટેનન્સ બિલિંગ & UPI ટ્રાન્ઝેક્શન્સ | `billTitle`, `societyId`, `blockName`, `unitNumber`, `memberId`, `memberName`, `dueDate`, `amount`, `penaltyAmount`, `status` (`unpaid`/`underReview`/`paid`/`overdue`), `paymentMode` (`upi`/`cash`/`cheque`), `utrNumber`, `receiptNumber`, `paidAt` |
| `notifications` | પુશ નોટિફિકેશન કતાર | `title`, `body`, `targetUID` (`ALL`/`ADMINS`/`WATCHMEN`/UserUID), `societyId`, `type`, `fcmDeliveryStatus` |

---

## ⚡ ક્લાઉડ ફંક્શન્સ (Firebase Cloud Functions v2)

`functions/index.js` માં નીચે મુજબના સર્વરલેસ ફંક્શન્સ સામેલ છે:

1. **`sendMemberPush` (Callable)**:
   - જ્યારે વોચમેન વિઝિટર એન્ટ્રી કરે ત્યારે ડાયરેક્ટ મેમ્બરના ફોન પર હાઈ-પ્રાયોરિટી FCM પુશ મોકલે છે.
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

3. **Firebase સાથે કનેક્ટ કરો**:
   - Firebase Console માં નવો પ્રોજેક્ટ બનાવો.
   - Firebase CLI વડે લૉગિન કરો:
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

6. **જૂના ડેટા માટે માઇગ્રેશન (જો લાગુ પડતું હોય)**:
   ```bash
   node scripts/migrate_default_society.js
   ```

---

## 🧪 ઓટોમેટેડ ટેસ્ટિંગ (Automated Tests)
એપ્લિકેશનના પેમેન્ટ, સિક્યુરિટી અને સ્ટેટસ મોડેલ્સના યુનિટ ટેસ્ટ્સ રન કરવા:
```bash
flutter test
```

---

## 🔔 પુશ નોટિફિકેશન કન્ફિગરેશન (Push Notifications)

- **Android ચેનલ**: `high_importance_channel`
- **લો-રેમ / MIUI ડિવાઇસ સેફ્ટી**: એપ્લિકેશનના `NotificationService` માં ટોકન રજિસ્ટ્રેશન અને ટોપિક સબસ્ક્રિપ્શનને ڈی-બાઉન્સ અને એક્સપોનેન્શિયલ બેક-ઓફ સાથે સેટ કરેલ છે, જેથી એપ શરૂ થતી વખતે ક્રેશ ન થાય.
- **બેકગ્રાઉન્ડ મેસેજિંગ**: `lib/firebase_messaging_background.dart` પર ટોપ-લેવલ સ્ટેટિક હેન્ડલર જોડાયેલ છે.

---

## 📱 બિલ્ડ અને રન (Build & Run)

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

## 🔒 સિક્યુરિટી અને પ્રાઇવસી (Security & Privacy)
- **Firestore RBAC Security Rules (`firestore.rules`)**:
  - રોલ-બેઝ્ડ એક્સેસ કંટ્રોલ (Admin, Watchman, Member) સર્વર-લેવલ પર લાગુ.
  - કોઈ પણ યુઝર પોતાની સોસાયટી સિવાય અન્ય સોસાયટીના ડેટાને વાંચી કે લખી શકતો નથી.
- **સુરક્ષિત રજીસ્ટ્રેશન આર્કિટેક્ચર**:
  - વોચમેનનું પબ્લિક સેલ્ફ-રજીસ્ટ્રેશન બંધ કરવામાં આવેલ છે; માત્ર અધિકૃત ચેરમેન જ વોચમેન એકાઉન્ટ બનાવી શકે છે.
  - સભ્યો માટે સોસાયટી કોડ અને બ્લોક/ફ્લેટ વેલિડેશન ફરજિયાત છે.
- **૦% ટ્રાન્ઝેક્શન ફી & પ્રાઇવેટ UPI**:
  - પેમેન્ટ સીધું સોસાયટીના સત્તાવાર બેંક એકાઉન્ટમાં જાય છે. કોઈ થર્ડ-પાર્ટી વોલેટ કે ગેટવેમાં ડેટા કે કમિશન કપાતું નથી.
- **એકાઉન્ટ બ્લોકિંગ & ઓટો-લૉગઆઉટ**:
  - સિક્યુરિટી ગાર્ડ કે સભ્ય ડી-એક્ટિવેટ થતાં જ તેનો સેશન તાત્કાલિક ટર્મિનેટ થઈ જાય છે.

---

## 👨‍💻 યોગદાન અને સપોર્ટ (Contributing & Support)
જો તમને કોઈ પ્રશ્ન હોય અથવા એપમાં નવું ફીચર ઉમેરવું હોય, તો કૃપા કરીને Issue અથવા Pull Request સબમિટ કરો.

**Made with ❤️ for safer, smarter society communities.**
