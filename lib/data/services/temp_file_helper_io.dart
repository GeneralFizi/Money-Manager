import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Native mobile/desktop share helper writing to temporary app cache directory.
Future<XFile> createShareableXFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(bytes, flush: true);
  return XFile(file.path, mimeType: mimeType, name: fileName);
}
