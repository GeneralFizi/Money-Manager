import 'dart:async';
import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;

import '../../domain/models/backup_payload.dart';

/// Result returned after an explicit on-demand Google Drive upload.
class DriveBackupMetadata {
  const DriveBackupMetadata({
    required this.fileId,
    required this.fileName,
    required this.folderName,
    required this.syncedAt,
    required this.accountEmail,
  });

  final String fileId;
  final String fileName;
  final String folderName;
  final DateTime syncedAt;
  final String accountEmail;
}

/// User-friendly exception for on-demand Google Drive operations.
class GoogleDriveBackupException implements Exception {
  const GoogleDriveBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Strictly on-demand Google Drive backup & restore service.
///
/// IMPORTANT PRIVACY INVARIANT:
/// - Performs ZERO initialization, polling, or network requests at app launch.
/// - Only connects when the user explicitly taps Backup or Restore.
/// - Uses only the least-privileged `drive.file` scope (accesses only files and
///   the `MoneyManagerBackups` folder created by this app).
class GoogleDriveService {
  static const String backupFolderName = 'MoneyManagerBackups';
  static const String latestBackupFileName = 'money_manager_backup_latest.json';
  static const List<String> _scopes = <String>[drive.DriveApi.driveFileScope];

  bool _isGoogleSignInInitialized = false;

