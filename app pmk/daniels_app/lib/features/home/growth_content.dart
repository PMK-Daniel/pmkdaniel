import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../account/account_controller.dart';
import '../equipping/circle_page.dart';

/// Editorial previews, deliberately separate from published PMK/Kambium content.
class Reflection {
  final String title, reading, body, question;
  const Reflection(this.title, this.reading, this.body, this.question);
}

const reflectionPreviews = [
  Reflection(
    'Bertumbuh dengan saling menguatkan',
    '1 Tesalonika 5:11',
    'Ada hari ketika kuliah, tugas, dan pelayanan terasa begitu penuh. Kita mungkin mengira harus melewati semuanya sendiri. Namun, kehidupan beriman juga bertumbuh melalui kehadiran orang lain.\n\nBacalah 1 Tesalonika 5:11. Ajakan untuk saling menasihati dan membangun mengingatkan kita bahwa perhatian kecil pun berarti. Mendengarkan tanpa buru-buru menjawab, menyapa teman yang mulai menjauh, atau mendoakan seseorang adalah langkah yang bisa kita ambil.\n\nHari ini, sediakan ruang untuk hadir bagi satu orang. Kita tidak harus memiliki semua jawaban untuk menjadi teman yang menguatkan.',
    'Siapa yang ingin kamu sapa dan kuatkan hari ini?',
  ),
  Reflection(
    'Membawa kekhawatiran dalam doa',
    '1 Petrus 5:7',
    'Masa depan sering datang bersama banyak pertanyaan. Ada rencana yang belum jelas dan tanggung jawab yang terasa berat.\n\nBacalah 1 Petrus 5:7 dengan perlahan. Membawa kekhawatiran kepada Tuhan tidak berarti mengabaikan tanggung jawab. Kita belajar jujur dalam doa, lalu mengambil langkah kecil yang bisa dilakukan hari ini.\n\nTuliskan satu hal yang membuatmu khawatir. Bawalah dalam doa dan pikirkan satu tindakan sederhana untuk menghadapinya bersama Tuhan.',
    'Kekhawatiran apa yang ingin kamu bawa dalam doa?',
  ),
  Reflection(
    'Setia dalam langkah kecil',
    'Kolose 3:23',
    'Tidak setiap hari dipenuhi pencapaian besar. Kadang kesetiaan terlihat dalam hal yang sederhana: menyelesaikan tugas dengan jujur, datang tepat waktu, atau menolong tanpa mencari pujian.\n\nBacalah Kolose 3:23. Pekerjaan sehari-hari bisa menjadi bagian dari respons kita kepada Tuhan. Nilainya tidak hanya ditentukan oleh siapa yang melihat atau memujinya.\n\nPilih satu tanggung jawab hari ini. Kerjakan dengan perhatian dan hati yang bersedia belajar.',
    'Langkah kecil apa yang ingin kamu kerjakan dengan setia?',
  ),
];

void openPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class ReadingPage extends StatelessWidget {
  final String title, subtitle, body;
  final Widget? footer;
  const ReadingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.footer,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Daniels App')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                height: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            SelectableText(
              body,
              style: const TextStyle(fontSize: 17, height: 1.8),
            ),
            if (footer != null) ...[const SizedBox(height: 28), footer!],
          ],
        ),
      ),
    ),
  );
}

class ReflectionPage extends StatelessWidget {
  final Reflection reflection;
  const ReflectionPage({super.key, required this.reflection});

  @override
  Widget build(BuildContext context) => ReadingPage(
    title: reflection.title,
    subtitle: '${reflection.reading} · Contoh renungan, belum publikasi PMK',
    body: reflection.body,
    footer: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Untuk direnungkan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          reflection.question,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () =>
              openPage(context, JournalPage(reflection: reflection)),
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Tulis refleksi pribadi'),
        ),
      ],
    ),
  );
}

class ReflectionArchivePage extends StatelessWidget {
  const ReflectionArchivePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Renungan')),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Waktu untuk bertumbuh',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Contoh bacaan untuk pratinjau. Arsip renungan harian akan tersedia setelah konten terbit.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 20),
            for (final reflection in reflectionPreviews)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                leading: const Icon(
                  Icons.auto_stories_outlined,
                  color: AppTheme.primary,
                ),
                title: Text(reflection.title),
                subtitle: Text(reflection.reading),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    openPage(context, ReflectionPage(reflection: reflection)),
              ),
          ],
        ),
      ),
    ),
  );
}

