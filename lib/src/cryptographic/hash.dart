import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:vania/vania.dart';

class Hash {
  static final Hash _singleton = Hash._internal();
  factory Hash() => _singleton;
  Hash._internal();

  String? _hashKey;

  void setHashKey(String hashKey) {
    _hashKey = hashKey;
  }

  /// Generates a hashed password using PBKDF2.
  ///
  /// This method creates a unique salt and uses it along with the given
  /// password to generate a hash using the PBKDF2 algorithm. The resulting
  /// hashed password is a concatenation of the salt and the hash.
  ///
  /// Returns a string containing the salt followed by the hash.

  String make(String password) {
    String salt = _generateSalt();
    String hash = _hashPbkdf2(password, salt);
    String hashedPassword = salt + hash;
    return hashedPassword;
  }

  /// Verifies if the provided password matches the stored hash.
  ///
  /// The method extracts the salt from the first 4 characters of the stored hash,
  /// then hashes the provided password with this salt using the same hashing
  /// mechanism. It then compares the newly created hash with the stored hash.
  ///
  /// Returns `true` if the hashes match, indicating the password is correct;
  /// otherwise, returns `false`.
  bool verify(String providedPassword, String storedHash) {
    int saltLength = 4;
    String salt = storedHash.substring(0, saltLength);
    String hash = _hashPbkdf2(providedPassword, salt);
    String recreatedStoredHash = salt + hash;
    return _hashEquals(recreatedStoredHash, storedHash);
  }

  String _generateSalt() {
    const charset =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        4, (_) => charset.codeUnitAt(random.nextInt(charset.length))));
  }

  /// Hashes the given [password] using the given [salt] and the APP_KEY or
  /// the given hash key.
  ///
  /// The method works by first encoding the given [salt] and [password] into bytes.
  /// These bytes are then used to compute a SHA-512 HMAC using the bytes of
  /// the hash key or the APP_KEY if no hash key is given.
  ///
  /// The resulting HMAC bytes are then encoded using Base64 and returned as a
  /// string.
  String _hashPbkdf2(String password, String salt) {
    var bytes = utf8.encode(salt + password);
    var hmac = Hmac(sha512, utf8.encode(_hashKey ?? env('APP_KEY')));
    return base64.encode(hmac.convert(bytes).bytes);
  }

  bool _hashEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
