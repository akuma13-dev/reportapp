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
  late String _currentDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDate = getTanggalNow();
    _pingServer();
    if (widget.editReport != null) {
      final r = widget.editReport!;
      _petugasController.text = r.namaPetugas;
      _pasienController.text = r.namaPasien;
      _inputController.text = r.inputReport;
      _translatedController.text = r.translatedReport;
    }
  }

  void _pingServer() async {
    await ApiServices.translateAndAnalyze(text: "ping", from: "id", to: "ja");
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
      final tempInput = _inputController.text;
      final tempTranslated = _translatedController.text;
      _inputController.text = tempTranslated;
      _translatedController.text = tempInput;
      _romaji = "";
    });
  }

  void _translate() async {
    final input = _inputController.text;
    if (input.isEmpty) return;

    setState(() => _isLoading = true);

    try {
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
        _romaji = result['romaji'] ?? '';

        if (!isIdToJa && result['japanese_text'] != null && result['japanese_text'] != input) {
          _inputController.text = result['japanese_text'];
        }
      });
    } catch (e) {
      setState(() {
        _translatedController.text = "Error: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _saveReport() async {
    if (_formKey.currentState!.validate()) {
      final report = Report(
        namaPetugas: _petugasController.text,
        namaPasien: _pasienController.text,
        tanggal: _currentDate,
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_petugasController, 'Nama Petugas 担当者の名前', Icons.person_outline),
              const SizedBox(height: 12),
              _buildTextField(_pasienController, 'Nama Pasien 患者の名前', Icons.local_hospital_outlined),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text("Tanggal 日付: $_currentDate")
                ],
              ),
              const SizedBox(height: 20),
              _buildLanguageSwap(),
              const SizedBox(height: 12),
              _buildReportInput(),
              const SizedBox(height: 20),
              _buildTranslatedOutput(),
              if (_romaji.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('🔤 Romaji:', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_romaji, style: GoogleFonts.notoSans(fontStyle: FontStyle.italic, fontSize: 14, color: Colors.grey[700]))
              ],
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildButton(Icons.translate, "Translate", Colors.indigo, _translate),
              const SizedBox(height: 10),
              _buildButton(Icons.save, "Save Report", Colors.green, _saveReport),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            validator: (value) => value!.isEmpty ? 'Wajib diisi!' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSwap() {
    return GestureDetector(
      onTap: _swapLang,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(isIdToJa ? "🇮🇩" : "🇯🇵", style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            isIdToJa ? "ID → JA" : "JA → ID",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(isIdToJa ? "🇯🇵" : "🇮🇩", style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildReportInput() {
    return TextFormField(
      controller: _inputController,
      maxLines: null,
      style: isIdToJa ? GoogleFonts.notoSans(fontSize: 16) : GoogleFonts.notoSansJp(fontSize: 16),
      decoration: InputDecoration(
        labelText: isIdToJa ? '✏️ Input Report (Bahasa Indonesia)' : '✏️ Input Report (日本語)',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTranslatedOutput() {
    return TextFormField(
      controller: _translatedController,
      maxLines: null,
      readOnly: true,
      style: isIdToJa ? GoogleFonts.notoSansJp(fontSize: 16) : GoogleFonts.notoSans(fontSize: 16),
      decoration: InputDecoration(
        labelText: isIdToJa ? '📄 Translated Report (日本語)' : '📄 Translated Report (Bahasa Indonesia)',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
