import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reportapp/screens/report_form.dart';
import '../data/db_helper.dart';
import '../data/models/report_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../services/pdf_generator.dart';

class PreviewPage extends StatelessWidget {
  final Report report;

  const PreviewPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final bool isIdToJa = _isJapanese(report.translatedReport);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Report"),
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
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () {
              _showPrintOptions(context);
            },
            icon: const Icon(Icons.print),
          ),
          IconButton(
            onPressed: () {
              _confirmDelete(context);
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _item("Nama Petugas", report.namaPetugas),
            _item("Nama Pasien", report.namaPasien),
            _item("Tanggal", report.tanggal),
            _item("Input Report", report.inputReport,
                isJapanese: _isJapanese(report.inputReport)),
            _item("Translated Report", report.translatedReport,
                isJapanese: _isJapanese(report.translatedReport)),
          ],
        ),
      ),
    );
  }

  Widget _item(String title, String content, {bool isJapanese = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            content,
            style: isJapanese
                ? GoogleFonts.notoSansJp(fontSize: 16)
                : GoogleFonts.notoSans(fontSize: 16),
          ),
        ],
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