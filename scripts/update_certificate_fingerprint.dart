// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// This script helps with certificate rotation by extracting the certificate
/// fingerprint from the server and updating the Config class.
///
/// Usage:
/// ```
/// dart scripts/update_certificate_fingerprint.dart
/// ```
void main() async {
  final domain = 'rewordgame.net';
  final configPath = 'lib/config/config.dart';

  print('🔒 Certificate Fingerprint Updater');
  print('==================================');
  print('Domain: $domain');

  try {
    // Get the certificate fingerprint
    final fingerprint = await getCertificateFingerprint(domain);
    print('✅ Successfully retrieved certificate fingerprint:');
    print(fingerprint);

    // Update the Config class
    final success = await updateConfigFile(configPath, fingerprint);
    if (success) {
      print('✅ Successfully updated $configPath');
      print('🎉 Certificate fingerprint has been updated!');
    } else {
      print('❌ Failed to update $configPath');
    }
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

/// Update the Config class with the new certificate fingerprint
Future<bool> updateConfigFile(String path, String fingerprint) async {
  final file = File(path);
  if (!await file.exists()) {
    throw Exception('Config file not found: $path');
  }

  final content = await file.readAsString();

  // Find the certificate fingerprint line and replace it
  final pattern = 'static const String certificateFingerprint =';
  final index = content.indexOf(pattern);

  if (index == -1) {
    throw Exception('Certificate fingerprint not found in $path');
  }

  // Find the semicolon after the fingerprint
  final semicolonIndex = content.indexOf(';', index);
  if (semicolonIndex == -1) {
    throw Exception('Invalid format in $path');
  }

  // Create the new content
  final before = content.substring(0, index);
  final after = content.substring(semicolonIndex);
  final replacement = '$pattern\n      "$fingerprint"';
  final newContent = before + replacement + after;

  // Write the updated content
  await file.writeAsString(newContent);

  return true;
}
