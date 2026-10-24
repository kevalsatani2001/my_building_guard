import '../services/localization_service.dart';

/// Universal Premise Architecture Types and Dynamic Vocabulary Engine
/// Supports Residential Apartments (Wing), Row-Houses (Street),
/// Commercial Shopping Centers / Markets (Commercial), and Mixed-Use Complexes.
enum PremiseType {
  wing,        // Apartment / Multi-Tower (Flats)
  street,      // Row-House / Tenement / Bungalows (Streets)
  commercial,  // Shopping Mall / Business Hub / Market (Shops, Offices, Godowns)
  mixed,       // Ground floor Shops + Upper floor Residential Flats
}

class PremiseVocabulary {
  final PremiseType type;

  const PremiseVocabulary(this.type);

  factory PremiseVocabulary.fromString(String? raw) {
    final s = (raw ?? '').toLowerCase().trim();
    if (s == 'street') return const PremiseVocabulary(PremiseType.street);
    if (s == 'commercial' || s == 'shopping' || s == 'mall' || s == 'market') {
      return const PremiseVocabulary(PremiseType.commercial);
    }
    if (s == 'mixed') return const PremiseVocabulary(PremiseType.mixed);
    return const PremiseVocabulary(PremiseType.wing);
  }

  String get _lang => LocalizationService.instance.currentCode;

  String get typeKey {
    switch (type) {
      case PremiseType.street:
        return 'Street';
      case PremiseType.commercial:
        return 'Commercial';
      case PremiseType.mixed:
        return 'Mixed';
      case PremiseType.wing:
        return 'Wing';
    }
  }

  /// Title for Sub-group / Block (e.g. "વિંગ / બ્લોક", "શેરી / લાઇન", "ફ્લોર / બ્લોક", "બ્લોક / શેરી")
  String get blockLabel {
    if (_lang == 'hi') {
      switch (type) {
        case PremiseType.street:
          return 'गली / लाइन';
        case PremiseType.commercial:
          return 'फ्लोर / ब्लॉक';
        case PremiseType.mixed:
          return 'विंग / ज़ोन';
        case PremiseType.wing:
          return 'विंग / ब्लॉक';
      }
    } else if (_lang == 'en') {
      switch (type) {
        case PremiseType.street:
          return 'Street / Lane';
        case PremiseType.commercial:
          return 'Floor / Block';
        case PremiseType.mixed:
          return 'Wing / Zone';
        case PremiseType.wing:
          return 'Wing / Block';
      }
    }
    switch (type) {
      case PremiseType.street:
        return 'શેરી / લાઇન';
      case PremiseType.commercial:
        return 'ફ્લોર / બ્લોક';
      case PremiseType.mixed:
        return 'વિંગ / ઝોન';
      case PremiseType.wing:
        return 'વિંગ / બ્લોક';
    }
  }

  /// Single short block noun (e.g. "વિંગ", "શેરી", "ફ્લોર", "બ્લોક")
  String get blockShortLabel {
    if (_lang == 'hi') {
      switch (type) {
        case PremiseType.street:
          return 'गली';
        case PremiseType.commercial:
          return 'फ्लोर';
        case PremiseType.mixed:
          return 'ब्लॉक';
        case PremiseType.wing:
          return 'विंग';
      }
    } else if (_lang == 'en') {
      switch (type) {
        case PremiseType.street:
          return 'Street';
        case PremiseType.commercial:
          return 'Floor';
        case PremiseType.mixed:
          return 'Block';
        case PremiseType.wing:
          return 'Wing';
      }
    }
    switch (type) {
      case PremiseType.street:
        return 'શેરી';
      case PremiseType.commercial:
        return 'ફ્લોર';
      case PremiseType.mixed:
        return 'બ્લોક';
      case PremiseType.wing:
        return 'વિંગ';
    }
  }

  /// Title for Unit (e.g. "ફ્લેટ નં.", "મકાન / પ્લોટ નં.", "દુકાન / ઓફિસ નં.", "યુનિટ નં.")
  String get unitLabel {
    if (_lang == 'hi') {
      switch (type) {
        case PremiseType.street:
          return 'मकान / प्लॉट नं.';
        case PremiseType.commercial:
          return 'दुकान / ऑफिस नं.';
        case PremiseType.mixed:
          return 'यूनिट नं. (दुकान/फ्लैट)';
        case PremiseType.wing:
          return 'फ्लैट नं.';
      }
    } else if (_lang == 'en') {
      switch (type) {
        case PremiseType.street:
          return 'House / Plot No.';
        case PremiseType.commercial:
          return 'Shop / Office No.';
        case PremiseType.mixed:
          return 'Unit No. (Shop/Flat)';
        case PremiseType.wing:
          return 'Flat No.';
      }
    }
    switch (type) {
      case PremiseType.street:
        return 'મકાન / પ્લોટ નં.';
      case PremiseType.commercial:
        return 'દુકાન / ઓફિસ નં.';
      case PremiseType.mixed:
        return 'યુનિટ નં. (શોપ/ફ્લેટ)';
      case PremiseType.wing:
        return 'ફ્લેટ નં.';
    }
  }

