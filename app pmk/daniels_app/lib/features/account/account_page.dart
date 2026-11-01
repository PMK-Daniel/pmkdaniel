import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'account_controller.dart';
import 'account_auth_form.dart';
import '../settings/settings_page.dart' show confirmSignOut;

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
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondary,
          foregroundColor: AppTheme.primaryDark,
          child: Text(
            user?.name.trim().isNotEmpty == true
                ? user!.name.trim().characters.first.toUpperCase()
                : 'D',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          user == null
              ? 'Masuk ke Daniel Apps'
              : (user.name.isEmpty ? 'Akun Daniel Apps' : user.name),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          user == null
              ? 'Gunakan email kampus atau email pribadi.'
              : 'Lihat dan edit profil',
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
    if (account.user == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: SafeArea(
          child: AccountAuthForm(
            key: ValueKey(account.intent),
            account: account,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(onboarding ? 'Lengkapi profil' : 'Profil saya'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: _ProfileForm(account: account, onboarding: onboarding),
        ),
      ),
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
  bool _leaving = false;
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
    final dirty = _name.text.trim() != user.name.trim();
    return PopScope(
      canPop: !dirty || _leaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _leaving) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Abaikan perubahan?'),
            content: const Text(
              'Nama panggilan yang kamu ubah belum disimpan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Lanjut edit'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Abaikan'),
              ),
            ],
          ),
        );
        if (discard == true && mounted) {
          setState(() => _leaving = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.warmSurface,
              foregroundColor: AppTheme.primaryDark,
              child: Text(
                user.name.trim().isEmpty
                    ? 'D'
                    : user.name.trim().characters.first.toUpperCase(),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.onboarding ? 'Kamu ingin\ndisapa siapa?' : 'Profilmu',
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
          const Text(
            'Nama ini digunakan untuk menyapamu di Home.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            enabled: !a.busy,
            textCapitalization: TextCapitalization.words,
            maxLength: 80,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Nama panggilan'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: a.busy || (!dirty && !widget.onboarding)
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
            onPressed: a.busy ? null : () => confirmSignOut(context),
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Keluar dari perangkat ini'),
          ),
        ],
      ),
    );
  }
}
