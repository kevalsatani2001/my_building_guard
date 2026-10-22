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
