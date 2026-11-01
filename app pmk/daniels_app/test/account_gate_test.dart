import 'package:checklist_app/main.dart';
import 'package:checklist_app/features/account/account_gateway.dart';
import 'package:checklist_app/features/home/growth_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_account_gateway.dart';

void main() {
  testWidgets(
    'Login is first, missing name needs onboarding, logout clears protected routes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeAccountGateway();
      await tester.pumpWidget(ChecklistApp(accountGateway: gateway));
      await tester.pumpAndSettle();
      expect(find.text('Kirim tautan masuk'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      gateway.emit(
        const MemberAccount(
          id: 'member',
          email: 'member@example.com',
          name: '',
          emailVerified: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kamu ingin\ndisapa siapa?'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Tobias');
      await tester.ensureVisible(find.text('Simpan dan masuk'));
      await tester.tap(find.text('Simpan dan masuk'));
      await tester.pumpAndSettle();
      expect(find.text('Hai, Tobias!'), findsOneWidget);
      await tester.ensureVisible(find.text('Renungan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Renungan'));
      await tester.pumpAndSettle();
      expect(find.byType(ReflectionArchivePage), findsOneWidget);
      gateway.emit(null);
      await tester.pumpAndSettle();
      expect(find.text('Kirim tautan masuk'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Hai, Tobias!'), findsNothing);
      expect(find.byType(ReflectionArchivePage), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await gateway.dispose();
    },
  );
}
