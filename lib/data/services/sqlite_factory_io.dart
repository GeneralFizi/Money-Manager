import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initializes SQLite FFI on desktop platforms (Windows, Linux, macOS) while
/// leaving Android and iOS on the native sqflite plugin factory.
DatabaseFactory? resolveDesktopDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return null;
}
