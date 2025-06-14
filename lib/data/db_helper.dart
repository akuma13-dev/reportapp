import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/report_model.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    await migrateAddMissingFields(); // ← tambahin migrasi aman
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'report.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE report (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        namaPetugas TEXT,
        namaPasien TEXT,
        tanggal TEXT,
        inputReport TEXT,
        translatedReport TEXT,
        romaji TEXT,
        breakdown TEXT
      )
    ''');
  }

  // Optional migrasi jika field belum ada (biar gak crash)
  static Future<void> migrateAddMissingFields() async {
    final db = await database;
    try {
      await db.execute("ALTER TABLE report ADD COLUMN romaji TEXT");
    } catch (e) {
      // ignore kalau kolom sudah ada
    }
    try {
      await db.execute("ALTER TABLE report ADD COLUMN breakdown TEXT");
    } catch (e) {
      // ignore kalau kolom sudah ada
    }
  }

  // Insert
  static Future<int> insertReport(Report report) async {
    final db = await database;
    return await db.insert('report', report.toMap());
  }

  // Get all
  static Future<List<Report>> getReports() async {
    final db = await database;
    final maps = await db.query('report', orderBy: 'id DESC');

    return List.generate(maps.length, (i) {
      return Report.fromMap(maps[i]);
    });
  }

  // Update
  static Future<int> updateReport(Report report) async {
    final db = await database;
    return await db.update(
      'report',
      report.toMap(),
      where: 'id = ?',
      whereArgs: [report.id],
    );
  }

  // Delete
  static Future<int> deleteReport(int id) async {
    final db = await database;
    return await db.delete(
      'report',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Auto-reset database setiap 30 hari
  static Future<void> checkResetDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastResetStr = prefs.getString('lastResetDate');

    if (lastResetStr != null) {
      final lastReset = DateTime.parse(lastResetStr);
      final difference = now.difference(lastReset).inDays;

      if (difference >= 30) {
        final db = await database;
        await db.delete('report');
        await prefs.setString('lastResetDate', now.toIso8601String());
        print("🔁 Report database di-reset otomatis setelah 30 hari");
      }
    } else {
      await prefs.setString('lastResetDate', now.toIso8601String());
    }
  }
}
