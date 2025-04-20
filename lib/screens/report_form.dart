import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/db_helper.dart';
import '../data/models/report_model.dart';
import '../services/api_services.dart';

class ReportFormPage extends StatefulWidget {
  final Report? editReport;
  const ReportFormPage({super.key, this.editReport});

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _petugasController = TextEditingController();
  final TextEditingController _pasienController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _translatedController = TextEditingController();

  String _romaji = "";
  bool isIdToJa = true;

  @override
  void initState() {
    super.initState();
    if (widget.editReport != null) {
      final r = widget.editReport!;
      _petugasController.text = r.namaPetugas;
      _pasienController.text = r.namaPasien;
      _inputController.text = r.inputReport;
      _translatedController.text = r.translatedReport;
    }
  }

  String getTanggalNow() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _petugasController.dispose();
    _pasienController.dispose();
    _inputController.dispose();
    _translatedController.dispose();
    super.dispose();
  }

  void _swapLang() {
    setState(() {
      isIdToJa = !isIdToJa;
      _inputController.clear();
      _translatedController.clear();
      _romaji = "";
    });
  }

  void _translate() async {
    final input = _inputController.text;
    if (input.isEmpty) return;

    final from = isIdToJa ? "id" : "ja";
    final to = isIdToJa ? "ja" : "id";

    final result = await ApiServices.translateAndAnalyze(
      text: input,
      from: from,
      to: to,
    );

    if (!mounted) return;
    setState(() {
      _translatedController.text = result['translated_text'] ?? '';
      _romaji = isIdToJa ? result['romaji'] ?? '' : '';
    });
  }

  void _saveReport() async {
    if (_formKey.currentState!.validate()) {
      final report = Report(
        namaPetugas: _petugasController.text,
        namaPasien: _pasienController.text,
        tanggal: getTanggalNow(),
        inputReport: _inputController.text,
        translatedReport: _translatedController.text,
      );

      await DBHelper.insertReport(report);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Report Form", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _swapLang,
            icon: const Icon(Icons.swap_horiz),
            color: Colors.white,
            tooltip: 'Swap Language',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _petugasController,
                      decoration: const InputDecoration(labelText: 'Nama Petugas 担当者の名前'),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi!' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.local_hospital_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _pasienController,
                      decoration: const InputDecoration(labelText: 'Nama Pasien 患者の名前'),
                      validator: (value) => value!.isEmpty ? 'Wajib diisi!' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text("Tanggal 日付: ${getTanggalNow()}"),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _inputController,
                maxLines: null,
                style: isIdToJa
                    ? GoogleFonts.notoSans(fontSize: 16)
                    : GoogleFonts.notoSansJp(fontSize: 16),
                decoration: InputDecoration(
                  labelText: isIdToJa
                      ? '✏️ Input Report (Bahasa Indonesia)'
                      : '✏️ Input Report (日本語)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _translatedController,
                maxLines: null,
                readOnly: true,
                style: isIdToJa
                    ? GoogleFonts.notoSansJp(fontSize: 16)
                    : GoogleFonts.notoSans(fontSize: 16),
                decoration: InputDecoration(
                  labelText: isIdToJa
                      ? '📄 Translated Report (日本語)'
                      : '📄 Translated Report (Bahasa Indonesia)',
                  border: const OutlineInputBorder(),
                ),
              ),
              if (isIdToJa && _romaji.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('🔤 Romaji:', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_romaji, style: GoogleFonts.notoSans(fontStyle: FontStyle.italic, fontSize: 14, color: Colors.grey[700])),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _translate,
                icon: const Icon(Icons.translate),
                label: const Text("Translate"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _saveReport,
                icon: const Icon(Icons.save),
                label: const Text("Save Report"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
