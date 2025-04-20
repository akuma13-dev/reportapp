import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reportapp/screens/report_form.dart';
import '../data/db_helper.dart';
import '../data/models/report_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../services/pdf_generator.dart';

class PreviewPage extends StatelessWidget {
  final Report report;

  const PreviewPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final bool isIdToJa = _isJapanese(report.translatedReport);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Detail Report", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportFormPage(editReport: report),
                ),
              );
              if (result == true) {
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              _showPrintOptions(context);
            },
            icon: const Icon(Icons.print, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              _confirmDelete(context);
            },
            icon: const Icon(Icons.delete, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _itemTile(Icons.person, "Nama Petugas 担当者の名前", report.namaPetugas),
            _itemTile(Icons.local_hospital, "Nama Pasien 患者の名前", report.namaPasien),
            _itemTile(Icons.calendar_today, "Tanggal 日付", report.tanggal),
            _itemTile(Icons.description, "Input Report 入力レポート", report.inputReport,
                isJapanese: _isJapanese(report.inputReport)),
            _itemTile(Icons.translate, "Translated Report 翻訳されたレポート", report.translatedReport,
                isJapanese: _isJapanese(report.translatedReport)),
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
        title: const Text("Hapus Report"),
        content: const Text("Yakin ingin menghapus report ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              await DBHelper.deleteReport(report.id!);
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
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
              leading: const Icon(Icons.print),
              title: const Text("Simpan sebagai PDF"),
              onTap: () async {
                final path = await PdfGenerator.saveReportAsPDF(report);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("PDF disimpan di:\n$path")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text("Simpan dan Bagikan"),
              onTap: () async {
                final path = await PdfGenerator.saveReportAsPDF(report);
                Navigator.pop(context);
                await Share.shareXFiles(
                  [XFile(path)],
                  text: "Report pasien: ${report.namaPasien}",
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _printReport(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Report Detail", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              _pdfItem("Nama Petugas", report.namaPetugas),
              _pdfItem("Nama Pasien", report.namaPasien),
              _pdfItem("Tanggal", report.tanggal),
              _pdfItem("Input Report", report.inputReport),
              _pdfItem("Translated Report", report.translatedReport),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  pw.Widget _pdfItem(String title, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(content),
        ],
      ),
    );
  }
}
