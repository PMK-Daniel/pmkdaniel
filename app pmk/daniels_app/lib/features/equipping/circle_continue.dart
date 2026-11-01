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
    CircleLesson? last;
    if (catalog != null && progress != null) {
      for (final lesson in catalog.meetings) {
        if (lesson.id == progress.lastId) last = lesson;
      }
    }
    final selected = last;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Material(
        color: AppTheme.warmSurface,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          leading: const Icon(
            Icons.menu_book_rounded,
            color: AppTheme.secondaryDark,
          ),
          title: Text(
            selected == null ? 'Mulai perjalanan Circle' : 'Lanjutkan Circle',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _failed
                  ? 'Progres belum terbaca. Buka Circle untuk mencoba lagi.'
                  : selected == null
                  ? 'Materi dan diskusi untuk bertumbuh bersama.'
                  : 'Pertemuan ${selected.number} · ${selected.title}',
              style: const TextStyle(
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final owner = _owner!;
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    selected == null || catalog == null || progress == null
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
        ),
      ),
    );
  }
}
