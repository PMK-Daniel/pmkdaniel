import 'package:checklist_app/main.dart';
import 'package:checklist_app/features/settings/app_preferences.dart';
import 'package:checklist_app/features/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_account_gateway.dart';

void main() {
  test(
    'Device preferences survive a new controller without touching notes',
    () async {
      SharedPreferences.setMockInitialValues({
        'daniel.circle.v1.member': 'private-note',
      });
      final first = AppPreferences();
      await first.load();
      expect(await first.update(scale: 1.3), isTrue);
      expect(await first.update(motion: true), isTrue);
      first.dispose();
      final restored = AppPreferences();
      await restored.load();
      expect(restored.textScale, 1.3);
      expect(restored.reduceMotion, isTrue);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'daniel.circle.v1.member',
        ),
        'private-note',
      );
      restored.dispose();
    },
  );

  testWidgets(
    'Settings journeys, scaled mobile, unsaved profile and cancelled logout',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gateway = FakeAccountGateway.signedIn();
      await tester.pumpWidget(ChecklistApp(accountGateway: gateway));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan ruang & cloud'), findsNothing);
      expect(find.text('List Interview'), findsNothing);
      await tester.tap(find.text('Tampilan & aksesibilitas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lebih besar'));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(AppearancePage));
      expect(MediaQuery.textScalerOf(context).scale(10), closeTo(13, .01));
      await tester.scrollUntilVisible(
        find.text('Kurangi gerakan'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getBool('ui.reduceMotion'),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      for (final label in [
        'Notifikasi',
        'Keamanan akun',
        'Privasi & penyimpanan',
        'Pusat bantuan',
        'Tentang Daniel Apps',
      ]) {
        await tester.scrollUntilVisible(
          find.text(label),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: label);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(
        find.text('Keluar dari akun'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Keluar dari akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(gateway.current, isNotNull);
      await tester.scrollUntilVisible(
        find.text('Edit profil'),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Edit profil'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Nama belum disimpan');
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Abaikan perubahan?'), findsOneWidget);
      await tester.tap(find.text('Lanjut edit'));
      await tester.pumpAndSettle();
      expect(find.text('Nama belum disimpan'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abaikan'));
      await tester.pumpAndSettle();
      expect(gateway.current!.name, 'Tobias Andra Valentino');
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await gateway.dispose();
    },
  );
}
