import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/official_pmk_data.dart';
import '../../theme/app_theme.dart';

// Model untuk kalkulasi analisis fungsionaris
class CandidateAnalytics {
  final String id;
  final String name;
  final String nickname;
  final String komisi;
  final bool hasInterview;
  final Map<String, String> notes;
  final List<String> top5Given;
  final List<VoteReceived> votesReceived;
  final List<int> ranksReceived; // [r1, r2, r3, r4, r5]
  final int totalRecommendations;
  final int weightedScore;
  final String lanjutCode; // 'LANJUT', 'RAGU', 'TIDAK_LANJUT', 'BELUM'
  final String lanjutLabel;
  final Color lanjutColor;
  final String caketumLabel;
  final Color caketumColor;
  final bool caketumWilling;

  CandidateAnalytics({
    required this.id,
    required this.name,
    required this.nickname,
    required this.komisi,
    required this.hasInterview,
    required this.notes,
    required this.top5Given,
    required this.votesReceived,
    required this.ranksReceived,
    required this.totalRecommendations,
    required this.weightedScore,
    required this.lanjutCode,
    required this.lanjutLabel,
    required this.lanjutColor,
    required this.caketumLabel,
    required this.caketumColor,
    required this.caketumWilling,
  });
}

class VoteReceived {
  final String voterName;
  final String voterNickname;
  final String voterKomisi;
  final int rank;
  final int points;

  VoteReceived({
    required this.voterName,
    required this.voterNickname,
    required this.voterKomisi,
    required this.rank,
    required this.points,
  });
}

class VisualisasiScreen extends StatefulWidget {
  final List<dynamic> items; // List<NameItem>
  final VoidCallback? onBackToHome;
  final VoidCallback? onGoToInterview;
  final Function(List<Map<String, dynamic>>)? onLoadOfficialData;

  const VisualisasiScreen({
    super.key,
    required this.items,
    this.onBackToHome,
    this.onGoToInterview,
    this.onLoadOfficialData,
  });

  @override
  State<VisualisasiScreen> createState() => _VisualisasiScreenState();
}

