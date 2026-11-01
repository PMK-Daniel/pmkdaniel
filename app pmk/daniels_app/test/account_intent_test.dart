import 'dart:convert';
import 'package:checklist_app/features/account/account_controller.dart';
import 'package:checklist_app/features/account/account_gateway.dart';
import 'package:checklist_app/features/account/account_page.dart';
import 'package:checklist_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'support/fake_account_gateway.dart';

class _TestPkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

void main() {
  test('Actual Supabase gateway sends distinct create_user flags', () async {
    final bodies = <Map<String, dynamic>>[];
    final transport = MockClient((request) async {
      expect(request.url.path, '/auth/v1/otp');
      bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response(
        '{}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final client = SupabaseClient(
      'https://project.example',
      'test-public-key',
      httpClient: transport,
      authOptions: AuthClientOptions(pkceAsyncStorage: _TestPkceStorage()),
    );
    final gateway = SupabaseAccountGateway(
      client: client,
      projectUrl: 'https://project.example',
      publicKey: 'test-public-key',
    );
    await gateway.requestEmailLogin('member@example.com');
    await gateway.requestEmailLogin('new@example.com', createAccount: true);
    expect(bodies.map((body) => body['create_user']), [false, true]);
    await client.dispose();
  });

  test(
    'Intent switch preserves resend cooldown and distinguishes email requests',
    () async {
      final gateway = FakeAccountGateway();
      final account = AccountController(gateway);
      await account.continueWithEmail('existing@example.com');
      final deadline = account.nextEmailAt;
      account.setIntent(AccountIntent.signUp);
      expect(account.nextEmailAt, deadline);
      await account.continueWithEmail('new@example.com');
      expect(gateway.createAccountRequests, [false]);
      account.nextEmailAt = DateTime.now().subtract(const Duration(seconds: 1));
      await account.continueWithEmail('new@example.com');
      expect(gateway.createAccountRequests, [false, true]);
      expect(account.user, isNull);
      account.dispose();
      await gateway.dispose();
    },
  );

  testWidgets(
    'Login and signup are separate forms with a verified signup journey',
    (tester) async {
      final gateway = FakeAccountGateway(
        available: const AccountProviders(email: true, google: true),
      );
      final account = AccountController(gateway);
      await account.loadProviders();
      await tester.pumpWidget(
        AccountScope(
          controller: account,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AccountPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Selamat datang kembali'), findsOneWidget);
      expect(find.text('Masuk atau daftar'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Buat akun'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buat akun'));
      await tester.pumpAndSettle();
      expect(account.intent, AccountIntent.signUp);
      expect(find.text('Selamat datang kembali'), findsNothing);
      expect(find.text('Kirim tautan masuk'), findsNothing);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'new@example.com');
      await tester.ensureVisible(find.text('Kirim tautan pendaftaran'));
      await tester.tap(find.text('Kirim tautan pendaftaran'));
      await tester.pumpAndSettle();
      expect(gateway.createAccountRequests, [true]);
      expect(find.text('Verifikasi emailmu'), findsOneWidget);
      expect(account.user, isNull);
      await account.verify('123456');
      await tester.pumpAndSettle();
      expect(account.user!.emailVerified, isTrue);
      await tester.pumpWidget(const SizedBox());
      account.dispose();
      await gateway.dispose();
    },
  );
}
