import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// સમગ્ર Building Guard એપ્લિકેશન માટે Cloud Firestore ઇન્સ્ટન્સ.
/// આ પ્રોજેક્ટ Firebase ના ડેડિકેટેડ 'building-guard' ડેટાબેઝ સાથે કનેક્ટ કરે છે.
class AppFirestore {
  AppFirestore._();

  static const String databaseId = 'building-guard';

  static FirebaseFirestore get instance {
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: databaseId,
    );
  }
}
