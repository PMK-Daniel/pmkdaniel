import 'dart:async';
import 'package:checklist_app/features/account/account_controller.dart';
import 'package:checklist_app/features/account/account_gateway.dart';
import 'package:checklist_app/features/account/account_page.dart';
import 'package:checklist_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_account_gateway.dart';

void main() {
  testWidgets(
    'Provider choices work from keyboard without email; email validates inline',
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
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(account.step, AccountStep.redirecting);
      expect(gateway.googleHint, isNull);
      expect(gateway.emails, isEmpty);
      account.changeEmail();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Login dengan akun student'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Login dengan akun student'));
      await tester.pumpAndSettle();
      expect(gateway.campusGoogle, isTrue);
      expect(gateway.emails, isEmpty);
      account.changeEmail();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'invalid');
      await tester.ensureVisible(find.text('Kirim tautan masuk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim tautan masuk'));
      await tester.pumpAndSettle();
      expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
      expect(gateway.emails, isEmpty);
      await tester.pumpWidget(const SizedBox());
      account.dispose();
      await gateway.dispose();
    },
  );
  test(
    'Web callback clears old query and fragment without empty delimiters',
    () {
      expect(
        accountWebRedirect(Uri.parse('http://localhost:8873/?code=old#state')),
        'http://localhost:8873/',
      );
      expect(
        accountWebRedirect(Uri.parse('https://example.com/account?next=home')),
        'https://example.com/',
      );
    },
  );
  test(
    'Google and UB shortcuts send distinct OAuth hints without treating hints as verification',
    () async {
      expect(googleLoginParameters(), {'prompt': 'select_account'});
      expect(googleLoginParameters(campus: true), {
        'prompt': 'select_account',
        'hd': 'student.ub.ac.id',
      });
      expect(
        googleLoginParameters(campus: true, emailHint: 'member@ub.ac.id'),
        {'login_hint': 'member@ub.ac.id', 'hd': 'ub.ac.id'},
      );
      final gateway = FakeAccountGateway(
        available: const AccountProviders(email: true, google: true),
      );
      final account = AccountController(gateway);
      await account.continueWithCampus('');
      expect(gateway.campusGoogle, isTrue);
      expect(gateway.googleHint, isNull);
      expect(account.user, isNull);
      expect(account.step, AccountStep.redirecting);
      account.dispose();
      await gateway.dispose();
    },
  );
  test('UB routing uses exact domains and requires a valid complete email', () {
    expect(isUbEmail(' Name@STUDENT.UB.AC.ID '), isTrue);
    expect(isUbEmail('name@ub.ac.id'), isTrue);
    for (final email in [
      'student.ub.ac.id',
      'name@student.ub.ac.id.evil.test',
      'name@evilub.ac.id',
      'name@x.ub.ac.id',
      'a@@student.ub.ac.id',
    ]) {
      expect(isUbEmail(email), isFalse, reason: email);
    }
  });

  test(
    'Unconfigured campus flow does not pretend to redirect or send email',
    () async {
      final gateway = FakeAccountGateway();
      final account = AccountController(gateway);
      await account.continueWithCampus(' Member@Student.UB.ac.id ');
      expect(account.email, 'member@student.ub.ac.id');
      expect(account.step, AccountStep.campusUnavailable);
      expect(gateway.emails, isEmpty);
      expect(gateway.googleHint, isNull);
      expect(account.user, isNull);
      await account.sendEmail();
      expect(gateway.emails, ['member@student.ub.ac.id']);
      expect(account.step, AccountStep.emailSent);
      expect(account.user, isNull);
      account.dispose();
      await gateway.dispose();
    },
  );

  test(
    'Campus option uses Google even when a direct SSO provider also exists',
    () async {
      final gateway = FakeAccountGateway(
        available: const AccountProviders(
          email: true,
          google: true,
          ubSso: true,
        ),
      );
      final account = AccountController(gateway);
      await account.continueWithCampus('member@student.ub.ac.id');
      expect(gateway.ssoDomain, isNull);
      expect(gateway.googleHint, 'member@student.ub.ac.id');
      expect(gateway.campusGoogle, isTrue);
      expect(gateway.emails, isEmpty);
      expect(account.step, AccountStep.redirecting);
      account.dispose();
      await gateway.dispose();
    },
  );

  test(
    'Workspace login receives the email hint; spoofed domains use ordinary email login',
    () async {
      final gateway = FakeAccountGateway(
        available: const AccountProviders(email: true, google: true),
      );
      final account = AccountController(gateway);
      await account.continueWithCampus('member@student.ub.ac.id');
      expect(gateway.googleHint, 'member@student.ub.ac.id');
      expect(gateway.campusGoogle, isTrue);
      account.changeEmail();
      await account.continueWithEmail('member@student.ub.ac.id.evil.test');
      expect(gateway.emails, ['member@student.ub.ac.id.evil.test']);
      account.dispose();
      await gateway.dispose();
    },
  );

  test(
    'Email option keeps UB email passwordless; campus option rejects personal email',
    () async {
      final gateway = FakeAccountGateway(
        available: const AccountProviders(email: true, google: true),
      );
      final account = AccountController(gateway);
      await account.continueWithCampus('person@gmail.com');
      expect(account.emailError, contains('@student.ub.ac.id'));
      expect(gateway.googleHint, isNull);
      expect(gateway.emails, isEmpty);
      await account.continueWithEmail('member@student.ub.ac.id');
      expect(account.emailError, isNull);
      expect(gateway.emails, ['member@student.ub.ac.id']);
      expect(gateway.googleHint, isNull);
      account.dispose();
      await gateway.dispose();
    },
  );

  test(
    'Email verification, resend cooldown, profile update, expired session and logout keep distinct states',
    () async {
      final gateway = FakeAccountGateway();
      final account = AccountController(gateway);
      await account.continueWithEmail('member@example.com');
      expect(account.user, isNull);
      await account.sendEmail();
      expect(gateway.emails.length, 1);
      expect(account.error, contains('satu menit'));
      await account.verify('000000');
      expect(account.user, isNull);
      expect(account.error, 'Kode tidak cocok.');
      await account.verify('123456');
      expect(account.user!.email, 'member@example.com');
      expect(account.user!.hasUbEmail, isFalse);
      expect(await account.saveName('Nama pengujian'), isTrue);
      expect(account.user!.name, 'Nama pengujian');
      gateway.failure = const AccountFailure('Jaringan terputus.');
      await account.signOut();
      expect(account.user, isNotNull);
      gateway.failure = null;
      await account.signOut();
      expect(account.user, isNull);
      expect(account.email, isEmpty);
      gateway.emit(
        const MemberAccount(
          id: 'restored',
          email: 'member@student.ub.ac.id',
          name: 'Uji',
          emailVerified: false,
        ),
      );
      expect(account.user!.hasUbEmail, isFalse);
      gateway.emit(null);
      expect(account.user, isNull);
      account.dispose();
      await gateway.dispose();
    },
  );

  test(
    'An in-flight email request cannot change identity; late completion after disposal does not notify',
    () async {
      final gateway = FakeAccountGateway()..pendingEmail = Completer<void>();
      final account = AccountController(gateway);
      await account.loadProviders();
      final first = account.continueWithEmail('first@example.com');
      await Future<void>.delayed(Duration.zero);
      await account.continueWithEmail('other@example.com');
      account.setIntent(AccountIntent.signUp);
      expect(account.intent, AccountIntent.signIn);
      expect(account.email, 'first@example.com');
      expect(gateway.emails, ['first@example.com']);
      account.dispose();
      gateway.pendingEmail!.complete();
      await first;
      await gateway.dispose();
    },
  );

  testWidgets(
    'Email-first page identifies UB, offers an honest fallback and never has a password input',
    (tester) async {
      final gateway = FakeAccountGateway();
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
      await tester.enterText(
        find.byType(TextField).first,
        'member@student.ub.ac.id',
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Login dengan akun student'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Login dengan akun student'));
      await tester.pumpAndSettle();
      expect(find.text('Kirim tautan ke email UB'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(gateway.emails, isEmpty);
      await tester.ensureVisible(find.text('Kirim tautan ke email UB'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim tautan ke email UB'));
      await tester.pumpAndSettle();
      expect(find.text('Cek emailmu'), findsOneWidget);
      expect(gateway.emails, ['member@student.ub.ac.id']);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.ensureVisible(find.text('Verifikasi kode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verifikasi kode'));
      await tester.pumpAndSettle();
      expect(find.text('Email UB terverifikasi'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      account.dispose();
      await gateway.dispose();
    },
  );
}
