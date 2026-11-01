import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/bible_data.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_page.dart';

class BibleScreen extends StatefulWidget {
  const BibleScreen({super.key});

  @override
  State<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends State<BibleScreen> {
  String _selectedTestament = 'SEMUA'; // 'SEMUA', 'PL', 'PB'
  String _searchQuery = '';
  BibleBook? _currentReadingBook;
  int _currentChapter = 1;
  final double _fontSize = 17.0;
  int _loadRevision = 0;

  List<BibleVerse> _currentVerses = [];
  bool _isLoadingChapter = false;
  final ScrollController _readerScrollController = ScrollController();

  @override
  void dispose() {
    _readerScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChapter(BibleBook book, int chapter) async {
    final revision = ++_loadRevision;
    setState(() {
      _currentReadingBook = book;
      _currentChapter = chapter;
      _isLoadingChapter = true;
    });

    final verses = await BibleData.getChapterVerses(book, chapter);

    if (mounted && revision == _loadRevision) {
      setState(() {
        _currentVerses = verses;
        _isLoadingChapter = false;
      });
      // Scroll to top
      if (_readerScrollController.hasClients) {
        _readerScrollController.jumpTo(0);
      }
    }
  }

  void _goToPreviousChapter() {
    if (_currentReadingBook == null) return;
    if (_currentChapter > 1) {
      _loadChapter(_currentReadingBook!, _currentChapter - 1);
    } else {
      // Go to previous book if available
      final curIdx = BibleData.books.indexWhere(
        (b) => b.bookId == _currentReadingBook!.bookId,
      );
      if (curIdx > 0) {
        final prevBook = BibleData.books[curIdx - 1];
        _loadChapter(prevBook, prevBook.chapters);
      }
    }
  }

  void _goToNextChapter() {
    if (_currentReadingBook == null) return;
    if (_currentChapter < _currentReadingBook!.chapters) {
      _loadChapter(_currentReadingBook!, _currentChapter + 1);
    } else {
      // Go to next book if available
      final curIdx = BibleData.books.indexWhere(
        (b) => b.bookId == _currentReadingBook!.bookId,
      );
      if (curIdx < BibleData.books.length - 1) {
        final nextBook = BibleData.books[curIdx + 1];
        _loadChapter(nextBook, 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentReadingBook != null) {
      return _buildReaderView();
    }

    final filteredBooks = BibleData.books.where((book) {
      final matchesTestament =
          _selectedTestament == 'SEMUA' || book.testament == _selectedTestament;
      final matchesSearch =
          book.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.abbr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesTestament && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alkitab Saku',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Terjemahan Baru (TB) • Lengkap 66 Kitab',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari kitab (misal: Mazmur, Yohanes, Daniel)...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Segmented Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildSegmentButton('SEMUA', 'Semua (66)'),
                const SizedBox(width: 8),
                _buildSegmentButton('PL', 'Perjanjian Lama (39)'),
                const SizedBox(width: 8),
                _buildSegmentButton('PB', 'Perjanjian Baru (27)'),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Books Grid
          Expanded(
            child: filteredBooks.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada kitab yang cocok.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredBooks.length,
                    itemBuilder: (ctx, idx) {
                      final book = filteredBooks[idx];
                      final isPL = book.testament == 'PL';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.border.withValues(alpha: 0.8),
                          ),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    (isPL
                                            ? AppTheme.primary
                                            : AppTheme.secondary)
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  book.abbr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isPL
                                        ? AppTheme.primary
                                        : AppTheme.secondary,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              book.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              '${book.category} • ${book.chapters} Pasal',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                            onTap: () => _selectChapterSheet(book),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String value, String label) {
    final isSelected = _selectedTestament == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTestament = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectChapterSheet(BibleBook book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (c, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kitab ${book.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih Pasal (1 - ${book.chapters})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: GridView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (MediaQuery.sizeOf(ctx).width / 72)
                      .floor()
                      .clamp(3, 8),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: book.chapters,
                itemBuilder: (ctx, i) {
                  final ch = i + 1;
                  final isCurrent =
                      _currentReadingBook?.bookId == book.bookId &&
                      _currentChapter == ch;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(ctx);
                      _loadChapter(book, ch);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppTheme.primary
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent ? AppTheme.primary : AppTheme.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$ch',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isCurrent
                                ? Colors.white
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderView() {
    final book = _currentReadingBook!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Daftar kitab',
          onPressed: () => setState(() => _currentReadingBook = null),
        ),
        title: InkWell(
          onTap: () => _selectChapterSheet(book),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '${book.name} $_currentChapter',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Ukuran teks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const AppearancePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: 'Salin Seluruh Pasal',
            onPressed: () {
              if (_currentVerses.isEmpty) return;
              final fullText = _currentVerses
                  .map((v) => '${v.verse}. ${v.text}')
                  .join('\n');
              Clipboard.setData(
                ClipboardData(
                  text: '${book.name} $_currentChapter (TB)\n\n$fullText',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Seluruh pasal ${book.name} $_currentChapter disalin!',
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoadingChapter
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 14),
                  Text(
                    'Memuat teks firman...',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  controller: _readerScrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    // Header perikop
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${book.name} Pasal $_currentChapter',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              book.testament == 'PL'
                                  ? 'Perjanjian Lama'
                                  : 'Perjanjian Baru',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_currentVerses.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              const Text(
                                'Teks pasal belum dapat dimuat.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () =>
                                    _loadChapter(book, _currentChapter),
                                child: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._currentVerses.map(
                        (v) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                margin: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${v.verse}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.secondaryDark,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SelectableText(
                                  v.text,
                                  style: TextStyle(
                                    fontSize: _fontSize,
                                    height: 1.6,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  size: 16,
                                  color: AppTheme.textMuted,
                                ),
                                tooltip: 'Salin Ayat',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: '${v.reference} (TB) - "${v.text}"',
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Ayat ${v.reference} disalin!',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),

                    // Navigation buttons (Prev & Next Chapter)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed:
                              _currentChapter == 1 &&
                                  book.bookId == BibleData.books.first.bookId
                              ? null
                              : _goToPreviousChapter,
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Pasal Sebelumnya'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed:
                              _currentChapter == book.chapters &&
                                  book.bookId == BibleData.books.last.bookId
                              ? null
                              : _goToNextChapter,
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Pasal Berikutnya'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
