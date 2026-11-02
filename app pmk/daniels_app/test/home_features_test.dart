import 'package:checklist_app/features/home/growth_content.dart';
import 'package:checklist_app/features/home/growth_home.dart';
import 'package:checklist_app/features/home/home_screen.dart';
import 'package:checklist_app/features/home/support_page.dart';
import 'package:checklist_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/features/equipping/circle_catalog.dart';

void main() {
  testWidgets(
    'Six feature launchers lead to their pages, with only Web PMK in quick access',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(CircleCatalog.load);
      var bibleOpened = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HomeScreen(
            onOpenInterview: () {},
            onOpenSettings: () {},
            onOpenBible: () => bibleOpened = true,
            newsLoader: () async => [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jurnal'), findsNothing);
      expect(find.text('Divisi & Kepengurusan PMK'), findsNothing);
      expect(find.text('List Interview'), findsNothing);
      for (final label in [
        'Renungan',
        'Alkitab',
        'Circle',
        'Dukungan doa',
        'Konsultasi Rohani',
        'Dukungan akademik',
      ]) {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        if (label == 'Alkitab') {
          expect(bibleOpened, isTrue);
          continue;
        }
        if (label == 'Renungan') {
          expect(find.byType(ReflectionArchivePage), findsOneWidget);
        }
        if (label == 'Circle') {
          expect(find.byType(EquippingPage), findsOneWidget);
        }
        if (label.startsWith('Dukungan') || label == 'Konsultasi Rohani') {
          expect(find.byType(SupportPage), findsOneWidget);
          expect(find.text('Belum terhubung ke pendamping'), findsOneWidget);
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(
        find.text('Web PMK'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Web PMK'), findsOneWidget);
      expect(find.text('Alkitab Saku'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Renungan launcher can be activated by keyboard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ListView(
            children: [
              GrowthHome(onOpenBible: () {}, newsLoader: () async => []),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(ReflectionArchivePage), findsOneWidget);
  });
}
