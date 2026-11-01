import 'dart:async';
import 'package:flutter/material.dart';
import 'account_gateway.dart';

enum AccountStep { email, campusUnavailable, emailSent, redirecting }

enum AccountIntent { signIn, signUp }

class AccountController extends ChangeNotifier {
  final AccountGateway gateway;
  late final StreamSubscription<MemberAccount?> _subscription;
  AccountProviders? providers;
  MemberAccount? user;
  String email = '';
  String? error;
  String? emailError;
  bool loadingProviders = false, busy = false, _disposed = false;
  AccountStep step = AccountStep.email;
  AccountIntent intent = AccountIntent.signIn;
  bool get isRegistering => intent == AccountIntent.signUp;

  void setIntent(AccountIntent value) {
    if (busy || _disposed || intent == value) return;
    intent = value;
    step = AccountStep.email;
    email = '';
    error = null;
    emailError = null;
    notifyListeners();
  }

  DateTime? nextEmailAt;

  AccountController(this.gateway) {
    user = gateway.current;
    _subscription = gateway.changes.listen(
      (value) {
        if (_disposed) return;
        user = value;
        error = null;
        if (value != null) step = AccountStep.email;
        notifyListeners();
      },
      onError: (Object value) {
        if (_disposed) return;
        user = gateway.current;
        error = 'Sesi akun belum dapat diperbarui. Periksa koneksimu.';
        notifyListeners();
      },
    );
  }

  Future<void> loadProviders() async {
    if (loadingProviders || _disposed) return;
    loadingProviders = true;
    error = null;
    notifyListeners();
    try {
      providers = await gateway.providers();
    } catch (value) {
      if (!_disposed) error = accountError(value);
    } finally {
      if (!_disposed) {
        loadingProviders = false;
        notifyListeners();
      }
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (busy || _disposed) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return !_disposed;
    } catch (value) {
      if (!_disposed) error = accountError(value);
      return false;
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> continueWithEmail(String value) async {
    if (busy || loadingProviders || _disposed) return;
    final normalized = normalizeEmail(value);
    if (!validEmail(normalized)) {
      emailError = 'Masukkan alamat email yang valid.';
      notifyListeners();
      return;
    }
    emailError = null;
    email = normalized;
    if (providers == null) await loadProviders();
    if (_disposed || providers == null) return;
    await sendEmail();
  }

  Future<void> continueWithCampus(String value) async {
    if (busy || loadingProviders || _disposed) return;
    final normalized = normalizeEmail(value);
    if (normalized.isNotEmpty && !isUbEmail(normalized)) {
      emailError = 'Gunakan email @student.ub.ac.id atau @ub.ac.id.';
      notifyListeners();
      return;
    }
    emailError = null;
    email = normalized;
    if (providers == null) await loadProviders();
    if (_disposed || providers == null) return;
    if (!providers!.google) {
      step = AccountStep.campusUnavailable;
      error = null;
      notifyListeners();
      return;
    }
    await startGoogle(campus: true);
  }

  Future<void> sendEmail() async {
    await _run(() async {
      if (providers?.email != true) {
        throw const AccountFailure(
          'Login email belum tersedia. Coba lagi nanti.',
        );
      }
      if (!validEmail(email)) {
        throw const AccountFailure('Masukkan alamat email yang valid.');
      }
      if (nextEmailAt != null && DateTime.now().isBefore(nextEmailAt!)) {
        throw const AccountFailure(
          'Tunggu satu menit sebelum mengirim email masuk lagi.',
        );
      }
      await gateway.requestEmailLogin(email, createAccount: isRegistering);
      if (_disposed) return;
      nextEmailAt = DateTime.now().add(const Duration(seconds: 60));
      step = AccountStep.emailSent;
    });
  }

  Future<void> verify(String code) async {
    await _run(() async {
      if (!RegExp(r'^\d{6,10}$').hasMatch(code.trim())) {
        throw const AccountFailure('Masukkan kode angka dari emailmu.');
      }
      await gateway.verifyEmailCode(email, code.trim());
      if (!_disposed) user = gateway.current;
    });
  }

  Future<void> startGoogle({bool campus = false}) async {
    await _run(() async {
      if (providers?.google != true) {
        throw const AccountFailure(
          'Login Google belum diaktifkan untuk Daniel Apps.',
        );
      }
      await gateway.signInGoogle(
        emailHint: validEmail(email) ? email : null,
        campus: campus,
      );
      if (!_disposed) step = AccountStep.redirecting;
    });
  }

  Future<void> startUb() async {
    await _run(() async {
      if (!isUbEmail(email) || providers?.ubSso != true) {
        throw const AccountFailure('SSO UB untuk Daniel Apps belum tersedia.');
      }
      await gateway.signInUb(email.split('@').last);
      if (!_disposed) step = AccountStep.redirecting;
    });
  }

  Future<bool> saveName(String name) => _run(() async {
    final normalized = name.trim();
    if (normalized.isEmpty || normalized.length > 80) {
      throw const AccountFailure('Nama harus diisi, maksimal 80 karakter.');
    }
    await gateway.updateName(normalized);
    if (!_disposed) user = gateway.current;
  });

  Future<void> signOut() => _run(() async {
    await gateway.signOut();
    if (_disposed) return;
    user = null;
    email = '';
    step = AccountStep.email;
    nextEmailAt = null;
    intent = AccountIntent.signIn;
  });

  void changeEmail() {
    if (busy || _disposed) return;
    step = AccountStep.email;
    error = null;
    notifyListeners();
  }

  void clearEmailError() {
    if (_disposed || emailError == null) return;
    emailError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}

class AccountScope extends InheritedNotifier<AccountController> {
  const AccountScope({
    super.key,
    required AccountController controller,
    required super.child,
  }) : super(notifier: controller);
  static AccountController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccountScope>()?.notifier;
  static AccountController of(BuildContext context) => maybeOf(context)!;
}
