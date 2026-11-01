import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'growth_content.dart';
import 'support_page.dart';

class GrowthHome extends StatelessWidget {
  final VoidCallback onOpenBible;
  final Future<List<NewsArticle>> Function()? newsLoader;
  final String? displayName;
  const GrowthHome({
    super.key,
    required this.onOpenBible,
    this.newsLoader,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Material(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/community.webp',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xB32B2C6E), Color(0xF22B2C6E)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bertumbuh dengan\nsaling menguatkan',
                    style: TextStyle(
                      fontSize: 30,
                      height: 1.22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Ambil waktu sejenak untuk firman,\nrefleksi, dan langkah kecil hari ini.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => openPage(
                      context,
                      ReflectionPage(reflection: reflectionPreviews.first),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: AppTheme.primaryDark,
                    ),
                    child: const Text(
                      'Baca renungan',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1 Tesalonika 5:11 · Contoh renungan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      Text(
        displayName == null || displayName!.isEmpty
            ? 'Shalom, Daniels!'
            : 'Shalom, $displayName!',
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryDark,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Ruang untuk iman, pertemanan, dan perjalanan kuliahmu.',
        style: TextStyle(
          color: AppTheme.textSecondary,
          height: 1.6,
          fontSize: 13,
        ),
      ),
      const SizedBox(height: 22),
      LayoutBuilder(
        builder: (context, constraints) {
          final scaled = MediaQuery.textScalerOf(context).scale(13) / 13;
          final columns = scaled > 1.35
              ? (constraints.maxWidth < 500 ? 2 : 3)
              : (constraints.maxWidth >= 760 ? 6 : 3);
          final entries = <(String, String, VoidCallback)>[
            (
              'renungan',
              'Renungan',
              () => openPage(context, const ReflectionArchivePage()),
            ),
            ('alkitab', 'Alkitab', onOpenBible),
            (
              'pembekalan',
              'Pembekalan',
              () => openPage(context, const EquippingPage()),
            ),
            (
              'dukungan-doa',
              'Dukungan doa',
              () => openPage(
                context,
                const SupportPage(kind: SupportKind.prayer),
              ),
            ),
            (
              'konsultasi-rohani',
              'Konsultasi Rohani',
              () => openPage(
                context,
                const SupportPage(kind: SupportKind.spiritual),
              ),
            ),
            (
              'dukungan-akademik',
              'Dukungan akademik',
              () => openPage(
                context,
                const SupportPage(kind: SupportKind.academic),
              ),
            ),
          ];
          return Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final entry in entries)
                SizedBox(
                  width: (constraints.maxWidth - (columns - 1) * 10) / columns,
                  child: FeatureLauncher(
                    asset: entry.$1,
                    label: entry.$2,
                    onTap: entry.$3,
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 26),
      const Divider(height: 1),
      const SizedBox(height: 26),
      NewsSection(loader: newsLoader),
    ],
  );
}

class FeatureLauncher extends StatefulWidget {
  final String asset, label;
  final VoidCallback onTap;
  const FeatureLauncher({
    super.key,
    required this.asset,
    required this.label,
    required this.onTap,
  });
  @override
  State<FeatureLauncher> createState() => _FeatureLauncherState();
}

class _FeatureLauncherState extends State<FeatureLauncher> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppTheme.primarySurface,
        onFocusChange: (value) => setState(() => _focused = value),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Image.asset(
                'assets/icons/flat-v2/${widget.asset}.png',
                width: 78,
                height: 78,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
