import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../account/account_controller.dart';

class PersonalEntry {
  const PersonalEntry({
    required this.id,
    required this.title,
    this.note = '',
    this.done = false,
  });
  final String id, title, note;
  final bool done;

  PersonalEntry copyWith({String? title, String? note, bool? done}) =>
      PersonalEntry(
        id: id,
        title: title ?? this.title,
        note: note ?? this.note,
        done: done ?? this.done,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'done': done,
  };

  static PersonalEntry? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'], title = raw['title'];
    if (id is! String || title is! String || title.trim().isEmpty) return null;
    return PersonalEntry(
      id: id,
      title: title,
      note: raw['note'] is String ? raw['note'] as String : '',
      done: raw['done'] == true,
    );
  }
}

/// Device-local list, isolated by list kind and by account ID.
/// Nothing here is sent to a server or to other members.
class PersonalListStore {
  PersonalListStore(this.preferences, this.kind, this.accountId) {
    _load();
  }
  final SharedPreferences preferences;
  final String kind, accountId;
  List<PersonalEntry> _entries = const [];
  List<PersonalEntry> get entries => _entries;

  String get _key => 'daniel.list.v1.$kind.${Uri.encodeComponent(accountId)}';

  void _load() {
    final raw = preferences.getString(_key);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw);
      final list = data is Map ? data['entries'] : null;
      if (list is List) {
        _entries = [for (final item in list) ?PersonalEntry.tryParse(item)];
      }
    } catch (_) {
      _entries = const [];
    }
  }

  Future<void> _commit(List<PersonalEntry> next) async {
    final saved = await preferences.setString(
      _key,
      jsonEncode({
        'entries': [for (final e in next) e.toJson()],
      }),
    );
    if (!saved) throw StateError('Gagal menyimpan daftar.');
    _entries = next;
  }

  Future<void> add(String title, String note) => _commit([
    PersonalEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      note: note.trim(),
    ),
    ..._entries,
  ]);

  Future<void> update(String id, {String? title, String? note, bool? done}) =>
      _commit([
        for (final e in _entries)
          e.id == id
              ? e.copyWith(title: title?.trim(), note: note?.trim(), done: done)
              : e,
      ]);

  Future<void> remove(String id) => _commit([
    for (final e in _entries)
      if (e.id != id) e,
  ]);

  Future<void> restore(PersonalEntry entry, int index) {
    final next = [..._entries];
    next.insert(index.clamp(0, next.length), entry);
    return _commit(next);
  }
}

class PersonalListConfig {
  const PersonalListConfig({
    required this.kind,
    required this.heading,
    required this.addLabel,
    required this.titleLabel,
    required this.noteLabel,
    required this.doneLabel,
    required this.emptyText,
    this.activeLabel = 'Belum selesai',
    this.completedLabel = 'Selesai',
  });
  final String kind,
      heading,
      addLabel,
      titleLabel,
      noteLabel,
      doneLabel,
      emptyText,
      activeLabel,
      completedLabel;
}

class PersonalListSection extends StatefulWidget {
  const PersonalListSection({super.key, required this.config});
  final PersonalListConfig config;
  @override
  State<PersonalListSection> createState() => _PersonalListSectionState();
}

