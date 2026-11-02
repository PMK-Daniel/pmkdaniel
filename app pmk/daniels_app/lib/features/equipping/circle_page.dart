import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../account/account_controller.dart';
import 'circle_catalog.dart';
import 'circle_group_card.dart';
import 'circle_group_page.dart';
import 'circle_reader.dart';

class CircleLearningPage extends StatefulWidget {
  const CircleLearningPage({super.key, this.loader = CircleCatalog.load});
  final Future<CircleCatalog> Function() loader;
  @override
  State<CircleLearningPage> createState() => _CircleLearningPageState();
}

class _CircleLearningPageState extends State<CircleLearningPage> {
  CircleCatalog? _catalog;
  CircleProgress? _progress;
  CircleGroupInfo _group = const CircleGroupInfo();
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
      final group = CircleGroupInfo.fromPrefs(prefs, id);
      if (!mounted || id != _accountId) return;
      setState(() {
        _catalog = catalog;
        _progress = progress;
        _group = group;
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

  Future<void> _openGroup() async {
    final owner = _accountId;
    if (owner == null || owner == 'guest') return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CircleGroupPage(
          loader: widget.loader,
          lessonBuilder: (lesson, catalog, progress) => CircleLessonPage(
            lesson: lesson,
            catalog: catalog,
            progress: progress,
          ),
        ),
      ),
    );
    if (mounted && owner == _accountId) await _load(owner);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog, progress = _progress;
    return Scaffold(
      appBar: AppBar(title: const Text('Circle')),
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
    final guide = catalog.lessons.where((p) => p.number == 0).firstOrNull;
    final phaseField = DropdownButtonFormField<String>(
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
      onChanged: (value) => setState(() => _phase = value == '' ? null : value),
    );
    final searchField = TextField(
      decoration: const InputDecoration(
        labelText: 'Cari pertemuan',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (v) => setState(() => _query = v),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      children: [
        Semantics(
          header: true,
          child: const Text(
            'Daniel Circle',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$done dari ${meetings.length} pertemuan selesai',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: meetings.isEmpty ? 0 : done / meetings.length,
          minHeight: 6,
        ),
        if (next != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _open(next),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(
              '${last == null ? 'Mulai' : 'Lanjutkan'}: ${next.title}',
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (guide != null)
              TextButton.icon(
                onPressed: () => _open(guide),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Panduan'),
              ),
            TextButton.icon(
              onPressed: _accountId == 'guest' ? null : _openGroup,
              icon: const Icon(Icons.groups_2_outlined, size: 18),
              label: const Text('Kelompokku'),
            ),
            if (_group.isConfigured)
              IconButton(
                tooltip: 'Salin ajakan kumpul',
                onPressed: () => copyTextWithFeedback(
                  context,
                  _group.buildInviteMessage(next),
                  'Pengingat kumpul disalin ke clipboard.',
                ),
                icon: const Icon(Icons.copy_outlined, size: 20),
              ),
          ],
        ),
        const Divider(height: 24),
        Semantics(
          header: true,
          child: const Text(
            'Urutan pembinaan',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 560
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: phaseField),
                    const SizedBox(width: 12),
                    Expanded(child: searchField),
                  ],
                )
              : Column(
                  children: [
                    phaseField,
                    const SizedBox(height: 12),
                    searchField,
                  ],
                ),
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
        const SizedBox(height: 24),
        const Text(
          'Kelompok, refleksi, dan progres tersimpan di perangkat ini untuk akunmu. Belum tersinkron dengan anggota lain.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

enum _LeaveChoice { stay, save, discard }

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
  late final _commitment = TextEditingController(
    text: widget.progress.commitment(widget.lesson.id),
  );
  late final _groupPrayer = TextEditingController(
    text: widget.progress.groupPrayer(widget.lesson.id),
  );
  int _document = 0, _page = 0;
  final _readerKey = GlobalKey(), _reflectionKey = GlobalKey();
  bool _saving = false;
  bool _leaving = false;
  bool get _dirty =>
      _note.text != widget.progress.reflection(widget.lesson.id) ||
      _commitment.text != widget.progress.commitment(widget.lesson.id) ||
      _groupPrayer.text != widget.progress.groupPrayer(widget.lesson.id);
  String? _message;
  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catatan belum disimpan'),
        content: Text(
          widget.canSave
              ? 'Simpan catatan pertemuan sebelum keluar, atau lanjut menulis. Perubahan yang dibuang tidak dapat dikembalikan.'
              : 'Perubahan yang dibuang tidak dapat dikembalikan.',
        ),
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _LeaveChoice.stay),
            child: const Text('Lanjut menulis'),
          ),
          if (widget.canSave)
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, _LeaveChoice.save),
              child: const Text('Simpan dan keluar'),
            ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF9D2632),
            ),
            onPressed: () => Navigator.pop(ctx, _LeaveChoice.discard),
            child: const Text('Buang perubahan'),
          ),
        ],
      ),
    );
    switch (choice) {
      case _LeaveChoice.discard:
        return true;
      case _LeaveChoice.save:
        return _save(widget.progress.completed(widget.lesson.id));
      case _LeaveChoice.stay:
      case null:
        return false;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    _commitment.dispose();
    _groupPrayer.dispose();
    super.dispose();
  }

  Future<bool> _save(bool complete) async {
    setState(() {
      _saving = true;
      _message = null;
    });
    var saved = false;
    try {
      await widget.progress.save(
        widget.lesson.id,
        _note.text,
        complete,
        commitment: _commitment.text,
        groupPrayer: _groupPrayer.text,
      );
      saved = true;
      if (mounted) {
        setState(
          () => _message = complete
              ? 'Catatan tersimpan. Pertemuan ditandai selesai.'
              : 'Catatan pertemuan tersimpan.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Catatan belum tersimpan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    return saved;
  }

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = key.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(target)
            ? Duration.zero
            : const Duration(milliseconds: 250),
      );
    });
  }

  void _goToPage(int page) {
    setState(() => _page = page);
    _scrollTo(_readerKey);
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

  Widget _readerFooter(
    List<CircleDocument> docs,
    CircleDocument doc,
    CircleLesson lesson,
  ) {
    final lastPage = _page >= doc.pages.length - 1;
    final nextDoc = _document + 1 < docs.length ? docs[_document + 1] : null;
    final Widget forward;
    if (!lastPage) {
      forward = FilledButton.icon(
        onPressed: () => _goToPage(_page + 1),
        icon: const Icon(Icons.arrow_forward),
        label: Text('Halaman ${_page + 2}'),
      );
    } else if (nextDoc != null) {
      forward = FilledButton.icon(
        onPressed: () {
          setState(() {
            _document++;
            _page = 0;
          });
          _scrollTo(_readerKey);
        },
        icon: const Icon(Icons.arrow_forward),
        label: Text('Lanjut: ${nextDoc.label}'),
      );
    } else if (lesson.number > 0) {
      forward = FilledButton.icon(
        onPressed: () => _scrollTo(_reflectionKey),
        icon: const Icon(Icons.edit_note),
        label: const Text('Lanjut ke refleksi'),
      );
    } else {
      forward = const SizedBox.shrink();
    }
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_page > 0)
          OutlinedButton.icon(
            onPressed: () => _goToPage(_page - 1),
            icon: const Icon(Icons.arrow_back),
            label: Text('Halaman $_page'),
          ),
        forward,
      ],
    );
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
    return PopScope(
      canPop: !_dirty || _leaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _saving) return;
        if (await _confirmLeave() && mounted) {
          setState(() => _leaving = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            lesson.number == 0
                ? 'Panduan Circle'
                : 'Pertemuan ${lesson.number}',
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warmSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: const Text(
                            'Ringkasan pertemuan',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.secondaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          lesson.introduction,
                          style: const TextStyle(fontSize: 16, height: 1.7),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _link(Uri.parse(lesson.source)),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Sumber: Notion Daniel Circle'),
                ),
                if (lesson.number > 0) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 16),
                    title: const Text('Alur pertemuan kelompok'),
                    subtitle: const Text(
                      'Dari saling menyapa sampai langkah nyata',
                    ),
                    children: [
                      for (final step in const [
                        (
                          'Sapa dan doa pembuka',
                          'Saling mendengar kabar dan membuka pertemuan dalam doa.',
                        ),
                        (
                          'Baca materi',
                          'Pelajari bacaan dan ayat dari pertemuan ini bersama.',
                        ),
                        (
                          'Diskusi bersama',
                          'Gunakan Bahan diskusi; beri ruang setiap anggota untuk berbagi.',
                        ),
                        (
                          'Refleksi dan langkah nyata',
                          'Catat satu penerapan dan pokok doa untuk ditindaklanjuti.',
                        ),
                      ].indexed)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text(
                            '${step.$1 + 1}',
                            style: const TextStyle(
                              color: AppTheme.secondaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          title: Text(step.$2.$1),
                          subtitle: Text(step.$2.$2),
                        ),
                    ],
                  ),
                ],
                const Divider(height: 32),
                if (doc == null)
                  const Text(
                    'Dokumen belum tersedia pada sumber untuk pertemuan ini.',
                  )
                else ...[
                  Wrap(
                    key: _readerKey,
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
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 18,
                        ),
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
                            : () => _goToPage(_page - 1),
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
                            : () => _goToPage(_page + 1),
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
                    CircleReadingBody(text: doc.pages[_page]),
                  const SizedBox(height: 24),
                  _readerFooter(docs, doc, lesson),
                ],
                if (lesson.number > 0) ...[
                  const Divider(height: 40),
                  Semantics(
                    header: true,
                    child: Text(
                      'Refleksi pribadi',
                      key: _reflectionKey,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Apa yang kamu pahami dari bacaan dan diskusi? Catatan ini untukmu sendiri dan tidak masuk ke ringkasan berbagi.',
                    style: TextStyle(height: 1.7),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _note,
                    onChanged: (_) => setState(() {}),
                    minLines: 4,
                    maxLines: 10,
                    enabled: widget.canSave && !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Catatan refleksi',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    key: const ValueKey('circle-sharing'),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 16),
                    initiallyExpanded:
                        _commitment.text.isNotEmpty ||
                        _groupPrayer.text.isNotEmpty,
                    title: const Text(
                      'Tindak lanjut pertemuan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Langkah nyata dan pokok doa untuk kelompok',
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Tulis hanya hal yang ingin kamu bagikan. Tombol salin di bawah tidak menyertakan refleksi pribadimu.',
                          style: TextStyle(
                            height: 1.6,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      TextField(
                        controller: _commitment,
                        enabled: widget.canSave && !_saving,
                        onChanged: (_) => setState(() {}),
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Langkah nyata minggu ini',
                          hintText: 'Satu tindakan yang ingin kamu lakukan.',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _groupPrayer,
                        enabled: widget.canSave && !_saving,
                        onChanged: (_) => setState(() {}),
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Pokok doa untuk kelompok',
                          hintText: 'Hal yang ingin didoakan bersama.',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => copyTextWithFeedback(
                            context,
                            lesson.sharingSummary(
                              commitment: _commitment.text,
                              groupPrayer: _groupPrayer.text,
                            ),
                            'Ringkasan disalin tanpa refleksi pribadi.',
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text(
                            'Salin ringkasan untuk grup Circle',
                          ),
                        ),
                      ),
                    ],
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
                    child: Text(_saving ? 'Menyimpan…' : 'Simpan catatan'),
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
                      onTap: _saving
                          ? null
                          : () async {
                              if (!await _confirmLeave() || !context.mounted) {
                                return;
                              }
                              try {
                                if (widget.canSave) {
                                  await widget.progress.visit(next.id);
                                }
                              } catch (_) {
                                if (mounted) {
                                  setState(
                                    () => _message =
                                        'Posisi belajar belum tersimpan. Coba lagi.',
                                  );
                                }
                                return;
                              }
                              if (!context.mounted) return;
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => CircleLessonPage(
                                    lesson: next,
                                    catalog: widget.catalog,
                                    progress: widget.progress,
                                    canSave: widget.canSave,
                                  ),
                                ),
                              );
                            },
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
