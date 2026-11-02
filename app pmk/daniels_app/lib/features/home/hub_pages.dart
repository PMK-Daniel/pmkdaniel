import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../community/personal_list.dart';
import '../equipping/circle_page.dart';
import '../equipping/circle_group_page.dart';
import 'app_links.dart';
import '../settings/settings_page.dart';

const friendsListConfig = PersonalListConfig(
  kind: 'friends',
  heading: 'Daftar teman',
  addLabel: 'Tambah teman',
  titleLabel: 'Nama teman',
  noteLabel:
      'Catatan (opsional): apa yang ingin kamu doakan atau tindak lanjuti',
  doneLabel: 'Sudah dihubungi',
  activeLabel: 'Perlu dihubungi',
  completedLabel: 'Sudah dihubungi',
  emptyText:
      'Belum ada teman di daftar. Tambahkan seseorang yang ingin kamu doakan, hubungi, atau ajak bergabung ke Circle.',
);

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});
  @override
  Widget build(BuildContext context) => SettingsLayout(
    title: 'Friend',
    children: [
      const SizedBox(height: 4),
      Semantics(
        header: true,
        child: const Text(
          'Teman perjalananmu',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: AppTheme.primaryDark,
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Catat teman yang ingin kamu doakan, hubungi, atau ajak bertumbuh bersama. Daftar ini milikmu sendiri dan belum terhubung dengan akun anggota lain.',
        style: TextStyle(fontSize: 16, height: 1.7),
      ),
      const SizedBox(height: 20),
      const PersonalListSection(config: friendsListConfig),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.warmSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.groups_2_rounded, color: AppTheme.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kelompok Circle-mu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Siapkan pertemuan bersama: materi, jadwal, dan pengingat untuk kelompokmu.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CircleGroupPage(
                    lessonBuilder: (lesson, catalog, progress) =>
                        CircleLessonPage(
                          lesson: lesson,
                          catalog: catalog,
                          progress: progress,
                        ),
                  ),
                ),
              ),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Buka kelompokku'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      const Divider(),
      const SettingsHeading('Kenali komunitas'),
      const Text(
        'Direktori anggota, permintaan pertemanan, dan percakapan belum tersedia. Kegiatan dan komunitas PMK dapat dilihat di Web PMK.',
        style: TextStyle(color: AppTheme.textSecondary, height: 1.7),
      ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => AppLinks.openWebsite(context),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Lihat kegiatan PMK'),
        ),
      ),
    ],
  );
}
