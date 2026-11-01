import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'account_controller.dart';
import 'account_gateway.dart';

void openAccount(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const AccountPage()));
}

class AccountEntry extends StatelessWidget {
  const AccountEntry({super.key});
  @override
  Widget build(BuildContext context) {
    final account = AccountScope.maybeOf(context);
    final user = account?.user;
    return Material(
      color: AppTheme.primarySurface,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: const Icon(
          Icons.account_circle_outlined,
          color: AppTheme.primary,
          size: 32,
        ),
        title: Text(
          user == null
              ? 'Masuk atau daftar'
              : (user.name.isEmpty ? 'Akun Daniel Apps' : user.name),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          user?.email ?? 'Gunakan email kampus atau email pribadi.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: account == null ? null : () => openAccount(context),
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  final bool onboarding;
  const AccountPage({super.key, this.onboarding = false});
  @override
  Widget build(BuildContext context) {
    final account = AccountScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(onboarding ? 'Lengkapi profil' : 'Akun Daniel Apps'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: account.user == null
              ? _LoginForm(account: account)
              : _ProfileForm(account: account, onboarding: onboarding),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  final AccountController account;
  const _LoginForm({required this.account});
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
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
    if (deadline == null) return 0;
    return ((deadline.difference(DateTime.now()).inMilliseconds / 1000).ceil())
        .clamp(0, 60);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.account;
    final sent = a.step == AccountStep.emailSent;
    final campus = a.step == AccountStep.campusUnavailable;
    final redirecting = a.step == AccountStep.redirecting;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            'assets/images/logo_pmk.png',
            width: 56,
            height: 56,
            semanticLabel: 'PMK Daniel',
          ),
        ),
        const SizedBox(height: 26),
        Text(
          sent
              ? 'Cek emailmu.'
              : campus
              ? 'Masuk dengan\nemail UB.'
              : redirecting
              ? 'Selesaikan login\ndi browser.'
              : 'Masuk ke\nDaniel Apps.',
          style: const TextStyle(
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          sent
              ? 'Buka tautan masuk yang dikirim ke ${a.email}. Jika emailmu juga berisi kode, masukkan kodenya di bawah.'
              : campus
              ? '${a.email.isEmpty ? '' : '${a.email}\n\n'}Login UB melalui Google belum diaktifkan di Daniel Apps. Kamu tetap bisa masuk lewat tautan email.'
              : redirecting
              ? 'Lanjutkan di halaman penyedia akun. Setelah berhasil, kamu akan kembali ke Daniel Apps.'
              : 'Masuk atau daftar menggunakan email kampus maupun pribadi. Tidak perlu membuat password baru.',
          style: const TextStyle(
            fontSize: 15,
            height: 1.75,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 26),
        if (a.loadingProviders) const LinearProgressIndicator(),
        if (!sent && !campus && !redirecting) ...[
          AutofillGroup(
            child: TextField(
              controller: _email,
              enabled: !a.busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              onChanged: (_) {
                a.clearEmailError();
                setState(() {});
              },
              onSubmitted: a.busy || a.loadingProviders
                  ? null
                  : (value) => a.continueWithEmail(value),
              decoration: InputDecoration(
                labelText: 'Alamat email',
                hintText: 'nama@student.ub.ac.id',
                errorText: a.emailError,
              ),
            ),
          ),
          if (validEmail(normalizeEmail(_email.text)) && isUbEmail(_email.text))
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Email UB dapat digunakan untuk tautan email atau login kampus melalui Google.',
                style: TextStyle(
                  color: AppTheme.primary,
                  height: 1.6,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: a.busy || a.loadingProviders
                ? null
                : () => a.continueWithEmail(_email.text),
            child: Text(a.busy ? 'Memproses…' : 'Lanjut dengan email'),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed:
                a.busy || a.loadingProviders || a.providers?.google != true
                ? null
                : () {
                    a.email = '';
                    a.startGoogle();
                  },
            icon: const Icon(Icons.login, size: 20),
            label: const Text('Lanjut dengan Google'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: a.busy || a.loadingProviders
                ? null
                : () => a.continueWithCampus(_email.text),
            icon: const Icon(Icons.school_outlined, size: 20),
            label: const Text('Universitas Brawijaya'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Login UB melalui Google. Kamu bisa mengisi email kampus di atas untuk mempercepat pemilihan akun.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          if (a.providers != null && !a.providers!.google)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Login Google dan UB melalui Google belum aktif. Gunakan tautan email untuk sementara.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
        ],
        if (campus && validEmail(a.email)) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.warmSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Login melalui email hanya memverifikasi kepemilikan email. Ini berbeda dari login SSO kampus.',
              style: TextStyle(height: 1.7),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: a.busy || a.providers?.email != true
                ? null
                : a.sendEmail,
            child: Text(a.busy ? 'Mengirim…' : 'Kirim tautan ke email UB'),
          ),
        ],
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
            onSubmitted: a.busy ? null : (value) => a.verify(value),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: a.busy ? null : () => a.verify(_code.text),
            child: Text(a.busy ? 'Memeriksa…' : 'Verifikasi kode'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: a.busy || _remaining > 0 ? null : a.sendEmail,
            child: Text(
              _remaining > 0
                  ? 'Kirim ulang dalam $_remaining detik'
                  : 'Kirim ulang email masuk',
            ),
          ),
        ],
        if (sent || campus || redirecting)
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
            padding: const EdgeInsets.only(top: 16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                a.error!,
                style: const TextStyle(color: Color(0xFF9D2632), height: 1.7),
              ),
            ),
          ),
        if (!a.loadingProviders && a.providers == null)
          TextButton.icon(
            onPressed: a.loadProviders,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba hubungkan lagi'),
          ),
        const SizedBox(height: 24),
        const Text(
          'Belum punya akun? Gunakan salah satu cara di atas untuk mendaftar. Akun email dapat digunakan setelah verifikasi berhasil.',
          style: TextStyle(
            fontSize: 12,
            height: 1.7,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ProfileForm extends StatefulWidget {
  final AccountController account;
  final bool onboarding;
  const _ProfileForm({required this.account, this.onboarding = false});
  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final TextEditingController _name = TextEditingController(
    text: widget.account.user!.name,
  );
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.account, user = a.user!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(
          Icons.account_circle_outlined,
          color: AppTheme.primary,
          size: 64,
        ),
        const SizedBox(height: 24),
        Text(
          widget.onboarding
              ? 'Kamu ingin\ndisapa siapa?'
              : (user.name.isEmpty ? 'Profilmu' : 'Hai, ${user.name}!'),
          style: const TextStyle(
            fontSize: 28,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(user.email, style: const TextStyle(height: 1.6)),
        const SizedBox(height: 8),
        Text(
          user.emailVerified
              ? (user.hasUbEmail
                    ? 'Email UB terverifikasi'
                    : 'Email terverifikasi')
              : 'Email belum terverifikasi',
          style: const TextStyle(color: AppTheme.primary, height: 1.6),
        ),
        if (user.hasUbEmail)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Verifikasi email tidak membuktikan status mahasiswa aktif.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.6,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 30),
        TextField(
          controller: _name,
          enabled: !a.busy,
          textCapitalization: TextCapitalization.words,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Nama panggilan'),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: a.busy
              ? null
              : () async {
                  if (await a.saveName(_name.text) && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil berhasil disimpan.'),
                      ),
                    );
                  }
                },
          child: Text(
            a.busy
                ? 'Memproses…'
                : widget.onboarding
                ? 'Simpan dan masuk'
                : 'Simpan profil',
          ),
        ),
        if (a.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                a.error!,
                style: const TextStyle(color: Color(0xFF9D2632), height: 1.7),
              ),
            ),
          ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(44, 48)),
          onPressed: a.busy ? null : a.signOut,
          icon: const Icon(Icons.logout, size: 20),
          label: const Text('Keluar dari perangkat ini'),
        ),
      ],
    );
  }
}
