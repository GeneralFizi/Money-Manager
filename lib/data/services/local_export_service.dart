import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/account.dart';
import '../../domain/models/backup_payload.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction_item.dart';
import 'temp_file_helper_stub.dart'
    if (dart.library.io) 'temp_file_helper_io.dart';

/// Handles offline local JSON/CSV export, file picking, and OS share sheet handoff.
class LocalExportService {
  /// Exports the full backup payload as a human-readable `.json` file using the OS file saver.
  Future<bool> saveJsonBackupToDevice(BackupPayload payload) async {
    final jsonString = payload.toPrettyJsonString();
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    final stamp = _dateStamp(DateTime.now());
    final savedUri = await FilePicker.saveFile(
      dialogTitle: 'Save Money Manager Backup',
      fileName: 'money_manager_backup_$stamp.json',
      bytes: bytes,
      mimeType: 'application/json',
    );
    return savedUri != null;
  }

  /// Opens the native OS Share Sheet so the user can save directly to the Google Drive
  /// mobile app, Files app, or AirDrop without any OAuth client configuration.
  Future<ShareResultStatus> shareJsonBackup(BackupPayload payload) async {
    final jsonString = payload.toPrettyJsonString();
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    final stamp = _dateStamp(DateTime.now());
    final fileName = 'money_manager_backup_$stamp.json';

    final xFile = await createShareableXFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/json',
    );
    final result = await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[xFile],
        subject: 'Money Manager Backup ($stamp)',
        text: 'Offline Money Manager JSON backup',
      ),
    );
    return result.status;
  }

  /// Exports transactions to a CSV file suitable for Excel / Google Sheets.
  Future<bool> saveTransactionsCsvToDevice({
    required List<TransactionItem> transactions,
    required List<Account> accounts,
    required List<CategoryItem> categories,
    required String currencyCode,
  }) async {
    final accountNames = <String, String>{
      for (final a in accounts) a.id: a.name,
    };
    final categoryNames = <String, String>{
      for (final c in categories) c.id: c.name,
    };

    final buffer = StringBuffer()
      ..writeln('Date,Type,Amount,Currency,Account,ToAccount,Category,Note');

    for (final tx in transactions) {
      final date = tx.date.toIso8601String();
      final type = tx.type.label;
      final amount = tx.amount.toStringAsFixed(2);
      final fromAcc = _escapeCsv(accountNames[tx.accountId] ?? tx.accountId);
      final toAcc = tx.toAccountId != null
          ? _escapeCsv(accountNames[tx.toAccountId!] ?? tx.toAccountId!)
          : '';
      final cat = tx.categoryId != null
          ? _escapeCsv(categoryNames[tx.categoryId!] ?? tx.categoryId!)
          : '';
      final note = _escapeCsv(tx.note);
      buffer.writeln(
        '$date,$type,$amount,$currencyCode,$fromAcc,$toAcc,$cat,$note',
      );
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    final stamp = _dateStamp(DateTime.now());
    final savedUri = await FilePicker.saveFile(
      dialogTitle: 'Export Transactions CSV',
      fileName: 'money_manager_transactions_$stamp.csv',
      bytes: bytes,
      mimeType: 'text/csv',
    );
    return savedUri != null;
  }

  /// Lets the user select a local `.json` backup file and parses it safely.
  Future<BackupPayload?> pickJsonBackupFromDevice() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Select Money Manager JSON Backup',
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final content = utf8.decode(bytes);
    return BackupPayload.fromJsonString(content);
  }

  String _dateStamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _escapeCsv(String value) {
    final sanitized = value.replaceAll('"', '""');
    if (sanitized.contains(',') ||
        sanitized.contains('"') ||
        sanitized.contains('\n')) {
      return '"$sanitized"';
    }
    return sanitized;
  }

  @visibleForTesting
  String formatTransactionsCsvForTest({
    required List<TransactionItem> transactions,
    required List<Account> accounts,
    required List<CategoryItem> categories,
    required String currencyCode,
  }) {
    final accountNames = <String, String>{
      for (final a in accounts) a.id: a.name,
    };
    final categoryNames = <String, String>{
      for (final c in categories) c.id: c.name,
    };
    final buffer = StringBuffer()
      ..writeln('Date,Type,Amount,Currency,Account,ToAccount,Category,Note');
    for (final tx in transactions) {
      final fromAcc = _escapeCsv(accountNames[tx.accountId] ?? tx.accountId);
      final toAcc = tx.toAccountId != null
          ? _escapeCsv(accountNames[tx.toAccountId!] ?? tx.toAccountId!)
          : '';
      final cat = tx.categoryId != null
          ? _escapeCsv(categoryNames[tx.categoryId!] ?? tx.categoryId!)
          : '';
      buffer.writeln(
        '${tx.date.toIso8601String()},${tx.type.label},${tx.amount.toStringAsFixed(2)},$currencyCode,$fromAcc,$toAcc,$cat,${_escapeCsv(tx.note)}',
      );
    }
    return buffer.toString();
  }
}
