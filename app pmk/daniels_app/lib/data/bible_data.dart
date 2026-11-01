import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BibleBook {
  final int bookId;
  final String name;
  final String abbr;
  final String testament; // 'PL' atau 'PB'
  final String category;
  final int chapters;

  const BibleBook({
    required this.bookId,
    required this.name,
    required this.abbr,
    required this.testament,
    required this.category,
    required this.chapters,
  });
}

class BibleVerse {
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String? topic;

  const BibleVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.topic,
  });

  String get reference => '$book $chapter:$verse';
}

class BibleData {
  static const List<BibleBook> books = [
    // PERJANJIAN LAMA (PL) - 39 Kitab
    BibleBook(bookId: 1, name: 'Kejadian', abbr: 'Kej', testament: 'PL', category: 'Taurat', chapters: 50),
    BibleBook(bookId: 2, name: 'Keluaran', abbr: 'Kel', testament: 'PL', category: 'Taurat', chapters: 40),
    BibleBook(bookId: 3, name: 'Imamat', abbr: 'Ima', testament: 'PL', category: 'Taurat', chapters: 27),
    BibleBook(bookId: 4, name: 'Bilangan', abbr: 'Bil', testament: 'PL', category: 'Taurat', chapters: 36),
    BibleBook(bookId: 5, name: 'Ulangan', abbr: 'Ula', testament: 'PL', category: 'Taurat', chapters: 34),
    BibleBook(bookId: 6, name: 'Yosua', abbr: 'Yos', testament: 'PL', category: 'Sejarah', chapters: 24),
    BibleBook(bookId: 7, name: 'Hakim-hakim', abbr: 'Hak', testament: 'PL', category: 'Sejarah', chapters: 21),
    BibleBook(bookId: 8, name: 'Rut', abbr: 'Rut', testament: 'PL', category: 'Sejarah', chapters: 4),
    BibleBook(bookId: 9, name: '1 Samuel', abbr: '1Sam', testament: 'PL', category: 'Sejarah', chapters: 31),
    BibleBook(bookId: 10, name: '2 Samuel', abbr: '2Sam', testament: 'PL', category: 'Sejarah', chapters: 24),
    BibleBook(bookId: 11, name: '1 Raja-raja', abbr: '1Raj', testament: 'PL', category: 'Sejarah', chapters: 22),
    BibleBook(bookId: 12, name: '2 Raja-raja', abbr: '2Raj', testament: 'PL', category: 'Sejarah', chapters: 25),
    BibleBook(bookId: 13, name: '1 Tawarikh', abbr: '1Taw', testament: 'PL', category: 'Sejarah', chapters: 29),
    BibleBook(bookId: 14, name: '2 Tawarikh', abbr: '2Taw', testament: 'PL', category: 'Sejarah', chapters: 36),
    BibleBook(bookId: 15, name: 'Ezra', abbr: 'Ezr', testament: 'PL', category: 'Sejarah', chapters: 10),
    BibleBook(bookId: 16, name: 'Nehemia', abbr: 'Neh', testament: 'PL', category: 'Sejarah', chapters: 13),
    BibleBook(bookId: 17, name: 'Ester', abbr: 'Est', testament: 'PL', category: 'Sejarah', chapters: 10),
    BibleBook(bookId: 18, name: 'Ayub', abbr: 'Ayb', testament: 'PL', category: 'Puisi & Hikmat', chapters: 42),
    BibleBook(bookId: 19, name: 'Mazmur', abbr: 'Maz', testament: 'PL', category: 'Puisi & Hikmat', chapters: 150),
    BibleBook(bookId: 20, name: 'Amsal', abbr: 'Ams', testament: 'PL', category: 'Puisi & Hikmat', chapters: 31),
    BibleBook(bookId: 21, name: 'Pengkhotbah', abbr: 'Pkh', testament: 'PL', category: 'Puisi & Hikmat', chapters: 12),
    BibleBook(bookId: 22, name: 'Kidung Agung', abbr: 'Kid', testament: 'PL', category: 'Puisi & Hikmat', chapters: 8),
    BibleBook(bookId: 23, name: 'Yesaya', abbr: 'Yes', testament: 'PL', category: 'Nabi-nabi Besar', chapters: 66),
    BibleBook(bookId: 24, name: 'Yeremia', abbr: 'Yer', testament: 'PL', category: 'Nabi-nabi Besar', chapters: 52),
    BibleBook(bookId: 25, name: 'Ratapan', abbr: 'Rat', testament: 'PL', category: 'Nabi-nabi Besar', chapters: 5),
    BibleBook(bookId: 26, name: 'Yehezkiel', abbr: 'Yeh', testament: 'PL', category: 'Nabi-nabi Besar', chapters: 48),
    BibleBook(bookId: 27, name: 'Daniel', abbr: 'Dan', testament: 'PL', category: 'Nabi-nabi Besar', chapters: 12),
    BibleBook(bookId: 28, name: 'Hosea', abbr: 'Hos', testament: 'PL', category: 'Nabi-nabi Kecil', chapters: 14),
    BibleBook(bookId: 29, name: 'Yoel', abbr: 'Yol', testament: 'PL', category: 'Nabi-nabi Kecil', chapters: 3),
    BibleBook(bookId: 30, name: 'Amos', abbr: 'Amo', testament: 'PL', category: 'Nabi-nabi Kecil', chapters: 9),
    BibleBook(bookId: 31, name: 'Obaja', abbr: 'Oba', testament: 'PL', category: 'Nabi-nabi Kecil', chapters: 1),
    BibleBook(bookId: 32, name: 'Yunus', abbr: 'Yun', testament: 'PL', category: 'Nabi-nabi Kecil', chapters: 4),
    BibleBook(bookId: 33, name: 'Mikha', abbr: 'Mik', testament: 'PL', category: 'Nabi-nabi Kecil', chapters: 7),
    BibleBook(bookId: 34, name: 'Nahum', abbr: 'Nah', testament: 'PL', category: 'Nabi-nabi Kecil', chapters: 3),
    BibleBook(bookId: 35, name: 'Habakuk', abbr: 'Hab', testament: 'PL', category: 'Nabi-nabi Kecil', chapters: 3),
    BibleBook(bookId: 36, name: 'Zefanya', abbr: 'Zef', testament: 'PL', category: 'Nabi-nabi Kecil', chapters: 3),
    BibleBook(bookId: 37, name: 'Hagai', abbr: 'Hag', testament: 'PL', category: 'Nabi-nabi Kecil', chapters: 2),
    BibleBook(bookId: 38, name: 'Zakharia', abbr: 'Zak', testament: 'PL', category: 'Nabi-nabi Kecil', chapters: 14),
    BibleBook(bookId: 39, name: 'Maleakhi', abbr: 'Mal', testament: 'PL', category: 'Nabi-nabi Kecil', chapters: 4),

    // PERJANJIAN BARU (PB) - 27 Kitab
    BibleBook(bookId: 40, name: 'Matius', abbr: 'Mat', testament: 'PB', category: 'Injil', chapters: 28),
    BibleBook(bookId: 41, name: 'Markus', abbr: 'Mrk', testament: 'PB', category: 'Injil', chapters: 16),
    BibleBook(bookId: 42, name: 'Lukas', abbr: 'Luk', testament: 'PB', category: 'Injil', chapters: 24),
    BibleBook(bookId: 43, name: 'Yohanes', abbr: 'Yoh', testament: 'PB', category: 'Injil', chapters: 21),
    BibleBook(bookId: 44, name: 'Kisah Para Rasul', abbr: 'Kis', testament: 'PB', category: 'Sejarah', chapters: 28),
    BibleBook(bookId: 45, name: 'Roma', abbr: 'Rom', testament: 'PB', category: 'Surat Paulus', chapters: 16),
    BibleBook(bookId: 46, name: '1 Korintus', abbr: '1Kor', testament: 'PB', category: 'Surat Paulus', chapters: 16),
    BibleBook(bookId: 47, name: '2 Korintus', abbr: '2Kor', testament: 'PB', category: 'Surat Paulus', chapters: 13),
    BibleBook(bookId: 48, name: 'Galatia', abbr: 'Gal', testament: 'PB', category: 'Surat Paulus', chapters: 6),
    BibleBook(bookId: 49, name: 'Efesus', abbr: 'Efe', testament: 'PB', category: 'Surat Paulus', chapters: 6),
    BibleBook(bookId: 50, name: 'Filipi', abbr: 'Flp', testament: 'PB', category: 'Surat Paulus', chapters: 4),
    BibleBook(bookId: 51, name: 'Kolose', abbr: 'Kol', testament: 'PB', category: 'Surat Paulus', chapters: 4),
    BibleBook(bookId: 52, name: '1 Tesalonika', abbr: '1Tes', testament: 'PB', category: 'Surat Paulus', chapters: 5),
    BibleBook(bookId: 53, name: '2 Tesalonika', abbr: '2Tes', testament: 'PB', category: 'Surat Paulus', chapters: 3),
    BibleBook(bookId: 54, name: '1 Timotius', abbr: '1Tim', testament: 'PB', category: 'Surat Pastoral', chapters: 6),
    BibleBook(bookId: 55, name: '2 Timotius', abbr: '2Tim', testament: 'PB', category: 'Surat Pastoral', chapters: 4),
    BibleBook(bookId: 56, name: 'Titus', abbr: 'Tit', testament: 'PB', category: 'Surat Pastoral', chapters: 3),
    BibleBook(bookId: 57, name: 'Filemon', abbr: 'Flm', testament: 'PB', category: 'Surat Paulus', chapters: 1),
    BibleBook(bookId: 58, name: 'Ibrani', abbr: 'Ibr', testament: 'PB', category: 'Surat Am', chapters: 13),
    BibleBook(bookId: 59, name: 'Yakobus', abbr: 'Yak', testament: 'PB', category: 'Surat Am', chapters: 5),
    BibleBook(bookId: 60, name: '1 Petrus', abbr: '1Pet', testament: 'PB', category: 'Surat Am', chapters: 5),
    BibleBook(bookId: 61, name: '2 Petrus', abbr: '2Pet', testament: 'PB', category: 'Surat Am', chapters: 3),
    BibleBook(bookId: 62, name: '1 Yohanes', abbr: '1Yoh', testament: 'PB', category: 'Surat Am', chapters: 5),
    BibleBook(bookId: 63, name: '2 Yohanes', abbr: '2Yoh', testament: 'PB', category: 'Surat Am', chapters: 1),
    BibleBook(bookId: 64, name: '3 Yohanes', abbr: '3Yoh', testament: 'PB', category: 'Surat Am', chapters: 1),
    BibleBook(bookId: 65, name: 'Yudas', abbr: 'Yud', testament: 'PB', category: 'Surat Am', chapters: 1),
    BibleBook(bookId: 66, name: 'Wahyu', abbr: 'Why', testament: 'PB', category: 'Nubuat', chapters: 22),
  ];

