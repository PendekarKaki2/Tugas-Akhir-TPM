import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../../data/models/material_model.dart';

class StudentMaterialsScreen extends StatefulWidget {
  const StudentMaterialsScreen({super.key});

  @override
  State<StudentMaterialsScreen> createState() => _StudentMaterialsScreenState();
}

class _StudentMaterialsScreenState extends State<StudentMaterialsScreen> {
  late Future<List<MaterialModel>> _materialsFuture;

  @override
  void initState() {
    super.initState();
    final student = Provider.of<StudentProvider>(context, listen: false);
    _materialsFuture = student.getMaterials();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materi')),
      body: FutureBuilder<List<MaterialModel>>(
        future: _materialsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Belum ada materi'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final m = items[index];
              return ListTile(title: Text(m.title), subtitle: Text(m.content ?? ''));
            },
          );
        },
      ),
    );
  }
}
