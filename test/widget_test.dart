import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:building_guard/models/maintenance_model.dart';
import 'package:building_guard/services/maintenance_service.dart';

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
}

