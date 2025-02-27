import 'dart:convert';
import 'package:fernet/fernet.dart';
import 'package:crypto/crypto.dart';
import '../config/config.dart';

class Security {
  static String _decrypt(String encryptedText, String key) {
    final fernet = Fernet(key);
    final decrypted = fernet.decrypt(encryptedText);
    return utf8.decode(decrypted);
  }

  static String generateApiKeyHash() {
    final apiKey = _decrypt(Config.encryptedApiKey, Config.fernetKey);
    final apiSalt = _decrypt(Config.encryptedApiSalt, Config.fernetKey);
    final saltBytes = base64Decode(apiSalt);
    final keyBytes = utf8.encode(apiKey);
    final bytesToHash = saltBytes + keyBytes;
    return sha512.convert(bytesToHash).toString();
  }
}
