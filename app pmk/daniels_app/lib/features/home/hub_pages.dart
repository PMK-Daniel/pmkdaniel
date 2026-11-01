import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'app_links.dart';
import '../account/account_page.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Friend')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(28),
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 72,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Iman tumbuh\ndalam kebersamaan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Ruang pertemanan sedang disiapkan. Nantinya kamu dapat menemukan teman dan terhubung dengan komunitas PMK.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 24),
            const AccountEntry(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => AppLinks.openWebsite(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Kenali PMK Daniel'),
            ),
          ],
        ),
      ),
    ),
  );
}

class HubSettingsPage extends StatelessWidget {
  final VoidCallback onCloudSettings, onInterview, onVisualisasi;
  const HubSettingsPage({
    super.key,
    required this.onCloudSettings,
    required this.onInterview,
    required this.onVisualisasi,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Atur ruang pelayananmu',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Koneksi dan alat pengurus tersedia di sini.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        const AccountEntry(),
        const SizedBox(height: 24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cloud_outlined),
          title: const Text('Pengaturan ruang & cloud'),
          subtitle: const Text('Koneksi dan ruang interview'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onCloudSettings,
        ),
        const Divider(height: 32),
        const Text(
          'Alat pelayanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.assignment_outlined),
          title: const Text('List Interview'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onInterview,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.insights_outlined),
          title: const Text('Visualisasi'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onVisualisasi,
        ),
        const Divider(height: 32),
        const Text(
          'Daniels App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'PMK Daniel FILKOM UB\nTogether to be Better.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
        ),
      ],
    ),
  );
}