class _PersonalListSectionState extends State<PersonalListSection> {
  PersonalListStore? _store;
  String? _accountId;
  bool _started = false;
  bool _failed = false;
  bool _busy = false;
  bool? _filter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = AccountScope.maybeOf(context)?.user?.id ?? 'guest';
    if (!_started || id != _accountId) {
      _started = true;
      _accountId = id;
      _store = null;
      _filter = null;
      _open(id);
    }
  }

  Future<void> _open(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || id != _accountId) return;
      setState(() {
        _failed = false;
        _store = PersonalListStore(prefs, widget.config.kind, id);
      });
    } catch (_) {
      if (mounted && id == _accountId) setState(() => _failed = true);
    }
  }

  void _toast(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    final owner = _accountId;
    setState(() => _busy = true);
    var saved = false;
    try {
      await action();
      saved = true;
    } catch (_) {
      if (mounted && owner == _accountId) {
        _toast('Catatan belum tersimpan. Coba lagi.');
      }
    }
    if (mounted) setState(() => _busy = false);
    return saved && mounted && owner == _accountId;
  }

  Future<void> _edit([PersonalEntry? entry]) async {
    final store = _store;
    if (store == null) return;
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _EntryDialog(config: widget.config, entry: entry),
    );
    if (result == null || !mounted || store != _store) return;
    final saved = await _run(
      () => entry == null
          ? store.add(result.$1, result.$2)
          : store.update(entry.id, title: result.$1, note: result.$2),
    );
    if (saved && entry == null) setState(() => _filter = null);
  }

  Future<void> _delete(PersonalEntry entry) async {
    final store = _store;
    if (store == null) return;
    final index = store.entries.indexWhere((e) => e.id == entry.id);
    if (!await _run(() => store.remove(entry.id))) return;
    _toast(
      'Catatan dihapus.',
      action: SnackBarAction(
        label: 'Urungkan',
        onPressed: () {
          if (mounted && _store == store) {
            _run(() => store.restore(entry, index));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config, store = _store;
    final entries =
        store?.entries
            .where((e) => _filter == null || e.done == _filter)
            .toList() ??
        <PersonalEntry>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            c.heading,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pribadi: tersimpan di perangkat ini untuk akunmu dan tidak dikirim kepada siapa pun.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        if (_failed)
          const Text('Daftar belum dapat dibuka. Coba buka ulang halaman ini.')
        else if (store == null)
          const LinearProgressIndicator()
        else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _edit(),
              icon: const Icon(Icons.add),
              label: Text(c.addLabel),
            ),
          ),
          const SizedBox(height: 8),
          if (store.entries.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in <(bool?, String)>[
                  (null, 'Semua (${store.entries.length})'),
                  (
                    false,
                    '${c.activeLabel} (${store.entries.where((e) => !e.done).length})',
                  ),
                  (
                    true,
                    '${c.completedLabel} (${store.entries.where((e) => e.done).length})',
                  ),
                ])
                  ChoiceChip(
                    label: Text(filter.$2),
                    selected: _filter == filter.$1,
                    onSelected: (_) => setState(() => _filter = filter.$1),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Belum ada catatan pada bagian ini.',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
          ],
          if (store.entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                c.emptyText,
                style: const TextStyle(
                  height: 1.6,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          for (final entry in entries) ...[
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Semantics(
                label: '${c.doneLabel}: ${entry.title}',
                child: Checkbox(
                  value: entry.done,
                  onChanged: _busy
                      ? null
                      : (v) => _run(
                          () => store.update(entry.id, done: v ?? false),
                        ),
                ),
              ),
              title: Text(
                entry.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              subtitle: entry.note.isEmpty && !entry.done
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.note.isNotEmpty)
                          Text(
                            entry.note,
                            style: const TextStyle(
                              height: 1.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        if (entry.done)
                          Text(
                            c.doneLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                      ],
                    ),
              trailing: PopupMenuButton<String>(
                enabled: !_busy,
                tooltip: 'Opsi untuk ${entry.title}',
                onSelected: (v) => v == 'edit' ? _edit(entry) : _delete(entry),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
              onTap: _busy ? null : () => _edit(entry),
            ),
          ],
          if (store.entries.isNotEmpty) const Divider(height: 1),
        ],
      ],
    );
  }
}

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({required this.config, this.entry});
  final PersonalListConfig config;
  final PersonalEntry? entry;
  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  late final _title = TextEditingController(text: widget.entry?.title);
  late final _note = TextEditingController(text: widget.entry?.note);
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Tulis dulu sebelum menyimpan.');
      return;
    }
    Navigator.pop(context, (_title.text, _note.text));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    return AlertDialog(
      title: Text(widget.entry == null ? c.addLabel : 'Ubah catatan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: c.titleLabel,
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 300,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: c.noteLabel,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
