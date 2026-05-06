import '../../../core/services/database_service.dart';
import '../../models/material_model.dart';

class MaterialLocalDataSource {
  final DatabaseService _databaseService;

  MaterialLocalDataSource(this._databaseService);

  Future<int> createMaterial(MaterialModel material) async {
    try {
      // Validate input
      if (material.title.isEmpty) {
        throw Exception('Judul materi tidak boleh kosong');
      }
      if (material.mentorId <= 0) {
        throw Exception('Mentor ID tidak valid');
      }

      final count = await _databaseService.getRowCount('materials');
      if (count >= DatabaseService.maxMaterials) {
        throw Exception('Batas materi sudah tercapai (max ${DatabaseService.maxMaterials})');
      }

      final db = await _databaseService.database;
      final id = await db.insert('materials', {
        'mentorId': material.mentorId,
        'title': material.title,
        'content': material.content ?? '',
        'filePath': material.filePath,
        'createdAt': material.createdAt ?? DateTime.now().toIso8601String(),
      });
      return id;
    } catch (e) {
      // bubble up error for caller to handle; do not crash the app
      throw Exception('Gagal menyimpan materi: $e');
    }
  }

  Future<List<MaterialModel>> getAllMaterials() async {
    final db = await _databaseService.database;
    final rows = await db.query('materials', orderBy: 'createdAt DESC');
    return rows.map((r) => MaterialModel.fromJson(r)).toList();
  }

  Future<List<MaterialModel>> getMaterialsByMentor(int mentorId) async {
    final db = await _databaseService.database;
    final rows = await db.query('materials', where: 'mentorId = ?', whereArgs: [mentorId]);
    return rows.map((r) => MaterialModel.fromJson(r)).toList();
  }
}
