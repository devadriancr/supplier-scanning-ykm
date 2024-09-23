import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'scanify.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  void _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        status INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertScan(String code) async {
    try {
      final Database db = await database;

      // Check if the code already exists
      final List<Map<String, dynamic>> existing = await db.query(
        'scans',
        where: 'code = ?',
        whereArgs: [code],
      );

      if (existing.isNotEmpty) {
        // Code already exists
        throw Exception('Code already exists');
      }

      final String now = DateTime.now().toIso8601String();
      await db.insert(
        'scans',
        {
          'code': code,
          'status': 1,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getScannedData() async {
    final Database db = await database;
    return await db.query(
      'scans',
      where: 'status = ?',
      whereArgs: [1],
    );
  }

  Future<void> sendScannedDataToApi() async {
    final List<Map<String, dynamic>> scannedData = await getScannedData();

    if (scannedData.isEmpty) return;

    final url =
        Uri.parse('http://192.168.130.9:8086/index.php/api/receive-providers');
    final headers = {'Content-Type': 'application/json'};

    for (var item in scannedData) {
      final body =
          jsonEncode({'code': item['code'], 'created_at': item['created_at']});
      try {
        final response = await http.post(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          final Database db = await database;
          await db.delete(
            'scans',
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        } else if (response.statusCode == 400) {
          final Database db = await database;
          await db.delete(
            'scans',
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        } else {
          throw Exception('Failed to send data: ${response.statusCode}');
        }
      } catch (e) {
        print('Error sending data: $e');
      }
    }
  }
}
