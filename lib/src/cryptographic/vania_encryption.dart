import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class VaniaEncryption {
  static IV iv = IV(Uint8List(16));

  /// Encrypts the given [plainText] using the provided [passphrase].
  ///
  /// This method first encodes the [plainText] using Base64 and UTF-8 encoding.
  /// Then, it creates a cryptographic key from the [passphrase] and uses the
  /// AES encryption algorithm to encrypt the text with a predefined initialization
  /// vector (IV). The result is an encrypted string returned in Base64 format.
  ///
  /// Parameters:
  /// - [plainText]: The text to be encrypted.
  /// - [passphrase]: The passphrase used to generate the encryption key.
  ///
  /// Returns:
  /// A Base64 encoded string representing the encrypted text.
  static String encryptString(String plainText, String passphrase) {
    plainText = base64.encode(utf8.encode(plainText));
    Key key = Key.fromUtf8(passphrase.substring(0, 32));
    Encrypter encrypter = Encrypter(AES(key));
    Encrypted encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  /// Decrypts the given [encryptedText] using the provided [passphrase].
  ///
  /// This method first creates a cryptographic key from the [passphrase].
  /// It then uses the AES encryption algorithm to decrypt the [encryptedText]
  /// with a predefined initialization vector (IV). The decrypted text is
  /// decoded from Base64 and UTF-8 encoding to return the original plain text.
  ///
  /// Parameters:
  /// - [encryptedText]: The text to be decrypted, in Base64 format.
  /// - [passphrase]: The passphrase used to generate the decryption key.
  ///
  /// Returns:
  /// The original plain text if decryption is successful, or an empty
  /// string if decryption fails.
  static String decryptString(String encryptedText, String passphrase) {
    try {
      Key key = Key.fromUtf8(passphrase.substring(0, 32));
      Encrypter encrypter = Encrypter(AES(key));
      String decrypted = encrypter.decrypt64(encryptedText, iv: iv);
      return utf8.decode(base64.decode(decrypted));
    } catch (error) {
      return '';
    }
  }
}
