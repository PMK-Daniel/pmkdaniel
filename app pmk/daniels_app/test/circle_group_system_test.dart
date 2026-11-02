import 'dart:convert';
import 'dart:io';
import 'package:checklist_app/features/account/account_controller.dart';
import 'package:checklist_app/features/account/account_gateway.dart';
import 'package:checklist_app/features/equipping/circle_catalog.dart';
import 'package:checklist_app/features/equipping/circle_group_page.dart';
import 'package:checklist_app/features/equipping/circle_page.dart';
import 'package:checklist_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_account_gateway.dart';

CircleCatalog catalog() => CircleCatalog.fromJson(
  jsonDecode(File('assets/circle/catalog.json').readAsStringSync())
      as Map<String, dynamic>,
);

Widget lessonPage(
  CircleLesson lesson,
  CircleCatalog catalog,
  CircleProgress progress,
) => CircleLessonPage(lesson: lesson, catalog: catalog, progress: progress);

Future<void> reach(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first,
    maxScrolls: 80,
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Meeting follow-up preserves legacy notes, survives legacy saves, and stays account-isolated',
    () async {
      SharedPreferences.setMockInitialValues({
        'daniel.circle.v1.a': jsonEncode({
          'lastId': '01',
          'entries': {
            '01': {'reflection': 'Catatan lama', 'completed': true},
          },
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final progress = CircleProgress(prefs, 'a')..load();
      expect(progress.reflection('01'), 'Catatan lama');
      expect(progress.commitment('01'), isEmpty);
      await progress.save(
        '01',
        'Catatan lama',
        true,
        commitment: 'Menghubungi teman',
        groupPrayer: 'Ujian bersama',
      );
      await progress.save('01', 'Catatan revisi', false);
      await progress.visit('02');
      final again = CircleProgress(prefs, 'a')..load();
      expect(again.reflection('01'), 'Catatan revisi');
      expect(again.commitment('01'), 'Menghubungi teman');
      expect(again.groupPrayer('01'), 'Ujian bersama');
      expect(again.lastId, '02');
      expect(again.completed('01'), isFalse);
      final other = CircleProgress(prefs, 'b')..load();
      expect(other.commitment('01'), isEmpty);
      expect(other.groupPrayer('01'), isEmpty);
    },
  );

  testWidgets(
    'Group prayer can be updated, filtered, reopened and never appears in another account',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeAccountGateway.signedIn();
      final account = AccountController(gateway);
      final source = catalog();
      Widget app() => AccountScope(
        controller: account,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: CircleGroupPage(
            loader: () async => source,
            lessonBuilder: lessonPage,
          ),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Doa').last);
      await tester.pumpAndSettle();
      await reach(tester, find.text('Tambah doa Circle'));
      await tester.tap(find.text('Tambah doa Circle'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Pokok doa kelompok'),
        'Ujian anggota Circle',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Catatan perkembangan (opsional)'),
        'Belajar bersama hari Jumat',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      await reach(tester, find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'Didoakan (0)'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Didoakan (0)'));
      await tester.pumpAndSettle();
      expect(find.text('Ujian anggota Circle'), findsNothing);
      await tester.tap(
        find.widgetWithText(ChoiceChip, 'Terjawab / disyukuri (1)'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ujian anggota Circle'), findsOneWidget);
      expect(find.text('Belajar bersama hari Jumat'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Doa').last);
      await tester.pumpAndSettle();
      await reach(tester, find.text('Ujian anggota Circle'));
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      gateway.emit(
        const MemberAccount(
          id: 'other-member',
          email: 'other@example.com',
          name: 'Other',
          emailVerified: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ujian anggota Circle'), findsNothing);
      expect(find.textContaining('Belum ada pokok doa.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      account.dispose();
      await gateway.dispose();
    },
  );

  testWidgets(
    'Sharing excludes private reflection, all notes persist, and changing only a commitment is guarded',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final progress = CircleProgress(prefs, 'member')..load();
      final source = catalog();
      final lesson = source.meetings.firstWhere(
        (l) => l.documents.every((d) => d.pageImages.isEmpty),
      );
      String? copied;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => lessonPage(lesson, source, progress),
                  ),
                ),
                child: const Text('Buka pertemuan'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka pertemuan'));
      await tester.pumpAndSettle();
      await reach(tester, find.widgetWithText(TextField, 'Catatan refleksi'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Catatan refleksi'),
        'Refleksi yang hanya untuk saya',
      );
      await reach(tester, find.text('Tindak lanjut pertemuan'));
      await tester.tap(find.text('Tindak lanjut pertemuan'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Langkah nyata minggu ini'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Langkah nyata minggu ini'),
        'Menghubungi teman',
      );
      await tester.ensureVisible(
        find.widgetWithText(TextField, 'Pokok doa untuk kelompok'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Pokok doa untuk kelompok'),
        'Ujian bersama',
      );
      await tester.ensureVisible(
        find.text('Salin ringkasan untuk grup Circle'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salin ringkasan untuk grup Circle'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(copied, contains('Menghubungi teman'));
      expect(copied, contains('Ujian bersama'));
      expect(copied, isNot(contains('Refleksi yang hanya untuk saya')));
      await tester.ensureVisible(find.text('Simpan catatan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan catatan'));
      await tester.pumpAndSettle();
      final stored = CircleProgress(prefs, 'member')..load();
      expect(stored.reflection(lesson.id), 'Refleksi yang hanya untuk saya');
      expect(stored.commitment(lesson.id), 'Menghubungi teman');
      expect(stored.groupPrayer(lesson.id), 'Ujian bersama');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka pertemuan'));
      await tester.pumpAndSettle();
      await reach(
        tester,
        find.widgetWithText(TextField, 'Langkah nyata minggu ini'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Langkah nyata minggu ini'),
        'Perubahan komitmen saja',
      );
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Catatan belum disimpan'), findsOneWidget);
      await tester.tap(find.text('Simpan dan keluar'));
      await tester.pumpAndSettle();
      expect(progress.commitment(lesson.id), 'Perubahan komitmen saja');
      expect(progress.reflection(lesson.id), 'Refleksi yang hanya untuk saya');
      expect(find.text('Buka pertemuan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
