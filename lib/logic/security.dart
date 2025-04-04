// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/config.dart';

class Security {
  static String generateApiKeyHash() {
    final saltBytes = utf8.encode(Config.getApiSalt()); // Plain string, no base64
    final keyBytes = utf8.encode(Config.getApiKey());
    final bytesToHash = saltBytes + keyBytes;
    return sha512.convert(bytesToHash).toString();
  }
}