  Future<({gapis.AuthClient client, String email})> _authenticateOnDemand({
    String? customClientId,
  }) async {
    try {
      if (!_isGoogleSignInInitialized) {
        await GoogleSignIn.instance.initialize(
          clientId: (customClientId != null && customClientId.trim().isNotEmpty)
              ? customClientId.trim()
              : null,
        );
        _isGoogleSignInInitialized = true;
      }

      GoogleSignInAccount? account;
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        account = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
      } else {
        final attempt = GoogleSignIn.instance.attemptLightweightAuthentication();
        if (attempt != null) {
          account = await attempt;
        }
      }

      if (account == null) {
        throw const GoogleDriveBackupException(
          'Google Sign-In is unavailable on this browser/platform without a configured OAuth Web Client ID. '
          'You can still use "Share Backup File to Google Drive App" or "Export JSON Backup" completely offline.',
        );
      }

      final authz =
          await account.authorizationClient.authorizationForScopes(_scopes) ??
              await account.authorizationClient.authorizeScopes(_scopes);

      final client = authz.authClient(scopes: _scopes);
      return (client: client, email: account.email);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleDriveBackupException('Google Sign-In was canceled.');
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw const GoogleDriveBackupException(
          'Google OAuth Client ID is not yet registered for this app signature. '
          'Add your OAuth Client ID in Google Cloud Console or use "Share Backup File to Drive App" below.',
        );
      }
      throw GoogleDriveBackupException(
        'Google Sign-In failed: ${e.description ?? e.code.name}',
      );
    } on PlatformException catch (e) {
      throw GoogleDriveBackupException(
        e.message ?? 'Could not connect to Google Play / Sign-In services.',
      );
    } catch (e) {
      if (e is GoogleDriveBackupException) rethrow;
      throw GoogleDriveBackupException(
        'Could not connect to Google Drive. Check your internet connection and OAuth setup ($e).',
      );
    }
  }

  /// Uploads a readable JSON backup to the visible `MoneyManagerBackups` folder in Google Drive.
  Future<DriveBackupMetadata> backupToGoogleDrive(
    BackupPayload payload, {
    String? customClientId,
  }) async {
    final session = await _authenticateOnDemand(customClientId: customClientId);
    final client = session.client;
    try {
      final driveApi = drive.DriveApi(client);
      final folderId = await _findOrCreateBackupFolder(driveApi);

      final prettyJson = payload.toPrettyJsonString();
      final bytes = utf8.encode(prettyJson);

      final existingFileId =
          await _findFileInFolder(driveApi, folderId, latestBackupFileName);

      final media = drive.Media(Stream<List<int>>.value(bytes), bytes.length);

      drive.File savedFile;
      if (existingFileId != null) {
        savedFile = await driveApi.files.update(
          drive.File()..name = latestBackupFileName,
          existingFileId,
          uploadMedia: media,
        );
      } else {
        savedFile = await driveApi.files.create(
          drive.File()
            ..name = latestBackupFileName
            ..parents = <String>[folderId]
            ..mimeType = 'application/json',
          uploadMedia: media,
        );
      }

      // Also upload a dated snapshot so the user keeps daily history in Drive.
      final now = DateTime.now();
      final datedName =
          'money_manager_backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';
      final existingDatedId =
          await _findFileInFolder(driveApi, folderId, datedName);
      final datedMedia =
          drive.Media(Stream<List<int>>.value(bytes), bytes.length);
      if (existingDatedId != null) {
        await driveApi.files.update(
          drive.File()..name = datedName,
          existingDatedId,
          uploadMedia: datedMedia,
        );
      } else {
        await driveApi.files.create(
          drive.File()
            ..name = datedName
            ..parents = <String>[folderId]
            ..mimeType = 'application/json',
          uploadMedia: datedMedia,
        );
      }

      return DriveBackupMetadata(
        fileId: savedFile.id ?? existingFileId ?? '',
        fileName: latestBackupFileName,
        folderName: backupFolderName,
        syncedAt: DateTime.now(),
        accountEmail: session.email,
      );
    } catch (e) {
      if (e is GoogleDriveBackupException) rethrow;
      throw GoogleDriveBackupException(
        'Failed to upload backup to Google Drive. Check your internet connection ($e).',
      );
    } finally {
      client.close();
    }
  }

  /// Downloads and parses `money_manager_backup_latest.json` from `MoneyManagerBackups`.
  Future<({BackupPayload payload, String accountEmail})> restoreFromGoogleDrive({
    String? customClientId,
  }) async {
    final session = await _authenticateOnDemand(customClientId: customClientId);
    final client = session.client;
    try {
      final driveApi = drive.DriveApi(client);
      final folderId = await _findBackupFolder(driveApi);
      if (folderId == null) {
        throw const GoogleDriveBackupException(
          'No "$backupFolderName" folder found in your Google Drive.',
        );
      }

      final fileId =
          await _findFileInFolder(driveApi, folderId, latestBackupFileName);
      if (fileId == null) {
        throw const GoogleDriveBackupException(
          'No "$latestBackupFileName" backup found inside "$backupFolderName".',
        );
      }

      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      if (response is! drive.Media) {
        throw const GoogleDriveBackupException(
          'Unexpected response while downloading backup from Google Drive.',
        );
      }

      final chunks = await response.stream.toList();
      final bytes = chunks.expand((chunk) => chunk).toList();
      final jsonString = utf8.decode(bytes);
      final payload = BackupPayload.fromJsonString(jsonString);
      return (payload: payload, accountEmail: session.email);
    } catch (e) {
      if (e is GoogleDriveBackupException) rethrow;
      throw GoogleDriveBackupException(
        'Failed to restore from Google Drive. Check your internet connection ($e).',
      );
    } finally {
      client.close();
    }
  }

  /// Signs out locally from cached Google Sign-In state without making Drive requests.
  Future<void> signOut() async {
    if (!_isGoogleSignInInitialized) return;
    await GoogleSignIn.instance.signOut();
  }

  Future<String?> _findBackupFolder(drive.DriveApi driveApi) async {
    final res = await driveApi.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' and name = '$backupFolderName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );
    final files = res.files;
    if (files != null && files.isNotEmpty) {
      return files.first.id;
    }
    return null;
  }

  Future<String> _findOrCreateBackupFolder(drive.DriveApi driveApi) async {
    final existingId = await _findBackupFolder(driveApi);
    if (existingId != null) return existingId;

    final created = await driveApi.files.create(
      drive.File()
        ..name = backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder',
    );
    if (created.id == null) {
      throw const GoogleDriveBackupException(
        'Could not create "$backupFolderName" folder in Google Drive.',
      );
    }
    return created.id!;
  }

  Future<String?> _findFileInFolder(
    drive.DriveApi driveApi,
    String folderId,
    String fileName,
  ) async {
    final res = await driveApi.files.list(
      q: "'$folderId' in parents and name = '$fileName' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );
    final files = res.files;
    if (files != null && files.isNotEmpty) {
      return files.first.id;
    }
    return null;
  }
}
