// Copyright © 2026 Digital Relics. All Rights Reserved.
import 'dart:io';
import 'package:crypto/crypto.dart';

/// This script extracts the certificate fingerprint from a server
/// and prints it to the console. The user can then manually update
/// the Config class with the new fingerprint.
///
/// Usage:
/// ```
/// dart scripts/get_certificate_fingerprint.dart
/// ```
void main() async {
  final domain = 'rewordgame.net';

  print('🔒 Certificate Fingerprint Extractor');
  print('====================================');
  print('Domain: $domain');

  try {
    // Get the certificate fingerprint
    final fingerprint = await getCertificateFingerprint(domain);
    print('\n✅ Successfully retrieved certificate fingerprint:');
    print('\n$fingerprint\n');

    print('To update your app, copy this fingerprint and replace the existing one in:');
    print('lib/config/config.dart');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

/// Get the certificate fingerprint for a domain
Future<String> getCertificateFingerprint(String domain) async {
  final socket = await SecureSocket.connect(domain, 443, timeout: Duration(seconds: 10));

  try {
    // Get the certificate
    final cert = socket.peerCertificate;
    if (cert == null) {
      throw Exception('Failed to get certificate from $domain');
    }

    // Calculate the SHA-256 fingerprint
    final digest = sha256.convert(cert.der);
    final fingerprint = formatFingerprint(digest.bytes);

    return fingerprint;
  } finally {
    socket.destroy();
  }
}

/// Format the fingerprint to match the OpenSSL format
String formatFingerprint(List<int> bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
}
