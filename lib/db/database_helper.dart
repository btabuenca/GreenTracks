import 'dart:async';
import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'telemetry.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE Telemetry(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            lux DOUBLE,
            decibel DOUBLE,
            latitude DOUBLE,
            longitude DOUBLE,
            altitude DOUBLE
          )
        ''');
      },
    );
  }

  Future<void> insertTelemetry(double? lux, double? decibel, double? latitude, double? longitude, double? altitude) async {
    final db = await database;
    await db.insert(
      'Telemetry',
      {
        'timestamp': DateTime.now().toIso8601String(),
        'lux': lux,
        'decibel': decibel,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTelemetry() async {
    final db = await database;
    return db.query('Telemetry', orderBy: 'timestamp DESC');
  }

  Future<void> resetTable() async {
    final db = await database;
    await db.delete('Telemetry'); // Elimina todos los registros de la tabla
  }

  Future<Map<String, dynamic>> calculateStatistics(String column) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT $column FROM Telemetry WHERE $column IS NOT NULL');

    if (result.isEmpty) {
      return {
        'max': 0.0,
        'min': 0.0,
        'avg': 0.0,
        'stdDev': 0.0,
        'q1': 0.0,
        'q3': 0.0,
      };
    }

    // Convertimos los valores de la columna a una lista de double
    List<double> values = result.map((row) => row[column] as double).toList();
    values.sort();

    // Cálculo de estadísticas
    double max = values.last;
    double min = values.first;
    double avg = values.reduce((a, b) => a + b) / values.length;
    double stdDev = _calculateStandardDeviation(values, avg);
    double q1 = _calculateQuantile(values, 0.25);
    double q3 = _calculateQuantile(values, 0.75);

    return {
      'max': max,
      'min': min,
      'avg': avg,
      'stdDev': stdDev,
      'q1': q1,
      'q3': q3,
    };
  }

  double _calculateStandardDeviation(List<double> values, double mean) {
    double sumOfSquaredDiffs = values.fold(0.0, (sum, value) => sum + pow(value - mean, 2));
    return sqrt(sumOfSquaredDiffs / values.length);
  }

  double _calculateQuantile(List<double> sortedValues, double quantile) {
    int n = sortedValues.length;
    double position = (n - 1) * quantile;
    int base = position.floor();
    double remainder = position - base;

    if (base + 1 < n) {
      return sortedValues[base] + remainder * (sortedValues[base + 1] - sortedValues[base]);
    } else {
      return sortedValues[base];
    }
  }
}