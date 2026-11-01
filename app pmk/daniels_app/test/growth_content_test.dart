import 'dart:async';
import 'dart:convert';
import 'package:checklist_app/features/home/growth_content.dart';
import 'package:checklist_app/features/home/growth_home.dart';
import 'package:checklist_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'Public news response preserves published content and handles server errors',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/pengumuman');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'success': true,
              'data': {
                'items': [
                  {
                    'title': 'Kabar komunitas',
                    'content': 'Shalom, Daniels! 🙏',
                    'category': 'kegiatan',
                    'date_published': '2026-09-24',
                    'author': 'Divisi Acara',
                  },
                ],
              },
            }),
          ),
          200,
        );
      });
      final articles = await NewsService.fetch(client: client);
      expect(articles.single.content, 'Shalom, Daniels! 🙏');
      expect(articles.single.image, isNull);
      final failure = MockClient(
        (_) async => http.Response('Unavailable', 503),
      );
      await expectLater(NewsService.fetch(client: failure), throwsStateError);
      client.close();
      failure.close();
    },
  );

  testWidgets('News loading and retry recover to an honest empty state', (
    tester,
  ) async {
    var attempts = 0;
    final pending = Completer<List<NewsArticle>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewsSection(
            loader: () {
              attempts++;
              return attempts == 1 ? pending.future : Future.value([]);
            },
          ),
        ),
      ),
    );
    expect(find.text('Memuat kabar PMK…'), findsOneWidget);
    pending.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Belum ada berita terbit. Cek kembali nanti, ya.'),
      findsOneWidget,
    );
    expect(attempts, 2);
  });

  testWidgets('Reflection journal survives closing and reopening', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: JournalPage(reflection: reflectionPreviews.first)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Mendoakan dan menyapa seorang teman.',
    );
    await tester.ensureVisible(find.text('Simpan refleksi'));
    await tester.tap(find.text('Simpan refleksi'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(home: JournalPage(reflection: reflectionPreviews.first)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mendoakan dan menyapa seorang teman.'), findsOneWidget);
  });

  testWidgets(
    'Home supports small screens and large text; shortcuts open the right pages',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var bibleOpened = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GrowthHome(
                    onOpenBible: () => bibleOpened = true,
                    newsLoader: () async => [
                      const NewsArticle(
                        title: 'PD-6 : Hidup Dengan Kekuatan Dari Kristus',
                        content: 'Berita PMK',
                        category: 'kegiatan',
                        date: '2026-09-24',
                        author: 'Divisi Acara',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Alkitab'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alkitab'));
      expect(bibleOpened, isTrue);
      await tester.tap(find.text('Renungan'));
      await tester.pumpAndSettle();
      expect(find.text('Waktu untuk bertumbuh'), findsOneWidget);
      await tester.tap(find.text(reflectionPreviews.first.title));
      await tester.pumpAndSettle();
      expect(find.byType(ReflectionPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
