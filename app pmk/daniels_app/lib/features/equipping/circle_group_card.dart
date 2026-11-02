import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import 'circle_catalog.dart';

class CircleGroupInfo {
  final String name, facilitator, schedule, members;
  const CircleGroupInfo({
    this.name = '',
    this.facilitator = '',
    this.schedule = '',
    this.members = '',
  });

  bool get isConfigured =>
      name.trim().isNotEmpty ||
      facilitator.trim().isNotEmpty ||
      schedule.trim().isNotEmpty ||
      members.trim().isNotEmpty;

  List<String> get memberList => members
      .split(RegExp(r'[,\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Map<String, dynamic> toJson() => {
    'name': name,
    'facilitator': facilitator,
    'schedule': schedule,
    'members': members,
  };

  static CircleGroupInfo fromPrefs(SharedPreferences prefs, String accountId) {
    final raw = prefs.getString(
      'daniel.circle.group.v1.${Uri.encodeComponent(accountId)}',
    );
    if (raw == null) return const CircleGroupInfo();
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return const CircleGroupInfo();
      return CircleGroupInfo(
        name: map['name'] is String ? map['name'] as String : '',
        facilitator: map['facilitator'] is String
            ? map['facilitator'] as String
            : '',
        schedule: map['schedule'] is String ? map['schedule'] as String : '',
        members: map['members'] is String ? map['members'] as String : '',
      );
    } catch (_) {
      return const CircleGroupInfo();
    }
  }

  Future<void> save(SharedPreferences prefs, String accountId) async {
    final saved = await prefs.setString(
      'daniel.circle.group.v1.${Uri.encodeComponent(accountId)}',
      jsonEncode(toJson()),
    );
    if (!saved) throw StateError('Kelompok belum tersimpan.');
  }

  String buildInviteMessage(CircleLesson? nextLesson) {
    final buffer = StringBuffer();
    final groupTitle = name.trim().isEmpty ? 'Kelompok Circle' : name.trim();
    buffer.writeln('Halo teman-teman $groupTitle!');
    if (nextLesson != null) {
      buffer.writeln(
        'Pertemuan kita berikutnya: Pertemuan ${nextLesson.number} — ${nextLesson.title} (${nextLesson.curriculum}).',
      );
    }
    if (schedule.trim().isNotEmpty) {
      buffer.writeln('Jadwal & tempat: ${schedule.trim()}');
    }
    if (facilitator.trim().isNotEmpty) {
      buffer.writeln('Kakak pendamping: ${facilitator.trim()}');
    }
    buffer.write('Jangan lupa baca materi dan siapkan hati ya!');
    return buffer.toString();
  }
}

Future<CircleGroupInfo?> showCircleGroupDialog(
  BuildContext context,
  CircleGroupInfo current,
) {
  return showDialog<CircleGroupInfo>(
    context: context,
    builder: (_) => _CircleGroupDialog(initial: current),
  );
}

class _CircleGroupDialog extends StatefulWidget {
  final CircleGroupInfo initial;
  const _CircleGroupDialog({required this.initial});
  @override
  State<_CircleGroupDialog> createState() => _CircleGroupDialogState();
}

class _CircleGroupDialogState extends State<_CircleGroupDialog> {
  late final _name = TextEditingController(text: widget.initial.name);
  late final _facilitator = TextEditingController(
    text: widget.initial.facilitator,
  );
  late final _schedule = TextEditingController(text: widget.initial.schedule);
  late final _members = TextEditingController(text: widget.initial.members);

  @override
  void dispose() {
    _name.dispose();
    _facilitator.dispose();
    _schedule.dispose();
    _members.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kelompok Circle-ku'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simpan informasi kelompok kecilmu di perangkat ini untuk memudahkan pengingat kumpul dan doa bersama.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nama kelompok Circle',
                hintText: 'Misal: Circle Daniel 3',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _facilitator,
              decoration: const InputDecoration(
                labelText: 'Nama kakak fasilitator',
                hintText: 'Misal: Kak Andi',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _schedule,
              decoration: const InputDecoration(
                labelText: 'Jadwal & tempat kumpul',
                hintText: 'Misal: Jumat 16.00 · Gazebo FILKOM',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _members,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Anggota kelompok',
                helperText: 'Pisahkan nama dengan koma atau baris baru.',
                helperMaxLines: 3,
                hintText: 'Budi, Sari, Raka',
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
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            CircleGroupInfo(
              name: _name.text.trim(),
              facilitator: _facilitator.text.trim(),
              schedule: _schedule.text.trim(),
              members: _members.text.trim(),
            ),
          ),
          child: const Text('Simpan kelompok'),
        ),
      ],
    );
  }
}

Future<void> copyTextWithFeedback(
  BuildContext context,
  String text,
  String message,
) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Belum dapat menyalin. Coba lagi.')),
    );
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
