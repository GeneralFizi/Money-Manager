import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Web/fallback share helper using in-memory XFile bytes.
Future<XFile> createShareableXFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  return XFile.fromData(bytes, mimeType: mimeType, name: fileName);
}
