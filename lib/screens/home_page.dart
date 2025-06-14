import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/db_helper.dart';
import '../data/models/report_model.dart';
import 'report_form.dart';
import 'preview_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Report> _reports = [];
  List<Report> _filteredReports = [];

  @override
  void initState() {
    super.initState();
    DBHelper.checkResetDatabase();
    _searchController.addListener(_filterReports);
    _loadReports();
  }

  Future<void> _loadReports() async {
    final data = await DBHelper.getReports();
    setState(() {
      _reports = data;
      _filteredReports = data;
    });
  }

  void _filterReports() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredReports = _reports;
      } else {
        _filteredReports = _reports.where((r) {
          return r.namaPasien.toLowerCase().contains(query) ||
              r.namaPetugas.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  String formatTanggal(String tanggal) {
    try {
      final parts = tanggal.split("-");
      final tahun = parts[0];
      final bulan = int.parse(parts[1]);
      final hari = parts[2];

      const namaBulan = [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];

      return "$hari ${namaBulan[bulan]} $tahun";
    } catch (_) {
      return tanggal;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nindogo!', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.notoSans(),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: GoogleFonts.notoSans(color: Colors.grey),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredReports.isEmpty
                ? Center(
              child: Text(
                'There is no report found.',
                style: GoogleFonts.notoSans(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filteredReports.length,
              itemBuilder: (context, index) {
                final report = _filteredReports[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        '${_filteredReports.length - index}',
                        style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      report.namaPasien,
                      style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      "📅 ${formatTanggal(report.tanggal)}\n👤 ${report.namaPetugas}",
                      style: GoogleFonts.notoSans(fontSize: 13, color: Colors.grey[700]),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right, color: Colors.deepPurple),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PreviewPage(report: report),
                        ),
                      );
                      if (result == true) _loadReports();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportFormPage()),
          );
          if (result == true) _loadReports();
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
