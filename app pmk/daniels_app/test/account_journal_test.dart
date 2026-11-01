import 'package:checklist_app/features/account/account_controller.dart';
import 'package:checklist_app/features/account/account_gateway.dart';
import 'package:checklist_app/features/home/growth_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_account_gateway.dart';

void main() {
  testWidgets('Local journals remain separate for guest and each account', (
    tester,
  ) async {
    final reflection = reflectionPreviews.first;
    SharedPreferences.setMockInitialValues({
      'reflection_note_${reflection.reading}': 'Guest note',
      'reflection_note_user_a_${reflection.reading}': 'Member A note',
      'reflection_note_user_b_${reflection.reading}': 'Member B note',
    });
    final gateway = FakeAccountGateway();
    final account = AccountController(gateway);
    await tester.pumpWidget(
      AccountScope(
        controller: account,
        child: MaterialApp(home: JournalPage(reflection: reflection)),
      ),
    );
    await tester.pumpAndSettle();
    String note() =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;
    expect(note(), 'Guest note');
    for (final id in ['a', 'b']) {
      gateway.emit(
        MemberAccount(
          id: id,
          email: '$id@example.com',
          name: '',
          emailVerified: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(note(), 'Member ${id.toUpperCase()} note');
    }
    await tester.enterText(find.byType(TextField), 'Unsaved B draft');
    gateway.emit(null);
    await tester.pumpAndSettle();
    expect(note(), 'Guest note');
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('reflection_note_user_b_${reflection.reading}'),
      'Member B note',
    );
    await tester.pumpWidget(const SizedBox());
    account.dispose();
    await gateway.dispose();
  });
}
