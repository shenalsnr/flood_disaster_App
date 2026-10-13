import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/offline_hazard_report.dart';

/// SQLite Database Service for Offline & Draft Hazard Reports.
/// Provides 100% persistent local storage on the device so reports
/// are NEVER lost even when the app is completely closed or the phone restarted.
class OfflineHazardDatabase {
  static final OfflineHazardDatabase instance = OfflineHazardDatabase._init();
  static Database? _database;

  OfflineHazardDatabase._init();

  static const String tableName = 'offline_hazard_reports';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hazard_reports_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    debugPrint('Initializing SQLite Offline Database at: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    debugPrint('Creating SQLite table: $tableName');
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        hazard_type TEXT NOT NULL,
        severity TEXT NOT NULL,
        description TEXT,
        location TEXT,
        latitude REAL,
        longitude REAL,
        reporter_name TEXT,
        reporter_email TEXT,
        photo_path TEXT,
        has_photo INTEGER,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
  }

  // ===========================================================================
  // CRUD 1: CREATE
  // ===========================================================================
  /// Inserts a new draft or offline hazard report into SQLite.
  Future<String> insertReport(OfflineHazardReport report) async {
    final db = await instance.database;
    await db.insert(
      tableName,
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('SQLite: Successfully saved report [${report.id}]');
    return report.id;
  }

  // ===========================================================================
  // CRUD 2: READ
  // ===========================================================================
  /// Retrieves all offline reports, optionally filtered by status ('DRAFT', 'PENDING_SYNC', 'SYNCED').
  Future<List<OfflineHazardReport>> getAllReports({String? statusFilter}) async {
    final db = await instance.database;
    List<Map<String, dynamic>> maps;

    if (statusFilter != null && statusFilter != 'ALL') {
      maps = await db.query(
        tableName,
        where: 'status = ?',
        whereArgs: [statusFilter],
        orderBy: 'updated_at DESC',
      );
    } else {
      maps = await db.query(
        tableName,
        orderBy: 'updated_at DESC',
      );
    }

    return maps.map((map) => OfflineHazardReport.fromMap(map)).toList();
  }

  /// Retrieves a single report by ID.
  Future<OfflineHazardReport?> getReportById(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return OfflineHazardReport.fromMap(maps.first);
    }
    return null;
  }

  /// Retrieves all reports pending cloud synchronization.
  Future<List<OfflineHazardReport>> getPendingReports() async {
    final db = await instance.database;
    final maps = await db.query(
      tableName,
      where: 'status = ?',
      whereArgs: ['PENDING_SYNC'],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => OfflineHazardReport.fromMap(map)).toList();
  }

  /// Retrieves count of pending synchronization reports.
  Future<int> getPendingCount() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $tableName WHERE status = ?',
      ['PENDING_SYNC'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Retrieves count of draft reports.
  Future<int> getDraftCount() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $tableName WHERE status = ?',
      ['DRAFT'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Retrieves total stored reports count.
  Future<int> getTotalCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ===========================================================================
  // CRUD 3: UPDATE
  // ===========================================================================
  /// Updates details of an existing draft or offline report in SQLite.
  Future<int> updateReport(OfflineHazardReport report) async {
    final db = await instance.database;
    final updatedReport = report.copyWith(updatedAt: DateTime.now());
    final count = await db.update(
      tableName,
      updatedReport.toMap(),
      where: 'id = ?',
      whereArgs: [report.id],
    );
    debugPrint('SQLite: Updated $count row(s) for report [${report.id}]');
    return count;
  }

  /// Marks a report as successfully synced to Firebase Firestore.
  Future<int> markAsSynced(String id) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      tableName,
      {
        'status': 'SYNCED',
        'synced_at': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===========================================================================
  // CRUD 4: DELETE
  // ===========================================================================
  /// Permanently removes a draft or offline report from SQLite.
  Future<int> deleteReport(String id) async {
    final db = await instance.database;
    final count = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('SQLite: Deleted report [$id] ($count rows affected)');
    return count;
  }

  /// Deletes all synced reports to clear disk storage.
  Future<int> clearSyncedReports() async {
    final db = await instance.database;
    return await db.delete(
      tableName,
      where: 'status = ?',
      whereArgs: ['SYNCED'],
    );
  }

  /// Deletes all records from the table.
  Future<int> clearAll() async {
    final db = await instance.database;
    return await db.delete(tableName);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
