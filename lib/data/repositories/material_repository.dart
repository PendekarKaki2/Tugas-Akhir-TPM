import '../models/material_model.dart';
import '../sources/local/material_local_data_source.dart';

class MaterialRepository {
  final MaterialLocalDataSource _local;

  MaterialRepository(this._local);

  Future<int> createMaterial(MaterialModel material) => _local.createMaterial(material);
  Future<List<MaterialModel>> getAllMaterials() => _local.getAllMaterials();
  Future<List<MaterialModel>> getMaterialsByMentor(int mentorId) => _local.getMaterialsByMentor(mentorId);
}
