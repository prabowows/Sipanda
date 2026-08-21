import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> saveFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) async {
  Directory? dir;
  if (Platform.isAndroid) {
    dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) {
      dir = await getExternalStorageDirectory();
    }
  } else {
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {}
    dir ??= await getApplicationDocumentsDirectory();
  }

  final targetDir = dir ?? await getTemporaryDirectory();
  final filePath = '${targetDir.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);
  return filePath;
}
