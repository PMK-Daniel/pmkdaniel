import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'app_links.dart';
import '../settings/settings_page.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});
  @override
  Widget build(BuildContext context) => SettingsLayout(
    title: 'Friend',
    children: [
      const SizedBox(height: 12),
      const Align(
        alignment: Alignment.centerLeft,
        child: CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.warmSurface,
          child: Icon(
            Icons.people_outline_rounded,
            size: 40,
            color: AppTheme.secondaryDark,
          ),
        ),
      ),
      const SizedBox(height: 28),
      const Text(
        'Bertemu lewat komunitas',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.3,
          color: AppTheme.primaryDark,
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'Direktori teman belum dibuka. Untuk saat ini, kenali kegiatan dan komunitas melalui Web PMK.',
        style: TextStyle(fontSize: 16, height: 1.8),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: () => AppLinks.openWebsite(context),
        icon: const Icon(Icons.open_in_new, size: 18),
        label: const Text('Lihat kegiatan PMK'),
      ),
      const SizedBox(height: 32),
      const Divider(),
      const SettingsHeading('Profilmu belum dipublikasikan'),
      const Text(
        'Nama dan email akunmu tidak otomatis menjadi profil publik di Friend. Belum ada pencarian anggota, permintaan pertemanan, atau percakapan di versi ini.',
        style: TextStyle(color: AppTheme.textSecondary, height: 1.8),
      ),
    ],
  );
}
