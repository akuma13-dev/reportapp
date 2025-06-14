import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reportapp/screens/report_form.dart';
import '../data/db_helper.dart';
import '../data/models/report_model.dart';
import 'package:share_plus/share_plus.dart';
import '../services/pdf_generator.dart';

class PreviewPage extends StatelessWidget {
  final Report report;

  const PreviewPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final isJapanese = _isJapanese(report.translatedReport);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Preview", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportFormPage(editReport: report),
                ),
              );
              if (result == true) Navigator.pop(context, true);
            },
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
          IconButton(
            onPressed: () => _showPrintOptions(context),
            icon: const Icon(Icons.share_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _itemTile(Icons.person, "Nama Petugas スタッフの名前", report.namaPetugas),
            _itemTile(Icons.local_hospital, "Nama Pasien 利用者の名前", report.namaPasien),
            _itemTile(Icons.calendar_today, "Tanggal 日付", report.tanggal),
            _itemTile(Icons.description, "Input Report 入力レポート", report.inputReport,
                isJapanese: _isJapanese(report.inputReport)),
            _itemTile(Icons.translate, "Translated Report 翻訳されたレポート", report.translatedReport,
                isJapanese: isJapanese),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(IconData icon, String title, String content, {bool isJapanese = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Colors.indigo),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: isJapanese
                        ? GoogleFonts.notoSansJp(fontSize: 16)
                        : GoogleFonts.notoSans(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isJapanese(String text) {
    return RegExp(r'[\u3040-\u30ff\u4e00-\u9faf]').hasMatch(text);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete report"),
        content: const Text("Are you sure to delete this report?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await DBHelper.deleteReport(report.id!);
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPrintOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text("Share as PDF"),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final path = await PdfGenerator.saveReportAsPDF(report);
                  await Share.shareXFiles(
                    [XFile(path, mimeType: 'application/pdf')],
                    text: "Report: ${report.namaPasien}",
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to share PDF: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
