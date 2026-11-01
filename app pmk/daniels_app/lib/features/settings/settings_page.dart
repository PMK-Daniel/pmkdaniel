import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../account/account_controller.dart';
import '../account/account_page.dart';
import '../home/app_links.dart';
import 'app_preferences.dart';

Future<void> confirmSignOut(BuildContext context) async {
  final account = AccountScope.maybeOf(context);
  if (account == null || account.busy) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Keluar dari akun?'),
      content: const Text(
        'Kamu perlu masuk lagi untuk menggunakan aplikasi. Catatan Circle tetap tersimpan di perangkat ini.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Keluar'),
        ),
      ],
    ),
  );
  if (confirmed == true) await account.signOut();
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final a = AccountScope.maybeOf(context);
    return SettingsLayout(
      title: 'Settings',
      children: [
        const AccountEntry(),
        const SettingsHeading('Preferensi'),
        SettingsRow(
          icon: Icons.text_fields_rounded,
          title: 'Tampilan & aksesibilitas',
          subtitle: 'Ukuran teks dan gerakan',
          onTap: () => _open(context, const AppearancePage()),
        ),
        SettingsRow(
          icon: Icons.notifications_outlined,
          title: 'Notifikasi',
          subtitle: 'Pengingat otomatis belum tersedia',
          onTap: () => _open(
            context,
            const SettingsInfoPage(
              title: 'Notifikasi',
              icon: Icons.notifications_none_rounded,
              sections: [
                (
                  'Belum ada pengingat otomatis',
                  'Daniel Apps saat ini belum mengirim notifikasi renungan, Circle, atau pesan. Tidak ada izin notifikasi yang perlu kamu aktifkan.',
                ),
                (
                  'Email akun',
                  'Tautan masuk dan verifikasi dikirim saat kamu memintanya. Email ini digunakan untuk mengakses akun, bukan langganan pengingat.',
                ),
              ],
            ),
          ),
        ),
        const SettingsHeading('Akun & privasi'),
        SettingsRow(
          icon: Icons.person_outline_rounded,
          title: 'Edit profil',
          subtitle: 'Nama panggilan dan email akun',
          onTap: () => openAccount(context),
        ),
        SettingsRow(
          icon: Icons.lock_outline_rounded,
          title: 'Keamanan akun',
          subtitle: 'Cara masuk dan keluar dari perangkat',
          onTap: () => _open(context, const SecurityPage()),
        ),
        SettingsRow(
          icon: Icons.privacy_tip_outlined,
          title: 'Privasi & penyimpanan',
          subtitle: 'Ketahui lokasi data dan siapa yang melihatnya',
          onTap: () => _open(
            context,
            const SettingsInfoPage(
              title: 'Privasi & penyimpanan',
              icon: Icons.privacy_tip_outlined,
              sections: [
                (
                  'Data akun',
                  'Email dan nama panggilan tersimpan pada layanan akun Daniel Apps. Email tidak ditampilkan sebagai direktori anggota di aplikasi.',
                ),
                (
                  'Catatan dan progres Circle',
                  'Tersimpan di browser atau perangkat ini, terpisah untuk setiap akun. Belum disinkronkan ke perangkat lain dan belum dibagikan kepada fasilitator. Menghapus data browser dapat menghilangkan catatan ini.',
                ),
                (
                  'Friend dan layanan dukungan',
                  'Direktori teman dan pengiriman permintaan belum aktif. Aplikasi tidak menerbitkan profil atau mengirim pokok doa secara otomatis.',
                ),
                (
                  'Pengaturan perangkat',
                  'Ukuran teks dan pengurangan gerakan berlaku untuk perangkat ini, termasuk setelah berganti akun.',
                ),
              ],
            ),
          ),
        ),
        const SettingsHeading('Bantuan & informasi'),
        SettingsRow(
          icon: Icons.help_outline_rounded,
          title: 'Pusat bantuan',
          subtitle: 'Masuk, membaca, dan menyimpan progres',
          onTap: () => _open(context, const HelpPage()),
        ),
        SettingsRow(
          icon: Icons.info_outline_rounded,
          title: 'Tentang Daniel Apps',
          subtitle: 'PMK Daniel FILKOM UB',
          onTap: () => _open(context, const AboutPage()),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: a == null || a.busy ? null : () => confirmSignOut(context),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: Text(a?.busy == true ? 'Memproses…' : 'Keluar dari akun'),
        ),
        if (a?.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              a!.error!,
              style: const TextStyle(color: Color(0xFF9D2632)),
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Daniel Apps · PMK Daniel FILKOM UB',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

void _open(BuildContext context, Widget page) =>
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

class SettingsLayout extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SettingsLayout({
    super.key,
    required this.title,
    required this.children,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: children,
        ),
      ),
    ),
  );
}

