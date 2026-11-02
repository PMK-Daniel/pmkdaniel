import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'account_controller.dart';
import 'account_gateway.dart';

class AccountAuthForm extends StatefulWidget {
  final AccountController account;
  const AccountAuthForm({super.key, required this.account});
  @override
  State<AccountAuthForm> createState() => _AccountAuthFormState();
}

class _AccountAuthFormState extends State<AccountAuthForm> {
  final _email = TextEditingController(), _code = TextEditingController();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _email.text = widget.account.email;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.account.step == AccountStep.emailSent) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  int get _remaining {
    final deadline = widget.account.nextEmailAt;
    return deadline == null
        ? 0
        : ((deadline.difference(DateTime.now()).inMilliseconds / 1000).ceil())
              .clamp(0, 60);
  }

  ButtonStyle get _providerStyle => OutlinedButton.styleFrom(
    minimumSize: const Size(48, 50),
    backgroundColor: Colors.white,
    foregroundColor: AppTheme.textPrimary,
    side: const BorderSide(color: Color(0xFF747775)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
  );
  Widget _emailField(AccountController a) => Semantics(
    container: true,
    child: TextField(
      controller: _email,
      enabled: !a.busy,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      textCapitalization: TextCapitalization.none,
      onChanged: (_) => a.clearEmailError(),
      onSubmitted: a.busy || a.loadingProviders ? null : a.continueWithEmail,
      decoration: InputDecoration(
        labelText: 'Alamat email',
        hintText: 'nama@contoh.com',
        prefixIcon: const Icon(Icons.mail_outline, size: 20),
        filled: true,
        fillColor: Colors.white,
        errorText: a.emailError,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF89899B)),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final a = widget.account;
    final signup = a.isRegistering;
    final sent = a.step == AccountStep.emailSent,
        campus = a.step == AccountStep.campusUnavailable,
        redirecting = a.step == AccountStep.redirecting;
    final initial = !sent && !campus && !redirecting;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            if (Navigator.canPop(context))
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Kembali',
                  color: AppTheme.primaryDark,
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
            const Text(
              'Daniel Apps',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Image.asset(
                'assets/images/logo_pmk.png',
                width: 108,
                height: 108,
                semanticLabel: 'PMK Daniel',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tumbuh bersama, setiap hari.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.secondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E2EF)),
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: Semantics(
                explicitChildNodes: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      sent
                          ? (signup ? 'Verifikasi emailmu' : 'Cek emailmu')
                          : campus
                          ? 'Login student belum tersedia'
                          : redirecting
                          ? 'Lanjutkan di browser'
                          : signup
                          ? 'Buat akun'
                          : 'Selamat datang kembali',
                      style: const TextStyle(
                        fontSize: 23,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sent
                          ? 'Buka tautan yang dikirim ke ${a.email}. Jika email berisi kode, masukkan di bawah.'
                          : campus
                          ? 'Login UB melalui Google belum diaktifkan di Daniel Apps. Kamu tetap bisa masuk lewat tautan email.'
                          : redirecting
                          ? 'Selesaikan proses di penyedia akun. Setelah berhasil, kamu akan kembali ke Daniel Apps.'
                          : signup
                          ? 'Daftarkan emailmu, lalu verifikasi untuk membaca dan menyimpan perjalanan Circle-mu.'
                          : 'Masuk dengan email yang sudah terdaftar. Tautan masuk akan dikirim tanpa password.',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.7,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (a.loadingProviders) const LinearProgressIndicator(),
                    if (initial) ...[
                      AutofillGroup(child: _emailField(a)),
                      const SizedBox(height: 14),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: a.busy || a.loadingProviders
                            ? null
                            : () => a.continueWithEmail(_email.text),
                        child: Text(
                          a.busy
                              ? 'Mengirim…'
                              : signup
                              ? 'Kirim tautan pendaftaran'
                              : 'Kirim tautan masuk',
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'atau lanjut dengan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        style: _providerStyle,
                        onPressed:
                            a.busy ||
                                a.loadingProviders ||
                                a.providers?.google != true
                            ? null
                            : () {
                                a.email = '';
                                a.startGoogle();
                              },
                        icon: Image.asset(
                          'assets/logos/google-g.png',
                          width: 20,
                          height: 20,
                          excludeFromSemantics: true,
                        ),
                        label: const Text('Lanjut dengan Google'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: _providerStyle.copyWith(
                          backgroundColor: const WidgetStatePropertyAll(
                            AppTheme.warmSurface,
                          ),
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.disabled)
                                ? AppTheme.textMuted
                                : AppTheme.secondaryDark,
                          ),
                          side: const WidgetStatePropertyAll(
                            BorderSide(color: AppTheme.secondaryDark),
                          ),
                        ),
                        onPressed: a.busy || a.loadingProviders
                            ? null
                            : () => a.continueWithCampus(_email.text),
                        icon: const Icon(Icons.school_outlined, size: 19),
                        label: const Text('Login dengan akun student'),
                      ),
                      if (a.providers != null && !a.providers!.google)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'Google dan UB belum tersedia. Gunakan email di atas.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.6,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          Text(
                            signup ? 'Sudah punya akun?' : 'Belum punya akun?',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: a.busy
                                ? null
                                : () => a.setIntent(
                                    signup
                                        ? AccountIntent.signIn
                                        : AccountIntent.signUp,
                                  ),
                            child: Text(signup ? 'Masuk' : 'Buat akun'),
                          ),
                        ],
                      ),
                    ],
                    if (campus && validEmail(a.email))
                      FilledButton(
                        onPressed: a.busy || a.providers?.email != true
                            ? null
                            : a.sendEmail,
                        child: Text(
                          signup
                              ? 'Kirim tautan pendaftaran'
                              : 'Kirim tautan ke email UB',
                        ),
                      ),
                    if (sent) ...[
                      TextField(
                        controller: _code,
                        enabled: !a.busy,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Kode dari email, jika tersedia',
                          hintText: 'Masukkan kode angka',
                        ),
                        onSubmitted: a.busy ? null : a.verify,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: a.busy ? null : () => a.verify(_code.text),
                        child: Text(a.busy ? 'Memeriksa…' : 'Verifikasi kode'),
                      ),
                      TextButton(
                        onPressed: a.busy || _remaining > 0
                            ? null
                            : a.sendEmail,
                        child: Text(
                          _remaining > 0
                              ? 'Kirim ulang dalam $_remaining detik'
                              : 'Kirim ulang email',
                        ),
                      ),
                    ],
                    if (!initial)
                      TextButton(
                        onPressed: a.busy
                            ? null
                            : () {
                                _code.clear();
                                a.changeEmail();
                              },
                        child: const Text('Ubah email atau cara masuk'),
                      ),
                    if (a.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            a.error!,
                            style: const TextStyle(
                              color: Color(0xFF9D2632),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    if (a.providers == null && !a.loadingProviders)
                      OutlinedButton.icon(
                        onPressed: a.loadProviders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba hubungkan lagi'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
