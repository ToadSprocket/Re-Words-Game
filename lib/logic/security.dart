// Copyright © 2025 Riverstone Entertainment. All Rights Reserved.
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/config.dart';

class Security {
  static String generateApiKeyHash() {
    final saltBytes = utf8.encode(Config.ApiSalt); // Plain string, no base64
    final keyBytes = utf8.encode(Config.ApiKey);
    final bytesToHash = saltBytes + keyBytes;
    return sha512.convert(bytesToHash).toString();
  }
}