class SettingsHeading extends StatelessWidget {
  final String label;
  const SettingsHeading(this.label, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 28, 0, 10),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppTheme.primaryDark,
      ),
    ),
  );
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        leading: Icon(icon, size: 23),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 22),
        onTap: onTap,
      ),
      const Divider(height: 1),
    ],
  );
}

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});
  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesScope.maybeOf(context);
    return SettingsLayout(
      title: 'Tampilan & aksesibilitas',
      children: [
        const Text(
          'Nyaman untukmu',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Text(
          'Perubahan langsung berlaku di aplikasi dan tersimpan pada perangkat ini.',
          style: TextStyle(height: 1.6),
        ),
        const SettingsHeading('Ukuran teks'),
        for (final option in [
          (1.0, 'Standar'),
          (1.15, 'Besar'),
          (1.3, 'Lebih besar'),
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(option.$2),
            leading: Icon(
              prefs?.textScale == option.$1
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            selected: prefs?.textScale == option.$1,
            onTap: prefs == null || prefs.saving
                ? null
                : () => prefs.update(scale: option.$1),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.warmSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pratinjau bacaan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'Sediakan waktu untuk membaca, merenungkan, dan bertumbuh bersama.',
                style: TextStyle(fontSize: 17, height: 1.8),
              ),
            ],
          ),
        ),
        const SettingsHeading('Gerakan'),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Kurangi gerakan'),
          subtitle: const Text('Hilangkan animasi perpindahan halaman.'),
          value: prefs?.reduceMotion ?? false,
          onChanged: prefs == null || prefs.saving
              ? null
              : (value) => prefs.update(motion: value),
        ),
        if (prefs?.error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              prefs!.error!,
              style: const TextStyle(color: Color(0xFF9D2632)),
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Pengaturan aksesibilitas perangkat tetap dihormati. Ukuran teks aplikasi menambah pembesaran dari sistem.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
        ),
      ],
    );
  }
}

class SettingsInfoPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String, String)> sections;
  const SettingsInfoPage({
    super.key,
    required this.title,
    required this.icon,
    required this.sections,
  });
  @override
  Widget build(BuildContext context) => SettingsLayout(
    title: title,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.warmSurface,
          child: Icon(icon, color: AppTheme.secondaryDark, size: 28),
        ),
      ),
      for (final section in sections) ...[
        SettingsHeading(section.$1),
        SelectableText(
          section.$2,
          style: const TextStyle(fontSize: 15, height: 1.8),
        ),
      ],
    ],
  );
}

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});
  @override
  Widget build(BuildContext context) {
    final a = AccountScope.maybeOf(context);
    return SettingsLayout(
      title: 'Keamanan akun',
      children: [
        const SettingsHeading('Email akun'),
        SelectableText(
          a?.user?.email ?? 'Belum masuk',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          a?.user?.emailVerified == true
              ? 'Email terverifikasi'
              : 'Email belum terverifikasi',
        ),
        const SettingsHeading('Cara masuk'),
        const Text(
          'Email menggunakan tautan masuk sekali pakai. Google dan akun student menggunakan halaman penyedia akun. Daniel Apps tidak meminta password Google atau UB.',
          style: TextStyle(height: 1.8),
        ),
        const SettingsHeading('Perangkat bersama'),
        const Text(
          'Keluar setelah selesai. Catatan Circle tersimpan di perangkat ini; gunakan perangkat pribadi untuk menulis refleksi pribadi.',
          style: TextStyle(height: 1.8),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: a == null || a.busy ? null : () => confirmSignOut(context),
          icon: const Icon(Icons.logout),
          label: const Text('Keluar dari perangkat ini'),
        ),
        if (a?.error != null)
          Text(a!.error!, style: const TextStyle(color: Color(0xFF9D2632))),
      ],
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext context) => SettingsLayout(
    title: 'Pusat bantuan',
    children: [
      const Text(
        'Apa yang perlu dibantu?',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 20),
      for (final item in const [
        (
          'Tautan masuk belum diterima',
          'Periksa alamat email dan folder spam. Tunggu jeda kirim ulang pada halaman masuk, kemudian minta tautan baru. Jika baru pertama kali, pilih Buat akun.',
        ),
        (
          'Masuk dengan akun student',
          'Pilih Login dengan akun student. Proses berjalan melalui Google, lalu mengikuti pengaturan login universitas. Email UB tidak otomatis membuktikan status mahasiswa aktif.',
        ),
        (
          'Catatan Circle tidak ada di perangkat lain',
          'Catatan dan progres saat ini tersimpan lokal. Buka perangkat tempat kamu menyimpannya. Sinkronisasi antarperangkat belum tersedia.',
        ),
        (
          'Membaca materi Circle',
          'Pilih fase atau cari judul pertemuan. Di dalamnya tersedia Materi, Diskusi, dan Panduan kakak. Dokumen asli tersedia melalui tombol PDF pada versi web.',
        ),
        (
          'Friend dan dukungan belum bisa digunakan',
          'Pengiriman permintaan dan direktori anggota belum dibuka. Informasi komunitas yang tersedia dapat dilihat melalui Web PMK.',
        ),
      ])
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(item.$1),
          childrenPadding: const EdgeInsets.fromLTRB(0, 0, 8, 20),
          children: [Text(item.$2, style: const TextStyle(height: 1.8))],
        ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: () => AppLinks.openWebsite(context),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Buka Web PMK'),
      ),
    ],
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => SettingsLayout(
    title: 'Tentang aplikasi',
    children: [
      Image.asset(
        'assets/images/logo_pmk.png',
        width: 100,
        height: 100,
        semanticLabel: 'Logo PMK Daniel',
      ),
      const SizedBox(height: 20),
      const Text(
        'Daniel Apps',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryDark,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'PMK Daniel FILKOM UB\nTogether to be Better.',
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.8),
      ),
      const SettingsHeading('Ruang bertumbuh bersama'),
      const Text(
        'Bacaan, materi Daniel Circle, dan informasi komunitas dalam satu aplikasi. Materi Circle mengikuti sumber Daniel Circle; status ketersediaan layanan ditampilkan pada tiap halaman.',
        style: TextStyle(height: 1.8),
      ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: () => AppLinks.openWebsite(context),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Kunjungi Web PMK'),
      ),
      TextButton(
        onPressed: () =>
            showLicensePage(context: context, applicationName: 'Daniel Apps'),
        child: const Text('Lisensi perangkat lunak'),
      ),
    ],
  );
}