class JournalPage extends StatefulWidget {
  final Reflection reflection;
  const JournalPage({super.key, required this.reflection});
  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _controller = TextEditingController();
  bool _loading = true, _saving = false, _dirty = false;
  bool _loadFailed = false;
  String? _error;
  String? _ownerId;
  bool _ownerInitialized = false;
  int _revision = 0;
  String get _key => _ownerId == null
      ? 'reflection_note_${widget.reflection.reading}'
      : 'reflection_note_user_${_ownerId}_${widget.reflection.reading}';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final owner = AccountScope.maybeOf(context)?.user?.id;
    if (!_ownerInitialized || owner != _ownerId) {
      _ownerInitialized = true;
      _ownerId = owner;
      _controller.clear();
      _dirty = false;
      _saving = false;
      _load();
    }
  }

  Future<void> _load() async {
    final revision = ++_revision;
    final key = _key;
    setState(() {
      _loading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || revision != _revision) return;
      _controller.text = prefs.getString(key) ?? '';
    } catch (_) {
      if (!mounted || revision != _revision) return;
      _loadFailed = true;
      _error = 'Catatan tidak dapat dimuat. Coba muat kembali.';
    }
    if (mounted && revision == _revision) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final revision = _revision;
    final key = _key;
    final note = _controller.text;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(key, note);
      if (!saved) throw StateError('Write failed');
      if (!mounted || revision != _revision) return;
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refleksi tersimpan di perangkat ini.')),
      );
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(() => _error = 'Belum tersimpan. Coba simpan kembali.');
      }
    } finally {
      if (mounted && revision == _revision) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty && !_saving,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || _saving) return;
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Keluar tanpa menyimpan?'),
          content: const Text('Perubahan catatan belum disimpan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Lanjut menulis'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Keluar'),
            ),
          ],
        ),
      );
      if (discard == true && mounted) {
        setState(() => _dirty = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Refleksi pribadi')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.reflection.question,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tersimpan hanya di perangkat ini, tanpa sinkronisasi. Catatan dapat hilang jika data aplikasi dihapus.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const LinearProgressIndicator()
          else
            TextField(
              controller: _controller,
              minLines: 8,
              maxLines: null,
              enabled: !_saving && !_loadFailed,
              onChanged: (_) => setState(() => _dirty = true),
              decoration: const InputDecoration(
                labelText: 'Catatanmu',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_error!),
            ),
          const SizedBox(height: 20),
          if (_loadFailed)
            TextButton(onPressed: _load, child: const Text('Muat kembali')),
          FilledButton(
            onPressed: _loading || _saving || _loadFailed ? null : _save,
            child: Text(_saving ? 'Menyimpan…' : 'Simpan refleksi'),
          ),
        ],
      ),
    ),
  );
}

class EquippingPage extends StatelessWidget {
  const EquippingPage({super.key});
  @override
  Widget build(BuildContext context) => const CircleLearningPage();
}

class NewsArticle {
  final String title, content, category, date, author;
  final String? image;
  const NewsArticle({
    required this.title,
    required this.content,
    required this.category,
    required this.date,
    required this.author,
    this.image,
  });
  factory NewsArticle.fromJson(Map<String, dynamic> data) => NewsArticle(
    title: data['title'] as String,
    content: data['content'] as String? ?? '',
    category: data['category'] as String? ?? 'PMK',
    date: data['date_published'] as String? ?? '',
    author: data['author'] as String? ?? 'PMK Daniel',
    image: data['image_url'] as String?,
  );
}

class NewsService {
  static final endpoint = Uri.parse(
    'https://pmkdaniel-api.danielmemory26.workers.dev/api/pengumuman?limit=50',
  );
  static Future<List<NewsArticle>> fetch({http.Client? client}) async {
    final owned = client == null;
    final transport = client ?? http.Client();
    try {
      final response = await transport
          .get(endpoint)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw StateError('News request failed');
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (json['success'] != true) throw StateError('Invalid news response');
      return (json['data']['items'] as List)
          .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
          .toList();
    } finally {
      if (owned) transport.close();
    }
  }
}

class NewsSection extends StatefulWidget {
  final Future<List<NewsArticle>> Function()? loader;
  const NewsSection({super.key, this.loader});
  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  late Future<List<NewsArticle>> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<NewsArticle>> _load() =>
      widget.loader?.call() ?? NewsService.fetch();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Berita & kabar PMK',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
          TextButton(
            onPressed: () => openPage(context, NewsListPage(initial: _future)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lihat'),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
      const Text(
        'Cerita dan informasi dari komunitas kita.',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      const SizedBox(height: 16),
      FutureBuilder<List<NewsArticle>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return NewsStatus(
              onRetry: () => setState(() {
                _future = _load();
              }),
            );
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  LinearProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Memuat kabar PMK…'),
                ],
              ),
            );
          }
          if (snapshot.data!.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Belum ada berita terbit. Cek kembali nanti, ya.'),
            );
          }
          return SizedBox(
            height: 312 + (MediaQuery.textScalerOf(context).scale(17) - 17) * 5,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.take(6).length,
              separatorBuilder: (_, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) => SizedBox(
                width: MediaQuery.sizeOf(context).width < 400 ? 270 : 310,
                child: NewsCard(article: snapshot.data![index]),
              ),
            ),
          );
        },
      ),
    ],
  );
}

class NewsStatus extends StatelessWidget {
  final VoidCallback onRetry;
  const NewsStatus({super.key, required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppTheme.warmSurface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Berita belum dapat dimuat. Periksa koneksi lalu coba kembali.',
        ),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
        ),
      ],
    ),
  );
}

class NewsCard extends StatelessWidget {
  final NewsArticle article;
  const NewsCard({super.key, required this.article});
  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.primarySurface,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => openPage(
        context,
        ReadingPage(
          title: article.title,
          subtitle: '${article.author} · ${article.date}',
          body: article.content,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: article.image == null || article.image!.isEmpty
                ? const ColoredBox(
                    color: AppTheme.primaryDark,
                    child: Icon(Icons.newspaper, color: Colors.white, size: 42),
                  )
                : Image.network(
                    article.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, trace) => const ColoredBox(
                      color: AppTheme.primaryDark,
                      child: Icon(
                        Icons.newspaper,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${article.category} · ${article.date}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  article.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class NewsListPage extends StatefulWidget {
  final Future<List<NewsArticle>> initial;
  const NewsListPage({super.key, required this.initial});
  @override
  State<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> {
  late Future<List<NewsArticle>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.initial;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Berita & kabar PMK')),
    body: FutureBuilder<List<NewsArticle>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: NewsStatus(
              onRetry: () => setState(() {
                _future = NewsService.fetch();
              }),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('Belum ada berita terbit.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.length,
          separatorBuilder: (_, index) => const SizedBox(height: 20),
          itemBuilder: (_, index) => NewsCard(article: snapshot.data![index]),
        );
      },
    ),
  );
}
