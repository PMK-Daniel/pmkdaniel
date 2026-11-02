import 'package:checklist_app/features/account/account_controller.dart';
import 'package:checklist_app/features/community/personal_list.dart';
import 'package:checklist_app/features/home/hub_pages.dart';
import 'package:checklist_app/features/home/support_page.dart';
import 'package:checklist_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_account_gateway.dart';

Widget app(Widget home, {AccountController? account}) {
  final page = MaterialApp(theme: AppTheme.lightTheme, home: home);
  return account == null
      ? page
      : AccountScope(controller: account, child: page);
}

void main() {
  test('Entries persist per list kind and per account, never mixed', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final a = PersonalListStore(prefs, 'friends', 'a');
    await a.add('  Budi ', ' ajak Circle ');
    await a.add('Sari', '');
    expect(a.entries.map((e) => e.title), ['Sari', 'Budi']);
    expect(a.entries.last.note, 'ajak Circle');
    await a.update(a.entries.last.id, done: true);

    final again = PersonalListStore(prefs, 'friends', 'a');
    expect(again.entries.map((e) => e.title), ['Sari', 'Budi']);
    expect(again.entries.last.done, isTrue);
    expect(PersonalListStore(prefs, 'friends', 'b').entries, isEmpty);
    expect(PersonalListStore(prefs, 'prayer', 'a').entries, isEmpty);

    final removed = again.entries.first;
    await again.remove(removed.id);
    expect(again.entries.map((e) => e.title), ['Budi']);
    await again.restore(removed, 0);
    expect(again.entries.map((e) => e.title), ['Sari', 'Budi']);
  });

  test('Corrupt or hostile stored data is ignored instead of crashing', () async {
    SharedPreferences.setMockInitialValues({
      'daniel.list.v1.friends.a': '{not json',
      'daniel.list.v1.friends.b':
          '{"entries":[1,{"id":"x"},{"id":"y","title":"  "},{"id":"z","title":"Ok","note":5}]}',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(PersonalListStore(prefs, 'friends', 'a').entries, isEmpty);
    final b = PersonalListStore(prefs, 'friends', 'b').entries;
    expect(b.map((e) => e.title), ['Ok']);
    expect(b.single.note, isEmpty);
  });

  testWidgets('Friend page adds, completes, edits, deletes and undoes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final gateway = FakeAccountGateway.signedIn();
    final account = AccountController(gateway);
    await tester.pumpWidget(app(const FriendsPage(), account: account));
    await tester.pumpAndSettle();
    expect(find.text('Teman perjalananmu'), findsOneWidget);
    expect(find.textContaining('Belum ada teman'), findsOneWidget);

    await tester.tap(find.text('Tambah teman'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Tulis dulu sebelum menyimpan.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nama teman'),
      'Budi',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Budi'), findsOneWidget);
    expect(find.textContaining('Belum ada teman'), findsNothing);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('Sudah dihubungi'), findsOneWidget);

    await tester.tap(find.byTooltip('Opsi untuk Budi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nama teman'),
      'Budi Santoso',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso'), findsOneWidget);

    await tester.tap(find.byTooltip('Opsi untuk Budi Santoso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso'), findsNothing);
    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Survives leaving and reopening the page.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(const FriendsPage(), account: account));
    await tester.pumpAndSettle();
    expect(find.text('Budi Santoso'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    account.dispose();
    await gateway.dispose();
  });

  testWidgets('Each support page keeps its own private list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final gateway = FakeAccountGateway.signedIn();
    final account = AccountController(gateway);
    await tester.pumpWidget(
      app(const SupportPage(kind: SupportKind.prayer), account: account),
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum terhubung ke pendamping'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tambah pokok doa'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tambah pokok doa'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Pokok doa'),
      'Ujian minggu depan',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Ujian minggu depan'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      app(const SupportPage(kind: SupportKind.academic), account: account),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tambah rencana belajar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ujian minggu depan'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    account.dispose();
    await gateway.dispose();
  });
}
