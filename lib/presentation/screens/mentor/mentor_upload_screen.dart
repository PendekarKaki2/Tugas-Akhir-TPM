import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mentor_provider.dart';
import '../../providers/auth_provider.dart';

class MentorUploadScreen extends StatefulWidget {
  const MentorUploadScreen({super.key});

  @override
  State<MentorUploadScreen> createState() => _MentorUploadScreenState();
}

class _MentorUploadScreenState extends State<MentorUploadScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

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
            Expanded(child: TextField(controller: _contentController, maxLines: null, decoration: const InputDecoration(labelText: 'Konten'))),
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
                      
                      final id = await mentor.uploadMaterial(mentorId, title, content, null);
                      if (id != null) {
                        messenger.showSnackBar(const SnackBar(content: Text('Materi berhasil diupload')));
                        _titleController.clear();
                        _contentController.clear();
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
