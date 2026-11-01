import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CircleDocument {
  final String role, name, asset;
  final List<String> pages, pageImages;
  CircleDocument.fromJson(Map<String, dynamic> json)
    : role = json['role'] as String,
      name = json['name'] as String,
      asset = json['asset'] as String,
      pages = List<String>.from(json['pages'] as List),
      pageImages = List<String>.from(json['pageImages'] as List? ?? []);
  String get label => switch (role) {
    'discussion' => 'Bahan diskusi',
    'facilitator' => 'Panduan kakak',
    _ => 'Materi',
  };
}

class CircleLesson {
  final String id, title, phase, curriculum, introduction, source, status;
  final int number;
  final List<String> semesters;
  final List<CircleDocument> documents;
  CircleLesson.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      title = json['title'] as String,
      phase = json['phase'] as String,
      curriculum = json['curriculum'] as String,
      introduction = json['introduction'] as String,
      source = json['source'] as String,
      status = json['status'] as String,
      number = json['number'] as int,
      semesters = List<String>.from(json['semesters'] as List),
      documents = (json['documents'] as List)
          .map(
            (d) => CircleDocument.fromJson(Map<String, dynamic>.from(d as Map)),
          )
          .toList();
}

class CircleCatalog {
  final List<CircleLesson> lessons;
  CircleCatalog.fromJson(Map<String, dynamic> json)
    : lessons =
          (json['lessons'] as List)
              .map(
                (p) =>
                    CircleLesson.fromJson(Map<String, dynamic>.from(p as Map)),
              )
              .toList()
            ..sort((a, b) => a.number.compareTo(b.number));
  static CircleCatalog? _cached;
  static Future<CircleCatalog> load() async {
    if (_cached != null) return _cached!;
    final catalog = CircleCatalog.fromJson(
      jsonDecode(await rootBundle.loadString('assets/circle/catalog.json'))
          as Map<String, dynamic>,
    );
    _cached = catalog;
    return catalog;
  }
  List<CircleLesson> get meetings =>
      lessons.where((p) => p.number > 0).toList();
  List<String> get phases => meetings.map((p) => p.phase).toSet().toList();
}

/// Device-local learning state, isolated by the verified Daniel account ID.
/// This does not write to KambiumGo or claim cloud synchronization.
class CircleProgress {
  final SharedPreferences preferences;
  final String accountId;
  late final String _key = 'daniel.circle.v1.${Uri.encodeComponent(accountId)}';
  Map<String, dynamic> _entries = {};
  String? lastId;
  CircleProgress(this.preferences, this.accountId);
  void load() {
    final raw = preferences.getString(_key);
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _entries = Map<String, dynamic>.from(data['entries'] as Map? ?? {});
    lastId = data['lastId'] as String?;
  }

  bool completed(String id) => (_entries[id] as Map?)?['completed'] == true;
  String reflection(String id) =>
      (_entries[id] as Map?)?['reflection'] as String? ?? '';
  Future<void> visit(String id) async {
    final saved = await preferences.setString(
      _key,
      jsonEncode({'lastId': id, 'entries': _entries}),
    );
    if (!saved) throw StateError('Gagal menyimpan posisi belajar.');
    lastId = id;
  }

  Future<void> save(String id, String reflection, bool completed) async {
    final entries = Map<String, dynamic>.from(_entries);
    entries[id] = {'reflection': reflection, 'completed': completed};
    final saved = await preferences.setString(
      _key,
      jsonEncode({'lastId': id, 'entries': entries}),
    );
    if (!saved) throw StateError('Gagal menyimpan catatan.');
    _entries = entries;
    lastId = id;
  }
}
