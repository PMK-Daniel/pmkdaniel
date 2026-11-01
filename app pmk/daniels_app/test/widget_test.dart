import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_account_gateway.dart';

void main() {
  testWidgets('Hub has three destinations and keeps utilities in Settings', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final gateway = FakeAccountGateway.signedIn();
    await tester.pumpWidget(ChecklistApp(accountGateway: gateway));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('Home'), findsOneWidget);
    await tester.tap(find.text('Friend'));
    await tester.pump();
    expect(find.text('Iman tumbuh\ndalam kebersamaan.'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Pengaturan ruang & cloud'), findsOneWidget);
    expect(find.text('List Interview'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await gateway.dispose();
  });
}
