import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
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

  String _translatedText = "";
  String _romaji = "";
  List<dynamic> _breakdown = [];
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
      _translatedText = r.translatedReport;
      _romaji = r.romaji;
      _breakdown = _parseBreakdownString(r.breakdown);
    }
  }

  void _pingServer() {
    ApiServices.translateAndAnalyze(text: "ping", from: "id", to: "ja");
  }

  String getTanggalNow() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  List<Map<String, String>> _parseBreakdownString(String breakdownStr) {
    return breakdownStr.split('\n').map((line) {
      final match = RegExp(r'^(.+?)（(.+?)） - (.+)\$').firstMatch(line);
      if (match != null) {
        return {
          'surface': match.group(1)!,
          'furigana': match.group(2)!,
          'romaji': match.group(3)!,
        };
      }
      return {'surface': '', 'furigana': '', 'romaji': ''};
    }).toList();
  }

  @override
  void dispose() {
    _petugasController.dispose();
    _pasienController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _swapLang() async {
    setState(() {
      isIdToJa = !isIdToJa;
      final temp = _inputController.text;
      _inputController.text = _translatedText;
      _translatedText = temp;
      _romaji = "";
      _breakdown = [];
    });
    await _translate();
  }

  Future<void> _translate() async {
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
        _translatedText = result['translated_text'] ?? '';
        _romaji = result['romaji'] ?? '';
        _breakdown = isIdToJa ? result['breakdown'] ?? [] : [];

        if (!isIdToJa && result['japanese_text'] != null && result['japanese_text'] != input) {
          _inputController.text = result['japanese_text'];
        }
      });
    } catch (e) {
      setState(() {
        _translatedText = "Error: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _playTTS() async {
    final text = _translatedText;
    final lang = isIdToJa ? "ja" : "id";
    if (text.isEmpty) return;

    final bytes = await ApiServices.textToSpeech(text: text, lang: lang);
    if (bytes == null) return;

    final player = AudioPlayer();
    await player.setAudioSource(
      AudioSource.uri(
        Uri.dataFromBytes(bytes, mimeType: 'audio/mpeg'),
      ),
    );
    await player.play();
  }

  void _saveReport() async {
    if (_formKey.currentState!.validate()) {
      final report = Report(
        namaPetugas: _petugasController.text,
        namaPasien: _pasienController.text,
        tanggal: _currentDate,
        inputReport: _inputController.text,
        translatedReport: _translatedText,
        romaji: _romaji,
        breakdown: _breakdown.map((token) {
          final s = token['surface'];
          final f = token['furigana'];
          final r = token['romaji'];
          return "$s（$f） - $r";
        }).join("\n"),
      );

      await DBHelper.insertReport(report);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Report Form", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_petugasController, 'Nama Petugas スタッフの名前', Icons.person_outline),
              const SizedBox(height: 12),
              _buildTextField(_pasienController, 'Nama Pasien 利用者の名前', Icons.local_hospital_outlined),
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
              if (!isIdToJa && _translatedText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _translatedText,
                    style: GoogleFonts.notoSans(fontSize: 16),
                  ),
                ),
              if (isIdToJa) _buildBreakdownField(),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildButton(Icons.translate, "Translate", Colors.indigo, _translate),
              const SizedBox(height: 10),
              _buildButton(Icons.volume_up, "Play TTS", Colors.deepPurple, _playTTS),
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
            validator: (value) => value!.isEmpty ? 'Required' : null,
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
        labelText: isIdToJa ? 'Input Report (Bahasa Indonesia)' : 'Input Report (日本語)',
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildBreakdownField() {
    if (_breakdown.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _breakdown.map((token) {
          final kanji = token['surface'] ?? '';
          final furi = token['furigana'] ?? '';
          final roma = token['romaji'] ?? '';
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(furi, textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontSize: 10, color: Colors.grey[600])),
              Text(kanji, textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(roma, textAlign: TextAlign.center, style: GoogleFonts.notoSans(fontSize: 11, color: Colors.grey[700])),
            ],
          );
        }).toList(),
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
