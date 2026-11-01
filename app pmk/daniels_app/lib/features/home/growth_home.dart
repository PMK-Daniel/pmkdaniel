import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'growth_content.dart';
import 'support_page.dart';
import '../equipping/circle_continue.dart';

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
      Image.asset(
        'assets/images/community.webp',
        height: MediaQuery.sizeOf(context).width < 600 ? 240 : 360,
        width: double.infinity,
        fit: BoxFit.cover,
        alignment: const Alignment(0, .45),
        semanticLabel: 'Kebersamaan komunitas PMK Daniel',
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reflectionPreviews.first.title,
              style: const TextStyle(
                fontSize: 26,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '1 Tesalonika 5:11 · Contoh renungan',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                minimumSize: const Size(48, 48),
              ),
              onPressed: () => openPage(
                context,
                ReflectionPage(reflection: reflectionPreviews.first),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Baca renungan'),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: AppTheme.primaryDark,
                  child: Text(
                    _initials(displayName),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName == null || displayName!.trim().isEmpty
                            ? 'Hai, teman!'
                            : 'Hai, ${displayName!.trim()}!',
                        style: const TextStyle(
                          fontSize: 19,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'PMK Daniel · FILKOM UB',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
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
                    'Circle',
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
                        width:
                            (constraints.maxWidth - (columns - 1) * 10) /
                            columns,
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
            const CircleContinue(),
            const SizedBox(height: 26),
            const Divider(height: 1),
            const SizedBox(height: 26),
            NewsSection(loader: newsLoader),
          ],
        ),
      ),
    ],
  );

  String _initials(String? name) {
    final words = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    return words.isEmpty
        ? 'D'
        : words.map((word) => word.characters.first).join().toUpperCase();
  }
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
