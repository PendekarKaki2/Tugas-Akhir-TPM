import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/database_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../models/user_location_model.dart';

bool _useSupabaseLocationGlobal() {
  try {
    return SupabaseService().isReady;
  } catch (_) {
    return false;
  }
}

class UserLocationLocalDataSource {
  final DatabaseService _databaseService;
  static final List<UserLocationModel> _memorySnapshots = [];
  static const String _locationCacheKey = 'cached_location_snapshots_v1';

  UserLocationLocalDataSource(this._databaseService);

  bool get _useSupabase => _useSupabaseLocationGlobal();

  Future<void> _loadMemory() async {
    if (_memorySnapshots.isNotEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_locationCacheKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _memorySnapshots
        ..clear()
        ..addAll(
          decoded
              .map((item) => UserLocationModel.fromJson((item as Map).cast<String, dynamic>()))
              .toList(),
        );
    } catch (e) {
      debugPrint('[UserLocationLocalDataSource] Failed to load memory cache: $e');
    }
  }

  Future<void> _saveMemory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _locationCacheKey,
      jsonEncode(_memorySnapshots.map((e) => e.toJson()).toList()),
    );
  }

  Future<UserLocationModel> saveSnapshot(UserLocationModel location) async {
    final stored = location.copyWith(timestamp: DateTime.now().toIso8601String());

    if (kIsWeb) {
      _memorySnapshots.removeWhere((e) => e.userId == stored.userId);
      _memorySnapshots.add(stored);
      await _saveMemory();
      return stored;
    }

    try {
      if (_useSupabase) {
        final client = Supabase.instance.client;
        final inserted = await client.from('user_locations').insert(stored.toJson()).select().maybeSingle();
        if (inserted != null) {
          return UserLocationModel.fromJson((inserted as Map).cast<String, dynamic>());
        }
      }

      final db = await _databaseService.database;
      final id = await db.insert('user_locations', stored.toJson());
      return stored.copyWith(id: id);
    } catch (e) {
      _memorySnapshots.removeWhere((e) => e.userId == stored.userId);
      _memorySnapshots.add(stored);
      await _saveMemory();
      return stored;
    }
  }

  Future<List<UserLocationModel>> getLatestSnapshots() async {
    if (kIsWeb) {
      await _loadMemory();
      return _dedupeLatest(_memorySnapshots);
    }

    try {
      if (_useSupabase) {
        final client = Supabase.instance.client;
        final rows = await client.from('user_locations').select().order('timestamp', ascending: false);
        final list = rows is List ? rows : [rows];
        return _dedupeLatest(
          list.map((r) => UserLocationModel.fromJson((r as Map).cast<String, dynamic>())).toList(),
        );
      }

      final db = await _databaseService.database;
      final rows = await db.query('user_locations', orderBy: 'timestamp DESC');
      return _dedupeLatest(rows.map((r) => UserLocationModel.fromJson(r)).toList());
    } catch (e) {
      debugPrint('[UserLocationLocalDataSource] Failed to load snapshots: $e');
      await _loadMemory();
      return _dedupeLatest(_memorySnapshots);
    }
  }

  List<UserLocationModel> _dedupeLatest(List<UserLocationModel> snapshots) {
    final latestByUser = <int, UserLocationModel>{};
    for (final snapshot in snapshots) {
      latestByUser.putIfAbsent(snapshot.userId, () => snapshot);
    }
    final list = latestByUser.values.toList();
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }
}
