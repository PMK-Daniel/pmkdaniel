import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../account/account_controller.dart';
import 'circle_catalog.dart';
import 'circle_page.dart';

class CircleContinue extends StatefulWidget {
  const CircleContinue({super.key});
  @override
  State<CircleContinue> createState() => _CircleContinueState();
}

class _CircleContinueState extends State<CircleContinue> {
  String? _owner;
  CircleCatalog? _catalog;
  CircleProgress? _progress;
  bool _failed = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = AccountScope.maybeOf(context)?.user?.id;
    if (id != _owner) {
      _owner = id;
      _catalog = null;
      _progress = null;
      if (id != null) _load(id);
    }
  }

  Future<void> _load(String id) async {
    try {
      final catalog = await CircleCatalog.load();
      final preferences = await SharedPreferences.getInstance();
      final progress = CircleProgress(preferences, id)..load();
      if (!mounted || _owner != id) return;
      setState(() {
        _catalog = catalog;
        _progress = progress;
        _failed = false;
      });
    } catch (_) {
      if (mounted && _owner == id) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_owner == null) return const SizedBox.shrink();
    final progress = _progress, catalog = _catalog;
    final meetings = catalog?.meetings ?? <CircleLesson>[];
    final last = meetings
        .where((lesson) => lesson.id == progress?.lastId)
        .firstOrNull;
    final selected = progress == null
        ? null
        : last != null && !progress.completed(last.id)
        ? last
        : meetings
              .where((lesson) => !progress.completed(lesson.id))
              .firstOrNull;
    final done = progress == null
        ? 0
        : meetings.where((lesson) => progress.completed(lesson.id)).length;
    final ready = progress != null && catalog != null;
    final complete = ready && meetings.isNotEmpty && done == meetings.length;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Material(
        color: AppTheme.warmSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final owner = _owner!;
            if (selected != null && progress != null) {
              try {
                await progress.visit(selected.id);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Posisi belum tersimpan. Materi tetap dapat dibaca.',
                      ),
                    ),
                  );
                }
              }
            }
            if (!context.mounted || _owner != owner) return;
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => selected == null || !ready
                    ? const CircleLearningPage()
                    : CircleLessonPage(
                        lesson: selected,
                        catalog: catalog,
                        progress: progress,
                      ),
              ),
            );
            if (mounted && _owner == owner) await _load(owner);
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Circle',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    if (ready)
                      Text(
                        '$done/${meetings.length} selesai',
                        style: const TextStyle(
                          color: AppTheme.secondaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _failed
                      ? 'Progres belum terbaca. Buka Circle untuk mencoba lagi.'
                      : !ready
                      ? 'Menyiapkan perjalanan Circle…'
                      : complete
                      ? 'Semua pertemuan selesai. Kamu bisa membaca kembali atau berdiskusi bersama kelompok.'
                      : selected == null
                      ? 'Buka Circle untuk melihat materi yang tersedia.'
                      : 'Pertemuan ${selected.number} · ${selected.title}',
                  style: const TextStyle(
                    height: 1.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        complete
                            ? 'Lihat kembali materi'
                            : last == null
                            ? 'Mulai bersama Circle'
                            : 'Lanjutkan pertemuan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
