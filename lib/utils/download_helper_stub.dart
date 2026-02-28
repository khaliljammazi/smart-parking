import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadBytes(Uint8List bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], subject: filename, text: '');
}
