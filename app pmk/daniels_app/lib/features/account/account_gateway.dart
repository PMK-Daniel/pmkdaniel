import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberAccount {
  final String id, email, name;
  final bool emailVerified;
  const MemberAccount({
    required this.id,
    required this.email,
    required this.name,
    required this.emailVerified,
  });
  bool get hasUbEmail => emailVerified && isUbEmail(email);
}

String normalizeEmail(String email) => email.trim().toLowerCase();
String accountWebRedirect(Uri location) => '${location.origin}/';
bool validEmail(String email) =>
    email.length <= 254 &&
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
bool isUbEmail(String email) =>
    validEmail(normalizeEmail(email)) &&
    const {
      'student.ub.ac.id',
      'ub.ac.id',
    }.contains(normalizeEmail(email).split('@').last);

Map<String, String> googleLoginParameters({
  String? emailHint,
  bool campus = false,
}) => {
  'login_hint': ?emailHint,
  if (emailHint == null) 'prompt': 'select_account',
  if (campus) 'hd': emailHint?.split('@').last ?? 'student.ub.ac.id',
};

class AccountProviders {
  final bool email, google, ubSso;
  const AccountProviders({
    this.email = false,
    this.google = false,
    this.ubSso = false,
  });
}

class AccountFailure implements Exception {
  final String message;
  const AccountFailure(this.message);
}

abstract class AccountGateway {
  MemberAccount? get current;
  Stream<MemberAccount?> get changes;
  Future<AccountProviders> providers();
  Future<void> requestEmailLogin(String email);
  Future<void> verifyEmailCode(String email, String code);
  Future<void> signInGoogle({String? emailHint, bool campus = false});
  Future<void> signInUb(String domain);
  Future<void> updateName(String name);
  Future<void> signOut();
}

class UnavailableAccountGateway implements AccountGateway {
  const UnavailableAccountGateway();
  Never _fail() => throw const AccountFailure(
    'Layanan akun belum terhubung. Coba buka ulang aplikasi.',
  );
  @override
  MemberAccount? get current => null;
  @override
  Stream<MemberAccount?> get changes => const Stream.empty();
  @override
  Future<AccountProviders> providers() async => _fail();
  @override
  Future<void> requestEmailLogin(String email) async => _fail();
  @override
  Future<void> verifyEmailCode(String email, String code) async => _fail();
  @override
  Future<void> signInGoogle({String? emailHint, bool campus = false}) async =>
      _fail();
  @override
  Future<void> signInUb(String domain) async => _fail();
  @override
  Future<void> updateName(String name) async => _fail();
  @override
  Future<void> signOut() async => _fail();
}

class SupabaseAccountGateway implements AccountGateway {
  final SupabaseClient client;
  final String projectUrl, publicKey;
  static const ubSsoConfigured = bool.fromEnvironment('UB_SSO_ENABLED');
  static const explicitRedirect = String.fromEnvironment(
    'ACCOUNT_REDIRECT_URL',
  );
  SupabaseAccountGateway({
    required this.client,
    required this.projectUrl,
    required this.publicKey,
  });

  String get redirectUrl => explicitRedirect.isNotEmpty
      ? explicitRedirect
      : (kIsWeb ? accountWebRedirect(Uri.base) : 'danielsapp://auth-callback');

  MemberAccount? _snapshot() {
    final session = client.auth.currentSession;
    if (session == null || session.isExpired) return null;
    final user = session.user;
    if (user.isAnonymous || user.email == null) return null;
    return MemberAccount(
      id: user.id,
      email: user.email!,
      name:
          (user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '')
              .toString(),
      emailVerified: user.emailConfirmedAt != null,
    );
  }

  @override
  MemberAccount? get current => _snapshot();
  @override
  Stream<MemberAccount?> get changes =>
      client.auth.onAuthStateChange.map((_) => _snapshot());

  @override
  Future<AccountProviders> providers() async {
    final transport = http.Client();
    try {
      final response = await transport
          .get(
            Uri.parse('$projectUrl/auth/v1/settings'),
            headers: {'apikey': publicKey},
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw const AccountFailure(
          'Layanan akun belum dapat diakses. Coba lagi.',
        );
      }
      final settings = jsonDecode(response.body) as Map<String, dynamic>;
      final external = settings['external'] as Map<String, dynamic>? ?? {};
      return AccountProviders(
        email: external['email'] == true,
        google: external['google'] == true,
        ubSso: ubSsoConfigured,
      );
    } finally {
      transport.close();
    }
  }

  @override
  Future<void> requestEmailLogin(String email) => client.auth.signInWithOtp(
    email: email,
    emailRedirectTo: redirectUrl,
    shouldCreateUser: true,
  );

  @override
  Future<void> verifyEmailCode(String email, String code) async {
    final result = await client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
    if (result.session == null) {
      throw const AccountFailure(
        'Login belum selesai. Periksa kembali kode dari email.',
      );
    }
  }

  @override
  Future<void> signInGoogle({String? emailHint, bool campus = false}) async {
    final launched = await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
      scopes: 'openid email profile',
      queryParams: googleLoginParameters(emailHint: emailHint, campus: campus),
    );
    if (!launched) {
      throw const AccountFailure(
        'Halaman Google belum dapat dibuka. Coba lagi.',
      );
    }
  }

  @override
  Future<void> signInUb(String domain) async {
    if (!ubSsoConfigured) {
      throw const AccountFailure('SSO UB untuk Daniel Apps belum tersedia.');
    }
    final launched = await client.auth.signInWithSSO(
      domain: domain,
      redirectTo: redirectUrl,
    );
    if (!launched) {
      throw const AccountFailure(
        'Halaman SSO UB belum dapat dibuka. Coba lagi.',
      );
    }
  }

  @override
  Future<void> updateName(String name) async {
    await client.auth.updateUser(UserAttributes(data: {'full_name': name}));
  }

  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
}

String accountError(Object error) {
  if (error is AccountFailure) return error.message;
  if (error is AuthException) {
    if (error.code == 'over_email_send_rate_limit' ||
        error.code == 'over_request_rate_limit' ||
        error.statusCode == '429') {
      return 'Terlalu banyak percobaan. Tunggu sebentar sebelum mencoba lagi.';
    }
    if (error.code == 'otp_expired') {
      return 'Kode atau tautan sudah tidak berlaku. Minta email masuk yang baru.';
    }
    if (error.code == 'email_address_invalid' ||
        error.code == 'validation_failed') {
      return 'Periksa kembali alamat email dan kode yang kamu masukkan.';
    }
    if (error.code == 'email_address_not_authorized' ||
        error.code == 'email_provider_disabled') {
      return 'Pengiriman email masuk belum tersedia untuk alamat ini. Hubungi pengurus PMK.';
    }
    if (error.code == 'provider_disabled' ||
        error.code == 'sso_provider_not_found') {
      return 'Penyedia login ini belum diaktifkan untuk Daniel Apps.';
    }
    return 'Login belum berhasil. Periksa email atau kodenya, lalu coba lagi.';
  }
  return 'Layanan akun belum dapat dihubungi. Periksa koneksi lalu coba lagi.';
}
