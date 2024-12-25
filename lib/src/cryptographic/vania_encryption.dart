import 'dart:convert';
import 'dart:math';

class VaniaEncryption {
  /// Encrypts the given [plainText] using the given [passphrase].
  ///
  /// The method generates a random salt and derives a key using the given
  /// [passphrase] and the generated salt. The derived key is then used to
  /// encrypt the given [plainText] using a simple XOR operation.
  ///
  /// The encrypted bytes are then combined with the salt bytes and encoded
  /// using Base64.
  ///
  /// The resulting Base64 encoded string can be decrypted using the
  /// [decryptString] method.
  static String encryptString(String plainText, String passphrase) {
    final saltBytes =
        List<int>.generate(16, (_) => Random.secure().nextInt(256));

    final plainBytes = utf8.encode(plainText);

    final keyBytes = _deriveKey(passphrase, saltBytes, plainBytes.length);

    final encryptedBytes = List<int>.generate(
      plainBytes.length,
      (i) => plainBytes[i] ^ keyBytes[i],
    );

    final combinedBytes = <int>[];
    combinedBytes.addAll(saltBytes);
    combinedBytes.addAll(encryptedBytes);

    return base64.encode(combinedBytes);
  }

  /// Decrypts the given [encryptedText] using the given [passphrase].
  ///
  /// The method first decodes the given [encryptedText] from Base64 and
  /// splits the decoded bytes into a salt and the encrypted bytes.
  ///
  /// The method then derives a key using the given [passphrase] and the
  /// salt bytes. The derived key is then used to decrypt the encrypted
  /// bytes using a simple XOR operation.
  ///
  /// The decrypted bytes are then decoded from UTF-8 and returned as a string.
  static String decryptString(String encryptedText, String passphrase) {
    final allBytes = base64.decode(encryptedText);

    final saltBytes = allBytes.sublist(0, 16);

    final encryptedBytes = allBytes.sublist(16);

    final keyBytes = _deriveKey(passphrase, saltBytes, encryptedBytes.length);

    final plainBytes = List<int>.generate(
      encryptedBytes.length,
      (i) => encryptedBytes[i] ^ keyBytes[i],
    );

    return utf8.decode(plainBytes);
  }

  /// Derives a key from the given [passphrase] and [saltBytes] with the given [length].
  ///
  /// The method works by first encoding the [passphrase] into bytes and then
  /// combining the bytes with the given [saltBytes]. The combined bytes are then
  /// repeated until their length is at least [length]. The resulting bytes are
  /// then trimmed to [length] bytes and returned as the derived key.
  static List<int> _deriveKey(
      String passphrase, List<int> saltBytes, int length) {
    final passBytes = utf8.encode(passphrase);

    final combined = <int>[];
    combined.addAll(passBytes);
    combined.addAll(saltBytes);

    final repeated = <int>[];
    while (repeated.length < length) {
      repeated.addAll(combined);
    }

    return repeated.sublist(0, length);
  }
}
