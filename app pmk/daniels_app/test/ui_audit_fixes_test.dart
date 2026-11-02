import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:checklist_app/data/bible_data.dart';
import 'package:checklist_app/features/account/account_controller.dart';
import 'package:checklist_app/features/bible/bible_screen.dart';
import 'package:checklist_app/features/equipping/circle_catalog.dart';
import 'package:checklist_app/features/equipping/circle_group_card.dart';
import 'package:checklist_app/features/equipping/circle_group_page.dart';
import 'package:checklist_app/features/equipping/circle_continue.dart';
import 'package:checklist_app/features/equipping/circle_page.dart';
import 'package:checklist_app/features/equipping/circle_reader.dart';
import 'package:checklist_app/features/home/hub_pages.dart';
import 'package:checklist_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_account_gateway.dart';

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final l1 = _luminance(a), l2 = _luminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  test('Reading parser keeps wording and recognises structure', () {
    const page =
        'PERTEMUAN 03\n\nBagian 01: Rancangan Allah\n\nTuhan menciptakan manusia untuk relasi.\n\n'
        '“Sebab Aku mengetahui rancangan-rancangan.” (Yeremia 29:11)\n\n•\n\nBacalah seluruh materi.\n\n'
        '1.\n\nTampilkan ilustrasi.\n\nJawabanmu:';
    final blocks = parseReadingBlocks(page);
    expect(blocks.map((b) => b.kind), [
      ReadingBlockKind.title,
      ReadingBlockKind.heading,
      ReadingBlockKind.paragraph,
      ReadingBlockKind.quote,
      ReadingBlockKind.listItem,
      ReadingBlockKind.listItem,
      ReadingBlockKind.label,
    ]);
    expect(blocks[4].marker, '•');
    expect(blocks[5].marker, '1.');
    expect(blocks[4].text, 'Bacalah seluruh materi.');
  });

  test('Every real page keeps all of its paragraphs verbatim', () {
    final catalog = CircleCatalog.fromJson(
      jsonDecode(File('assets/circle/catalog.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    for (final doc in catalog.lessons.expand((l) => l.documents)) {
      for (final page in doc.pages) {
        final blocks = parseReadingBlocks(page);
        for (final part
            in page.split(RegExp(r'\n[ \t]*\n')).map((p) => p.trim())) {
          if (part.length <= 3) continue;
          expect(blocks.any((b) => b.text == part), isTrue, reason: part);
        }
      }
    }
  });

  test('Orange testament abbreviation now passes text contrast', () {
    final pale = Color.alphaBlend(
      AppTheme.secondary.withValues(alpha: 0.12),
      Colors.white,
    );
    expect(_contrast(AppTheme.secondaryDark, pale), greaterThanOrEqualTo(4.5));
    expect(_contrast(AppTheme.secondary, pale), lessThan(3));
  });

  testWidgets('Testament filter is a keyboard-focusable choice control', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const BibleScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNWidgets(3));
    await tester.tap(find.text('Perjanjian Baru (27)'));
    await tester.pumpAndSettle();
    final selected = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .where((c) => c.selected)
        .toList();
    expect(selected, hasLength(1));
    expect((selected.single.label as Text).data, 'Perjanjian Baru (27)');
    expect(find.text('Kejadian'), findsNothing);
    expect(find.text('Matius'), findsOneWidget);
    expect(BibleData.books.where((b) => b.testament == 'PB'), hasLength(27));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Circle opens with the continue action and lessons above the fold',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeAccountGateway.signedIn();
      final account = AccountController(gateway);
      final catalog = CircleCatalog.fromJson(
        jsonDecode(File('assets/circle/catalog.json').readAsStringSync())
            as Map<String, dynamic>,
      );
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
      expect(find.text('Mulai: Siapakah Aku?'), findsOneWidget);
      final firstLesson = find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Siapakah Aku?'),
      );
      expect(firstLesson, findsOneWidget);
      expect(tester.getTopLeft(firstLesson).dy, lessThan(844));
      await tester.pumpWidget(const SizedBox());
      account.dispose();
      await gateway.dispose();
    },
  );

  testWidgets(
    'Leaving with unsaved reflection prefers keeping the note and can save it',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final progress = CircleProgress(prefs, 'a')..load();
      final catalog = CircleCatalog.fromJson(
        jsonDecode(File('assets/circle/catalog.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      final lesson = catalog.meetings.first;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CircleLessonPage(
                      lesson: lesson,
                      catalog: catalog,
                      progress: progress,
                    ),
                  ),
                ),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(TextField),
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 80,
      );
      await tester.enterText(find.byType(TextField), 'Catatan penting');
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Lanjut menulis'), findsOneWidget);
      expect(find.text('Buang perubahan'), findsOneWidget);
      expect(find.text('Abaikan'), findsNothing);
      expect(
        tester.widget(find.widgetWithText(FilledButton, 'Lanjut menulis')),
        isA<FilledButton>(),
      );
      expect(
        find.widgetWithText(FilledButton, 'Buang perubahan'),
        findsNothing,
      );

      await tester.tap(find.text('Lanjut menulis'));
      await tester.pumpAndSettle();
      expect(find.text('Pertemuan ${lesson.number}'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan dan keluar'));
      await tester.pumpAndSettle();
      expect(find.text('buka'), findsOneWidget);
      expect(progress.reflection(lesson.id), 'Catatan penting');
    },
  );

  test(
    'Circle group persists per account and invitation leaves member list private',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const group = CircleGroupInfo(
        name: 'Circle Kasih',
        facilitator: 'Kak Rani',
        schedule: 'Jumat 16.00',
        members: 'Budi, Sari\nRaka',
      );
      await group.save(prefs, 'anggota-a');
      final stored = CircleGroupInfo.fromPrefs(prefs, 'anggota-a');
      expect(stored.memberList, ['Budi', 'Sari', 'Raka']);
      expect(stored.name, 'Circle Kasih');
      expect(
        CircleGroupInfo.fromPrefs(prefs, 'anggota-b').isConfigured,
        isFalse,
      );
      final invitation = stored.buildInviteMessage(null);
      expect(invitation, contains('Jumat 16.00'));
      expect(invitation, contains('Kak Rani'));
      expect(invitation, isNot(contains('Budi')));
    },
  );

  testWidgets(
    'Circle group can be saved, reopened and copied without pushing lessons down',
    (tester) async {
      String? copiedText;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeAccountGateway.signedIn();
      final account = AccountController(gateway);
      final catalog = CircleCatalog.fromJson(
        jsonDecode(File('assets/circle/catalog.json').readAsStringSync())
            as Map<String, dynamic>,
      );
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
      await tester.tap(find.text('Kelompokku'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atur kelompok'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nama kelompok Circle'),
        'Circle Kasih',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Jadwal & tempat kumpul'),
        'Jumat 16.00',
      );
      await tester.tap(find.text('Simpan kelompok'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Salin ajakan kumpul'), findsOneWidget);
      final firstLesson = find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Siapakah Aku?'),
      );
      expect(tester.getBottomLeft(firstLesson).dy, lessThan(844));
      await tester.tap(find.byTooltip('Salin ajakan kumpul'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(copiedText, contains('Circle Kasih'));
      expect(copiedText, contains('Jumat 16.00'));
      await tester.tap(find.text('Kelompokku'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ubah kelompok'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Nama kelompok Circle'),
            )
            .controller!
            .text,
        'Circle Kasih',
      );
      await tester.pumpWidget(const SizedBox());
      account.dispose();
      await gateway.dispose();
    },
  );

  testWidgets('Home Circle continues to the next unfinished meeting', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final catalog = (await tester.runAsync(CircleCatalog.load))!;
    final gateway = FakeAccountGateway.signedIn();
    final account = AccountController(gateway);
    final progress = CircleProgress(prefs, account.user!.id)..load();
    await progress.save(catalog.meetings.first.id, 'Selesai dibahas', true);
    final next = catalog.meetings[1];
    await tester.pumpWidget(
      AccountScope(
        controller: account,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(child: CircleContinue()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Pertemuan ${next.number} · ${next.title}'),
      findsOneWidget,
    );
    expect(find.text('1/${catalog.meetings.length} selesai'), findsOneWidget);
    await tester.tap(find.text('Lanjutkan pertemuan'));
    await tester.pumpAndSettle();
    expect(find.text('Pertemuan ${next.number}'), findsOneWidget);
    final reloaded = CircleProgress(prefs, account.user!.id)..load();
    expect(reloaded.lastId, next.id);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    account.dispose();
    await gateway.dispose();
  });

  testWidgets(
    'Circle and Friend remain usable at 200 percent text on a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final catalog = (await tester.runAsync(CircleCatalog.load))!;
      final gateway = FakeAccountGateway.signedIn();
      final account = AccountController(gateway);
      for (final page in [
        CircleLearningPage(loader: () async => catalog),
        const FriendsPage(),
        const Scaffold(body: SingleChildScrollView(child: CircleContinue())),
      ]) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          AccountScope(
            controller: account,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
              home: page,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (page is CircleLearningPage) {
          await tester.ensureVisible(find.text('Kelompokku'));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<TextButton>(
                  find.widgetWithText(TextButton, 'Kelompokku'),
                )
                .onPressed,
            isNotNull,
          );
          await tester.tap(find.text('Kelompokku'));
          await tester.pumpAndSettle();
          expect(find.byType(CircleGroupPage), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text('Atur kelompok'),
            200,
            scrollable: find
                .descendant(
                  of: find.byType(ListView).first,
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Atur kelompok'));
          await tester.pumpAndSettle();
          expect(find.text('Kelompok Circle-ku'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
      await tester.pumpWidget(const SizedBox());
      account.dispose();
      await gateway.dispose();
    },
  );

  testWidgets('Reader footer continues to next document and the reflection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final progress = CircleProgress(prefs, 'a')..load();
    final catalog = CircleCatalog.fromJson(
      jsonDecode(File('assets/circle/catalog.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final lesson = catalog.meetings.firstWhere(
      (l) => l.documents.first.pageImages.isEmpty,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: CircleLessonPage(
          lesson: lesson,
          catalog: catalog,
          progress: progress,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pages = lesson.documents
        .firstWhere((d) => d.role == 'material')
        .pages
        .length;
    for (var i = 1; i < pages; i++) {
      await tester.scrollUntilVisible(
        find.text('Halaman ${i + 1}'),
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 80,
      );
      await tester.tap(find.text('Halaman ${i + 1}'));
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(
      find.text('Lanjut: Bahan diskusi'),
      -300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 80,
    );
    expect(find.text('Lanjut: Bahan diskusi'), findsOneWidget);
    await tester.tap(find.text('Lanjut: Bahan diskusi'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
