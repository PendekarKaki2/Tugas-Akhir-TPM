import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/material_model.dart';
import '../../providers/student_provider.dart';

class StudentMaterialsScreen extends StatefulWidget {
  const StudentMaterialsScreen({super.key});

  @override
  State<StudentMaterialsScreen> createState() => _StudentMaterialsScreenState();
}

class _StudentMaterialsScreenState extends State<StudentMaterialsScreen> {
  late Future<List<MaterialModel>> _materialsFuture;
  final _searchController = TextEditingController();
  List<MaterialModel> _allMaterials = [];
  List<MaterialModel> _filteredMaterials = [];

  @override
  void initState() {
    super.initState();
    final student = Provider.of<StudentProvider>(context, listen: false);
    _materialsFuture = student.getMaterials();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    final materials = await _materialsFuture;
    if (!mounted) return;
    setState(() {
      _allMaterials = materials;
      _filteredMaterials = materials;
    });
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredMaterials = _allMaterials;
      } else {
        _filteredMaterials = _allMaterials.where((m) {
          final title = m.title.toLowerCase();
          final content = (m.content ?? '').toLowerCase();
          return title.contains(q) || content.contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openMaterialDetail(MaterialModel material) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Text(
                  material.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: 'Mentor #${material.mentorId}'),
                    if ((material.filePath ?? '').isNotEmpty) _InfoChip(label: material.filePath!),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  material.content ?? 'Tidak ada isi materi.',
                  style: const TextStyle(height: 1.6, fontSize: 15),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materi Student')),
      body: RefreshIndicator(
        onRefresh: () async {
          final student = context.read<StudentProvider>();
          final materials = await student.getMaterials();
          if (!mounted) return;
          setState(() {
            _allMaterials = materials;
            _filteredMaterials = materials;
          });
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Materi dari mentor akan muncul di sini dan dapat dibaca langsung.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Cari materi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            if (_filteredMaterials.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: Text('Belum ada materi yang cocok')),
              )
            else
              ..._filteredMaterials.map(
                (material) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.menu_book, color: Color(0xFF6366F1)),
                      ),
                      title: Text(
                        material.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _previewText(material.content ?? ''),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _openMaterialDetail(material),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _previewText(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 120) return normalized;
    return '${normalized.substring(0, 120)}...';
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: const Color(0xFFF8FAFC),
    );
  }
}
