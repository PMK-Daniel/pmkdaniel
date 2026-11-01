import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'app_links.dart';

enum SupportKind {
  prayer(
    'Dukungan doa',
    'dukungan-doa',
    'Kamu tidak harus\nbergumul sendiri.',
    'Ada hal yang sedang kamu doakan? Ruang ini disiapkan untuk saling menopang dalam doa.',
    'Pokok doa yang ingin dibagikan',
    'Hal yang ingin didoakan bersama',
    'Batas informasi yang nyaman kamu ceritakan',
  ),
  spiritual(
    'Konsultasi Rohani',
    'konsultasi-rohani',
    'Ada ruang\nuntuk bercerita.',
    'Pertanyaan tentang iman, relasi, atau pelayanan layak didengarkan. Ruang ini disiapkan untuk percakapan dengan pendamping rohani.',
    'Topik yang ingin kamu bicarakan',
    'Pertanyaan yang ingin kamu tanyakan',
    'Waktu yang nyaman untuk berbincang',
  ),
  academic(
    'Dukungan akademik',
    'dukungan-akademik',
    'Kuliah juga\nbisa dijalani bersama.',
    'Kesulitan memahami materi atau mengatur waktu belajar? Ruang ini disiapkan untuk dukungan belajar antar mahasiswa.',
    'Mata kuliah atau materi yang menantang',
    'Bantuan belajar yang kamu perlukan',
    'Waktu belajar yang cocok untukmu',
  );

  final String label, asset, title, description, first, second, third;
  const SupportKind(
    this.label,
    this.asset,
    this.title,
    this.description,
    this.first,
    this.second,
    this.third,
  );
}

class SupportPage extends StatelessWidget {
  final SupportKind kind;
  const SupportPage({super.key, required this.kind});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(kind.label)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/icons/flat-v2/${kind.asset}.png',
                width: 88,
                height: 88,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              kind.title,
              style: const TextStyle(
                fontSize: 30,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              kind.description,
              style: const TextStyle(fontSize: 16, height: 1.8),
            ),
            const SizedBox(height: 28),
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
                    'Layanan sedang disiapkan',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Permintaan belum bisa dikirim melalui aplikasi. Belum ada penerima atau jadwal pendampingan yang ditetapkan di sini.',
                    style: TextStyle(height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Sambil mempersiapkan diri',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            for (final text in [kind.first, kind.second, kind.third])
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.notes_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(text, style: const TextStyle(height: 1.6)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => AppLinks.openWebsite(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Buka Web PMK'),
            ),
          ],
        ),
      ),
    ),
  );
}