  static final Map<int, Map<String, dynamic>> _cache = {};

  /// Memuat ayat-ayat asli Alkitab Terjemahan Baru (TB) untuk kitab dan pasal yang dipilih.
  static Future<List<BibleVerse>> getChapterVerses(BibleBook book, int chapter) async {
    try {
      if (!_cache.containsKey(book.bookId)) {
        final jsonStr = await rootBundle.loadString('assets/bible/${book.bookId}.json');
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        _cache[book.bookId] = data;
      }
      final bookData = _cache[book.bookId];
      final chapterList = bookData?[chapter.toString()];
      if (chapterList is List) {
        return chapterList.map((item) {
          return BibleVerse(
            book: book.name,
            chapter: chapter,
            verse: item['verse'] as int,
            text: (item['text'] as String).replaceAll(RegExp(r'<[^>]*>'), '').trim(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading bible chapter ${book.name} $chapter: $e');
    }
    return [];
  }

  // Koleksi Ayat Emas Harian (Daily Verses)
  static const List<BibleVerse> dailyVerses = [
    BibleVerse(
      book: 'Yeremia',
      chapter: 29,
      verse: 11,
      text: 'Sebab Aku ini mengetahui rancangan-rancangan apa yang ada pada-Ku mengenai kamu, demikianlah firman TUHAN, yaitu rancangan damai sejahtera dan bukan rancangan kecelakaan, untuk memberikan kepadamu hari depan yang penuh harapan.',
      topic: 'Harapan & Masa Depan',
    ),
    BibleVerse(
      book: 'Daniel',
      chapter: 1,
      verse: 8,
      text: 'Daniel berketetapan untuk tidak menajiskan dirinya dengan santapan raja dan dengan anggur yang biasa diminum raja; dimintanyalah kepada pemimpin pegawai istana itu, supaya ia jangan menajiskan dirinya.',
      topic: 'Integritas & Kesetiaan',
    ),
    BibleVerse(
      book: 'Filipi',
      chapter: 4,
      verse: 13,
      text: 'Segala perkara dapat kutanggung di dalam Dia yang memberi kekuatan kepadaku.',
      topic: 'Kekuatan',
    ),
    BibleVerse(
      book: 'Mazmur',
      chapter: 23,
      verse: 1,
      text: 'TUHAN adalah gembalaku, takkan kekurangan aku.',
      topic: 'Pemeliharaan Tuhan',
    ),
    BibleVerse(
      book: 'Yosua',
      chapter: 1,
      verse: 9,
      text: 'Bukankah telah Kuperintahkan kepadamu: kuatkan dan teguhkanlah hatimu? Janganlah kecut dan tawar hati, sebab TUHAN, Allahmu, menyertai engkau, ke mana pun engkau pergi.',
      topic: 'Keberanian',
    ),
    BibleVerse(
      book: 'Amsal',
      chapter: 3,
      verse: 5,
      text: 'Percayalah kepada TUHAN dengan segenap hatimu, dan janganlah bersandar kepada pengertianmu sendiri.',
      topic: 'Kepercayaan',
    ),
    BibleVerse(
      book: 'Roma',
      chapter: 8,
      verse: 28,
      text: 'Kita tahu sekarang, bahwa Allah turut bekerja dalam segala sesuatu untuk mendatangkan kebaikan bagi mereka yang mengasihi Dia, yaitu bagi mereka yang terpanggil sesuai dengan rencana Allah.',
      topic: 'Rencana Allah',
    ),
    BibleVerse(
      book: 'Matius',
      chapter: 6,
      verse: 33,
      text: 'Tetapi carilah dahulu Kerajaan Allah dan kebenarannya, maka semuanya itu akan ditambahkan kepadamu.',
      topic: 'Prioritas Hidup',
    ),
    BibleVerse(
      book: 'Yesaya',
      chapter: 40,
      verse: 31,
      text: 'Tetapi orang-orang yang menanti-nantikan TUHAN mendapat kekuatan baru: mereka seumpama rajawali yang naik terbang dengan kekuatan sayapnya; mereka berlari dan tidak menjadi lesu, mereka berjalan dan tidak menjadi lelah.',
      topic: 'Kekuatan Baru',
    ),
    BibleVerse(
      book: 'Daniel',
      chapter: 2,
      verse: 20,
      text: 'Berkatalah Daniel: "Terpujilah nama Allah dari selama-lamanya sampai selama-lamanya, sebab dari pada Dialah hikmat dan kekuatan!"',
      topic: 'Pujian & Hikmat',
    ),
    BibleVerse(
      book: 'Yohanes',
      chapter: 14,
      verse: 27,
      text: 'Damai sejahtera Kutinggalkan bagimu. Damai sejahtera-Ku Kuberikan kepadamu, dan apa yang Kuberikan tidak seperti yang diberikan oleh dunia kepadamu. Janganlah gelisah dan gentar hatimu.',
      topic: 'Damai Sejahtera',
    ),
    BibleVerse(
      book: '1 Korintus',
      chapter: 13,
      verse: 13,
      text: 'Demikianlah tinggal ketiga hal ini, yaitu iman, pengharapan dan kasih, dan yang paling besar di antaranya ialah kasih.',
      topic: 'Kasih',
    ),
  ];
}
