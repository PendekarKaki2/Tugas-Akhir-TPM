import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Extracts text from uploaded learning materials so the chatbot can read them.
///
/// Supports PDF and PPTX files on mobile and web. Legacy PPT files are not
/// parsed directly because they use the old binary format.
class MaterialParserService {
  Future<String> extractText({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final extension = _extensionOf(fileName);

    try {
      switch (extension) {
        case 'pdf':
          return _extractPdfText(bytes);
        case 'pptx':
          return _extractPptxText(bytes);
        case 'ppt':
          return _unsupportedPptMessage(fileName);
        default:
          return '';
      }
    } catch (e) {
      debugPrint('[MaterialParserService] Failed to extract text from $fileName: $e');
      return '';
    }
  }

  String _extractPdfText(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      return _normalizeWhitespace(text);
    } finally {
      document.dispose();
    }
  }

  String _extractPptxText(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final buffer = StringBuffer();

    final slideEntries = archive
        .where((entry) =>
            entry.isFile &&
            entry.name.startsWith('ppt/slides/slide') &&
            entry.name.endsWith('.xml'))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final entry in slideEntries) {
      final raw = utf8.decode(entry.content as List<int>, allowMalformed: true);
      final texts = RegExp(r'<a:t[^>]*>(.*?)</a:t>', dotAll: true)
          .allMatches(raw)
          .map((match) => _decodeXmlEntities(match.group(1) ?? ''))
          .where((text) => text.trim().isNotEmpty)
          .toList();
      if (texts.isNotEmpty) {
        buffer.writeln(texts.join(' '));
      }
    }

    return _normalizeWhitespace(buffer.toString());
  }

  String _unsupportedPptMessage(String fileName) {
    return 'File $fileName adalah format PPT lama (.ppt) dan belum bisa dibaca langsung. Silakan simpan ulang sebagai .pptx agar chatbot bisa membaca isinya.';
  }

  String _extensionOf(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) return '';
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String _normalizeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _decodeXmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }
}
