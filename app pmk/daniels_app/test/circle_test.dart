import 'dart:convert';
import 'dart:io';
import 'package:checklist_app/features/account/account_controller.dart';
import 'package:checklist_app/features/equipping/circle_catalog.dart';
import 'package:checklist_app/features/equipping/circle_page.dart';
import 'package:checklist_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_account_gateway.dart';

CircleCatalog catalogFromDisk() => CircleCatalog.fromJson(
  jsonDecode(File('assets/circle/catalog.json').readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  test(
    'All 58 source meetings and the guide have complete original documents',
    () {
      final catalog = catalogFromDisk();
      expect(
        catalog.meetings.map((p) => p.number),
        List.generate(58, (i) => i + 1),
      );
      expect(catalog.lessons.length, 59);
      expect(catalog.phases.length, 5);
      expect(catalog.lessons.expand((p) => p.documents).length, 175);
      for (final lesson in catalog.lessons) {
        expect(Uri.parse(lesson.source).host, 'daniel-circle.notion.site');
        expect(lesson.introduction, isNotEmpty);
        expect(
          lesson.documents.map((d) => d.role).toSet(),
          lesson.number == 0
              ? {'material'}
              : {'material', 'discussion', 'facilitator'},
        );
        for (final doc in lesson.documents) {
          expect(doc.pages, isNotEmpty);
          expect(
            doc.pageImages.isNotEmpty ||
                doc.pages.every((p) => p.trim().isNotEmpty),
            isTrue,
          );
          expect(File(doc.asset).readAsBytesSync().take(5), [
            37,
            80,
            68,
            70,
            45,
          ]);
          for (final image in doc.pageImages) {
            expect(File(image).existsSync(), isTrue);
          }
        }
      }
      expect(catalog.meetings.first.title, 'Siapakah Aku?');
      expect(catalog.meetings.last.title, 'Menjadi Duta Kristus Setelah Lulus');
      expect(
        File('assets/circle/catalog.json').readAsStringSync(),
        isNot(contains('signature=')),
      );
    },
  );

  test(
    'Reflection, completion and resume persist separately for each account',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final a = CircleProgress(prefs, 'a')..load();
      await a.save('01', 'Refleksi pertama', true);
      await a.visit('02');
      final reloaded = CircleProgress(prefs, 'a')..load();
      expect(reloaded.completed('01'), isTrue);
      expect(reloaded.reflection('01'), 'Refleksi pertama');
      expect(reloaded.lastId, '02');
      final b = CircleProgress(prefs, 'b')..load();
      expect(b.completed('01'), isFalse);
      expect(b.reflection('01'), isEmpty);
      expect(b.lastId, isNull);
      await reloaded.save('01', 'Revisi refleksi', false);
      expect(reloaded.completed('01'), isFalse);
    },
  );

  testWidgets(
    'Actual catalog searches, opens original reading and saves completion',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeAccountGateway.signedIn();
      final account = AccountController(gateway);
      final catalog = catalogFromDisk();
      await tester.pumpWidget(
        AccountScope(
          controller: account,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: CircleLearningPage(loader: () async => catalog),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 dari 58 pertemuan selesai'), findsOneWidget);
      await tester.tap(find.text('Mulai: Siapakah Aku?'));
      await tester.pumpAndSettle();
      expect(find.text('Pertemuan 1'), findsOneWidget);
      Future<void> reach(Finder target) async {
        await tester.scrollUntilVisible(
          target,
          250,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
          maxScrolls: 70,
        );
        await tester.pumpAndSettle();
      }

      await reach(find.text('Bahan diskusi'));
      await tester.tap(find.text('Bahan diskusi'));
      await tester.pumpAndSettle();
      expect(find.text('BDK Pertemuan 01 - Siapakah Aku.pdf'), findsOneWidget);
      await tester.tap(find.byTooltip('Halaman berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('Halaman 2 dari 3'), findsOneWidget);
      await reach(find.text('Refleksi pribadi'));
      await tester.enterText(
        find.byType(TextField),
        'Saya belajar mengenal identitas dalam Kristus.',
      );
      await reach(find.text('Simpan dan tandai selesai'));
      await tester.tap(find.text('Simpan dan tandai selesai'));
      await tester.pumpAndSettle();
      expect(find.text('Tandai belum selesai'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('1 dari 58 pertemuan selesai'), findsOneWidget);
      await reach(find.text('Cari pertemuan'));
      await tester.enterText(find.byType(TextField), 'Etika Kristen di Era AI');
      await tester.pumpAndSettle();
      final aiLesson = find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Etika Kristen di Era AI'),
      );
      await reach(aiLesson);
      expect(find.text('Siapakah Aku?'), findsNothing);
      await tester.tap(aiLesson);
      await tester.pumpAndSettle();
      expect(find.text('Pertemuan 31'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      account.dispose();
      await gateway.dispose();
    },
  );

  testWidgets('Catalog load failure offers retry rather than a dummy lesson', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CircleLearningPage(
          loader: () async {
            attempts++;
            throw StateError('unavailable');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Muat kembali'), findsOneWidget);
    await tester.tap(find.text('Muat kembali'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Siapakah Aku?'), findsNothing);
  });
}
