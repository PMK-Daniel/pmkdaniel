// Opt-in native Flutter render review: flutter test --dart-define=VISUAL_REVIEW=true test/visual_review_test.dart
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:checklist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/features/account/account_controller.dart';
import 'package:checklist_app/features/account/account_page.dart';
import 'support/fake_account_gateway.dart';
import 'package:checklist_app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('VISUAL_REVIEW');

  setUpAll(() async {
    if (!enabled) return;
    final config = jsonDecode(
      File('.dart_tool/package_config.json').readAsStringSync(),
    );
    final flutterPackage = (config['packages'] as List).firstWhere(
      (p) => p['name'] == 'flutter',
    );
    final root = Directory.fromUri(
      Uri.parse(flutterPackage['rootUri'] as String),
    ).parent.parent.path;
    final fonts = FontLoader('PlusJakartaSans');
    fonts.addFont(
      File(
        'assets/fonts/PlusJakartaSans.ttf',
      ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
    await fonts.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(
      File(
        '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
      ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
    await icons.load();
  });

  for (final device in [
    ('phone', const Size(390, 844)),
    ('tablet', const Size(1024, 1366)),
  ]) {
    testWidgets('Render actual hub on ${device.$1}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = device.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final hubGateway = FakeAccountGateway.signedIn();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ChecklistApp(accountGateway: hubGateway),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(MaterialApp));
        await Future.wait([
          precacheImage(
            const AssetImage('assets/images/community.webp'),
            context,
          ),
          precacheImage(
            const AssetImage('assets/images/logo_pmk.png'),
            context,
          ),
          for (final name in [
            'renungan',
            'alkitab',
            'pembekalan',
            'dukungan-doa',
            'konsultasi-rohani',
            'dukungan-akademik',
          ])
            precacheImage(
              AssetImage('assets/icons/flat-v2/$name.png'),
              context,
            ),
        ]);
      });
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);

      Future<void> capture(String name) async {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('.impeccable/review');
          await directory.create(recursive: true);
          await File(
            '${directory.path}/$name.png',
          ).writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture(device.$1);
      if (device.$1 == 'phone') {
        await tester.drag(find.byType(ListView).first, const Offset(0, -560));
        await tester.pumpAndSettle();
        await capture('phone-news');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await hubGateway.dispose();
      final gateway = FakeAccountGateway();
      final account = AccountController(gateway);
      await account.loadProviders();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: AccountScope(
            controller: account,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => openAccount(context),
                    child: const Text('Open account'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open account'));
      await tester.pumpAndSettle();
      await capture('account-${device.$1}');
      await account.continueWithCampus('nama@student.ub.ac.id');
      await tester.pumpAndSettle();
      await capture('account-ub-${device.$1}');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      account.dispose();
      await gateway.dispose();
    }, skip: !enabled);
  }
}
