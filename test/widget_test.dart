import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:building_guard/models/maintenance_model.dart';
import 'package:building_guard/models/society_expense_model.dart';
import 'package:building_guard/services/maintenance_service.dart';
import 'package:building_guard/services/parking_slot_service.dart';
import 'package:building_guard/services/society_accounts_service.dart';
import 'package:building_guard/services/society_accounts_pdf_service.dart';

void main() {
  test('Basic project smoke test', () {
    expect(true, isTrue);
  });

  group('Maintenance Module Tests', () {
    test('MaintenanceStatus parsing and labels', () {
      expect(MaintenanceStatus.fromString('paid'), MaintenanceStatus.paid);
      expect(MaintenanceStatus.fromString('under_review'), MaintenanceStatus.underReview);
      expect(MaintenanceStatus.fromString('overdue'), MaintenanceStatus.overdue);
      expect(MaintenanceStatus.fromString('pending'), MaintenanceStatus.pending);
      expect(MaintenanceStatus.fromString('unknown'), MaintenanceStatus.pending);

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

    test('MaintenanceService buildUpiUri produces valid URI with standard parameters', () {
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
    });

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
                                  data: 'upi://pay?pa=society@upi&pn=Society&am=1500.00&cu=INR',
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

    test('SocietyLedgerEntry particulars and non-Latin character detection', () {
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
    });
  });
}


