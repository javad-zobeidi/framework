import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:vania/vania.dart';
import '../../cryptographic/vania_encryption.dart';

class SessionFileStore {
  static final SessionFileStore _singleton = SessionFileStore._internal();
  factory SessionFileStore() => _singleton;
  SessionFileStore._internal();

  final String _secretKey = env('APP_KEY');
  final String sessionPath = 'storage/framework/sessions';

  /// Tries to lock a file in the given mode, with retries in case of failure.
  ///
  /// This method attempts to lock a file in the given mode, and if the
  /// operation fails, it waits for the given delay and then retries. This
  /// process is repeated for the given number of retries. If the lock
  /// operation still fails after the specified number of retries, the
  /// exception is rethrown.
  ///
  /// Parameters:
  /// - [raf]: The file to lock.
  /// - [mode]: The lock mode to use.
  /// - [retries]: The number of times to retry the lock operation in
  ///   case of failure. Defaults to 5.
  /// - [delay]: The delay between retries. Defaults to a 150ms delay.
  ///
  Future<void> _lockFile(
    RandomAccessFile raf,
    FileLock mode, {
    int retries = 5,
    Duration delay = const Duration(milliseconds: 150),
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        await raf.lock(mode);
        return;
      } catch (e) {
        if (i == retries - 1) {
          rethrow;
        }
        await Future.delayed(delay);
      }
    }
  }

  /// Stores session data in a file with the given session ID.
  ///
  /// This method creates or overwrites a file in the session path to store
  /// session data. The data is serialized to JSON, encrypted, and then written
  /// to the file. An expiration timestamp is added to the session data, which
  /// is set to the current time plus the specified duration. The file is locked
  /// during the write operation to ensure data integrity.
  ///
  /// Parameters:
  /// - [sessionId]: The unique identifier for the session.
  /// - [data]: A map containing the session data to be stored.
  /// - [duration]: (Optional) The duration for which the session is valid.
  ///   Defaults to one hour.
  ///
  Future<void> storeSession(
    String sessionId,
    Map<String, dynamic> data, {
    Duration duration = const Duration(hours: 1),
  }) async {
    sessionId = _makeHash(sessionId).toString();
    final file = File('$sessionPath/$sessionId');
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    int expiration =
        DateTime.now().toUtc().millisecondsSinceEpoch + duration.inMilliseconds;
    final Map<String, dynamic> sessionData = {
      "data": data,
      "expiration": expiration,
    };
    final String content =
        VaniaEncryption.encryptString(json.encode(sessionData), _secretKey);

    final raf = await file.open(mode: FileMode.write);
    try {
      await _lockFile(raf, FileLock.exclusive);
      await raf.writeFrom(utf8.encode(content));
    } finally {
      try {
        await raf.unlock();
      } catch (_) {}
      await raf.close();
    }
  }

  /// Retrieves the session data associated with the given session ID.
  ///
  /// This function checks if a session file exists for the given session ID,
  /// reads its contents, and decrypts the data. If the session data is valid
  /// and not expired, it returns the session data as a map. If the session
  /// does not exist, is expired, or decryption fails, it returns null.
  ///
  /// Parameters:
  /// - [sessionId]: The unique identifier for the session to be retrieved.
  ///
  /// Returns:
  /// A map containing the session data, or null if the session does not exist,
  /// is expired, or if there is an error in reading or decrypting the file.
  ///
  Future<Map<String, dynamic>?> retrieveSession(String sessionId) async {
    sessionId = _makeHash(sessionId).toString();
    final file = File('$sessionPath/$sessionId');
    if (!await file.exists()) {
      return null;
    }
    final raf = await file.open(mode: FileMode.read);
    String fileContent = '';
    try {
      await _lockFile(raf, FileLock.exclusive);
      final int length = await raf.length();
      final List<int> bytes = await raf.read(length);
      fileContent = utf8.decode(bytes);
    } finally {
      try {
        await raf.unlock();
      } catch (_) {}
      await raf.close();
    }

    final String decrypted =
        VaniaEncryption.decryptString(fileContent, _secretKey);
    if (decrypted.isEmpty) {
      return null;
    }
    final Map<String, dynamic> data = json.decode(decrypted);
    int expiration = int.tryParse(data['expiration'].toString()) ?? 0;

    if (!DateTime.now().toUtc().isBefore(
          DateTime.fromMillisecondsSinceEpoch(expiration),
        )) {
      await file.delete();
      return null;
    }
    return data['data'];
  }

  Future<bool> hasSession(String sessionId) async {
    Map<String, dynamic>? data = await retrieveSession(sessionId);
    return data != null;
  }

  /// Deletes a specific session from the session storage.
  ///
  /// This function first checks if a session exists for the given session ID.
  /// If the session exists, it deletes the session by setting the expiration
  /// time to the current time minus 1 millisecond, and encrypts the new data
  /// using the `VaniaEncryption` class. The encrypted data is then written
  /// to the session file. If the session does not exist, this function does
  /// nothing.
  ///
  /// Parameters:
  /// - [sessionId]: The unique identifier for the session to be deleted.
  ///
  /// Returns:
  /// A Future that resolves to `null`, indicating that the session was
  /// successfully deleted.
  ///
  Future<void> deleteSession(String sessionId) async {
    sessionId = _makeHash(sessionId).toString();
    final file = File('$sessionPath/$sessionId');
    if (await file.exists()) {
      final raf = await file.open(mode: FileMode.write);
      try {
        await _lockFile(raf, FileLock.exclusive);
        int expiration = DateTime.now().toUtc().millisecondsSinceEpoch - 1;
        final String content = VaniaEncryption.encryptString(
          json.encode({"data": {}, "expiration": expiration}),
          _secretKey,
        );
        await raf.writeFrom(utf8.encode(content));
      } finally {
        try {
          await raf.unlock();
        } catch (_) {}
        await raf.close();
      }
    }
  }

  Digest _makeHash(String key) {
    var secKey = utf8.encode(_secretKey);
    var bytes = utf8.encode(key);
    var hmacSha256 = Hmac(sha256, secKey);
    return hmacSha256.convert(bytes);
  }
}
