import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/mentor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/services/material_parser_service.dart';

class MentorUploadScreen extends StatefulWidget {
  const MentorUploadScreen({super.key});

  @override
  State<MentorUploadScreen> createState() => _MentorUploadScreenState();
}

class _MentorUploadScreenState extends State<MentorUploadScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _parserService = MaterialParserService();

  String? _selectedFileName;
  bool _isParsingFile = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // role check handled in build to avoid async BuildContext usage
  }

  @override
  Widget build(BuildContext context) {
    final mentor = Provider.of<MentorProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    if (auth.currentUser?.role != 'mentor') {
      return Scaffold(
        appBar: AppBar(title: const Text('Akses Materi')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Akses ditolak. Hanya mentor dapat mengupload materi.'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kembali')),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Materi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Judul')),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Konten manual',
                hintText: 'Opsional: isi manual materi jika tidak mengunggah file',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isParsingFile
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: const ['pdf', 'pptx', 'ppt'],
                              withData: true,
                            );
                            if (result == null || result.files.isEmpty) {
                              return;
                            }

                            final file = result.files.first;
                            final bytes = file.bytes;
                            if (bytes == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('File tidak bisa dibaca di perangkat ini.')),
                              );
                              return;
                            }

                            setState(() {
                              _isParsingFile = true;
                              _selectedFileName = file.name;
                            });

                            final extracted = await _parserService.extractText(
                              bytes: bytes,
                              fileName: file.name,
                            );

                            if (!mounted) return;

                            if (extracted.isNotEmpty) {
                              _contentController.text = extracted;
                            }

                            setState(() {
                              _isParsingFile = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  extracted.isNotEmpty
                                      ? 'Isi file berhasil diekstrak ke konten materi.'
                                      : 'File dipilih, tetapi isi teks tidak ditemukan. Kamu masih bisa isi manual.',
                                ),
                              ),
                            );
                          },
                    icon: _isParsingFile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(_selectedFileName == null ? 'Pilih PDF / PPTX / PPT' : 'File: $_selectedFileName'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedFileName != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedFileName!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: mentor.isLoading
                  ? null
                  : () async {
                      // capture things synchronously to avoid using BuildContext across async gaps
                      final messenger = ScaffoldMessenger.of(context);
                      final title = _titleController.text.trim();
                      final content = _contentController.text.trim();
                      final mentorId = auth.currentUser?.id;
                      
                      // Validation
                      if (mentorId == null) {
                        messenger.showSnackBar(const SnackBar(content: Text('Error: User ID tidak ditemukan')));
                        return;
                      }
                      if (title.isEmpty) {
                        messenger.showSnackBar(const SnackBar(content: Text('Judul tidak boleh kosong')));
                        return;
                      }
                      if (content.isEmpty) {
                        messenger.showSnackBar(const SnackBar(content: Text('Konten tidak boleh kosong')));
                        return;
                      }

                      final filePath = _selectedFileName;
                      final id = await mentor.uploadMaterial(mentorId, title, content, filePath);
                      if (id != null) {
                        messenger.showSnackBar(const SnackBar(content: Text('Materi berhasil diupload')));
                        _titleController.clear();
                        _contentController.clear();
                        setState(() {
                          _selectedFileName = null;
                        });
                      } else {
                        messenger.showSnackBar(SnackBar(content: Text(mentor.error ?? 'Gagal upload materi')));
                      }
                    },
              child: mentor.isLoading ? const CircularProgressIndicator() : const Text('Upload'),
            )
          ],
        ),
      ),
    );
  }
}
