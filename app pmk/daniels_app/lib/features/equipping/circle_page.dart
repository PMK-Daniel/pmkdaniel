import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../account/account_controller.dart';
import 'circle_catalog.dart';

class CircleLearningPage extends StatefulWidget {
  const CircleLearningPage({super.key, this.loader = CircleCatalog.load});
  final Future<CircleCatalog> Function() loader;
  @override
  State<CircleLearningPage> createState() => _CircleLearningPageState();
}

class _CircleLearningPageState extends State<CircleLearningPage> {
  CircleCatalog? _catalog;
  CircleProgress? _progress;
  String? _error, _phase, _accountId;
  String _query = '';
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = AccountScope.maybeOf(context)?.user?.id ?? 'guest';
    if (!_started || id != _accountId) {
      _started = true;
      _accountId = id;
      _catalog = null;
      _progress = null;
      _load(id);
    }
  }

  Future<void> _load(String id) async {
    setState(() => _error = null);
    try {
      final catalog = await widget.loader();
      final prefs = await SharedPreferences.getInstance();
      final progress = CircleProgress(prefs, id)..load();
      if (!mounted || id != _accountId) return;
      setState(() {
        _catalog = catalog;
        _progress = progress;
      });
    } catch (_) {
      if (mounted && id == _accountId) {
        setState(
          () => _error = 'Materi belum dapat dibuka. Coba muat kembali.',
        );
      }
    }
  }

  Future<void> _open(CircleLesson lesson) async {
    if (_accountId != 'guest' && lesson.number > 0) {
      try {
        await _progress!.visit(lesson.id);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Posisi belajar belum tersimpan. Materi tetap dapat dibaca.',
              ),
            ),
          );
        }
      }
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CircleLessonPage(
          lesson: lesson,
          catalog: _catalog!,
          progress: _progress!,
          canSave: _accountId != 'guest',
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog, progress = _progress;
    return Scaffold(
      appBar: AppBar(title: const Text('Pembekalan')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: catalog == null || progress == null
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (_error == null) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Menyiapkan materi Circle…'),
                    ] else ...[
                      Text(_error!),
                      TextButton(
                        onPressed: () => _load(_accountId!),
                        child: const Text('Muat kembali'),
                      ),
                    ],
                  ],
                )
              : _content(catalog, progress),
        ),
      ),
    );
  }

  Widget _content(CircleCatalog catalog, CircleProgress progress) {
    final meetings = catalog.meetings;
    final done = meetings.where((p) => progress.completed(p.id)).length;
    final visible = meetings
        .where(
          (p) =>
              (_phase == null || _phase == p.phase) &&
              '${p.number} ${p.title} ${p.curriculum}'.toLowerCase().contains(
                _query.toLowerCase(),
              ),
        )
        .toList();
    final last = meetings.where((p) => p.id == progress.lastId).firstOrNull;
    final next = last != null && !progress.completed(last.id)
        ? last
        : meetings.where((p) => !progress.completed(p.id)).firstOrNull;
    String? previousGroup;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        const Text(
          'Daniel Circle',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Belajar bersama, bertumbuh dalam keseharian.',
          style: TextStyle(fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 20),
        Text(
          '$done dari ${meetings.length} pertemuan selesai',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: meetings.isEmpty ? 0 : done / meetings.length,
          minHeight: 6,
        ),
        const SizedBox(height: 8),
        const Text(
          'Refleksi dan progres tersimpan di perangkat ini untuk akunmu.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        if (next != null) ...[
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _open(next),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(
              '${last == null ? 'Mulai' : 'Lanjutkan'}: ${next.title}',
            ),
          ),
        ],
        if (catalog.lessons.any((p) => p.number == 0)) ...[
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.info_outline,
              color: AppTheme.secondaryDark,
            ),
            title: const Text('Panduan penerapan Circle'),
            subtitle: const Text(
              'Alur pembinaan dan cara memakai ketiga jenis modul',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _open(catalog.lessons.firstWhere((p) => p.number == 0)),
          ),
        ],
        const Divider(height: 32),
        const Text(
          'Urutan pembinaan',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Text(
          'Ikuti nomor pertemuan. Pilih fase untuk melihat bagian tertentu.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _phase ?? '',
          isExpanded: true,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            fontFamily: 'PlusJakartaSans',
          ),
          decoration: const InputDecoration(labelText: 'Fase pembinaan'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Semua fase')),
            for (final phase in catalog.phases)
              DropdownMenuItem(value: phase, child: Text(phase)),
          ],
          onChanged: (value) =>
              setState(() => _phase = value == '' ? null : value),
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Cari pertemuan',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Tidak ada pertemuan yang cocok. Coba kata lain atau pilih semua fase.',
            ),
          ),
        for (final lesson in visible) ...[
          if (previousGroup != '${lesson.phase} / ${lesson.curriculum}')
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Text(
                previousGroup = '${lesson.phase} / ${lesson.curriculum}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                  height: 1.6,
                ),
              ),
            ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 5),
            leading: SizedBox(
              width: 30,
              child: Text(
                '${lesson.number}'.padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 18,
                  color: AppTheme.secondaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(lesson.title),
            subtitle: Text(
              progress.completed(lesson.id)
                  ? 'Selesai'
                  : lesson.semesters.join(' · '),
            ),
            trailing: Icon(
              progress.completed(lesson.id)
                  ? Icons.check_circle_outline
                  : Icons.chevron_right,
              color: AppTheme.primary,
            ),
            onTap: () => _open(lesson),
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

class CircleLessonPage extends StatefulWidget {
  final CircleLesson lesson;
  final CircleCatalog catalog;
  final CircleProgress progress;
  final bool canSave;
  const CircleLessonPage({
    super.key,
    required this.lesson,
    required this.catalog,
    required this.progress,
    this.canSave = true,
  });
  @override
  State<CircleLessonPage> createState() => _CircleLessonPageState();
}

class _CircleLessonPageState extends State<CircleLessonPage> {
  late final _note = TextEditingController(
    text: widget.progress.reflection(widget.lesson.id),
  );
  int _document = 0, _page = 0;
  bool _saving = false;
  String? _message;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(bool complete) async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await widget.progress.save(widget.lesson.id, _note.text, complete);
      if (mounted) {
        setState(
          () => _message = complete
              ? 'Refleksi tersimpan. Pertemuan ditandai selesai.'
              : 'Refleksi tersimpan.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Catatan belum tersimpan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _link(Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('link');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tautan belum dapat dibuka. Coba lagi.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final docs = [...lesson.documents]
      ..sort(
        (a, b) => ['material', 'discussion', 'facilitator']
            .indexOf(a.role)
            .compareTo(
              ['material', 'discussion', 'facilitator'].indexOf(b.role),
            ),
      );
    final doc = docs.isEmpty ? null : docs[_document];
    final next = widget.catalog.meetings
        .where((p) => p.number > lesson.number)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          lesson.number == 0 ? 'Panduan Circle' : 'Pertemuan ${lesson.number}',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              Text(
                lesson.title,
                style: const TextStyle(
                  fontSize: 27,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDark,
                ),
              ),
              if (lesson.phase.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${lesson.phase}\n${lesson.curriculum}',
                  style: const TextStyle(
                    color: AppTheme.secondaryDark,
                    height: 1.7,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (lesson.introduction.isNotEmpty)
                SelectableText(
                  lesson.introduction,
                  style: const TextStyle(fontSize: 16, height: 1.8),
                ),
              const SizedBox(height: 18),
              TextButton.icon(
                onPressed: () => _link(Uri.parse(lesson.source)),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Sumber: Notion Daniel Circle'),
              ),
              const Divider(height: 32),
              if (doc == null)
                const Text(
                  'Dokumen belum tersedia pada sumber untuk pertemuan ini.',
                )
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < docs.length; i++)
                      ChoiceChip(
                        label: Text(docs[i].label),
                        selected: _document == i,
                        onSelected: (_) => setState(() {
                          _document = i;
                          _page = 0;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  doc.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                if (doc.role == 'facilitator')
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Panduan ini ditujukan untuk kakak fasilitator.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                if (kIsWeb)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          _link(Uri.base.resolve('assets/${doc.asset}')),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Buka PDF asli'),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Halaman sebelumnya',
                      onPressed: _page == 0
                          ? null
                          : () => setState(() => _page--),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        'Halaman ${_page + 1} dari ${doc.pages.length}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Halaman berikutnya',
                      onPressed: _page >= doc.pages.length - 1
                          ? null
                          : () => setState(() => _page++),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (doc.pageImages.isNotEmpty)
                  Image.asset(
                    doc.pageImages[_page],
                    semanticLabel: '${doc.name}, halaman ${_page + 1}',
                  )
                else
                  SelectableText(
                    doc.pages[_page],
                    style: const TextStyle(fontSize: 17, height: 1.8),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Halaman ${_page + 1} / ${doc.pages.length}. Gunakan panah di atas untuk melanjutkan.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              if (lesson.number > 0) ...[
                const Divider(height: 40),
                const Text(
                  'Refleksi pribadi',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Gunakan pertanyaan pada Bahan diskusi untuk mencatat pemahaman dan penerapanmu.',
                  style: TextStyle(height: 1.7),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _note,
                  minLines: 4,
                  maxLines: 10,
                  enabled: widget.canSave && !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Catatan refleksi',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Disimpan pada perangkat ini untuk akun Daniel Apps yang sedang masuk.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (!widget.canSave)
                  const Text(
                    'Masuk ke akun Daniel Apps untuk menyimpan refleksi dan progres.',
                  ),
                FilledButton(
                  onPressed: _saving || !widget.canSave
                      ? null
                      : () => _save(widget.progress.completed(lesson.id)),
                  child: Text(_saving ? 'Menyimpan…' : 'Simpan refleksi'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving || !widget.canSave
                      ? null
                      : () => _save(!widget.progress.completed(lesson.id)),
                  icon: Icon(
                    widget.progress.completed(lesson.id)
                        ? Icons.undo
                        : Icons.check,
                  ),
                  label: Text(
                    widget.progress.completed(lesson.id)
                        ? 'Tandai belum selesai'
                        : 'Simpan dan tandai selesai',
                  ),
                ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _message!,
                        style: const TextStyle(height: 1.6),
                      ),
                    ),
                  ),
                if (next != null) ...[
                  const Divider(height: 32),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pertemuan berikutnya'),
                    subtitle: Text('${next.number}. ${next.title}'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => CircleLessonPage(
                          lesson: next,
                          catalog: widget.catalog,
                          progress: widget.progress,
                          canSave: widget.canSave,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
