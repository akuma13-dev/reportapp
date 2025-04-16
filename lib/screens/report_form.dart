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
    });
  }

  void _translate() async {
    final input = _inputController.text;
    if (input.isEmpty) return;

    final from = isIdToJa ? "id" : "ja";
    final to = isIdToJa ? "ja" : "id";

    final result = await ApiServices.translateText(
      text: input,
      from: from,
      to: to,
    );

    if (!mounted) return;
    setState(() {
      _translatedController.text = result;
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
        title: const Text("Tambah Report"),
        actions: [
          IconButton(
            onPressed: _swapLang,
            icon: const Icon(Icons.swap_horiz),
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
              TextFormField(
                controller: _petugasController,
                decoration: const InputDecoration(labelText: 'Nama Petugas'),
                validator: (value) =>
                value!.isEmpty ? 'Wajib diisi!' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _pasienController,
                decoration: const InputDecoration(labelText: 'Nama Pasien'),
                validator: (value) =>
                value!.isEmpty ? 'Wajib diisi!' : null,
              ),
              const SizedBox(height: 20),
              Text("Tanggal: ${getTanggalNow()}"),
              const SizedBox(height: 20),
              TextFormField(
                controller: _inputController,
                maxLines: null,
                style: isIdToJa
                    ? GoogleFonts.notoSans(fontSize: 16)
                    : GoogleFonts.notoSansJp(fontSize: 16),
                decoration: InputDecoration(
                  labelText: isIdToJa
                      ? 'Input Report (Bahasa Indonesia)'
                      : 'Input Report (日本語)',
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
                      ? 'Translated Report (日本語)'
                      : 'Translated Report (Bahasa Indonesia)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _translate,
                icon: const Icon(Icons.translate),
                label: const Text("Translate"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _saveReport,
                icon: const Icon(Icons.save),
                label: const Text("Simpan Report"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
