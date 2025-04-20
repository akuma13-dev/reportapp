import 'package:flutter/material.dart';
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
        title: const Text('Nindogo!', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredReports.isEmpty
                ? const Center(child: Text('No reports found'))
                : ListView.separated(
              itemCount: _filteredReports.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final report = _filteredReports[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text('${_filteredReports.length - index}'),
                  ),
                  title: Text(
                    report.namaPasien,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Date: ${formatTanggal(report.tanggal)}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PreviewPage(report: report),
                      ),
                    ).then((_) => _loadReports());
                  },
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
      ),
    );
  }
}
