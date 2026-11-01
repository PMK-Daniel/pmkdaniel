import 'package:checklist_app/data/bible_data.dart';
import 'package:checklist_app/features/bible/bible_screen.dart';
import 'package:checklist_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Narrow reader with enlarged text chooses chapter and exposes size settings',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(
        () => BibleData.getChapterVerses(BibleData.books.first, 1),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const BibleScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kejadian').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();
      expect(find.text('Kejadian 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Ukuran teks'));
      await tester.pumpAndSettle();
      expect(find.text('Tampilan & aksesibilitas'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Daftar kitab'));
      await tester.pumpAndSettle();
      expect(find.text('Kejadian'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
