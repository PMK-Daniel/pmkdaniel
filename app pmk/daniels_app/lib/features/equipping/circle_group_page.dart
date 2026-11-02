import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../account/account_controller.dart';
import '../community/personal_list.dart';
import 'circle_catalog.dart';
import 'circle_group_card.dart';

const circlePrayerList = PersonalListConfig(
  kind: 'circle-prayer',
  heading: 'Doa Circle',
  addLabel: 'Tambah doa Circle',
  titleLabel: 'Pokok doa kelompok',
  noteLabel: 'Catatan perkembangan (opsional)',
  doneLabel: 'Terjawab atau disyukuri',
  activeLabel: 'Didoakan',
  completedLabel: 'Terjawab / disyukuri',
  emptyText:
      'Belum ada pokok doa. Catat hal yang disepakati untuk didoakan bersama.',
);

class CircleGroupPage extends StatefulWidget {
  const CircleGroupPage({
    super.key,
    required this.lessonBuilder,
    this.loader = CircleCatalog.load,
  });

  final Widget Function(CircleLesson, CircleCatalog, CircleProgress)
  lessonBuilder;
  final Future<CircleCatalog> Function() loader;

  @override
  State<CircleGroupPage> createState() => _CircleGroupPageState();
}

class _CircleGroupPageState extends State<CircleGroupPage> {
  String? _owner, _error;
  SharedPreferences? _prefs;
  CircleCatalog? _catalog;
  CircleProgress? _progress;
  CircleGroupInfo _group = const CircleGroupInfo();
  CircleGroupInfo? _draft;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final owner = AccountScope.maybeOf(context)?.user?.id ?? 'guest';
    if (owner != _owner) {
      _owner = owner;
      _catalog = null;
      _progress = null;
      _group = const CircleGroupInfo();
      _draft = null;
      _load(owner);
    }
  }

  Future<void> _load(String owner) async {
    setState(() => _error = null);
    try {
      final catalog = await widget.loader();
      final prefs = await SharedPreferences.getInstance();
      final progress = CircleProgress(prefs, owner)..load();
      final group = CircleGroupInfo.fromPrefs(prefs, owner);
      if (!mounted || owner != _owner) return;
      setState(() {
        _prefs = prefs;
        _catalog = catalog;
        _progress = progress;
        _group = group;
      });
    } catch (_) {
      if (mounted && owner == _owner) {
        setState(() => _error = 'Kelompok belum dapat dimuat. Coba lagi.');
      }
    }
  }

  Future<void> _edit() async {
    final owner = _owner, prefs = _prefs;
    if (owner == null || owner == 'guest' || prefs == null || _saving) return;
    final updated = await showCircleGroupDialog(context, _draft ?? _group);
    if (updated == null || !mounted || owner != _owner) return;
    setState(() {
      _saving = true;
      _draft = updated;
    });
    try {
      await updated.save(prefs, owner);
      if (mounted && owner == _owner) {
        setState(() {
          _group = updated;
          _draft = null;
        });
      }
    } catch (_) {
      if (mounted && owner == _owner) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kelompok belum tersimpan. Buka Ubah kelompok untuk mencoba lagi; isianmu tetap tersedia.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openMeeting(CircleLesson lesson) async {
    final owner = _owner, progress = _progress!, catalog = _catalog!;
    if (owner != 'guest') {
      try {
        await progress.visit(lesson.id);
      } catch (_) {
        if (mounted) {
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
    if (!mounted || owner != _owner) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => widget.lessonBuilder(lesson, catalog, progress),
      ),
    );
    if (mounted && owner == _owner) await _load(owner!);
  }

  Widget _groupTab() {
    final catalog = _catalog!, progress = _progress!;
    final last = catalog.meetings
        .where((lesson) => lesson.id == progress.lastId)
        .firstOrNull;
    final next = last != null && !progress.completed(last.id)
        ? last
        : catalog.meetings
              .where((lesson) => !progress.completed(lesson.id))
              .firstOrNull;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        Semantics(
          header: true,
          child: Text(
            _group.name.isEmpty ? 'Kelompok Circle-mu' : _group.name,
            style: const TextStyle(
              fontSize: 28,
              height: 1.3,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _group.isConfigured
              ? 'Satu tempat untuk menyiapkan pertemuan dan mengingat teman yang didoakan.'
              : 'Mulai dengan nama kelompok, kakak fasilitator, dan jadwal kumpulmu.',
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _saving || _owner == 'guest' ? null : _edit,
            icon: const Icon(Icons.edit_outlined, size: 19),
            label: Text(
              _saving
                  ? 'Menyimpan…'
                  : _group.isConfigured || _draft != null
                  ? 'Ubah kelompok'
                  : 'Atur kelompok',
            ),
          ),
        ),
        if (_owner == 'guest')
          const Text('Masuk untuk menyimpan kelompok dan catatan doa.'),
        if (_group.isConfigured) ...[
          const SizedBox(height: 16),
          _detail(
            Icons.event_outlined,
            'Jadwal dan tempat',
            _group.schedule.isEmpty ? 'Belum dicatat' : _group.schedule,
          ),
          _detail(
            Icons.person_outline,
            'Kakak fasilitator',
            _group.facilitator.isEmpty ? 'Belum dicatat' : _group.facilitator,
          ),
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: const Text(
              'Anggota kelompok',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          if (_group.memberList.isEmpty)
            const Text(
              'Nama anggota belum dicatat.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in _group.memberList)
                  Chip(
                    label: Text(name),
                    avatar: const Icon(Icons.person_outline, size: 18),
                  ),
              ],
            ),
        ],
        const Divider(height: 40),
        Semantics(
          header: true,
          child: const Text(
            'Pertemuan selanjutnya',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        if (next != null) ...[
          Text(
            '${next.number}. ${next.title}',
            style: const TextStyle(
              fontSize: 19,
              height: 1.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            next.curriculum,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => _openMeeting(next),
              icon: const Icon(Icons.menu_book_outlined, size: 20),
              label: const Text('Buka pertemuan'),
            ),
          ),
        ] else
          const Text(
            'Semua pertemuan sudah selesai. Materi tetap tersedia di katalog Circle.',
          ),
        if (_group.isConfigured) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => copyTextWithFeedback(
                context,
                _group.buildInviteMessage(next),
                'Ajakan kumpul disalin. Tempel ke grup saat kamu siap.',
              ),
              icon: const Icon(Icons.copy_outlined, size: 19),
              label: const Text('Salin ajakan kumpul'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Informasi kelompok tersimpan untuk akunmu di perangkat ini. Nama anggota belum terhubung ke akun lain; ajakan tidak dikirim otomatis.',
          style: TextStyle(
            fontSize: 13,
            height: 1.6,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _detail(IconData icon, String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppTheme.primary),
    title: Text(
      label,
      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
        color: AppTheme.textPrimary,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Kelompokku'),
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Kelompok'),
            Tab(text: 'Doa'),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: _catalog == null || _progress == null
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (_error == null) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Menyiapkan kelompok…'),
                    ] else ...[
                      Text(_error!),
                      TextButton(
                        onPressed: () => _load(_owner!),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ],
                )
              : TabBarView(
                  children: [
                    _groupTab(),
                    ListView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      children: [
                        const Text(
                          'Tambahkan pokok doa yang disepakati dan catat perkembangannya.',
                          style: TextStyle(fontSize: 16, height: 1.6),
                        ),
                        const SizedBox(height: 20),
                        if (_owner == 'guest')
                          const Text('Masuk untuk menyimpan catatan doa.')
                        else
                          PersonalListSection(
                            key: ValueKey(_owner),
                            config: circlePrayerList,
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
