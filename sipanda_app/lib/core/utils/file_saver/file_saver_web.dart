// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

Future<String?> saveFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) async {
  try {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();

    Future.delayed(const Duration(seconds: 10), () {
      try {
        html.Url.revokeObjectUrl(url);
      } catch (_) {}
    });
    return fileName;
  } catch (e) {
    try {
      final base64String = base64Encode(bytes);
      final dataUrl = 'data:$mimeType;base64,$base64String';
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = dataUrl
        ..setAttribute('download', fileName)
        ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
      return fileName;
    } catch (_) {
      rethrow;
    }
  }
}
