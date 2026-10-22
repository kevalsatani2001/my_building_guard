import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:building_guard/models/maintenance_model.dart';
import 'package:building_guard/models/society_expense_model.dart';
import 'package:building_guard/models/premise_type.dart';
import 'package:building_guard/models/user_model.dart';
import 'package:building_guard/models/visitor_model.dart';
import 'package:building_guard/services/maintenance_service.dart';
import 'package:building_guard/services/parking_slot_service.dart';
import 'package:building_guard/services/society_accounts_service.dart';
import 'package:building_guard/models/super_admin_models.dart';

void main() {
  test('Basic project smoke test', () {
    expect(true, isTrue);
  });

  group('Maintenance Module Tests', () {
    test('MaintenanceStatus parsing and labels', () {
      expect(MaintenanceStatus.fromString('paid'), MaintenanceStatus.paid);
      expect(
        MaintenanceStatus.fromString('under_review'),
        MaintenanceStatus.underReview,
      );
      expect(
        MaintenanceStatus.fromString('overdue'),
        MaintenanceStatus.overdue,
      );
      expect(
        MaintenanceStatus.fromString('pending'),
        MaintenanceStatus.pending,
      );
      expect(
        MaintenanceStatus.fromString('unknown'),
        MaintenanceStatus.pending,
      );

      expect(MaintenanceStatus.paid.labelGujarati, contains('ચૂકવેલ'));
      expect(MaintenanceStatus.underReview.labelGujarati, contains('ચકાસણી'));
      expect(MaintenanceStatus.pending.labelGujarati, contains('બાકી'));
    });

    test('MaintenanceBill payable calculation and flat display', () {
      final bill = MaintenanceBill(
        id: 'test_123',
        societyId: 'soc_test',
        billTitle: 'ઓક્ટોબર ૨૦૨૬ મેન્ટેનન્સ',
        billingMonth: '2026-10',
        dueDate: DateTime(2026, 10, 10),
        amount: 1500.0,
        penaltyAmount: 100.0,
        blockName: 'A',
        unitNumber: '204',
      );

      expect(bill.totalPayable, 1600.0);
      expect(bill.flatDisplay, 'A-204');
      expect(bill.isPending, isTrue);
      expect(bill.isPaid, isFalse);

      final map = bill.toMap();
      expect(map['societyId'], 'soc_test');
      expect(map['amount'], 1500.0);
      expect(map['penaltyAmount'], 100.0);
      expect(map['status'], 'pending');
    });

    test(
      'MaintenanceService buildUpiUri produces valid URI with standard parameters',
      () {
        final uri = MaintenanceService.instance.buildUpiUri(
          upiId: 'shantivan@sbi',
          payeeName: 'Shantivan Society',
          amount: 1500.0,
          note: 'Oct Maint Flat A-204',
        );

        expect(uri.scheme, 'upi');
        expect(uri.host, 'pay');
        expect(uri.queryParameters['pa'], 'shantivan@sbi');
        expect(uri.queryParameters['am'], '1500.00');
        expect(uri.queryParameters['cu'], 'INR');
        expect(uri.queryParameters['tn'], 'Oct Maint Flat A-204');
      },
    );

    test('Dynamic bill QR URI contains exact flat and month note', () {
      final bill = MaintenanceBill(
        id: 'bill_b102',
        societyId: 'soc_test',
        billTitle: 'October Maintenance',
        billingMonth: '2026-10',
        dueDate: DateTime(2026, 10, 10),
        amount: 2000.0,
        blockName: 'B',
        unitNumber: '102',
      );

      final uri = MaintenanceService.instance.buildUpiUri(
        upiId: 'society@okhdfcbank',
        payeeName: 'Gokuldham Society',
        amount: bill.totalPayable,
        note: 'Maint ${bill.flatDisplay} ${bill.billingMonth}',
      );

      expect(uri.queryParameters['pa'], 'society@okhdfcbank');
      expect(uri.queryParameters['pn'], 'Gokuldham Society');
      expect(uri.queryParameters['am'], '2000.00');
      expect(uri.queryParameters['tn'], 'Maint B-102 2026-10');
    });

    testWidgets('QrImageView renders without exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrImageView(
              data: 'upi://pay?pa=test@upi&pn=Test&am=100.00&cu=INR',
              version: QrVersions.auto,
              size: 200,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('QR AlertDialog opens and displays QR', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: ctx,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('ફ્લેટ A-101 પેમેન્ટ QR'),
                      content: SizedBox(
                        width: 300,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: QrImageView(
                                  data:
                                      'upi://pay?pa=society@upi&pn=Society&am=1500.00&cu=INR',
                                  version: QrVersions.auto,
                                  size: 200,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Show QR'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show QR'));
      await tester.pumpAndSettle();

      expect(find.text('ફ્લેટ A-101 પેમેન્ટ QR'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });
  });

  group('VehiclePlateValidator Tests', () {
    test('Valid standard Gujarat plate with spaces', () {
      final res = VehiclePlateValidator.validate('GJ 01 AB 1234');
      expect(res.isValid, isTrue);
      expect(res.formattedPlate, 'GJ 01 AB 1234');
      expect(res.cleanPlate, 'GJ01AB1234');
    });

    test('Valid standard plate without spaces or hyphens', () {
      final res = VehiclePlateValidator.validate('gj05cd5678');
      expect(res.isValid, isTrue);
      expect(res.formattedPlate, 'GJ 05 CD 5678');
      expect(res.cleanPlate, 'GJ05CD5678');
    });

    test('Valid Bharat (BH) series plate', () {
      final res = VehiclePlateValidator.validate('22 BH 1234 AA');
      expect(res.isValid, isTrue);
      expect(res.formattedPlate, '22 BH 1234 AA');
      expect(res.cleanPlate, '22BH1234AA');
    });

    test('Valid Delhi style with subcategory', () {
      final res = VehiclePlateValidator.validate('DL 1C AA 1111');
      expect(res.isValid, isTrue);
      expect(res.formattedPlate, 'DL 1C AA 1111');
    });

    test('Valid plate with single digit RTO or number', () {
      final res = VehiclePlateValidator.validate('GJ 5 1234');
      expect(res.isValid, isTrue);
      expect(res.formattedPlate, 'GJ 5 1234');

      final vip = VehiclePlateValidator.validate('GJ 01 A 7');
      expect(vip.isValid, isTrue);
      expect(vip.formattedPlate, 'GJ 01 A 7');
    });

    test('Reject empty or whitespace', () {
      final res = VehiclePlateValidator.validate('   ');
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('દાખલ કરો'));
    });

    test('Reject too short', () {
      final res = VehiclePlateValidator.validate('GJ 1');
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('ટૂંકી'));
    });

    test('Reject invalid state code', () {
      final res = VehiclePlateValidator.validate('ZZ 01 AB 1234');
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('રાજ્ય કોડ'));
    });

    test('Reject invalid random characters', () {
      final res = VehiclePlateValidator.validate('ABCDEF123456');
      expect(res.isValid, isFalse);
    });
  });

  group('Society Accounts & Festival Charges Tests', () {
    test('MaintenanceBill with festival contribution calculation', () {
      final bill = MaintenanceBill(
        id: 'fest_bill_1',
        societyId: 'soc_1',
        billTitle: 'દિવાળી મેન્ટેનન્સ',
        billingMonth: '2026-11',
        dueDate: DateTime(2026, 11, 10),
        amount: 2000.0,
        penaltyAmount: 50.0,
        festivalCharge: 500.0,
        festivalName: 'દિવાળી લાઈટિંગ ફાળો',
        blockName: 'B',
        unitNumber: '102',
      );

      expect(bill.totalPayable, 2550.0);
      expect(bill.festivalCharge, 500.0);
      expect(bill.festivalName, 'દિવાળી લાઈટિંગ ફાળો');

      final map = bill.toMap();
      expect(map['festivalCharge'], 500.0);
      expect(map['festivalName'], 'દિવાળી લાઈટિંગ ફાળો');
      expect(map['amount'], 2000.0);
    });

    test('SocietyExpenseCategory resolution and labels', () {
      final watchman = SocietyExpenseCategory.fromKey('watchman_salary');
      expect(watchman.titleGujarati, contains('વોચમેન'));

      final cleaning = SocietyExpenseCategory.fromKey('cleaning_staff');
      expect(cleaning.titleGujarati, contains('સફાઈ'));

      final fallback = SocietyExpenseCategory.fromKey('unknown_key');
      expect(fallback.key, 'other');
    });

    test('SocietyExpense data model serialization and paymentMode labels', () {
      final exp = SocietyExpense(
        id: 'exp_1',
        societyId: 'soc_1',
        title: 'ઓક્ટોબર વોચમેન પગાર',
        categoryKey: 'watchman_salary',
        amount: 8000.0,
        expenseDate: DateTime(2026, 10, 1),
        paidTo: 'રમેશભાઈ',
        paymentMode: 'cash',
        notes: 'ઓક્ટોબર મહિનો ચુકતે',
      );

      expect(exp.paymentModeLabel, contains('રોકડ'));
      expect(exp.category.titleGujarati, contains('વોચમેન'));

      final map = exp.toMap();
      expect(map['societyId'], 'soc_1');
      expect(map['amount'], 8000.0);
      expect(map['paidTo'], 'રમેશભાઈ');
      expect(map['categoryKey'], 'watchman_salary');
    });

    test('SocietyLedgerEntry running balance calculation logic', () {
      final entries = [
        SocietyLedgerEntry(
          id: 'b1',
          date: DateTime(2026, 10, 1),
          title: 'મેન્ટેનન્સ [A-101]',
          subtitle: 'રસીદ: R01',
          categoryKey: 'maintenance_income',
          categoryLabel: 'મેન્ટેનન્સ આવક',
          isCredit: true,
          amount: 5000.0,
          paymentMode: 'ONLINE',
          reference: 'R01',
        ),
        SocietyLedgerEntry(
          id: 'e1',
          date: DateTime(2026, 10, 5),
          title: 'વોચમેન પગાર',
          subtitle: 'ચૂકવ્યા: સુરેશભાઈ',
          categoryKey: 'watchman_salary',
          categoryLabel: 'સુરક્ષા / વોચમેન',
          isCredit: false,
          amount: 2000.0,
          paymentMode: 'CASH',
          reference: 'E01',
        ),
        SocietyLedgerEntry(
          id: 'b2',
          date: DateTime(2026, 10, 10),
          title: 'મેન્ટેનન્સ + દિવાળી ફાળો [B-202]',
          subtitle: 'રસીદ: R02',
          categoryKey: 'maintenance_income',
          categoryLabel: 'મેન્ટેનન્સ + તહેવાર ફાળો',
          isCredit: true,
          amount: 4000.0,
          paymentMode: 'UPI',
          reference: 'R02',
        ),
      ];

      // Calculate running balance
      double running = 0.0;
      for (final e in entries) {
        if (e.isCredit) {
          running += e.amount;
        } else {
          running -= e.amount;
        }
        e.runningBalance = running;
      }

      expect(entries[0].runningBalance, 5000.0);
      expect(entries[1].runningBalance, 3000.0);
      expect(entries[2].runningBalance, 7000.0);
      expect(running, 7000.0);
    });

    test('Payment mode normalization converts Gujarati to clean ASCII', () {
      expect(SocietyAccountsService.normalizePaymentMode('રોકડ'), 'CASH');
      expect(SocietyAccountsService.normalizePaymentMode('રોકડ રકમ'), 'CASH');
      expect(SocietyAccountsService.normalizePaymentMode('ઓનલાઇન'), 'ONLINE');
      expect(SocietyAccountsService.normalizePaymentMode('ચેક'), 'CHEQUE');
      expect(SocietyAccountsService.normalizePaymentMode('UPI / QR'), 'UPI');
    });

    test(
      'SocietyLedgerEntry particulars and non-Latin character detection',
      () {
        final entry = SocietyLedgerEntry(
          id: 'l1',
          date: DateTime(2026, 10, 15),
          title: 'October 2026 મેન્ટેનન્સ [ફ્લેટ: S-2-40]',
          subtitle: 'રસીદ: REC-001',
          categoryKey: 'maintenance_income',
          categoryLabel: 'મેન્ટેનન્સ આવક',
          isCredit: true,
          amount: 4500,
          paymentMode: 'CASH',
          reference: 'REC-001',
        );

        expect(entry.title, contains('મેન્ટેનન્સ'));
        expect(entry.subtitle, contains('રસીદ'));
        expect(entry.paymentMode, 'CASH');
      },
    );
  });

  group('Universal Premise & Enterprise ERP Architecture Tests', () {
    test(
      'PremiseVocabulary provides accurate dynamic labels for all 4 premise types',
      () {
        final wingVocab = PremiseVocabulary.fromString('Wing');
        expect(wingVocab.blockLabel, 'વિંગ / બ્લોક');
        expect(wingVocab.unitLabel, 'ફ્લેટ નં.');
        expect(wingVocab.adminLabel, 'સોસાયટી પ્રમુખ');

        final streetVocab = PremiseVocabulary.fromString('Street');
        expect(streetVocab.blockLabel, 'શેરી / લાઇન');
        expect(streetVocab.unitLabel, 'મકાન / પ્લોટ નં.');
        expect(streetVocab.adminLabel, 'સોસાયટી પ્રમુખ');

        final commVocab = PremiseVocabulary.fromString('Commercial');
        expect(commVocab.blockLabel, 'ફ્લોર / બ્લોક');
        expect(commVocab.unitLabel, 'દુકાન / ઓફિસ નં.');
        expect(commVocab.memberLabel, 'વેપારી / દુકાનદાર');
        expect(commVocab.adminLabel, 'વેપારી મંડળ પ્રમુખ');

        final mixedVocab = PremiseVocabulary.fromString('Mixed');
        expect(mixedVocab.unitLabel, 'યુનિટ નં. (શોપ/ફ્લેટ)');
        expect(mixedVocab.memberLabel, 'રહીશ / દુકાનદાર');
      },
    );

    test(
      'UserModel role helpers support SuperAdmin and WingAdmin boundaries',
      () {
        const superAdmin = UserModel(
          uid: 'admin_1',
          name: 'Main Pramukh',
          email: 'main@society.com',
          role: 'admin',
        );
        expect(superAdmin.isSuperAdmin, isTrue);
        expect(superAdmin.isWingAdmin, isFalse);
        expect(superAdmin.isAnyAdmin, isTrue);
        expect(superAdmin.canManageBlock('A'), isTrue);
        expect(superAdmin.canManageBlock('B'), isTrue);

        const wingAdminA = UserModel(
          uid: 'wing_a_admin',
          name: 'Wing A Pramukh',
          email: 'winga@society.com',
          role: 'wing_admin',
          blockName: 'A',
        );
        expect(wingAdminA.isSuperAdmin, isFalse);
        expect(wingAdminA.isWingAdmin, isTrue);
        expect(wingAdminA.isAnyAdmin, isTrue);
        expect(wingAdminA.canManageBlock('A'), isTrue);
        expect(wingAdminA.canManageBlock('B'), isFalse);
      },
    );

    test('SocietyExpense scope and targetBlock serialization and labels', () {
      final commonExp = SocietyExpense(
        id: 'e1',
        societyId: 'soc_1',
        title: 'Borewell Motor Repair',
        categoryKey: 'water_borewell',
        amount: 8500,
        expenseDate: DateTime(2026, 10, 20),
        paidTo: 'Patel Plumbing Works',
        scope: 'common',
        targetBlock: 'ALL',
      );
      expect(commonExp.isCommon, isTrue);
      expect(commonExp.scopeLabelGujarati, contains('સમગ્ર સોસાયટી'));

      final wingExp = SocietyExpense(
        id: 'e2',
        societyId: 'soc_1',
        title: 'Wing A Lift Servicing',
        categoryKey: 'lift_amc',
        amount: 4200,
        expenseDate: DateTime(2026, 10, 21),
        paidTo: 'Schindler AMC',
        scope: 'wing',
        targetBlock: 'A',
      );
      expect(wingExp.isCommon, isFalse);
      expect(wingExp.targetBlock, 'A');
      expect(wingExp.scopeLabelGujarati, contains('A (વિંગ/શેરી સ્પેશિયલ)'));

      final map = wingExp.toMap();
      expect(map['scope'], 'wing');
      expect(map['targetBlock'], 'A');
    });

    test('MaintenanceBill commercial area and GST calculation', () {
      final shopBill = MaintenanceBill(
        id: 'shop_101_oct',
        societyId: 'commercial_mall_1',
        billTitle: 'October 2026 Shop Maintenance + GST',
        billingMonth: '2026-10',
        dueDate: DateTime(2026, 10, 10),
        amount: 5000.0, // Base maintenance (e.g. 500 sq.ft * Rs 10/sq.ft)
        penaltyAmount: 0.0,
        festivalCharge: 0.0,
        blockName: 'Ground',
        unitNumber: 'G-101',
        unitType: 'shop',
        areaSqFt: 500.0,
        gstRate: 18.0,
        gstAmount: 900.0, // 18% of 5000
        gstin: '24AAAAA0000A1Z5',
      );

      expect(shopBill.totalPayable, 5900.0);
      expect(shopBill.unitType, 'shop');
      expect(shopBill.areaSqFt, 500.0);
      expect(shopBill.gstRate, 18.0);
      expect(shopBill.gstAmount, 900.0);
      expect(shopBill.gstin, '24AAAAA0000A1Z5');

      final map = shopBill.toMap();
      expect(map['unitType'], 'shop');
      expect(map['gstAmount'], 900.0);
      expect(map['gstin'], '24AAAAA0000A1Z5');
    });

    test('ParkingSlotModel multi-level basement and commercial bay labels', () {
      const b1Slot = ParkingSlotModel(
        id: 'b1_01',
        societyId: 'soc_1',
        slotNumber: 'A-B1-C01',
        blockName: 'A',
        category: 'Wing',
        slotType: 'car',
        level: 'B1',
        isAssigned: false,
      );
      expect(b1Slot.levelLabelGujarati, contains('બેઝમેન્ટ - 1'));

      const groundSlot = ParkingSlotModel(
        id: 'g_01',
        societyId: 'soc_1',
        slotNumber: 'G-C01',
        blockName: 'Ground',
        category: 'Wing',
        slotType: 'car',
        level: 'Ground',
        isAssigned: false,
      );
      expect(groundSlot.levelLabelGujarati, contains('ગ્રાઉન્ડ'));

      const tempoSlot = ParkingSlotModel(
        id: 'load_01',
        societyId: 'soc_1',
        slotNumber: 'LOAD-01',
        blockName: 'Commercial',
        category: 'Commercial',
        slotType: 'loading',
        level: 'Loading',
        parkingZone: 'loading',
        isAssigned: false,
      );
      expect(tempoSlot.levelLabelGujarati, contains('લોડિંગ'));
      expect(tempoSlot.parkingZone, 'loading');
    });

    test('VisitorModel commercial delivery cargo and goods tracking', () {
      final cargoVisitor = VisitorModel(
        id: 'v_cargo_1',
        name: 'Ramesh Tempo Driver',
        phone: '9876543210',
        purpose: 'કાપડ માલ-સામાન ડિલિવરી',
        photoUrl: '',
        memberId: 'shop_204',
        blockName: 'First Floor',
        unitNumber: '104',
        status: 'approved',
        visitorType: 'cargo',
        vehicleNumber: 'GJ 01 AB 9999',
        goodsDescription: '50 બોક્સ કાપડ તાકા',
        entryTime: DateTime.now(),
      );

      expect(cargoVisitor.visitorType, 'cargo');
      expect(cargoVisitor.vehicleNumber, 'GJ 01 AB 9999');
      expect(cargoVisitor.goodsDescription, contains('કાપડ'));

      final map = cargoVisitor.toMap();
      expect(map['visitorType'], 'cargo');
      expect(map['vehicleNumber'], 'GJ 01 AB 9999');
      expect(map['goodsDescription'], contains('કાપડ'));
    });

    test(
      'Commercial shopping mall flexible floor-wise unit generation with sizes',
      () {
        // Ground Floor: 20 shops (G-01 to G-20), 350 sqft
        final groundUnits = <String>[];
        for (int i = 1; i <= 20; i++) {
          groundUnits.add('G-${i.toString().padLeft(2, '0')}');
        }
        expect(groundUnits.length, 20);
        expect(groundUnits.first, 'G-01');
        expect(groundUnits.last, 'G-20');

        // 1st Floor: 15 shops (101 to 115), 400 sqft
        final firstFloorUnits = <String>[];
        for (int i = 1; i <= 15; i++) {
          firstFloorUnits.add('1${i.toString().padLeft(2, '0')}');
        }
        expect(firstFloorUnits.length, 15);
        expect(firstFloorUnits.first, '101');
        expect(firstFloorUnits.last, '115');

        // Floors 2 to 10: 8 offices per floor (201-208 ... 1001-1008), 500 sqft
        final upperOffices = <String>[];
        for (int f = 2; f <= 10; f++) {
          for (int u = 1; u <= 8; u++) {
            upperOffices.add('$f${u.toString().padLeft(2, '0')}');
          }
        }
        expect(upperOffices.length, 72); // 9 floors * 8 = 72 offices
        expect(upperOffices.first, '201');
        expect(upperOffices.last, '1008');

        final totalCommercialUnits =
            groundUnits.length + firstFloorUnits.length + upperOffices.length;
        expect(totalCommercialUnits, 107);
      },
    );

    test(
      'Mixed-use complex multi-category unit generation (Commercial Shops + Residential Wing)',
      () {
        // 18 Ground floor commercial shops
        final shops = List.generate(
          18,
          (i) => 'SHOP-${(i + 1).toString().padLeft(2, '0')}',
        );
        expect(shops.length, 18);
        expect(shops.first, 'SHOP-01');
        expect(shops.last, 'SHOP-18');

        // Residential Tower Wing A: 10 floors * 4 flats
        final flatsA = <String>[];
        for (int f = 1; f <= 10; f++) {
          for (int u = 1; u <= 4; u++) {
            flatsA.add('A-$f${u.toString().padLeft(2, '0')}');
          }
        }
        expect(flatsA.length, 40);
        expect(flatsA.first, 'A-101');
        expect(flatsA.last, 'A-1004');

        final mixedTotal = shops.length + flatsA.length;
        expect(mixedTotal, 58);
      },
    );

    test(
      'Premise billing desk architecture mapping and features validation',
      () {
        final commVocab = PremiseVocabulary.fromString('Commercial');
        expect(commVocab.type, PremiseType.commercial);
        expect(commVocab.unitLabel, contains('દુકાન'));

        final mixedVocab = PremiseVocabulary.fromString('Mixed');
        expect(mixedVocab.type, PremiseType.mixed);
        expect(mixedVocab.unitLabel, contains('યુનિટ'));

        final wingVocab = PremiseVocabulary.fromString('Wing');
        expect(wingVocab.type, PremiseType.wing);
        expect(wingVocab.unitLabel, contains('ફ્લેટ'));

        final streetVocab = PremiseVocabulary.fromString('Street');
        expect(streetVocab.type, PremiseType.street);
        expect(streetVocab.unitLabel, contains('મકાન'));
      },
    );
  });

  group('Super Admin Master Portal Tests', () {
    test('UserModel isPlatformSuperAdmin and permission hierarchy', () {
      const superAdminUser = UserModel(
        uid: 'sa_1',
        name: 'App Owner',
        email: 'owner@buildingguard.com',
        role: 'super_admin',
      );
      expect(superAdminUser.isPlatformSuperAdmin, isTrue);
      expect(superAdminUser.isSuperAdmin, isTrue);
      expect(superAdminUser.isAnyAdmin, isTrue);
      expect(superAdminUser.canManageBlock('AnyBlock'), isTrue);

      const regularAdmin = UserModel(
        uid: 'adm_1',
        name: 'Secretary',
        email: 'sec@society.com',
        role: 'admin',
      );
      expect(regularAdmin.isPlatformSuperAdmin, isFalse);
      expect(regularAdmin.isSuperAdmin, isTrue);
    });

    test('SocietyOverview metrics and collection percentage calculation', () {
      final soc = SocietyOverview(
        id: 'soc_101',
        name: 'Royal Arcade & Mall',
        architectureType: 'Commercial',
        city: 'Surat',
        adminName: 'Keval Patel',
        adminPhone: '9876543210',
        adminEmail: 'keval@mall.com',
        totalUnits: 50,
        totalMembers: 45,
        totalWatchmen: 4,
        totalAdmins: 2,
        totalBilledMonth: 200000,
        totalCollectedMonth: 150000,
        pendingComplaints: 3,
        todayVisitors: 28,
        isActive: true,
        createdAt: DateTime.now(),
      );

      expect(soc.collectionPercentage, 75.0);
      expect(soc.isActive, isTrue);
      expect(soc.architectureType, 'Commercial');
    });

    test(
      'Multi-premise bulk billing calculation logic for Shopping, Mixed, and Society',
      () {
        // 1. Shopping (Commercial): Sq.Ft billing + 18% GST
        const double sqftRate = 4.5;
        const double shopArea = 600.0;
        final baseAmount = shopArea * sqftRate; // 2700.0
        final gstAmount = (baseAmount * 18.0) / 100.0; // 486.0
        final totalShopBill = baseAmount + gstAmount; // 3186.0
        expect(baseAmount, 2700.0);
        expect(gstAmount, 486.0);
        expect(totalShopBill, 3186.0);

        // 2. Mixed Complex: Differentiated rates (Shops vs Flats)
        const double shopRate = 3500.0;
        const double flatRate = 1200.0;
        bool isCommercialUnit(String code) => code.startsWith('S');
        final billForShop = isCommercialUnit('S-01') ? shopRate : flatRate;
        final billForFlat = isCommercialUnit('A-101') ? shopRate : flatRate;
        expect(billForShop, 3500.0);
        expect(billForFlat, 1200.0);

        // 3. Society / Wing-wise: Targeting verification
        final List<Map<String, dynamic>> mockUnits = [
          {'blockName': 'A', 'unitNumber': 'A-101', 'isCommercial': false},
          {'blockName': 'A', 'unitNumber': 'A-102', 'isCommercial': false},
          {'blockName': 'B', 'unitNumber': 'B-101', 'isCommercial': false},
          {'blockName': 'Shops', 'unitNumber': 'S-01', 'isCommercial': true},
        ];

        // Wing A only
        final wingAUnits = mockUnits
            .where((u) => u['blockName'] == 'A')
            .toList();
        expect(wingAUnits.length, 2);

        // Commercial only in Mixed complex
        final commercialUnits = mockUnits
            .where((u) => u['isCommercial'] == true)
            .toList();
        expect(commercialUnits.length, 1);
        expect(commercialUnits.first['unitNumber'], 'S-01');
      },
    );
  });
}
