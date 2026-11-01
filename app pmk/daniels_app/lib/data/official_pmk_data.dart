/// Member and interview records belong in private storage, not source control.
class OfficialCandidateInfo {
  final int id;
  final String name;
  final String nickname;
  final String komisi;

  const OfficialCandidateInfo({
    required this.id,
    required this.name,
    required this.nickname,
    required this.komisi,
  });
}

const List<OfficialCandidateInfo> kOfficialCandidates23 = [];

List<Map<String, dynamic>> getOfficialSeedItems() => [];