  String get unitShortLabel {
    if (_lang == 'hi') {
      switch (type) {
        case PremiseType.street:
          return 'मकान';
        case PremiseType.commercial:
          return 'दुकान/ऑफिस';
        case PremiseType.mixed:
          return 'यूनिट';
        case PremiseType.wing:
          return 'फ्लैट';
      }
    } else if (_lang == 'en') {
      switch (type) {
        case PremiseType.street:
          return 'House';
        case PremiseType.commercial:
          return 'Shop/Office';
        case PremiseType.mixed:
          return 'Unit';
        case PremiseType.wing:
          return 'Flat';
      }
    }
    switch (type) {
      case PremiseType.street:
        return 'મકાન';
      case PremiseType.commercial:
        return 'દુકાન/ઓફિસ';
      case PremiseType.mixed:
        return 'યુનિટ';
      case PremiseType.wing:
        return 'ફ્લેટ';
    }
  }

  /// Member label (e.g. "રહીશ / સભ્ય", "રહીશ", "વેપારી / દુકાનદાર", "સભ્ય / વેપારી")
  String get memberLabel {
    if (_lang == 'hi') {
      switch (type) {
        case PremiseType.street:
          return 'निवासी / सदस्य';
        case PremiseType.commercial:
          return 'व्यापारी / दुकानदार';
        case PremiseType.mixed:
          return 'निवासी / दुकानदार';
        case PremiseType.wing:
          return 'निवासी / सदस्य';
      }
    } else if (_lang == 'en') {
      switch (type) {
        case PremiseType.street:
          return 'Resident / Member';
        case PremiseType.commercial:
          return 'Merchant / Shopkeeper';
        case PremiseType.mixed:
          return 'Resident / Shopkeeper';
        case PremiseType.wing:
          return 'Resident / Member';
      }
    }
    switch (type) {
      case PremiseType.street:
        return 'રહીશ / સભ્ય';
      case PremiseType.commercial:
        return 'વેપારી / દુકાનદાર';
      case PremiseType.mixed:
        return 'રહીશ / દુકાનદાર';
      case PremiseType.wing:
        return 'રહીશ / સભ્ય';
    }
  }

  /// Admin title (e.g. "સોસાયટી પ્રમુખ", "સોસાયટી પ્રમુખ", "વેપારી મંડળ પ્રમુખ", "મુખ્ય પ્રમુખ")
  String get adminLabel {
    if (_lang == 'hi') {
      switch (type) {
        case PremiseType.street:
          return 'सोसायटी अध्यक्ष';
        case PremiseType.commercial:
          return 'व्यापारी मंडल अध्यक्ष';
        case PremiseType.mixed:
          return 'मुख्य अध्यक्ष';
        case PremiseType.wing:
          return 'सोसायटी अध्यक्ष';
      }
    } else if (_lang == 'en') {
      switch (type) {
        case PremiseType.street:
          return 'Society President';
        case PremiseType.commercial:
          return 'Merchant Association Head';
        case PremiseType.mixed:
          return 'Chief President';
        case PremiseType.wing:
          return 'Society President';
      }
    }
    switch (type) {
      case PremiseType.street:
        return 'સોસાયટી પ્રમુખ';
      case PremiseType.commercial:
        return 'વેપારી મંડળ પ્રમુખ';
      case PremiseType.mixed:
        return 'મુખ્ય પ્રમુખ';
      case PremiseType.wing:
        return 'સોસાયટી પ્રમુખ';
    }
  }

  /// Project description badge (e.g. "🏢 વિંગ / એપાર્ટમેન્ટ", "🏡 શેરી / બંગલો", "🏬 શોપિંગ મોલ / માર્કેટ", "🏙️ મિક્સ્ડ (દુકાન + ફ્લેટ્સ)")
  String get premiseBadge {
    if (_lang == 'hi') {
      switch (type) {
        case PremiseType.street:
          return '🏡 गली / रो-हाउस';
        case PremiseType.commercial:
          return '🏬 शॉपिंग / कॉमर्शियल';
        case PremiseType.mixed:
          return '🏙️ मिक्स्ड (दुकान + फ्लैट)';
        case PremiseType.wing:
          return '🏢 विंग / अपार्टमेंट';
      }
    } else if (_lang == 'en') {
      switch (type) {
        case PremiseType.street:
          return '🏡 Street / Row-House';
        case PremiseType.commercial:
          return '🏬 Shopping / Commercial';
        case PremiseType.mixed:
          return '🏙️ Mixed (Shop + Flat)';
        case PremiseType.wing:
          return '🏢 Wing / Apartment';
      }
    }
    switch (type) {
      case PremiseType.street:
        return '🏡 શેરી / રો-હાઉસ';
      case PremiseType.commercial:
        return '🏬 શોપિંગ / કોમર્શિયલ';
      case PremiseType.mixed:
        return '🏙️ મિક્સ્ડ (દુકાન + ફ્લેટ)';
      case PremiseType.wing:
        return '🏢 વિંગ / એપાર્ટમેન્ટ';
    }
  }

  /// Format unit display string
  String formatUnitDisplay({
    required String block,
    required String unit,
    String? unitType,
  }) {
    final cleanBlock = block.replaceAll(RegExp(r'^(W|S|C|M)-'), '');
    if (type == PremiseType.commercial) {
      final prefix = (unitType == 'office')
          ? 'ઓફિસ'
          : ((unitType == 'godown') ? 'ગોડાઉન' : 'શોપ');
      return '$prefix $unit ($cleanBlock)';
    } else if (type == PremiseType.street) {
      return 'શેરી $cleanBlock - મકાન $unit';
    } else if (type == PremiseType.mixed) {
      if (unitType == 'shop' || unitType == 'commercial') {
        return 'શોપ $unit ($cleanBlock)';
      }
      return 'ફ્લેટ $cleanBlock-$unit';
    } else {
      return 'ફ્લેટ $cleanBlock-$unit';
    }
  }
}
