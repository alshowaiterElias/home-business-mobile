import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  /// Compresses a single image file (resizes to max 1200x1200px, quality 80%)
  static Future<File> compressFile(
    File file, {
    int quality = 80,
    int minWidth = 1200,
    int minHeight = 1200,
  }) async {
    try {
      final fileLength = await file.length();
      // Skip if file is already small (< 200 KB)
      if (fileLength < 200 * 1024) {
        return file;
      }

      final tempDir = await getTemporaryDirectory();
      final filename = file.path.split(RegExp(r'[/\\]')).last;
      final targetPath = '${tempDir.path}/comp_${DateTime.now().millisecondsSinceEpoch}_$filename';

      final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile != null) {
        final compressedFile = File(compressedXFile.path);
        final compressedLength = await compressedFile.length();
        debugPrint(
          '⚡ Client Image Compressed: ${(fileLength / 1024).toStringAsFixed(1)}KB ➔ ${(compressedLength / 1024).toStringAsFixed(1)}KB',
        );
        return compressedFile;
      }
    } catch (e) {
      debugPrint('⚠️ Client image compression skipped: $e');
    }
    return file;
  }

  /// Compresses a list of image files sequentially or in parallel
  static Future<List<File>> compressFileList(List<File> files) async {
    return Future.wait(files.map((f) => compressFile(f)));
  }
}
