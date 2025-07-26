import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> saveBytesToMediaStorage({
  required String fileName,
  required DirType dirType,
  required Uint8List data,
}) async {
  final MediaStore mediaStore = MediaStore();

  try {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(data);
    final fileInfo = await mediaStore.saveFile(
      dirName: dirType.defaults,
      dirType: dirType,
      tempFilePath: tempFile.path,
    );

    if (await tempFile.exists()) {
      tempFile.deleteSync();
    }

    if (fileInfo != null) {
      if (kDebugMode) {
        print("Dosya başarıyla kaydedildi.");
      }

      return true;
    } else {
      if (kDebugMode) {
        print("Dosya kaydetme işlemi iptal edildi veya başarısız oldu.");
      }

      return false;
    }
  } catch (e) {
    if (kDebugMode) {
      print("Dosya kaydederken hata oluştu: $e");
    }

    return false;
  }
}
