class Report {
  final int? id;
  final String namaPetugas;
  final String namaPasien;
  final String tanggal;
  final String inputReport;
  final String translatedReport;
  final String romaji;
  final String breakdown;

  Report({
    this.id,
    required this.namaPetugas,
    required this.namaPasien,
    required this.tanggal,
    required this.inputReport,
    required this.translatedReport,
    required this.romaji,
    required this.breakdown,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'namaPetugas': namaPetugas,
      'namaPasien': namaPasien,
      'tanggal': tanggal,
      'inputReport': inputReport,
      'translatedReport': translatedReport,
      'romaji': romaji,
      'breakdown': breakdown,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'],
      namaPetugas: map['namaPetugas'],
      namaPasien: map['namaPasien'],
      tanggal: map['tanggal'],
      inputReport: map['inputReport'],
      translatedReport: map['translatedReport'],
      romaji: map['romaji'] ?? '',
      breakdown: map['breakdown'] ?? '',
    );
  }
}
