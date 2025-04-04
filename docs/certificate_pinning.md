# Certificate Pinning Implementation

This document explains the certificate pinning implementation in the Reword Game app and provides instructions for certificate rotation.

## What is Certificate Pinning?

Certificate pinning is a security technique that associates a host (like your game server) with its expected X.509 certificate or public key. When implemented, your app will only trust connections to your server if they present the exact certificate or key that you've "pinned" in your code.

## Why Certificate Pinning?

Without certificate pinning, your app is vulnerable to man-in-the-middle (MITM) attacks in certain scenarios:

1. **Compromised Certificate Authorities (CAs)**: If a CA is compromised, attackers could issue fraudulent certificates for your domain.
2. **Local Security Compromises**: If a user's device has a malicious root certificate installed, an attacker could intercept and decrypt all HTTPS traffic.
3. **DNS Hijacking**: If an attacker can redirect traffic through DNS manipulation, they could present their own valid certificate for your domain.

## Implementation Details

The certificate pinning implementation in the Reword Game app consists of the following components:

1. **SecureHttpClient**: A custom HTTP client that implements certificate pinning using the Dio package.
2. **Config**: Configuration settings for certificate pinning, including the certificate fingerprint.
3. **Certificate Fingerprint Extractor**: A script to extract the certificate fingerprint from the server.

### SecureHttpClient

The `SecureHttpClient` class in `lib/utils/secure_http_client.dart` implements certificate pinning using the Dio package. It verifies that the server's certificate matches the expected fingerprint stored in the `Config` class.

### Config

The `Config` class in `lib/config/config.dart` contains configuration settings for certificate pinning:

```dart
// Certificate pinning configuration
static const bool enableCertificatePinning = true; // Set to false to disable certificate pinning
static const String certificateFingerprint =
    'DD:E9:59:7B:3C:5D:3F:11:00:85:06:6D:B4:5E:1B:80:16:F8:3A:2A:30:5C:33:BF:45:E5:4B:67:CF:05:3B:14';
```

### Certificate Fingerprint Extractor

The `get_certificate_fingerprint.dart` script in the `scripts` directory extracts the certificate fingerprint from the server. This script is used during certificate rotation to get the new certificate fingerprint.

## Certificate Rotation

The certificate for rewordgame.net is managed by Certbot and is set to expire in 58 days. When the certificate is renewed, you'll need to update the certificate fingerprint in the app.

### Certificate Rotation Process

1. Run the certificate fingerprint extractor script:

```bash
dart scripts/get_certificate_fingerprint.dart
```

2. Copy the new certificate fingerprint and update the `certificateFingerprint` constant in `lib/config/config.dart`.

3. Test the app to ensure it can connect to the server with the new certificate.

4. Release a new version of the app with the updated certificate fingerprint.

### Handling Certificate Rotation in Production

To handle certificate rotation in production, you have several options:

1. **Temporary Disable Certificate Pinning**: Set `enableCertificatePinning` to `false` in `lib/config/config.dart` during the certificate rotation period. This will allow the app to connect to the server with the new certificate, but it will also make the app vulnerable to MITM attacks during this period.

2. **Pin Multiple Certificates**: Update the `SecureHttpClient` class to accept multiple certificate fingerprints. This will allow the app to connect to the server with either the old or new certificate.

3. **Remote Configuration**: Implement a remote configuration system that allows you to update the certificate fingerprint without releasing a new version of the app.

## Security Considerations

- **Backup Fingerprints**: Consider pinning multiple certificates or implementing a backup mechanism in case the primary certificate is compromised.

- **Fallback Mechanism**: Implement a fallback mechanism that allows the app to connect to the server even if certificate pinning fails. This should be used only as a last resort and should be carefully designed to avoid security vulnerabilities.

- **Testing**: Thoroughly test the certificate pinning implementation to ensure it works correctly and doesn't cause connectivity issues.