class _VisualisasiScreenState extends State<VisualisasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedKomisiFilter = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Helper resolusi nama pemilih / kandidat
  String? _resolveCandidateName(String input) {
    final s = input.trim().toLowerCase();
    if (s.isEmpty) return null;

    // fallback cari kemiripan di official list
    for (final off in kOfficialCandidates23) {
      if (off.name.toLowerCase().contains(s) ||
          off.nickname.toLowerCase().contains(s)) {
        return off.name;
      }
    }
    return null;
  }

  List<String> _parseTop5(String text) {
    if (text.trim().isEmpty) return [];
    final List<String> rawParts = text.contains('\n')
        ? text.split('\n')
        : text.split(',');

    final List<String> results = [];
    for (var part in rawParts) {
      part = part.trim();
      if (part.isEmpty) continue;
      // Hapus prefix numbering: "1.", "2)", dll
      part = part.replaceAll(RegExp(r'^[\d\.\)\-\s]+'), '').trim();
      final resolved = _resolveCandidateName(part);
      if (resolved != null && !results.contains(resolved)) {
        results.add(resolved);
      }
    }
    return results.take(5).toList();
  }

  List<CandidateAnalytics> _buildAnalytics() {
    // Bangun map kandidat dari items yang ada
    final Map<String, dynamic> rawItemMap = {};
    for (var item in widget.items) {
      final name = item.name.toString();
      final resolved = _resolveCandidateName(name) ?? name;
      rawItemMap[resolved] = item;
    }

    final List<CandidateAnalytics> list = [];
    final weights = [5, 4, 3, 2, 1];

    // Gunakan daftar resmi 23 sebagai baseline jika ada, tambahkan item lain
    final List<OfficialCandidateInfo> baseCandidates = List.from(
      kOfficialCandidates23,
    );

    for (final off in baseCandidates) {
      final rawItem = rawItemMap[off.name];
      final Map<String, String> notes = {};
      bool hasInterview = false;

      if (rawItem != null) {
        hasInterview = rawItem.isChecked == true;
        if (rawItem.notes is Map) {
          (rawItem.notes as Map).forEach((k, v) {
            notes[k.toString()] = v?.toString() ?? '';
          });
        }
      }

      final lanjutText =
          (notes['Lanjut jadi pengururs? Kalau ngga, kenapa & kesibukan apa?'] ??
                  '')
              .toLowerCase();
      final caketumText =
          (notes['Apakah bersedia kalau menjadi calon ketua?'] ??
                  notes['Apakah bersedia kalau menjadi calon'] ??
                  '')
              .toLowerCase();

      // Kategori Lanjut
      String lCode = 'BELUM';
      String lLabel = 'Belum Wawancara';
      Color lColor = Colors.grey;

      if (hasInterview) {
        if (lanjutText.contains('tidak') ||
            lanjutText.contains('ngga') ||
            lanjutText.contains('gak')) {
          lCode = 'TIDAK_LANJUT';
          lLabel = 'Tidak Lanjut';
          lColor = const Color(0xFFEF4444);
        } else if (lanjutText.contains('ragu') ||
            lanjutText.contains('50') ||
            lanjutText.contains('belum kepikiran')) {
          lCode = 'RAGU';
          lLabel = 'Ragu-ragu';
          lColor = const Color(0xFFF59E0B);
        } else {
          lCode = 'LANJUT';
          lLabel = 'Lanjut 2026';
          lColor = const Color(0xFF10B981);
        }
      }

      // Kategori Caketum
      String cLabel = hasInterview ? 'Tidak Bersedia' : 'Belum Wawancara';
      Color cColor = Colors.grey;
      bool cWilling = false;

      if (hasInterview) {
        if (lanjutText.contains('mau jadi ketua') ||
            caketumText.contains('mau ngajuin diri') ||
            caketumText.contains('sangat bersedia')) {
          cLabel = 'Sangat Bersedia (Proaktif)';
          cColor = const Color(0xFF8B5CF6);
          cWilling = true;
        } else if (caketumText.contains('yakin') ||
            caketumText.contains('bpi') ||
            caketumText.contains('bph')) {
          cLabel = 'Bersedia (BPI/BPH)';
          cColor = const Color(0xFF3B82F6);
          cWilling = true;
        } else if (caketumText.contains('dipercaya') ||
            caketumText.contains('gapapa')) {
          cLabel = 'Bersedia Jika Dipercaya';
          cColor = const Color(0xFF06B6D4);
          cWilling = true;
        } else if (caketumText.contains('doa') ||
            caketumText.contains('pikir') ||
            caketumText.contains('bingung')) {
          cLabel = 'Perlu Pertimbangan / Doa';
          cColor = const Color(0xFFF59E0B);
        } else {
          cLabel = 'Tidak Bersedia';
          cColor = const Color(0xFFEF4444);
        }
      }

      final top5Raw =
          notes['Top 5 nama cocok?'] ??
          notes['Top 5 nama cocok jadi ketum?'] ??
          '';
      final top5Given = _parseTop5(top5Raw);

      list.add(
        CandidateAnalytics(
          id: off.id.toString(),
          name: off.name,
          nickname: off.nickname,
          komisi: off.komisi,
          hasInterview: hasInterview,
          notes: notes,
          top5Given: top5Given,
          votesReceived: [],
          ranksReceived: [0, 0, 0, 0, 0],
          totalRecommendations: 0,
          weightedScore: 0,
          lanjutCode: lCode,
          lanjutLabel: lLabel,
          lanjutColor: lColor,
          caketumLabel: cLabel,
          caketumColor: cColor,
          caketumWilling: cWilling,
        ),
      );
    }

    // Hitung suara yang masuk ke masing-masing kandidat
    final Map<String, CandidateAnalytics> mapByName = {
      for (var c in list) c.name: c,
    };

    for (final voter in list) {
      for (int rankIdx = 0; rankIdx < voter.top5Given.length; rankIdx++) {
        final targetName = voter.top5Given[rankIdx];
        if (mapByName.containsKey(targetName)) {
          final target = mapByName[targetName]!;
          final rank = rankIdx + 1;
          final pts = weights[rankIdx];

          target.votesReceived.add(
            VoteReceived(
              voterName: voter.name,
              voterNickname: voter.nickname,
              voterKomisi: voter.komisi,
              rank: rank,
              points: pts,
            ),
          );
          target.ranksReceived[rankIdx]++;
        }
      }
    }

    // Update total rec dan skor
    for (int i = 0; i < list.length; i++) {
      final c = list[i];
      int score = 0;
      for (int r = 0; r < 5; r++) {
        score += c.ranksReceived[r] * weights[r];
      }
      list[i] = CandidateAnalytics(
        id: c.id,
        name: c.name,
        nickname: c.nickname,
        komisi: c.komisi,
        hasInterview: c.hasInterview,
        notes: c.notes,
        top5Given: c.top5Given,
        votesReceived: c.votesReceived,
        ranksReceived: c.ranksReceived,
        totalRecommendations: c.votesReceived.length,
        weightedScore: score,
        lanjutCode: c.lanjutCode,
        lanjutLabel: c.lanjutLabel,
        lanjutColor: c.lanjutColor,
        caketumLabel: c.caketumLabel,
        caketumColor: c.caketumColor,
        caketumWilling: c.caketumWilling,
      );
    }

    return list;
  }

  void _showCandidateDossier(CandidateAnalytics cand) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Grab Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // Header Nama & Komisi
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            cand.nickname.isNotEmpty
                                ? cand.nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cand.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Komisi ${cand.komisi}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cand.lanjutColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cand.lanjutLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: cand.lanjutColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),

                    // Kartu Statistik Suara Rekomendasi
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatBadge(
                            'Total Rekomendasi',
                            '${cand.totalRecommendations} Rekan',
                            Icons.people_outline,
                            AppTheme.primary,
                          ),
                          Container(
                            width: 1,
                            height: 35,
                            color: Colors.grey.shade300,
                          ),
                          _buildStatBadge(
                            'Skor Terbobot',
                            '${cand.weightedScore} Pts',
                            Icons.star_outline,
                            const Color(0xFFD97706),
                          ),
                          Container(
                            width: 1,
                            height: 35,
                            color: Colors.grey.shade300,
                          ),
                          _buildStatBadge(
                            'Status Calon',
                            cand.caketumWilling ? 'Bersedia' : 'Belum/Tidak',
                            Icons.check_circle_outline,
                            cand.caketumColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bagian 1: Jawaban Wawancara 7 Pertanyaan
                    const Text(
                      'CATATAN RESMI 7 PERTANYAAN WAWANCARA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!cand.hasInterview)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Fungsionaris ini belum memiliki catatan wawancara di sistem. Anda dapat mengisinya langsung di tab Interview.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      _buildQAItem(
                        '1. Pengalaman di PMK?',
                        cand.notes['Pengalaman di PMK?'],
                      ),
                      _buildQAItem(
                        '2. Apa yang perlu diperbaiki (PMK dan Proker)?',
                        cand.notes['Apa yang perlu diperbaiki (PMK dan Proker)?'],
                      ),
                      _buildQAItem(
                        '3. Paling enak ajak kerjasama?',
                        cand.notes['Paling enak ajak kerjasama?'],
                      ),
                      _buildQAItem(
                        '4. Paling ga enak?',
                        cand.notes['Paling ga enak?'],
                      ),
                      _buildQAItem(
                        '5. Lanjut jadi pengurus? Kalau ngga, kenapa & kesibukan apa?',
                        cand.notes['Lanjut jadi pengururs? Kalau ngga, kenapa & kesibukan apa?'],
                      ),
                      _buildQAItem(
                        '6. Top 5 nama cocok jadi ketum?',
                        cand.notes['Top 5 nama cocok?'] ??
                            cand.notes['Top 5 nama cocok jadi ketum?'],
                      ),
                      _buildQAItem(
                        '7. Apakah bersedia menjadi calon ketua?',
                        cand.notes['Apakah bersedia kalau menjadi calon ketua?'] ??
                            cand.notes['Apakah bersedia kalau menjadi calon'],
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Bagian 2: Suara Rekomendasi yang Diterima
                    Text(
                      'DIREKOMENDASIKAN OLEH (${cand.votesReceived.length} ORANG)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (cand.votesReceived.isEmpty)
                      const Text(
                        'Belum ada fungsionaris yang merekomendasikan dalam Top 5.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      )
                    else
                      ...cand.votesReceived.map(
                        (v) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRankBadgeColor(
                                    v.rank,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Pilihan #${v.rank}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getRankBadgeColor(v.rank),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${v.voterName} (${v.voterKomisi})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '+${v.points} pts',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String title, String val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildQAItem(String q, String? a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              (a != null && a.trim().isNotEmpty)
                  ? a.trim()
                  : '(Belum ada catatan)',
              style: TextStyle(
                fontSize: 12,
                color: (a != null && a.trim().isNotEmpty)
                    ? AppTheme.textPrimary
                    : Colors.grey,
                fontStyle: (a != null && a.trim().isNotEmpty)
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankBadgeColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFD97706); // Gold
      case 2:
        return const Color(0xFF475569); // Silver
      case 3:
        return const Color(0xFFB45309); // Bronze
      case 4:
        return const Color(0xFF0284C7); // Cyan
      case 5:
        return const Color(0xFF4F46E5); // Indigo
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsList = _buildAnalytics();

    // Saring sesuai komisi & pencarian
    final filteredList = analyticsList.where((c) {
      final matchesKomisi =
          _selectedKomisiFilter == 'Semua' || c.komisi == _selectedKomisiFilter;
      final matchesSearch =
          _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.nickname.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesKomisi && matchesSearch;
    }).toList();

    // Hitung KPI Cepat
    final totalFungsio = analyticsList.length;
    final sudahWawancara = analyticsList.where((c) => c.hasInterview).length;
    final bersediaCaketum = analyticsList.where((c) => c.caketumWilling).length;
    final lanjutCount = analyticsList
        .where((c) => c.lanjutCode == 'LANJUT')
        .length;
    final pctLanjut = sudahWawancara > 0
        ? (lanjutCount / sudahWawancara * 100).toStringAsFixed(1)
        : '0';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visualisasi & Matriks Regenerasi',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'Analisis Rekapitulasi Calon Ketua Umum PMK Daniel 2026',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.download_for_offline_outlined,
              color: AppTheme.primary,
            ),
            tooltip: 'Periksa data awal',
            onPressed: () => _confirmLoadOfficialData(),
          ),
          IconButton(
            icon: const Icon(
              Icons.open_in_browser_rounded,
              color: AppTheme.primary,
            ),
            tooltip: 'Buka Dashboard Web Lengkap',
            onPressed: _openWebDashboard,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.emoji_events_outlined, size: 20),
              text: 'Leaderboard',
            ),
            Tab(
              icon: Icon(Icons.grid_on_outlined, size: 20),
              text: 'Matriks 23x23',
            ),
            Tab(
              icon: Icon(Icons.pie_chart_outline, size: 20),
              text: 'Statistik & Status',
            ),
            Tab(
              icon: Icon(Icons.handshake_outlined, size: 20),
              text: 'Kolaborasi',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // KPI Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildKpiCard(
                  'Total Peserta',
                  '$totalFungsio Orang',
                  const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  'Wawancara',
                  '$sudahWawancara ($pctLanjut%)',
                  const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  'Siap Caketum',
                  '$bersediaCaketum Calon',
                  const Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 8),
                _buildKpiCard(
                  'Siap Lanjut',
                  '$lanjutCount Orang',
                  const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Konten Tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Leaderboard
                _buildLeaderboardTab(analyticsList),

                // Tab 2: Matriks 23x23 Spreadsheet
                _buildMatrixTab(analyticsList),

                // Tab 3: Statistik & Regenerasi
                _buildStatsTab(analyticsList),

                // Tab 4: Kolaborasi & Evaluasi Proker
                _buildCollaborationTab(analyticsList),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: LEADERBOARD CALON KETUA UMUM
  // -------------------------------------------------------------
  Widget _buildLeaderboardTab(List<CandidateAnalytics> all) {
    final sorted = List<CandidateAnalytics>.from(all)
      ..sort((a, b) {
        final cmp = b.totalRecommendations.compareTo(a.totalRecommendations);
        if (cmp != 0) return cmp;
        return b.weightedScore.compareTo(a.weightedScore);
      });

    final maxScore = sorted.isNotEmpty && sorted.first.weightedScore > 0
        ? sorted.first.weightedScore
        : 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // Penjelasan Bobot
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: const Row(
            children: [
              Icon(Icons.military_tech, color: Color(0xFFD97706), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Perhitungan Skor Bobot: Pilihan 1 = 5 pts | Pilihan 2 = 4 pts | Pilihan 3 = 3 pts | Pilihan 4 = 2 pts | Pilihan 5 = 1 pt',
                  style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List Kandidat
        ...sorted.asMap().entries.map((entry) {
          final idx = entry.key;
          final c = entry.value;
          final rankNumber = idx + 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: rankNumber <= 3
                    ? _getRankBadgeColor(rankNumber).withValues(alpha: 0.3)
                    : Colors.grey.shade200,
                width: rankNumber <= 3 ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showCandidateDossier(c),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Rank Badge
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: rankNumber <= 3
                                ? _getRankBadgeColor(rankNumber)
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$rankNumber',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: rankNumber <= 3
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Nama & Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (c.caketumWilling) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: Color(0xFFD97706),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Komisi ${c.komisi}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.caketumColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      c.caketumLabel,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: c.caketumColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Skor Bobot & Rekomendasi
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${c.totalRecommendations} Rekan',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              '${c.weightedScore} Pts',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Progress Bar Skor
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c.weightedScore / maxScore,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          rankNumber == 1
                              ? const Color(0xFFD97706)
                              : rankNumber == 2
                              ? AppTheme.primary
                              : AppTheme.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: MATRIKS 23x23 SPREADSHEET
  // -------------------------------------------------------------
  Widget _buildMatrixTab(List<CandidateAnalytics> all) {
    return Column(
      children: [
        // Legend Status Baris & Kolom
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLegendItem('Rec #1 (5pt)', const Color(0xFFD97706)),
                const SizedBox(width: 8),
                _buildLegendItem('Rec #2 (4pt)', const Color(0xFF475569)),
                const SizedBox(width: 8),
                _buildLegendItem('Rec #3 (3pt)', const Color(0xFFB45309)),
                const SizedBox(width: 8),
                _buildLegendItem('Rec #4 (2pt)', const Color(0xFF0284C7)),
                const SizedBox(width: 8),
                _buildLegendItem('Rec #5 (1pt)', const Color(0xFF4F46E5)),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // Matriks Grid Scrollable (Horizontal & Vertical)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DataTable(
                  columnSpacing: 14,
                  horizontalMargin: 10,
                  headingRowColor: WidgetStateProperty.all(AppTheme.primary),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  dataRowMinHeight: 38,
                  dataRowMaxHeight: 44,
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 0.5,
                  ),
                  columns: [
                    const DataColumn(label: Text('No')),
                    const DataColumn(label: Text('Nama Pemilih')),
                    ...all.map(
                      (target) => DataColumn(
                        label: Text(
                          target.nickname,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                  rows: [
                    // Baris untuk setiap pemilih
                    ...all.asMap().entries.map((entry) {
                      final rIdx = entry.key;
                      final voter = entry.value;

                      return DataRow(
                        color: WidgetStateProperty.resolveWith<Color>((_) {
                          if (voter.lanjutCode == 'LANJUT') {
                            return const Color(
                              0xFFD1FAE5,
                            ).withValues(alpha: 0.5);
                          }
                          if (voter.lanjutCode == 'RAGU') {
                            return const Color(
                              0xFFFEF3C7,
                            ).withValues(alpha: 0.5);
                          }
                          if (voter.lanjutCode == 'TIDAK_LANJUT') {
                            return const Color(
                              0xFFFEE2E2,
                            ).withValues(alpha: 0.5);
                          }
                          return Colors.white;
                        }),
                        cells: [
                          DataCell(
                            Text(
                              '${rIdx + 1}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          DataCell(
                            InkWell(
                              onTap: () => _showCandidateDossier(voter),
                              child: Text(
                                voter.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: voter.caketumWilling
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontStyle: voter.caketumWilling
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                          ...all.map((target) {
                            final targetRankIdx = voter.top5Given.indexOf(
                              target.name,
                            );
                            if (targetRankIdx != -1) {
                              final rank = targetRankIdx + 1;
                              return DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRankBadgeColor(
                                      rank,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#$rank',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getRankBadgeColor(rank),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const DataCell(
                              Text(
                                '-',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),

                    // Baris Footer: Total Rekomendasi
                    DataRow(
                      color: WidgetStateProperty.all(const Color(0xFFFEF3C7)),
                      cells: [
                        const DataCell(Text('')),
                        const DataCell(
                          Text(
                            'Total Rekomendasi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        ...all.map(
                          (target) => DataCell(
                            Center(
                              child: Text(
                                '${target.totalRecommendations}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Baris Footer: Total Skor Bobot
                    DataRow(
                      color: WidgetStateProperty.all(
                        AppTheme.primary.withValues(alpha: 0.15),
                      ),
                      cells: [
                        const DataCell(Text('')),
                        const DataCell(
                          Text(
                            'Total Skor Bobot',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        ...all.map(
                          (target) => DataCell(
                            Center(
                              child: Text(
                                '${target.weightedScore}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: STATISTIK & KELANJUTAN
  // -------------------------------------------------------------
  Widget _buildStatsTab(List<CandidateAnalytics> all) {
    final interviewed = all.where((c) => c.hasInterview).toList();
    final lanjutList = interviewed
        .where((c) => c.lanjutCode == 'LANJUT')
        .toList();
    final raguList = interviewed.where((c) => c.lanjutCode == 'RAGU').toList();
    final tidakLanjutList = interviewed
        .where((c) => c.lanjutCode == 'TIDAK_LANJUT')
        .toList();
    final willingCaketumList = interviewed
        .where((c) => c.caketumWilling)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Ringkasan Status Lanjut Kepengurusan
        const Text(
          'STATUS KELANJUTAN KEPENGURUSAN 2026',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _buildStatCard(
          'Lanjut Periode 2026',
          '${lanjutList.length} Orang (${(lanjutList.length / interviewed.length * 100).toStringAsFixed(1)}%)',
          lanjutList.map((c) => c.nickname).join(', '),
          const Color(0xFF10B981),
          Icons.thumb_up_alt_outlined,
        ),
        const SizedBox(height: 8),
        _buildStatCard(
          'Ragu-ragu / 50-50',
          '${raguList.length} Orang (${(raguList.length / interviewed.length * 100).toStringAsFixed(1)}%)',
          raguList.map((c) => c.nickname).join(', '),
          const Color(0xFFF59E0B),
          Icons.help_outline,
        ),
        const SizedBox(height: 8),
        _buildStatCard(
          'Tidak Lanjut',
          '${tidakLanjutList.length} Orang (${(tidakLanjutList.length / interviewed.length * 100).toStringAsFixed(1)}%)',
          tidakLanjutList.map((c) => c.nickname).join(', '),
          const Color(0xFFEF4444),
          Icons.thumb_down_alt_outlined,
        ),
        const SizedBox(height: 20),

        // Calon yang Bersedia Menjadi Ketua Umum
        const Text(
          'DAFTAR KESEDIAAN CALON KETUA UMUM',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ...willingCaketumList.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.caketumColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.stars_rounded, color: c.caketumColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Komisi ${c.komisi}  ${c.caketumLabel}',
                        style: TextStyle(
                          fontSize: 11,
                          color: c.caketumColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${c.totalRecommendations} Rec',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String countText,
    String names,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                countText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            names.isNotEmpty ? names : '-',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: KOLABORASI & EVALUASI PROKER
  // -------------------------------------------------------------
  Widget _buildCollaborationTab(List<CandidateAnalytics> all) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top Rekan Paling Enak Kerjasama
        const Text(
          'FIGUR PALING BANYAK DISEBUT "PALING ENAK KERJASAMA"',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildCollabRow(
                'Ringkasan belum tersedia',
                '',
                'Penilaian individu tidak disertakan dalam source publik.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Temuan Masukan Perbaikan Proker
        const Text(
          'RINGKASAN TEMA MASUKAN PERBAIKAN PMK & PROKER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _buildThemeCard(
          'Evaluasi kegiatan',
          'Ringkasan evaluasi pribadi tidak disertakan dalam source publik.',
          const Color(0xFFEF4444),
        ),
      ],
    );
  }

  static Widget _buildCollabRow(String name, String count, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildThemeCard(String title, String content, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  void _confirmLoadOfficialData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data awal pribadi tidak disertakan'),
        content: const Text(
          'Versi source ini tidak menyertakan nama anggota atau jawaban wawancara pribadi. Gunakan menu impor cadangan di halaman Interview untuk memuat data milikmu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.onLoadOfficialData != null) {
                final seed = getOfficialSeedItems();
                widget.onLoadOfficialData!(seed);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Berhasil memuat 23 data fungsionaris resmi!',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Muat Sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _openWebDashboard() async {
    // Coba buka visualisasi dashboard lokal / web
    final uri = Uri.parse('http://localhost:8080/dashboard.html');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Jalankan jalankan_pwa_di_wifi.bat terlebih dahulu untuk membuka dashboard di browser.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error launching web: $e');
    }
  }
}
