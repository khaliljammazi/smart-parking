import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Saves the PDF to the device (mobile/desktop). Returns the file path.
Future<String?> downloadPdf(Uint8List bytes, String filename) async {
  final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}
