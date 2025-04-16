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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReportApp'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari nama pasien / petugas...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredReports.isEmpty
                ? const Center(child: Text('Tidak ada report yang cocok.'))
                : ListView.builder(
              itemCount: _filteredReports.length,
              itemBuilder: (context, index) {
                final report = _filteredReports[index];
                return ListTile(
                  title: Text(report.namaPasien),
                  subtitle: Text(report.tanggal),
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